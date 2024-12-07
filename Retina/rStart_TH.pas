unit rStart_TH;

interface

uses
  Classes, SysUtils, ABL.Core.Debug, Windows, rReceiverList_Cl, rDecoderList_Cl, rPlugin_Cl, rData_DM, DB,
  cHalter_TH, IniFiles;

type
  /// <summary>
  /// Поток запускающий необходимые потоки для работы службы.
  /// Сделано так вместо работы внутри события запуска службы, чтобы ОС не ждала логического запуска службы, а сразу считала её работающей
  /// </summary>
  TStartTH = class(TThread)
  protected
    procedure Execute; override;
  end;

function CoInitialize(pvReserved: Pointer): HResult; stdcall;
procedure CoUninitialize; stdcall;

function CoInitialize; external 'ole32.dll' name 'CoInitialize';
procedure CoUninitialize; external 'ole32.dll' name 'CoUninitialize';

procedure StopAllStarted;

implementation

/// <summary>
/// Процедура для остановки всего запущенного при старте службы.
/// Сделано так вместо работы внутри события запуска службы, чтобы была централизованная и гарантированно единая секция uses.
/// </summary>
procedure StopAllStarted;
//var
//  Camera: TCamera;
begin
  try
    SendDebugMsg('rStart_TH.StopAllStarted 37');
    if assigned(Halter) then
      Halter.Free;
    if assigned(ReceiverList) then
      ReceiverList.Free;
    if assigned(DecoderList) then
      DecoderList.Free;
//    if assigned(PluginList) then
//      PluginList.Free;
//    SendDebugMsg('rStart_TH.StopAllStarted 47: PluginList остановлен');
    if assigned(DataDM) then
      FreeAndNil(DataDM);
    SendDebugMsg('rStart_TH.StopAllStarted 48: DataDM остановлен');
  except on e: Exception do
    SendErrorMsg('rStart_TH.StopAllStarted 73: '+e.ClassName+' - '+e.Message);
  end;
end;

{ TStartTH }

procedure TStartTH.Execute;
var
  VerString: string;
  AHandle,vSize: Cardinal;
  Buffer: PChar;
  FileVersion: PVSFixedFileInfo;
  AFMask,w: integer;
  lSFile: TSearchRec;
  PPoint: Pointer;
  DataSet: TDataSet;
  tmpPlugin: TPlugin;
  FConnectionString: TStringList;
begin
  Sleep(6000);
  FreeOnTerminate:=true;
  try
    SetCurrentDir(ExtractFilePath(ParamStr(0)));
    VerString:='<версия не известна>';
    vSize:=GetFileVersionInfoSize(PChar(ParamStr(0)),AHandle);
    Buffer:=AllocMem(vSize+1);
    try
      if GetFileVersionInfo(PChar(ParamStr(0)),AHandle,vSize,Buffer) then
        if VerQueryValue(Buffer,'\',Pointer(FileVersion),UINT(vSize)) then
          if vSize>=SizeOf(TVSFixedFileInfo) then
            VerString:=IntToStr(HIWORD(FileVersion.dwFileVersionMS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionMS))+'.'+
                IntToStr(HIWORD(FileVersion.dwFileVersionLS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionLS));
    finally
      FreeMem(Buffer,vSize+1);
    end;
    SendDebugMsg('TStartTH.Execute 100: '+VerString);
    //запрет на использование ядра 0
    if ProcessorCount>2 then
    begin
      //значение маски=(2 в_степени <кол-во_процессоров> - 2)
      //(14 для 4 ядер; 62 для 6; 254 для 8 и т.д.)
      AFMask:=2;
      for w:=2 to ProcessorCount do
        AFMask:=AFMask*2;
      AFMask:=AFMask-2;
      SetProcessAffinityMask(GetCurrentProcess,AFMask);
    end;
    ReceiverList:=TReceiverList.Create(false);
    DecoderList:=TDecoderList.Create(false);
    CoInitialize(nil);
    try
      FConnectionString:=TStringList.Create;
      try
        With TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
          try
            ReadSectionValues('CONNECTION',FConnectionString);
          finally
            Free;
          end;
        DataDM:=TDataDM.Create(FConnectionString.Text);
      finally
        FreeAndNil(FConnectionString);
      end;
      if DataDM.Connected then
      begin
        DataDM.InitializeModule;
        if DataDM.DBType='PG' then
          DataSet:=DataDM.tPluginPG
        else
          DataSet:=DataDM.tPluginMS;
        DataSet.Open;
        if FindFirst(ExtractFilePath(ParamStr(0))+'\*.dll',faAnyFile,lSFile) = 0 then
        try
          repeat
            if (string(lSFile.Name).StartsWith('cp')) and ((ExtractFileExt(lSFile.Name))='.dll') then
            begin
              if not DataSet.Locate('FileName',lSFile.Name,[]) then
              begin
                tmpPlugin:=PluginList.PluginByFileName(lSFile.Name);
                DataDM.ExecSQL('INSERT INTO Plugin (Name,FileName) VALUES ('''+tmpPlugin.Name+''','''+lSFile.Name+''')');
              end;
            end;
          until (FindNext(lSFile) <> 0);
        finally
          SysUtils.FindClose(lSFile);
        end;
        DataSet.Close;
        DataSet.Open;
      end;
    finally
      CoUninitialize;
    end;
    if DataDM.DBType='PG' then
      DataSet:=DataDM.qPluginPG
    else
      DataSet:=DataDM.qPluginMS;
    //идём по НД плугинских подключений
    DataSet.Open;
    SendDebugMsg('TStartTH.Execute 153: DataDM.qPlugin.RecordCount='+IntToStr(DataSet.RecordCount));
    DataSet.First;
    while not DataSet.Eof do
    begin
      if FileExists(ExtractFilePath(ParamStr(0))+DataSet.FieldByName('FileName').AsString) then
      begin
        tmpPlugin:=PluginList.PluginByFileName(DataSet.FieldByName('FileName').AsString);
        if tmpPlugin.Active then
        begin
          PPoint:=tmpPlugin.TryConnect(DataSet.FieldByName('ID_Camera').AsInteger,DataSet.FieldByName('APrimary').AsBoolean);
          if PPoint<>nil then
          begin
            DecoderList.DecoderByCamera(DataSet.FieldByName('ID_Camera').AsInteger,DataSet.FieldByName('APrimary').AsBoolean);
            ReceiverList.ReceiverByCamera(DataSet.FieldByName('ID_Camera').AsInteger,DataSet.FieldByName('APrimary').AsBoolean);
          end;
        end;
      end;
      DataSet.Next;
    end;
   Halter:=THalter.Create(15000);
  except on e: Exception do
    SendErrorMsg('TStartTH.Execute 154: '+e.ClassName+' - '+e.Message);
  end;
  Terminate;
end;

end.
