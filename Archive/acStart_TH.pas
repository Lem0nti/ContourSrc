unit acStart_TH;

interface

uses
  Classes, SysUtils, Windows, acHTTPReceiver_DM, ABL.Core.Debug, acData_DM, IniFiles;

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
begin
  try
    SendDebugMsg('StopAllStarted 29');
    if assigned(HTTPReceiverDM) then
      FreeAndNil(HTTPReceiverDM);
    SendDebugMsg('StopAllStarted 36');
  except on e: Exception do
    SendErrorMsg('StopAllStarted 38: '+e.ClassName+' - '+e.Message);
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
  FConnectionString: TStringList;
begin
  FreeOnTerminate:=true;
  try
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
      SendDebugMsg('TStartTH.Execute 56: '+VerString);
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
          HTTPReceiverDM:=THTTPReceiverDM.Create(nil);
        end;
      finally
        CoUninitialize;
      end;
    except on e: Exception do
      SendErrorMsg('TStartTH.Execute 86: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Terminate;
  end;
end;

end.
