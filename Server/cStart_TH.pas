unit cStart_TH;

interface

uses
  Classes, SysUtils, ABL.Core.Debug, Windows, ABL.Core.ThreadController, cData_DM, DB, cCamera_Cl, cVideoSaver_TH,
  cSlider_TH, cCutVideo_TH, cClient_Cl, cScheduleTypes, cHalter_TH, IniFiles,
  cCommon, Contnrs, cConnectoionController_TH, cAlarmer_TH, ABL.Core.ThreadQueue, cIndexSaver_TH, cMotionSaver_TH;

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
var
  Camera: TCamera;
begin
  try
    SendDebugMsg('sStart_TH.StopAllStarted 37');
    if assigned(Halter) then
      Halter.Free;
    if assigned(ConnectWaitThread) then
      ConnectWaitThread.Terminate;
    if assigned(ConnectionController) then
      ConnectionController.Stop;
    SendDebugMsg('sStart_TH.StopAllStarted 41: ConnectionController остановлен');
    while AllCameras.Count>0 do
    begin
      Camera:=TCamera(AllCameras[0]);
      Camera.Free;
    end;
    SendDebugMsg('sStart_TH.StopAllStarted 46: камеры остановлены');
    if assigned(Alarmer) then
      Alarmer.Terminate;
    SendDebugMsg('sStart_TH.StopAllStarted 49: Alarmer остановлен');
    if assigned(VideoSaver) then
      VideoSaver.Free;
    if assigned(IndexSaver) then
      IndexSaver.Free;
    if assigned(MotionSaver) then
      MotionSaver.Free;
    if assigned(Slider) then
      Slider.Free;
    if assigned(CutVideo) then
      CutVideo.Free;
    if assigned(DataDM) then
      FreeAndNil(DataDM);
  except on e: Exception do
    SendErrorMsg('rStart_TH.StopAllStarted 73: '+e.ClassName+' - '+e.Message);
  end;
end;

{ TStartTH }

procedure TStartTH.Execute;
var
  VerString,ArchList: string;
  AHandle,vSize: Cardinal;
  Buffer: PChar;
  FileVersion: PVSFixedFileInfo;
  AFMask,w,CDay: integer;
  Camera: TCamera;
  tmpID_Camera: integer;
  Schedule: TWeekDay;
  tCameraDataSet,tSchedule: TDataSet;
  FConnectionString: TStringList;
begin
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
    SendDebugMsg('TStartTH.Execute 89: '+VerString);
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
        ArchList:=trim(DataDM.GetArchives);
        if ArchList='' then
        begin
          SendErrorMsg('TStartTH.Execute 90: нет путей сохранения видео');
          exit;
        end
        else
        begin
          if DataDM.DBType='PG' then
          begin
            tCameraDataSet:=DataDM.tCameraPG;
            tSchedule:=DataDM.tSchedulePG;
          end
          else
          begin
            tCameraDataSet:=DataDM.tCameraMS;
            tSchedule:=DataDM.tScheduleMS;
          end;
          tCameraDataSet.Open;
          if not tCameraDataSet.IsEmpty then
          begin
            ThreadController.LogMem:=256;
            IndexSaver:=TIndexSaver.Create('IndexSaver');
            VideoSaver:=TVideoSaver.Create(ArchList);
            VideoSaver.SetOutputQueue(IndexSaver.InputQueue);
            IndexSaver.Active:=true;
            MotionSaver:=TMotionSaver.Create(ThreadController.QueueByName('MotionQueue'));
            Slider:=TSlider.Create(ThreadController.QueueByName('SliderQueue'),ArchList);
            while not tCameraDataSet.Eof do
            begin
              if tCameraDataSet.FieldByName('ConnectionString').AsString<>'' then
              begin
                tmpID_Camera:=tCameraDataSet.FieldByName('ID_Camera').AsInteger;
                Camera:=TCamera.Create(tmpID_Camera,tCameraDataSet.FieldByName('ConnectionString').AsString,tCameraDataSet.FieldByName('Secondary').AsString);
                if tCameraDataSet.FieldByName('Schedule_Type').AsInteger=3 then  //свободное расписание)
                begin
                  tSchedule.Open;
                  tSchedule.Filter:='ID_Camera='+IntToStr(tmpID_Camera);
                  try
                    tSchedule.Filtered:=true;
                    try
                      while not tSchedule.Eof do
                      begin
                        CDay:=tSchedule.FieldByName('Day').AsInteger;
                        if CDay in [1..7] then
                        begin
                          Schedule[CDay].DayBegin:=tSchedule.FieldByName('SBegin').AsInteger;
                          Schedule[CDay].DayEnd:=tSchedule.FieldByName('SEnd').AsInteger;
                        end;
                        tSchedule.Next;
                      end;
                    finally
                      tSchedule.Filtered:=false;
                    end;
                  finally
                    tSchedule.Filter:='';
                  end;
                end;
                Camera.ApplySchedule(tCameraDataSet.FieldByName('Schedule_Type').AsInteger,Schedule);
              end;
              tCameraDataSet.Next;
            end;
          end
          else
            SendErrorMsg('TStartTH.Execute 93: нет видеокамер для записи');
          ConnectionController:=TConnectionController.Create;
          Alarmer:=TAlarmer.Create(TThreadQueue(ThreadController.QueueByName('AlarmerQueue')));
          CutVideo:=TCutVideo.Create(ArchList);
          ThreadController.LogPerformanceValue:=32;
        end;
      end;
    finally
      CoUninitialize;
    end;
    ConnectWaitThread:=TConnectWaitThread.Create;
    Halter:=THalter.Create;
  except on e: Exception do
    SendErrorMsg('TStartTH.Execute 154: '+e.ClassName+' - '+e.Message);
  end;
  Terminate;
end;

end.
