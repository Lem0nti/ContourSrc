unit cCamera_Cl;

interface

uses
  ABL.VS.RTSPReceiver, ABL.Core.ThreadQueue, SysUtils, cFrameGrabber_TH, cFrameCollector_TH, cVideoSaver_TH,
  cCommon, Windows, ABL.Core.Debug, Classes, Contnrs, Types, ABL.Core.QueueMultiplier,
  ABL.VS.VideoDecoder, cScheduleTypes,
  cMotionDetector_TH, ABL.VS.FFMPEG, cMotionSaver_TH, cSlider_TH, {ABL.VS.DecodedMultiplier, }cPrepareSlide_TH;

type
  TCamera=class
  private
    FConnectTryCount: integer;
    FID_Camera: integer;
    FLastConnect: TDateTime;
    FLock: TRTLCriticalSection;
    PrimaryReceiver, SecondaryReceiver: TRTSPReceiver;
    PrimaryOutput, SecondaryOutput, FramesQueue, SecondaryGrabberQueue, SecondaryDecoderQueue, DecodedQueue: TThreadQueue;
    PrimaryGrabber, SecondaryGrabber: TFrameGrabber;
    FrameCollector: TFrameCollector;
    FConnectionString, FSecondaryConnection: string;
    SecondaryMultiplier: TQueueMultiplier;
    SecondaryDecoder: TVideoDecoder;
    MotionDetector: TMotionDetector;
    PrepareSlide: TPrepareSlide;
    DecodedMultiplier: TQueueMultiplier;
    function GetLastInput: TDateTime;
    function GetConnectTryCount: integer;
    function GetSecondaryExist: boolean;
    function GetLastSecondaryInput: TDateTime;
  public
    constructor Create(AID_Camera: integer; AConnectionString: string; ASecondaryConnection: String = '');
    destructor Destroy; override;
    procedure ApplySchedule(AScheduleType: byte; ASchedule: TWeekDay);
    procedure ReconnectSecondary;
    procedure TryConnect;
    property ConnectTryCount: integer read GetConnectTryCount;
    property ID_Camera: integer read FID_Camera;
    property LastInput: TDateTime read GetLastInput;
    property LastSecondaryInput: TDateTime read GetLastSecondaryInput;
    property SecondaryExist: boolean read GetSecondaryExist;
  end;

implementation

{ TCamera }

procedure TCamera.ApplySchedule(AScheduleType: byte; ASchedule: TWeekDay);
begin
  FrameCollector.ApplySchedule(AScheduleType,ASchedule);
  if AScheduleType=4 then
    MotionDetector.ApplyIncSave(FrameCollector.IncSave)
end;

constructor TCamera.Create(AID_Camera: integer; AConnectionString, ASecondaryConnection: String);
begin
  FID_Camera:=AID_Camera;
  FConnectionString:=AConnectionString;
  FSecondaryConnection:=ASecondaryConnection;
  InitializeCriticalSection(FLock);
  FLastConnect:=0;
  PrimaryOutput:=TThreadQueue.Create('TCamera_'+IntToStr(AID_Camera)+'_PrimaryOutput');
  SecondaryOutput:=TThreadQueue.Create('TCamera_'+IntToStr(AID_Camera)+'_SecondaryOutput');
  FramesQueue:=TThreadQueue.Create('TCamera_'+IntToStr(AID_Camera)+'_FramesQueue');
  PrimaryReceiver:=TRTSPReceiver.Create(PrimaryOutput,'TCamera_'+IntToStr(AID_Camera)+'_PrimaryReceiver',AConnectionString);
  PrimaryGrabber:=TFrameGrabber.Create(PrimaryOutput,FramesQueue,FID_Camera,true,'TCamera_'+IntToStr(AID_Camera)+'_PrimaryGrabber');
  if FSecondaryConnection<>'' then
  begin
    SecondaryReceiver:=TRTSPReceiver.Create(SecondaryOutput,'TCamera_'+IntToStr(AID_Camera)+'_SecondaryReceiver',ASecondaryConnection);
    SecondaryMultiplier:=TQueueMultiplier.Create(SecondaryOutput,'TCamera_'+IntToStr(AID_Camera)+'_SecondaryMultiplier');
    SecondaryGrabberQueue:=TThreadQueue.Create('TCamera_'+IntToStr(AID_Camera)+'_SecondaryGrabberQueue');
    SecondaryMultiplier.AddReceiver(SecondaryGrabberQueue);
    SecondaryGrabber:=TFrameGrabber.Create(SecondaryGrabberQueue,FramesQueue,FID_Camera,false,'TCamera_'+IntToStr(AID_Camera)+'_SecondaryGrabber');
    SecondaryDecoderQueue:=TThreadQueue.Create('TCamera_'+IntToStr(AID_Camera)+'_SecondaryDecoderQueue');
    SecondaryMultiplier.AddReceiver(SecondaryDecoderQueue);
    MotionDetector:=TMotionDetector.Create('TCamera_'+IntToStr(AID_Camera)+'_MotionDetector');
    MotionDetector.ID_Camera:=AID_Camera;
    MotionDetector.Active:=true;
    DecodedQueue:=TThreadQueue.Create('TCamera_'+IntToStr(AID_Camera)+'_DecodedQueue');
    SecondaryDecoder:=TVideoDecoder.Create(SecondaryDecoderQueue,DecodedQueue,AV_CODEC_ID_H264,'TCamera_'+IntToStr(AID_Camera)+'_SecondaryDecoder');
    DecodedMultiplier:=TQueueMultiplier.Create(DecodedQueue,'TCamera_'+IntToStr(AID_Camera)+'_DecodedMultiplier');
    DecodedMultiplier.AddReceiver(MotionDetector.InputQueue);
    PrepareSlide:=TPrepareSlide.Create('TCamera_'+IntToStr(AID_Camera)+'_PrepareSlide');
    PrepareSlide.ID_Camera:=AID_Camera;
    PrepareSlide.Active:=true;
    DecodedMultiplier.AddReceiver(PrepareSlide.InputQueue);
    MotionDetector.SetOutputQueue(MotionSaver.InputQueue);
    PrepareSlide.SetOutputQueue(Slider.InputQueue);
  end;
  FrameCollector:=TFrameCollector.Create(FramesQueue,VideoSaver.InputQueue,'TCamera_'+IntToStr(AID_Camera)+'_FrameCollector');
  AllCameras.Add(self);
end;

destructor TCamera.Destroy;
begin
  AllCameras.Remove(self);
  DeleteCriticalSection(FLock);
  FreeAndNil(PrimaryReceiver);
  FreeAndNil(PrimaryGrabber);
  if assigned(SecondaryReceiver) then
    FreeAndNil(SecondaryReceiver);
  if assigned(SecondaryMultiplier) then
    FreeAndNil(SecondaryMultiplier);
  if assigned(SecondaryGrabber) then
    FreeAndNil(SecondaryGrabber);
  if assigned(SecondaryDecoder) then
    FreeAndNil(SecondaryDecoder);
  if assigned(MotionDetector) then
    FreeAndNil(MotionDetector);
  if assigned(DecodedMultiplier) then
    FreeAndNil(DecodedMultiplier);
  if assigned(PrepareSlide) then
    FreeAndNil(PrepareSlide);
  FreeAndNil(FrameCollector);
  inherited;
end;

function TCamera.GetConnectTryCount: integer;
begin
  EnterCriticalSection(FLock);
  try
    if FLastConnect<trunc(now) then
    begin
      FConnectTryCount:=0;
      FLastConnect:=trunc(now);
    end;
    result:=FConnectTryCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TCamera.GetLastInput: TDateTime;
begin
  result:=PrimaryOutput.LastInput;
end;

function TCamera.GetLastSecondaryInput: TDateTime;
begin
  if FSecondaryConnection='' then
    result:=now
  else
    Result:=SecondaryOutput.LastInput;
end;

function TCamera.GetSecondaryExist: boolean;
begin
  EnterCriticalSection(FLock);
  try
    result:=FSecondaryConnection<>'';
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TCamera.ReconnectSecondary;
begin
  try
    if assigned(SecondaryReceiver) then
    begin
      SecondaryReceiver.Active:=false;
      SecondaryReceiver.Active:=true;
      if not SecondaryReceiver.Active then
        SendErrorMsg('TCamera.ReconnectSecondary 152: подключение не удалось к вторичному потоку ('+FSecondaryConnection+')');
    end;
  except on e: Exception do
    SendErrorMsg('TCamera.ReconnectSecondary 168: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TCamera.TryConnect;
var
  StrNum: string;
begin
  EnterCriticalSection(FLock);
  try
    StrNum:='174';
    try
      //если есть что-то в буффере кадров, то отправить на сохранение
      if FLastConnect<trunc(now) then
      begin
        FConnectTryCount:=0;
        FLastConnect:=trunc(now);
      end;
      inc(FConnectTryCount);
      if ConnectTryCount>=256 then
      begin
        if ConnectTryCount<257 then  //это чтобы в лог билось только раз
          SendErrorMsg('TCamera.TryConnect 188: слишком много переподключений за сутки для камеры '+IntToStr(FID_Camera)+' ('+IntToStr(ConnectTryCount)+'), останавливаю попытки')
      end
      else
      begin
        StrNum:='191';
        PrimaryReceiver.Active:=false;
        StrNum:='193';
        PrimaryGrabber.DropList;
        PrimaryReceiver.Active:=true;
        StrNum:='197';
        if PrimaryReceiver.Active then
        begin
          StrNum:='198';
          FLastConnect:=now;
          StrNum:='200';
          ReconnectSecondary;
        end
        else
          SendErrorMsg('TCamera.TryConnect 203: подключение не удалось ('+FConnectionString+')');
      end;
    except on e: Exception do
      SendErrorMsg('TCamera.TryConnect 206, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

end.
