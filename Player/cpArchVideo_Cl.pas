unit cpArchVideo_Cl;

interface

uses
  Generics.Collections, acTypes, Classes, Windows, ABL.Core.Debug, SysUtils, SyncObjs, Types, cCommon,
  DateUtils, cpArchManager_TH, Math, ABL.Core.DirectThread, ABL.Render.Drawer,
  cpTypes, ABL.Core.ThreadItem, ABL.VS.VideoDecoder, ABL.Render.DirectRender, ABL.VS.FFMPEG,
  ABL.IO.IOTypes, ABL.Core.ThreadController, ABL.IA.ImageCutter;

type
  TPlayThread=class;

  PLoadCommand=^TLoadCommand;
  TLoadCommand=record
    Server,Camera: integer;
    DateTime: TDateTime;
    NextType: TNextType;
    Primary: Boolean;
  end;

  TLoader=class(TDirectThread)
  private
    FInLoad: boolean;
    FPlayThread: TPlayThread;
    function GetInLoad: boolean;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(APlayThread: TPlayThread); reintroduce;
    procedure LoadVideo(AServer, ACamera: integer; ADateTime: TDateTime; NextType: TNextType; APrimary: boolean);
    property InLoad: boolean read GetInLoad;
  end;

  TPlayState = (psStop, psPlay, psStepforward, psStepbackward, psPlayRewind);

  Tcbf = procedure(Server, Camera: integer; DateTime: int64); stdcall;
  Tcbd = procedure(Server, Camera: integer; DateTime: int64; DC: HDC; Width, Height: integer); stdcall;

  TPlayThread=class(TThread)
  private
    FZoomRect: TRect;
    FID_Server, FID_Camera: integer;
    FCommand: TEvent;
    FHandle: HWND;
    FLock: TRTLCriticalSection;
    Frames: TList<PTimedDataHeader>;
    Loader: TLoader;
    OldTime: int64;
    Position: integer;
    Render: TDirectRender;
    FPrimary: boolean;
    ImageCutter: TImageCutter;
    procedure CheckFramesCount;
    procedure DoNeedLoad;
    procedure FramePause(AFromTime: UInt64);
    procedure SetHandle(const Value: HWND);
    procedure SetPrimary(const Value: boolean);
    function GetPrimary: boolean;
    function GetFocusRect: TRect;
    procedure SetFocusRect(const Value: TRect);
    function GetZoomed: boolean;
    function GetOnDraw: TDrawNotify;
    procedure SetOnDraw(const Value: TDrawNotify);
    function GetID_Camera: integer;
    function GetID_Server: integer;
  protected
    procedure Execute; override;
  public
    Decoder: TVideoDecoder;
    Acbf: Tcbf;
    PlayState: TPlayState;
    MapHandle: THandle;
    Speed: integer;     //x-сервер,y-камера
    constructor Create(AID_Server, AID_Camera: integer; AHandle: HWND; ACameraName: string); reintroduce;
    destructor Destroy; override;
    procedure DropZoom;
    function GetCurTime: TDateTime;
    function LoadFrames(FileName: TFileName; ADay: integer; AClear: boolean=true): boolean;
    procedure LoadVideo(ATime: TDateTime);
    procedure SetPositionByTime(ATime: TDateTime);
    procedure ShowCurrentFrame;
    procedure UpdateScreen;
    procedure ZoomFromFocus;
    property FocusRect: TRect read GetFocusRect write SetFocusRect;
    property Handle: HWND read FHandle write SetHandle;
    property ID_Server: integer read GetID_Server;
    property ID_Camera: integer read GetID_Camera;
    property OnDraw: TDrawNotify read GetOnDraw write SetOnDraw;
    property Primary: boolean read GetPrimary write SetPrimary;
    property Zoomed: boolean read GetZoomed;
  end;

function GetPlayThread(AID_Server, AID_Camera: integer; AName: string): TPlayThread;

implementation

var
  PlayPool: TDictionary<integer, TPlayThread> = nil;

function GetPlayThread(AID_Server, AID_Camera: integer; AName: string): TPlayThread;
var
  tmpPlayThread: TPlayThread;
begin
  if not assigned(PlayPool) then
    PlayPool:=TDictionary<integer, TPlayThread>.Create;
  if not PlayPool.TryGetValue(AID_Server*1000+AID_Camera,tmpPlayThread) then
  begin
    tmpPlayThread:=TPlayThread.Create(AID_Server,AID_Camera,0,AName);
    PlayPool.Add(AID_Server*1000+AID_Camera,tmpPlayThread);
  end;
  result:=tmpPlayThread;
end;

{ TLoader }

constructor TLoader.Create(APlayThread: TPlayThread);
begin
  inherited Create(TThreadItem.Create('Loader_'+IntToStr(APlayThread.FID_Server)+'_'+IntToStr(APlayThread.FID_Camera)),nil);
  FPlayThread:=APlayThread;
  FInLoad:=false;
  Active:=true;
end;

procedure TLoader.DoExecute(var AInputData, AResultData: Pointer);
var
  LoadCommand: PLoadCommand;
  fn: TFileName;
  StrNum: string;
begin
  try
    StrNum:='124';
    FLock.Enter;
    FInLoad:=true;
    FLock.Leave;
    LoadCommand:=PLoadCommand(AInputData);
    fn:=ArchManager.Video(LoadCommand.Server,LoadCommand.Camera,LoadCommand.DateTime,LoadCommand.NextType,LoadCommand.Primary);
    if FileExists(fn) then
    begin
      StrNum:='132';
      FPlayThread.LoadFrames(fn,trunc(LoadCommand.DateTime),LoadCommand.NextType=ntUsual);
      if LoadCommand.NextType=ntUsual then
      begin
        FPlayThread.SetPositionByTime(LoadCommand.DateTime);
        FPlayThread.ShowCurrentFrame;
      end;
    end;
    StrNum:='140';
    FLock.Enter;
    FInLoad:=false;
    FLock.Leave;
  except on e: Exception do
    SendErrorMsg('TLoader.DoExecute 147, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
  end;
end;

function TLoader.GetInLoad: boolean;
begin
  Lock;
  try
    result:=FInLoad;
  finally
    Unlock;
  end;
end;

procedure TLoader.LoadVideo(AServer, ACamera: integer; ADateTime: TDateTime; NextType: TNextType; APrimary: boolean);
var
  LoadCommand: PLoadCommand;
begin
  new(LoadCommand);
  LoadCommand.Server:=AServer;
  LoadCommand.Camera:=ACamera;
  LoadCommand.DateTime:=ADateTime;
  LoadCommand.NextType:=NextType;
  LoadCommand.Primary:=APrimary;
  InputQueue.Push(LoadCommand);
end;

{ TPlayThread }

procedure TPlayThread.CheckFramesCount;
var
  DataFrame: PTimedDataHeader;
  DelCount,FrameType: byte;
begin
  EnterCriticalSection(FLock);
  try
    if Frames.Count>500 then
      if PlayState in [psStepbackward,psPlayRewind] then
      begin
        DataFrame:=Frames[Frames.Count-1];
        while (PByte(NativeUInt(DataFrame.Data)+3)^ and $1F)<>7 do
        begin
          FreeMem(DataFrame);
          Frames.Delete(Frames.Count-1);
          DataFrame:=Frames[Frames.Count-1];
        end;
        FreeMem(DataFrame);
        Frames.Delete(Frames.Count-1);
      end
      else
      begin
        DataFrame:=Frames[0];
        FreeMem(DataFrame);
        Frames.Delete(0);
        DelCount:=1;
        DataFrame:=Frames[0];
        FrameType:=PByte(NativeUInt(DataFrame.Data)+3)^ and $1F;
        while FrameType<>7 do
        begin
          FreeMem(DataFrame);
          Frames.Delete(0);
          inc(DelCount);
          DataFrame:=Frames[0];
          FrameType:=PByte(NativeUInt(DataFrame.Data)+3)^ and $1F;
        end;
        Position:=max(0,Position-DelCount);
      end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

constructor TPlayThread.Create(AID_Server, AID_Camera: integer; AHandle: HWND; ACameraName: string);
begin
  inherited Create(false);
  InitializeCriticalSection(FLock);
  FID_Server:=AID_Server;
  FID_Camera:=AID_Camera;
  FHandle:=AHandle;
  FCommand:=TEvent.Create(nil, true, false, '');
  Render:=TDirectRender.Create('Render_'+IntToStr(FID_Server)+'_'+IntToStr(FID_Camera));
  Render.Handle:=FHandle;
  Render.Drawer.ShowTime:=true;
  Render.CameraName:=ACameraName;
  Decoder:=TVideoDecoder.Create(ThreadController.QueueByName('Decoder_'+IntToStr(FID_Server)+'_'+IntToStr(FID_Camera)+'_Input'),Render.InputQueue,AV_CODEC_ID_H264,
      'Decoder_'+IntToStr(FID_Server)+'_'+IntToStr(FID_Camera));
  Frames:=TList<PTimedDataHeader>.Create;
  Loader:=TLoader.Create(Self);
  MapHandle:=0;
  Speed:=1;
  ImageCutter:=TImageCutter.Create(ThreadController.QueueByName('ImageCutter_'+IntToStr(FID_Server)+'_'+IntToStr(FID_Camera)+'_Input'),
      'ImageCutter_'+IntToStr(FID_Server)+'_'+IntToStr(FID_Camera));
  ImageCutter.Active:=true;
end;

destructor TPlayThread.Destroy;
begin
  if assigned(Loader) then
  begin
    Loader.Stop;
    Loader.SetInputQueue(nil);
    FreeAndNil(Loader);
  end;
  if assigned(Frames) then
    FreeAndNil(Frames);
  if assigned(Decoder) then
    FreeAndNil(Decoder);
  if assigned(Render) then
    FreeAndNil(Render);
  if assigned(FCommand) then
    FreeAndNil(FCommand);
  DeleteCriticalSection(FLock);
  inherited;
end;

procedure TPlayThread.DoNeedLoad;
var
  Cnt: integer;
  TimePoint: int64;
  NextType: TNextType;
begin
  if not Loader.InLoad then
  begin
    Cnt:=Frames.Count;
    if Cnt>0 then
    begin
      //Если вперёд осталось мало кадров, то запросить следующий фрагмент
      if Cnt-Position<64 then
      begin
        TimePoint:=Frames[Cnt-1].Time;
        NextType:=ntNext;
      end
      //Если назад осталось мало кадров, то запросить предыдущий фрагмент
      else if Position<64 then
      begin
        TimePoint:=Frames[0].Time;
        NextType:=ntPrior;
      end
      else
      begin
        TimePoint:=0;
        NextType:=ntUsual;
      end;
      if TimePoint>0 then
        Loader.LoadVideo(FID_Server,FID_Camera,IncMilliSecond(UnixDateDelta,TimePoint),NextType,FPrimary);
    end;
  end;
end;

procedure TPlayThread.DropZoom;
begin
  FZoomRect.Left:=0;
  Decoder.SetOutputQueue(Render.InputQueue);
  Decoder.PushLastFrame;
end;

procedure TPlayThread.Execute;
var
  PushFrame: PTimedDataHeader;
  CTime: UInt64;
  q: PDateTime;
  tmpTime: TDateTime;
  StrNum: string;
begin
  FreeOnTerminate:=true;
  try
    try
      while not Terminated do
      begin
        FCommand.WaitFor(128);
        //проверяем - нет ли команды на терминейт без команды через метод
        if Terminated then
          exit;
        case PlayState of
          //достаём следующий кадр, показываем
          psPlay:
            try
              StrNum:='334';
              if Position<Frames.Count then
              begin
                CTime:=GetTickCount64;
                FCommand.SetEvent;
                GetMem(PushFrame,Frames.Items[Position].DataHeader.Size);
                Move(Frames.Items[Position]^,PushFrame^,Frames.Items[Position].DataHeader.Size);
                PushFrame.Reserved:=0;
                Decoder.InputQueue.Push(PushFrame);
                OldTime:=Frames.Items[Position].Time;
                DoNeedLoad;
                StrNum:='345';
                if MapHandle>0 then
                begin
                  New(q);
                  tmpTime:=IncMilliSecond(UnixDateDelta,Frames.Items[Position].Time);
                  move(tmpTime,q^,SizeOf(TDateTime));
                  PostMessage(MapHandle,WM_SET_CURTIME,Integer(q),1000);
                end;
                inc(Position);
                StrNum:='354';
                if (@Acbf<>nil)and(Position<Frames.Count) then
                  Acbf(FID_Server,FID_Camera,Frames[Position].Time);
                FramePause(CTime);
              end;
            except on e: Exception do
              SendErrorMsg('TPlayThread.Execute 366, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
            end;
          //ничего не делаем
          psStop:
          begin
            FCommand.ResetEvent;
            MapHandle:=0;
            Acbf:=nil;
          end;
          //достаём следующий кадр, показываем, ставим остановку
          psStepforward:
          begin
            if Position<Frames.Count-1 then
              inc(Position);
            ShowCurrentFrame;
            if @Acbf<>nil then
              Acbf(FID_Server,FID_Camera,Frames[Position].Time);
            FCommand.ResetEvent;
            PlayState:=psStop;
            CheckFramesCount;
          end;
          //достаём предыдущий кадр, показываем, ставим остановку
          psStepbackward:
          begin
            if Position>0 then
              dec(Position);
            ShowCurrentFrame;
            if @Acbf<>nil then
              Acbf(FID_Server,FID_Camera,Frames[Position].Time);
            FCommand.ResetEvent;
            PlayState:=psStop;
            CheckFramesCount;
          end;
          //достаём предыдущий кадр, показываем
          psPlayRewind:
          begin
            FCommand.SetEvent;
            if Position>0 then
            begin
              Dec(Position);
              ShowCurrentFrame;
              if @Acbf<>nil then
                Acbf(FID_Server,FID_Camera,Frames[Position].Time);
            end
            else
              PlayState:=psStop;
          end;
        end;
      end;
    except on e: Exception do
      SendErrorMsg('TPlayThread.Execute 401: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Terminate;
  end;
end;

procedure TPlayThread.FramePause(AFromTime: UInt64);
var
  NPause,CTime: UInt64;
begin
  CheckFramesCount;
  if Position<Frames.Count-1 then
  begin
    NPause:=Frames[Position+1].Time-Frames[Position].Time;
    NPause:=min(trunc(max(NPause,0)/Speed),128);
    CTime:=GetTickCount64-AFromTime+5;
    if CTime<NPause then
      sleep(NPause-CTime);
  end;
end;

function TPlayThread.GetCurTime: TDateTime;
begin
  EnterCriticalSection(FLock);
  try
    result:=0;
    if (Position>-1)and(Position<Frames.Count) then
      result:=IncMilliSecond(UnixDateDelta,Frames[Position].Time);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TPlayThread.GetFocusRect: TRect;
begin
  result:=Render.Drawer.FocusRect;
end;

function TPlayThread.GetID_Camera: integer;
begin
  EnterCriticalSection(FLock);
  result:=FID_Camera;
  LeaveCriticalSection(FLock);
end;

function TPlayThread.GetID_Server: integer;
begin
  EnterCriticalSection(FLock);
  result:=FID_Server;
  LeaveCriticalSection(FLock);
end;

function TPlayThread.GetOnDraw: TDrawNotify;
begin
  result:=Render.OnDraw;
end;

function TPlayThread.GetPrimary: boolean;
begin
  EnterCriticalSection(FLock);
  result:=FPrimary;
  LeaveCriticalSection(FLock);
end;

function TPlayThread.GetZoomed: boolean;
begin
  EnterCriticalSection(FLock);
  result:=FZoomRect.Left>0;
  LeaveCriticalSection(FLock);
end;

function TPlayThread.LoadFrames(FileName: TFileName; ADay: integer; AClear: boolean=true): boolean;
var
  ms: TMemoryStream;
  e: integer;
  DataFrame: PTimedDataHeader;
  ACurTime: int64;
  VideoHeader: TVideoHeader;
  FramesList: array of TFrameHeader;
  tmpNow: int64;
  tmpData: Pointer;
  tmpDataSize: Cardinal;
begin
  EnterCriticalSection(FLock);
  try
    result:=false;
    ACurTime:=0;
    try
      if AClear then
        while Frames.Count>0 do
        begin
          DataFrame:=Frames[0];
          FreeMem(DataFrame);
          Frames.Delete(0);
        end
      else if Frames.Count>0 then
        if Position<Frames.Count then
          ACurTime:=Frames[Position].Time
        else
          ACurTime:=Frames.Last.Time;
    except on e: Exception do
      ACurTime:=ACurTime;
    end;
    if FileExists(FileName) then
    begin
      ms:=TMemoryStream.Create;
      try
        ms.LoadFromFile(FileName);
        //ищем кадры
        ms.Position:=0;
        //заголовок видео
        ms.Read(VideoHeader,SizeOf(VideoHeader));
        if VideoHeader.Version=VideoVersion then
        begin
          //заголовки кадров
          SetLength(FramesList,VideoHeader.FrameCount);
          ms.Read(FramesList[0],SizeOf(TFrameHeader)*VideoHeader.FrameCount);
          //кадры
          tmpNow:=MilliSecondsBetween(UnixDateDelta,Now);
          for e:=0 to High(FramesList) do
            if FramesList[e].TimeStamp>tmpNow then
            begin
              SendErrorMsg('TPlayThread.LoadFrames 507: invalid frame time - '+DateTimeToStr(IncMilliSecond(UnixDateDelta,FramesList[e].TimeStamp)));
              exit;
            end
            else
            begin
              tmpDataSize:=FramesList[e].Size+SizeOf(TTimedDataHeader);
              GetMem(tmpData,tmpDataSize);
              DataFrame:=tmpData;
              DataFrame.DataHeader.Magic:=16961;
              DataFrame.DataHeader.DataType:=1;
              DataFrame.DataHeader.Version:=0;
              DataFrame.DataHeader.Size:=tmpDataSize;
              DataFrame.Time:=FramesList[e].TimeStamp;
              DataFrame.Reserved:=0;
              ms.Read(DataFrame.Data^,FramesList[e].Size);
              if DataFrame.Time>ACurTime then
                Frames.Add(DataFrame)
              else  //если не было затирания, то добавлять в соответствующее место
              begin
                Frames.Insert(e,DataFrame);
                inc(Position);
              end;
            end;
        end;
      finally
        FreeAndNil(ms);
      end;
      result:=true;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TPlayThread.LoadVideo(ATime: TDateTime);
begin
  Loader.LoadVideo(FID_Server,FID_Camera,ATime,ntUsual,FPrimary);
end;

procedure TPlayThread.SetFocusRect(const Value: TRect);
begin
  Render.Drawer.FocusRect:=Value;
  Render.UpdateScreen;
end;

procedure TPlayThread.SetHandle(const Value: HWND);
begin
  if FHandle<>Value then
  begin
    FHandle:=Value;
    Render.Handle:=Value;
  end;
end;

procedure TPlayThread.SetOnDraw(const Value: TDrawNotify);
begin
  Render.OnDraw:=Value;
end;

procedure TPlayThread.SetPositionByTime(ATime: TDateTime);
var
  q,CheckIndex: integer;
  MinDiff,CurTimeStamp,CheckDiff,LastDiff: int64;
begin
  CurTimeStamp:=MilliSecondsBetween(ATime,UnixDateDelta);
  MinDiff:=MaxInt;
  LastDiff:=MaxInt;
  CheckIndex:=-1;
  for q := 0 to Frames.Count-1 do
  begin
    CheckDiff:=abs(Frames[q].Time-CurTimeStamp);
    if CheckDiff>=LastDiff then
      break;
    if CheckDiff<MinDiff then
    begin
      MinDiff:=CheckDiff;
      CheckIndex:=q;
    end;
    LastDiff:=CheckDiff;
  end;
  if CheckIndex>-1 then
    Position:=CheckIndex;
end;

procedure TPlayThread.SetPrimary(const Value: boolean);
begin
  FLock.Enter;
  FPrimary:=Value;
  FLock.Leave;
end;

procedure TPlayThread.ShowCurrentFrame;
var
  q,w,sp: integer;
  Frame,PushFrame: PTimedDataHeader;
  tmpData: Pointer;
begin
  if Frames.Count>0 then
  begin
    sp:=0;
    //листаем от текущего назад до 0 или ключевого
    for q := Position downto 0 do
    begin
      Frame:=Frames.Items[q];
      if (q=0)or((PByte(NativeUInt(Frame.Data)+3)^ and $1F)=7) then
      begin
        sp:=q;
        break;
      end;
    end;
    Decoder.InputQueue.Clear;
    for w := sp to Position do
    begin
      Frame:=Frames.Items[w];
      GetMem(tmpData,Frame.DataHeader.Size);
      Move(Frame^,tmpData^,Frame.DataHeader.Size);
      PushFrame:=tmpData;
      if w=Position then
        PushFrame.Reserved:=0
      else
        PushFrame.Reserved:=1;
      Decoder.InputQueue.Push(tmpData);
    end;
    DoNeedLoad;
  end;
end;

procedure TPlayThread.UpdateScreen;
begin
  Render.UpdateScreen;
end;

procedure TPlayThread.ZoomFromFocus;
var
  ppRect: TRect;
begin
  FLock.Enter;
  try
    FZoomRect:=Render.Drawer.FocusRect;
    Render.Drawer.FocusRect:=Rect(0,0,0,0);
    if FHandle>0 then
    begin
      GetWindowRect(FHandle,ppRect);
      FZoomRect.Left:=Round(FZoomRect.Left/ppRect.Width*10000);
      FZoomRect.Top:=Round(FZoomRect.Top/ppRect.Height*10000);
      FZoomRect.Right:=Round(FZoomRect.Right/ppRect.Width*10000);
      FZoomRect.Bottom:=Round(FZoomRect.Bottom/ppRect.Height*10000);
      if FZoomRect.Left>0 then
      begin
        Decoder.SetOutputQueue(ImageCutter.InputQueue);
        ImageCutter.AddReceiver(Render.InputQueue,FZoomRect);
      end
      else
      begin
        ImageCutter.RemoveReceiver(Render.InputQueue);
        Decoder.SetOutputQueue(Render.InputQueue);
      end;
      Decoder.PushLastFrame;
    end;
  finally
    FLock.Leave;
  end;
end;

end.
