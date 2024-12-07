unit mdtOptions_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, ABL.IO.IOTypes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, ABL.Core.ThreadController, ABL.VS.FFMPEG, ABL.Core.ThreadQueue,
  mdtMotionDetector_TH, ABL.IA.IATypes, ABL.Render.DirectRender, ABL.Core.QueueMultiplier, mdtCommon, ABL.Core.Debug,
  Contnrs, Vcl.StdCtrls, ABL.VS.RTSPReceiver, ABL.IA.ImageResize, ABL.VS.VideoDecoder, ABL.Core.Callback;

type
  TGrabStart=class(TThread)
  private
    FConnectionString: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AConnectionString: string); reintroduce;
  end;

  TOptionsFM = class(TForm)
    pnlScreen: TPanel;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
    FLock: TRTLCriticalSection;
    VideoDecoder: TVideoDecoder;
    MotionDetector: TMotionDetector;
    Callback: TCallback;
    DirectRender: TDirectRender;
    QueueMultiplier: TQueueMultiplier;
    OldDateTime: int64;
    InputRect, DrawRect: array of TRect;
    MotionUpdateTime: UInt64;
    procedure CBExecute(var AInputData: Pointer);
    procedure RenderDraw(DC: HDC; Width, Height: integer; DateTime: int64);
  public
    { Public declarations }
    procedure Preview(AConnectionString: string);
    procedure StopPreview;
  end;

var
  OptionsFM: TOptionsFM;
  RTSPReceiver: TRTSPReceiver;
  MDTPreviewRTSPOutput: TThreadQueue;

implementation

{$R *.dfm}

{ TGrabStart }

constructor TGrabStart.Create(AConnectionString: string);
begin
  inherited Create(false);
  FConnectionString:=AConnectionString;
end;

procedure TGrabStart.Execute;
begin
  if assigned(RTSPReceiver)and(RTSPReceiver.Link.GetFullURI<>FConnectionString) then
    FreeAndNil(RTSPReceiver);
  if not assigned(RTSPReceiver) then
    RTSPReceiver:=TRTSPReceiver.Create(MDTPreviewRTSPOutput,'MDTPreviewRTSPReceiver',FConnectionString);
end;

{ TOptionsFM }

procedure TOptionsFM.CBExecute(var AInputData: Pointer);
var
  TimedDataHeader: PTimedDataHeader;
  Area: TArea;
begin
  TimedDataHeader:=AInputData;
  EnterCriticalSection(FLock);
  try
    //если сменилась дата, то добавить все прямоугольники для рисования
    if OldDateTime<>TimedDataHeader.Time then
    begin
      if length(InputRect)>0 then
      begin
        SetLength(DrawRect,length(InputRect));
        Move(InputRect[0],DrawRect[0],SizeOf(TRect)*length(InputRect));
      end
      else
        DrawRect:=[];
      InputRect:=[];
      OldDateTime:=TimedDataHeader.Time;
    end;
    Move(TimedDataHeader.Data^,Area,SizeOf(TArea));
    InputRect:=InputRect+[Area.Rect];
    MotionUpdateTime:=GetTickCount64
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TOptionsFM.FormCreate(Sender: TObject);
begin
  InitializeCriticalSection(FLock);
  OldDateTime:=0;
end;

procedure TOptionsFM.FormDestroy(Sender: TObject);
begin
  if assigned(DirectRender) then
  begin
    DirectRender.OnDraw:=nil;
    FreeAndNil(DirectRender);
  end;
  DeleteCriticalSection(FLock);
end;

procedure TOptionsFM.Preview(AConnectionString: string);
begin
  if assigned(MotionDetector) then
  begin
    DirectRender.Handle:=0;
    DirectRender.InputQueue.Clear;
  end;
  pnlScreen.Hint:=AConnectionString;
  MDTPreviewRTSPOutput:=TThreadQueue(ThreadController.QueueByName('MDTPreviewRTSPOutput'));
  if not assigned(VideoDecoder) then
    VideoDecoder:=TVideoDecoder.Create(MDTPreviewRTSPOutput,ThreadController.QueueByName('MDTPreviewDecoderOutput'),AV_CODEC_ID_H264,
        'MDTPreviewDecoder');
  if not assigned(QueueMultiplier) then
    QueueMultiplier:=TQueueMultiplier.Create(VideoDecoder.OutputQueue);
  if not assigned(DirectRender) then
  begin
    DirectRender:=TDirectRender.Create('DirectRender');
    DirectRender.OnDraw:=RenderDraw;
    QueueMultiplier.AddReceiver(DirectRender.InputQueue);
  end;
  DirectRender.Handle:=pnlScreen.Handle;
  if not assigned(MotionDetector) then
  begin
    MotionDetector:=TMotionDetector.Create(0);
    QueueMultiplier.AddReceiver(MotionDetector.InputQueue);
  end;
  if not assigned(Callback) then
  begin
    Callback:=TCallback.Create(MotionDetector.OutputQueue,'Callback');
    Callback.OnExecute:=CBExecute;
  end;
  TGrabStart.Create(AConnectionString);
end;

procedure TOptionsFM.RenderDraw(DC: HDC; Width, Height: integer; DateTime: int64);
var
  wh,hh: Extended;
  tmpRect,AbsRect: TRect;
  tmpPen: HPEN;
begin
  EnterCriticalSection(FLock);
  try
    if length(DrawRect)>0 then
    begin
      wh:=Width/IcoSize;
      hh:=Height/IcoSize;
      tmpPen:= CreatePen(PS_SOLID,2,RGB(200,0,0));
      SelectObject(DC,tmpPen);
      for tmpRect in DrawRect do
      begin
        AbsRect:=Rect(Round(tmpRect.Left*wh),Round(tmpRect.Top*hh),Round(tmpRect.Right*wh),Round(tmpRect.Bottom*hh));
        MoveToEx(DC,AbsRect.Left,AbsRect.Top,nil);
        LineTo(DC,AbsRect.Right,AbsRect.Top);
        LineTo(DC,AbsRect.Right,AbsRect.Bottom);
        LineTo(DC,AbsRect.Left,AbsRect.Bottom);
        LineTo(DC,AbsRect.Left,AbsRect.Top);
      end;
      DeleteObject(tmpPen);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TOptionsFM.StopPreview;
begin
  if assigned(RTSPReceiver) then
    FreeAndNil(RTSPReceiver);
  if assigned(VideoDecoder) then
    FreeAndNil(VideoDecoder);
  if assigned(MotionDetector) then
    FreeAndNil(MotionDetector);
  if assigned(Callback) then
    FreeAndNil(Callback);
end;

procedure TOptionsFM.TimerTimer(Sender: TObject);
begin
  EnterCriticalSection(FLock);
  try
    if GetTickCount64-MotionUpdateTime>200 then
      DrawRect:=[];
  finally
    LeaveCriticalSection(FLock);
  end;
end;

end.
