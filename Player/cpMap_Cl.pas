unit cpMap_Cl;

interface

uses
  Vcl.ExtCtrls, Classes, Vcl.Controls, Vcl.Graphics, SysUtils, DateUtils, Menus, SyncObjs,
  Generics.Collections, IniFiles, ShellAPI, ABL.Core.DirectThread, cpArchManager_TH, Contnrs,
  Math, Windows, Messages, ABL.Core.Debug, Forms, PsAPI, ABL.Core.BaseQueue, cpTypes, cpThumb_FM;

const
  WM_MAP_FILL_FINISHED = WM_USER+130;

type
  PMapFillCommand=^TMapFillCommand;
  TMapFillCommand=record
    ID_Server: integer;
    ID_Camera: integer;
    BeginTime: TDateTime;
    EndTime: TDateTime;
    CanFollowRequest: boolean;
    Width: integer;
    Handle: HWND;
  end;

  PSingleFill=^TSingleFill;
  TSingleFill=record
    ID_Server: integer;
    ID_Camera: integer;
    Plot: array [0..2047] of boolean;
    Motion: array [0..2047] of boolean;
    Alarm: array [0..2047] of boolean;
    Length: Word;
    FromSecond, ToSecond: int64;
  end;

  TFillCommandQueue = class(TBaseQueue)
  public
    procedure Clear; override;
    function Pop: Pointer; override;
    procedure Push(AItem: Pointer); override;
  end;

  TOuterControl = class
  public
    procedure ResizeMap(Sender: TObject);
  end;

  TMapFiller = class(TDirectThread)
  private
    FillList: TList<TSingleFill>;
    IndexCache: TDictionary<string,TDayContent>;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue); reintroduce;
    Destructor Destroy; override;
    procedure ClearIndexCache(AServer: integer);
  end;

  TMapNotifyEvent = procedure(ADateTime: TDateTime) of object;

  TMap = class(TCustomControl)
  private
    SurfaceBmp: Vcl.Graphics.TBitmap;
    FBeginTime, FEndTime: TDateTime;
    FCurTime: TDateTime;
    FDownPoint,FDragPoint,FTrackPoint: integer;
    FPixelWeight: Extended;
    FInUpdate: byte;
    FNeedRefill: boolean;
    FResizeTimer: TTimer;
    function GetCapacity: integer;
    procedure ResizeProc(Sender: TObject);
    procedure RebuildBmp;
    procedure Refill(AItem: integer=-1);
    procedure ResizeTimerTimer(Sender: TObject);
    procedure SendTimeMessage;
    procedure SetCapacity(const Value: integer);
    procedure SetCurTime(const Value: TDateTime);
    procedure SlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SlMouseLeave(Sender: TObject);
    procedure SlMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure SlMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    function GetInUpdate: boolean;
  protected
    FAllowSlide: boolean;
    function GetCurX: integer;
    procedure Paint; override;
    procedure WMExchangeCameras(var Message: TMessage); message WM_EXCHANGE_CAMERAS;
    procedure WMMapFillFinished(var Message: TMessage); message WM_MAP_FILL_FINISHED;
    procedure WMSetCurTime(var Message: TMessage); message WM_SET_CURTIME;
  public
    Cameras: TList<PSCamera>;
    ScreenHandle: HWND;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure ClearIndexCache(AServer: integer);
    procedure EndUpdate;
    procedure InsertCamera(ID_Server, ID_Camera: integer; APosition: byte);
    procedure RemoveCamera(APosition: byte);
    procedure SetRange(ABeginTime, AEndTime: TDateTime);
    property BeginTime: TDateTime read FBeginTime;
    property EndTime: TDateTime read FEndTime;
    property Capacity: integer read GetCapacity write SetCapacity;
    property CurTime: TDateTime read FCurTime write SetCurTime;
    property InUpdate: boolean read GetInUpdate;
  end;

var
  Map: TMap;
  OuterControl: TOuterControl;
  AllowInc: array [false..true] of byte = (0,1);
  MapForm: TForm;

implementation

var
  MapFiller: TMapFiller;
  FillCommandQueue: TFillCommandQueue;

procedure GradientFillRect(Canvas: TCanvas; Rect: TRect; StartColor, EndColor: TColor);
var
  Steps: Integer;
  StartR, StartG, StartB, EndR, EndG, EndB: Byte;
  CrrR, CrrG, CrrB: Double;
  IncR, IncG, incB: Double;
  i: integer;
begin
  Steps:= Rect.Bottom - Rect.Top;
  StartR:= GetRValue(StartColor);  EndR:= GetRValue(EndColor);
  StartG:= GetGValue(StartColor);  EndG:= GetGValue(EndColor);
  StartB:= GetBValue(StartColor);  EndB:= GetBValue(EndColor);
  IncR:= (EndR - StartR) / steps;
  IncG:= (EndG - StartG) / steps;
  IncB:= (EndB - StartB) / steps;
  CrrR:= StartR;
  CrrG:= StartG;
  CrrB:= StartB;
  for i:=Rect.Top to Rect.Bottom do
  begin
    Canvas.Pen.Color:= RGB(Round(CrrR), Round(CrrG), Round(CrrB));
    Canvas.MoveTo(Rect.Left, i);
    Canvas.LineTo(Rect.Right + Rect.Left, i);
    CrrR:= CrrR + IncR;
    CrrG:= CrrG + IncG;
    CrrB:= CrrB + IncB;
  end;
end;

{ TSlider }

procedure TMap.BeginUpdate;
begin
  FInUpdate:=FInUpdate+1;
end;

procedure TMap.ClearIndexCache(AServer: integer);
begin
  MapFiller.ClearIndexCache(AServer);
end;

constructor TMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered:=true;
  Align:=alClient;
  BevelOuter:=bvNone;
  SurfaceBmp:=Vcl.Graphics.TBitmap.Create;
  OnResize:=ResizeProc;
  FBeginTime:=trunc(now);
  FEndTime:=FBeginTime+1;
  FCurTime:=now;
  Cameras:=TList<PSCamera>.Create;
  SetCapacity(1);
  FillCommandQueue:=TFillCommandQueue.Create;
  MapFiller:=TMapFiller.Create(FillCommandQueue);
  FDownPoint:=-1;
  FTrackPoint:=-1;
  FDragPoint:=-1;
  OnMouseDown:=SlMouseDown;
  OnMouseMove:=SlMouseMove;
  OnMouseUp:=SlMouseUp;
  OnMouseLeave:=SlMouseLeave;
  FNeedRefill:=false;
  if not assigned(ThumbFM) then
    ThumbFM:=TThumbFM.Create(nil);
  FResizeTimer:=TTimer.Create(nil);
  FResizeTimer.Interval:=20;
  FResizeTimer.OnTimer:=ResizeTimerTimer;
end;

procedure TMap.ResizeProc(Sender: TObject);
begin
  FResizeTimer.Enabled:=true;
end;

procedure TMap.ResizeTimerTimer(Sender: TObject);
begin
  FResizeTimer.Enabled:=false;
  Refill;
  RebuildBmp;
end;

procedure TMap.SendTimeMessage;
var
  q: PDateTime;
begin
  New(q);
  move(FCurTime,q^,SizeOf(TDateTime));
  PostMessage(ScreenHandle,WM_SET_CURTIME,Integer(q),0);
end;

procedure TMap.SetCapacity(const Value: integer);
var
  SingleFill: PSingleFill;
  NCamera: PSCamera;
begin
  try
    if Cameras.Count<>Value then
    begin
      if Value<Cameras.Count then
        while Value<Cameras.Count do
        begin
          NCamera:=Cameras[Value];
          if assigned(NCamera) then
          begin
            SingleFill:=PSingleFill(NCamera.SingleFill);
            if SingleFill<>nil then
              Dispose(SingleFill);
            Dispose(NCamera);
          end;
          Cameras.Delete(Value);
        end
      else
        while Value>Cameras.Count do
        begin
          New(SingleFill);
          FillChar(SingleFill.Plot[0],2048,0);
          FillChar(SingleFill.Motion[0],2048,0);
          FillChar(SingleFill.Alarm[0],2048,0);
          SingleFill.ID_Camera:=-1;
          SingleFill.Length:=0;
          New(NCamera);
          NCamera.ID_Camera:=-1;
          NCamera.Name:='';
          NCamera.SingleFill:=SingleFill;
          Cameras.Add(NCamera);
        end;
      if FInUpdate=0 then
        RebuildBmp
      else
        FNeedRefill:=true;
    end;
  except on e: Exception do
    SendErrorMsg('TMap.SetCapacity 237: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TMap.SetCurTime(const Value: TDateTime);
begin
  if FCurTime<>Value then
  begin
    FCurTime:=Value;
    if FInUpdate=0 then
    begin
      invalidate;
      Application.ProcessMessages;
      if ScreenHandle>0 then
        SendTimeMessage;
    end
    else
      FNeedRefill:=true;
  end;
end;

procedure TMap.SetRange(ABeginTime, AEndTime: TDateTime);
begin
  if (FBeginTime<>ABeginTime)or(FEndTime<>AEndTime) then
  begin
    FBeginTime:=ABeginTime;
    FEndTime:=AEndTime;
    if SecondsBetween(FBeginTime,FEndTime)<20 then
      FEndTime:=IncSecond(FBeginTime,20);
    if FInUpdate=0 then
      Refill
    else
      FNeedRefill:=true;
  end;
end;

procedure TMap.WMSetCurTime(var Message: TMessage);
var
  DT: TDateTime;
  P: PDateTime;
  CurX: integer;
  DateDiff: TDateTime;
begin
  try
    P:=PDateTime(Message.WParam);
    Move(P^, DT, SizeOf(TDateTime));
    if Message.LParam>100 then
      PostMessage(ScreenHandle,WM_SET_CURTIME,Integer(P),1000)
    else
      Dispose(P);
    if (DT>0) and (FCurTime<>DT) then
    begin
      FCurTime:=DT;
      CurX:=GetCurX;
      if CurX>=trunc(Width*0.95) then
      begin
        DateDiff:=(FEndTime-FBeginTime)/2;
        SetRange(FBeginTime+DateDiff,FEndTime+DateDiff);
      end
      else
        invalidate;
    end;
  except on e: Exception do
    SendErrorMsg('TMap.WMSetCurTime 318: '+e.ClassName+' - '+e.Message);
  end;
end;

destructor TMap.Destroy;
begin
  FResizeTimer.Free;
  MapFiller.Free;
  SetCapacity(0);
  Cameras.Free;
  SurfaceBmp.Free;
  FillCommandQueue.Free;
  inherited;
end;

procedure TMap.EndUpdate;
begin
  if FInUpdate>0 then
    FInUpdate:=FInUpdate-1;
  if FInUpdate<=0 then
  begin
    FInUpdate:=0;
    if FNeedRefill then
    begin
      Refill;
      RebuildBmp;
    end;
    FNeedRefill:=false;
  end;
end;

function TMap.GetCapacity: integer;
begin
  result:=Cameras.Count;
end;

function TMap.GetCurX: integer;
begin
  result:=-1;
  if FCurTime>FBeginTime then
    result:=trunc(MilliSecondsBetween(FBeginTime,FCurTime)/FPixelWeight/1000);
end;

function TMap.GetInUpdate: boolean;
begin
  result:=FInUpdate>0;
end;

procedure TMap.InsertCamera(ID_Server, ID_Camera: integer; APosition: byte);
var
  OldPosition,i: integer;
  ACamera: PSCamera;
begin
  if APosition<Cameras.Count then
  begin
    OldPosition:=-1;
    for i:=0 to Cameras.Count-1 do
      if (Cameras[i].ID_Camera=ID_Camera) and (Cameras[i].ID_Server=ID_Server) then
      begin
        OldPosition:=i;
        break;
      end;
    if (OldPosition<>APosition) then
    begin
      if (OldPosition>=0) then
        Cameras.Exchange(OldPosition,APosition)
      else
      begin
        ACamera:=Cameras[APosition];
        ACamera.ID_Camera:=ID_Camera;
        ACamera.ID_Server:=ID_Server;
      end;
      if FInUpdate=0 then
      begin
        Refill(APosition);
        RebuildBmp;
      end
      else
        FNeedRefill:=true;
    end;
  end;
end;

procedure TMap.SlMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
  begin
    if Y<(Height-18) then
      FDownPoint:=X
    else
    begin
      if X<18 then
      begin
        FAllowSlide:=not FAllowSlide;
        with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
          try
            WriteBool('MAP','Thumb',FAllowSlide);
          finally
            Free;
          end;
        RebuildBmp;
      end
      else
        FDragPoint:=X;
    end;
  end
  else
  begin
    FDownPoint:=-1;
    FDragPoint:=-1;
    FTrackPoint:=-1;
    if Button=mbRight then
    begin
      FBeginTime:=IncHour(FBeginTime,-2);
      FEndTime:=IncHour(FEndTime,2);
      if FInUpdate=0 then
      begin
        RebuildBmp;
        Refill;
      end
      else
        FNeedRefill:=true;
    end;
    Invalidate;
  end;
end;

procedure TMap.SlMouseLeave(Sender: TObject);
begin
  ThumbFM.Hide;
end;

procedure TMap.SlMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  NewTrack,HoverCamera: integer;
  SecondIncrement: Extended;
  I: integer;
  DragLength: integer;
  sf: PSingleFill;
  HoverPoint: TDateTime;
begin
  if (Shift=[]) then
  begin
    if (Y>(Height-18)) then
      Cursor:=crHandPoint
    else
    begin
      Cursor:=crDefault;
      if FAllowSlide then
      begin
        HoverCamera:=(Y div ((Height-18) div Cameras.Count));
        if (HoverCamera<Cameras.Count) then
        begin
          if PSingleFill(Cameras[HoverCamera].SingleFill).Plot[X] then
          begin
            HoverPoint:=IncSecond(FBeginTime,Round(FPixelWeight*X));
            ThumbFM.TryShow(Cameras[HoverCamera].ID_Server,Cameras[HoverCamera].ID_Camera,HoverPoint,Handle,false);
          end
          else if PSingleFill(Cameras[HoverCamera].SingleFill).Alarm[X] then
          begin
            HoverPoint:=IncSecond(FBeginTime,Round(FPixelWeight*X));
            ThumbFM.TryShow(Cameras[HoverCamera].ID_Server,Cameras[HoverCamera].ID_Camera,HoverPoint,Handle,true);
          end
          else
            ThumbFM.TryHide;
        end
        else
          ThumbFM.TryHide;
      end;
    end;
  end
  else
  begin
    Cursor:=crDefault;
    if (ssLeft in Shift)and(FDragPoint>-1) then
    begin
      if FDragPoint<>X then
      begin
        DragLength:=X-FDragPoint;
        SecondIncrement:=FPixelWeight*(DragLength);
        if trunc(SecondIncrement)<>0 then
        begin
          FBeginTime:=FBeginTime-SecondIncrement/86400;
          FEndTime:=FEndTime-SecondIncrement/86400;
          FDragPoint:=X;
          for I := 0 to Cameras.Count-1 do
          begin
            sf:=PSingleFill(Cameras[i].SingleFill);
            if DragLength>0 then
            begin
              Move(sf.Plot[0],sf.Plot[DragLength],length(sf.Plot)-DragLength);
              FillChar(sf.Plot,DragLength,0);
              Move(sf.Motion[0],sf.Motion[DragLength],length(sf.Motion)-DragLength);
              FillChar(sf.Motion,DragLength,0);
              Move(sf.Alarm[0],sf.Alarm[DragLength],length(sf.Alarm)-DragLength);
              FillChar(sf.Alarm,DragLength,0);
            end
            else
            begin
              Move(sf.Plot[-DragLength],sf.Plot[0],length(sf.Plot)+DragLength);
              FillChar(sf.Plot[length(sf.Plot)-1+DragLength],-DragLength,0);
              Move(sf.Motion[-DragLength],sf.Motion[0],length(sf.Motion)+DragLength);
              FillChar(sf.Motion[length(sf.Motion)-1+DragLength],-DragLength,0);
              Move(sf.Alarm[-DragLength],sf.Alarm[0],length(sf.Alarm)+DragLength);
              FillChar(sf.Alarm[length(sf.Alarm)-1+DragLength],-DragLength,0);
            end;
          end;
          RebuildBmp;
        end;
      end;
    end
    else
      FDragPoint:=-1;
      if (ssLeft in Shift)and(FDownPoint>-1)and((X-FDownPoint)>3) then
        NewTrack:=X
      else
        NewTrack:=-1;
      if FTrackPoint<>NewTrack then
      begin
        FTrackPoint:=NewTrack;
        invalidate;
      end;
  end;
end;

procedure TMap.SlMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DownTime,UpTime: TDateTime;
begin
  try
    if FDownPoint>-1 then
    begin
      DownTime:=IncMilliSecond(FBeginTime,trunc(FPixelWeight*FDownPoint*1000));
      if (X-FDownPoint)<=3 then
        CurTime:=DownTime
      else
      begin
        UpTime:=IncSecond(FBeginTime,trunc(FPixelWeight*X));
        SetRange(DownTime,UpTime);
        RebuildBmp;
      end;
    end;
    if FDragPoint>0 then
    begin
      FDragPoint:=-1;
      Refill;
    end;
    FDownPoint:=-1;
    FTrackPoint:=-1;
  except on e: Exception do
    SendErrorMsg('TMap.SlMouseUp 545: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TMap.WMExchangeCameras(var Message: TMessage);
begin
  try
    Cameras.Exchange(Message.LParam,Message.WParam);
    if FInUpdate=0 then
    begin
      Refill;
      RebuildBmp;
    end
    else
      FNeedRefill:=true;
  except on e: Exception do
    SendErrorMsg('TMap.WMExchangeCameras 580: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TMap.WMMapFillFinished(var Message: TMessage);
var
  SingleFill,SingleFill1: PSingleFill;
  I: integer;
begin
  try
    SingleFill:=PSingleFill(Message.WParam);
    try
      for I:=0 to Cameras.Count-1 do
        if (Cameras[I].ID_Camera=SingleFill.ID_Camera)and(Cameras[I].ID_Server=SingleFill.ID_Server) then
        begin
          SingleFill1:=PSingleFill(Cameras[I].SingleFill);
          Move(SingleFill^,SingleFill1^,SizeOf(TSingleFill));
          break;
        end;
    finally
      Dispose(SingleFill);
    end;
    if FInUpdate=0 then
      RebuildBmp
    else
      FNeedRefill:=true;
  except on e: Exception do
    SendErrorMsg('TMap.WMMapFillFinished 607: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TMap.Paint;
var
  CurX: integer;
begin
  if Assigned(SurfaceBmp)and(SurfaceBmp.Width>0) then
  begin
    Canvas.Draw(0,0,SurfaceBmp);
    if FCurTime>=0 then
    begin
      Canvas.Font.Color:=clWhite;
      Canvas.Brush.Style:=bsClear;
      Canvas.TextOut(0,0,DateTimeToStr(FCurTime));
    end;
    if FTrackPoint>0 then
      BitBlt(Canvas.Handle,FDownPoint,0,FTrackPoint-FDownPoint,Height-17,Canvas.Handle,FDownPoint,0,DSTINVERT);
    if (FCurTime>FBeginTime)and(FCurTime<FEndTime) then
    begin
      CurX:=GetCurX;
      Canvas.Brush.Color:=clWhite;
      Canvas.Pen.Color:=clWhite;
      Canvas.MoveTo(CurX,0);
      Canvas.LineTo(CurX,Height-15);
      Canvas.Brush.Color:=clBlack;
      Canvas.Pen.Color:=clBlack;
      Canvas.MoveTo(CurX-1,0);
      Canvas.LineTo(CurX-1,Height-15);
      Canvas.MoveTo(CurX+1,0);
      Canvas.LineTo(CurX+1,Height-15);
    end;
  end;
end;

procedure TMap.RebuildBmp;
var
  AWorkHeight,SecDiff,CurTickPos: integer;
  TickTimeRange,TickTimeWhole,CurTextWidth,i: integer;
  TickPixelRange: Extended;
  FSecOf,FMinuteOf,FHourOf,FTmp: Word;
  FTmpExtended: Extended;
  CaptionFormat,CurCaption: string;
  NeedCaption,FirstCaption: boolean;
  CurTickTime: TDateTime;
  SingleHeight: Extended;
  SingleHeight_I_1,SingleHeight_I,w: integer;
  SingleFill: PSingleFill;
  J: integer;
  q: Extended;
begin
  if assigned(SurfaceBmp)and(FInUpdate=0) then
  begin
    SurfaceBmp.Width:=Width;
    SurfaceBmp.Height:=Height;
    SurfaceBmp.Canvas.Pen.Color:=$003F4145;
    SurfaceBmp.Canvas.Brush.Color:=$003F4145;
    SurfaceBmp.Canvas.FillRect(Rect(0,0,Width-1,Height-1));
    SurfaceBmp.Canvas.Font.Color:=clWhite;
    if Height>18 then
    begin
      SecDiff:=SecondsBetween(FBeginTime,FEndTime);
      if FEndTime-FBeginTime>3 then
      begin
        TickTimeRange:=60*60*24;
        CaptionFormat:='DD.MM HH:mm';
      end
      else if FEndTime-FBeginTime>1 then
      begin
        TickTimeRange:=60*60*6;
        CaptionFormat:='DD.MM HH:mm';
      end
      else if SecDiff>60*60*5 then
      begin
        TickTimeRange:=60*60;
        CaptionFormat:='HH:mm';
      end
      else if SecDiff>60*60*3 then
      begin
        TickTimeRange:=60*30;
        CaptionFormat:='HH:mm';
      end
      else if SecDiff>60*60 then
      begin
        TickTimeRange:=60*10;
        CaptionFormat:='HH:mm';
      end
      else if SecDiff>60*15 then
      begin
        TickTimeRange:=60*5;
        CaptionFormat:='HH:mm';
      end
      else if SecDiff>60*5 then
      begin
        TickTimeRange:=30;
        CaptionFormat:='HH:mm:ss';
      end
      else if SecDiff>60 then
      begin
        TickTimeRange:=10;
        CaptionFormat:='HH:mm:ss';
      end
      else if SecDiff>20 then
      begin
        TickTimeRange:=5;
        CaptionFormat:='HH:mm:ss';
      end
      else
      begin
        TickTimeRange:=1;
        CaptionFormat:='HH:mm:ss';
      end;
      TickTimeWhole:=Round(SecDiff/TickTimeRange);
      TickPixelRange:=Width/TickTimeWhole;
      FPixelWeight:=TickTimeRange/(Width/(SecDiff/TickTimeRange));
      DecodeTime(FBeginTime,FHourOf,FMinuteOf,FSecOf,FTmp);
      q:=Round(frac(FBeginTime)/IncSecond(0,TickTimeRange));
      q:=frac(FBeginTime)-q*IncSecond(0,TickTimeRange);
      CurTickTime:=FBeginTime-q;
      q:=q*24*60*60;
      FTmpExtended:=-q/FPixelWeight;
      NeedCaption:=(TickPixelRange>45)and((TickPixelRange+FTmpExtended)>40);
      FirstCaption:=true;
      while FTmpExtended<Width do
      begin
        CurTickPos:=Round(FTmpExtended);
        SurfaceBmp.Canvas.Pixels[CurTickPos,Height-16]:=clWhite;
        SurfaceBmp.Canvas.Pixels[CurTickPos,Height-15]:=clWhite;
        if CurTickPos>=0 then
        begin
          if NeedCaption then
          begin
            CurCaption:=FormatDateTime(CaptionFormat,CurTickTime);
            if FirstCaption and (Pos('D',CaptionFormat)<=0) then
              CurCaption:=FormatDateTime('DD.MM.YY ',CurTickTime)+CurCaption;
            CurTextWidth:=SurfaceBmp.Canvas.TextWidth(CurCaption);
            SurfaceBmp.Canvas.TextOut(CurTickPos-CurTextWidth div 2,Height-13,CurCaption);
            FirstCaption:=false;
          end;
          NeedCaption:=(TickPixelRange>45) or (not NeedCaption);
        end;
        FTmpExtended:=FTmpExtended+TickPixelRange;
        CurTickTime:=IncSecond(CurTickTime,TickTimeRange);
      end;
      //кнопка для слайдов
      if FAllowSlide then
        SurfaceBmp.Canvas.Pen.Color:=clGray
      else
        SurfaceBmp.Canvas.Pen.Color:=clWhite;
      SurfaceBmp.Canvas.Rectangle(0,Height-17,17,Height);
      if FAllowSlide then
        SurfaceBmp.Canvas.Pen.Color:=clWhite
      else
        SurfaceBmp.Canvas.Pen.Color:=clGray;
      SurfaceBmp.Canvas.Rectangle(1,Height-16,17,Height);
      SurfaceBmp.Canvas.Pen.Color:=$003F4145;
      SurfaceBmp.Canvas.Rectangle(1,Height-16,16,Height-1);
      SurfaceBmp.Canvas.Pen.Color:=clWhite;
      SurfaceBmp.Canvas.Rectangle(2+AllowInc[FAllowSlide],Height-12+AllowInc[FAllowSlide],13+AllowInc[FAllowSlide],Height-3+AllowInc[FAllowSlide]);
      SurfaceBmp.Canvas.Rectangle(7+AllowInc[FAllowSlide],Height-15+AllowInc[FAllowSlide],12+AllowInc[FAllowSlide],Height-11+AllowInc[FAllowSlide]);
      SurfaceBmp.Canvas.Ellipse(5+AllowInc[FAllowSlide],Height-10+AllowInc[FAllowSlide],10+AllowInc[FAllowSlide],Height-5+AllowInc[FAllowSlide]);
      SurfaceBmp.Canvas.Pen.Color:=$003F4145;
    end;
    AWorkHeight:=Height-18;
    if AWorkHeight>0 then
    begin
      SingleHeight:=AWorkHeight/Cameras.Count;
      for I:=0 to Cameras.Count-1 do
      begin
        SingleHeight_I:=Round(SingleHeight*I);
        SingleHeight_I_1:=Round(SingleHeight*(I+1));
        GradientFillRect(SurfaceBmp.Canvas,Rect(0,SingleHeight_I,Width,SingleHeight_I_1-1),$d67a24,$ab621d);
        w:=Cameras[I].ID_Camera;
        if w>0 then
        begin
          SingleFill:=PSingleFill(Cameras[i].SingleFill);
          if SingleFill.Length<=2048 then
            for J := 0 to SingleFill.Length-1 do
              if SingleFill.Plot[J] then
              begin
                if SingleFill.Motion[J] then
                  SurfaceBmp.Canvas.Pen.Color:=$e8af79
                else
                  SurfaceBmp.Canvas.Pen.Color:=clSkyBlue;
                SurfaceBmp.Canvas.MoveTo(J,SingleHeight_I);
                SurfaceBmp.Canvas.LineTo(J,SingleHeight_I_1);
              end
              else if SingleFill.Alarm[J] then
              begin
                SurfaceBmp.Canvas.Pen.Color:=$7575FF;
                SurfaceBmp.Canvas.MoveTo(J,SingleHeight_I);
                SurfaceBmp.Canvas.LineTo(J,SingleHeight_I_1);
              end;
        end;
        SurfaceBmp.Canvas.MoveTo(0,SingleHeight_I_1-1);
        SurfaceBmp.Canvas.Pen.Color:=$303030;
        SurfaceBmp.Canvas.Brush.Color:=$303030;
        SurfaceBmp.Canvas.LineTo(Width,SingleHeight_I_1-1);
      end;
      SurfaceBmp.Canvas.Pen.Color:=$003F4145;
      SurfaceBmp.Canvas.Brush.Color:=$003F4145;
    end;
    Invalidate;
  end;
end;

procedure TMap.Refill(AItem: integer=-1);
var
  b,e,q: integer;
  FillCommand: PMapFillCommand;
  sf: PSingleFill;
begin
  if FInUpdate=0 then
  begin
    if AItem=-1 then
    begin
      b:=0;
      e:=Cameras.Count-1;
    end
    else
    begin
      b:=AItem;
      e:=AItem;
    end;
    for q := b to e do
      if (Cameras[q].ID_Camera>0) and (Cameras[q].ID_Server>=0) then
      begin
        new(FillCommand);
        FillCommand.ID_Server:=Cameras[q].ID_Server;
        FillCommand.ID_Camera:=Cameras[q].ID_Camera;
        FillCommand.BeginTime:=FBeginTime;
        FillCommand.EndTime:=FEndTime;
        FillCommand.CanFollowRequest:=true;
        FillCommand.Handle:=Handle;
        FillCommand.Width:=Width;
        sf:=PSingleFill(Cameras[q].SingleFill);
        FillChar(sf.Plot,2048,0);
        FillChar(sf.Motion,2048,0);
        FillChar(sf.Alarm,2048,0);
        FillCommandQueue.Push(FillCommand);
      end;
  end;
end;

procedure TMap.RemoveCamera(APosition: byte);
var
  SingleFill: PSingleFill;
  ACamera: PSCamera;
begin
  if (APosition<Cameras.Count) then
  begin
    ACamera:=Cameras[APosition];
    ACamera.ID_Camera:=-1;
    SingleFill:=PSingleFill(ACamera.SingleFill);
    FillChar(SingleFill.Plot,2048,0);
    FillChar(SingleFill.Motion,2048,0);
    FillChar(SingleFill.Alarm,2048,0);
    if FInUpdate=0 then
      RebuildBmp
    else
      FNeedRefill:=true;
  end;
end;

{ TSliderFiller }

procedure TMapFiller.ClearIndexCache(AServer: integer);
var
  I: integer;
  tmpString,Key: string;
  KeyList: TArray<string>;
begin
  for I:=FillList.Count-1 downto 0 do
    if FillList[I].ID_Server=AServer then
      FillList.Delete(I);
  tmpString:=IntToStr(AServer)+'_';
  KeyList:=IndexCache.Keys.ToArray;
  for Key in KeyList do
    if copy(Key,1,length(tmpString))=tmpString then
      IndexCache.Remove(Key);
end;

constructor TMapFiller.Create(AInputQueue: TBaseQueue);
begin
  inherited Create(AInputQueue, nil, 'MapFiller');
  FillList:=TList<TSingleFill>.Create;
  IndexCache:=TDictionary<string,TDayContent>.Create;
  Active:=true;
end;

destructor TMapFiller.Destroy;
begin
  if assigned(FillList) then
    FreeAndNil(FillList);
  inherited;
end;

procedure TMapFiller.DoExecute(var AInputData, AResultData: Pointer);
var
  FillCommand: PMapFillCommand;
  SingleFill: PSingleFill;
  WholeSecs,i,j,q: integer;
  SecsPerPixel: Extended;
  dc: TDayContent;
  fa: array of TDayContent;
  tmpDay: array of Integer;
  CurSecStart,CurSecFinish,Today: integer;
  StartSec,EndSec: int64;
  sfCache: TSingleFill;
  IndexIdent: string;
  StrNum: string;
begin
  try
    StrNum:='929';
    FillCommand:=PMapFillCommand(AInputData);
    if FillCommand.ID_Camera>0 then
    begin
      StartSec:=SecondsBetween(UnixDateDelta,FillCommand.BeginTime);
      EndSec:=SecondsBetween(UnixDateDelta,FillCommand.EndTime);
      sfCache.ID_Camera:=0;
      for I:=0 to FillList.Count-1 do
      begin
        if (FillList[i].ID_Camera=FillCommand.ID_Camera)and(FillList[i].ID_Server=FillCommand.ID_Server)and(FillList[i].FromSecond=StartSec)and(FillList[i].ToSecond=EndSec) then
        begin
          sfCache:=FillList[i];
          break;
        end;
      end;
      if sfCache.ID_Camera=0 then
      begin
        fa:=[];
        tmpDay:=[];
        Today:=trunc(now);
        for i := trunc(FillCommand.BeginTime) to trunc(FillCommand.EndTime) do
        begin
          tmpDay:=tmpDay+[i];
          j:=(YearOf(i)-2000)*10000+MonthOf(i)*100+DayOf(i);
          IndexIdent:=IntToStr(FillCommand.ID_Server)+'_'+IntToStr(FillCommand.ID_Camera)+'_'+IntToStr(j)+'_0';
          if not IndexCache.TryGetValue(IndexIdent,dc) then
          begin
            dc:=ArchManager.DayContent(FillCommand.ID_Server,FillCommand.ID_Camera,j,0);
            if Today<>i then
              IndexCache.Add(IndexIdent,dc);
          end;
          fa:=fa+[dc];
        end;
        New(SingleFill);
        FillChar(SingleFill.Plot,2048,0);
        FillChar(SingleFill.Motion,2048,0);
        FillChar(SingleFill.Alarm,2048,0);
        StrNum:='966, FillCommand.Width='+IntToStr(FillCommand.Width);
        SingleFill.Length:=min(2048,FillCommand.Width);
        SingleFill.ID_Server:=FillCommand.ID_Server;
        SingleFill.ID_Camera:=FillCommand.ID_Camera;
        SingleFill.FromSecond:=StartSec;
        SingleFill.ToSecond:=EndSec;
        WholeSecs:=SecondsBetween(FillCommand.BeginTime,FillCommand.EndTime);
        SecsPerPixel:=WholeSecs/SingleFill.Length;
        if (length(fa)>0) and (FillCommand.Width>0) then
        begin
          for j := 0 to length(fa)-1 do
          begin
            dc:=fa[j];
            for q := 0 to High(dc) do
            begin
              StrNum:='981';
              if dc[q].BeginSecond+dc[q].EndSecond>0 then
              begin
                CurSecStart:=SecondsBetween(UnixDateDelta,tmpDay[j]);
                CurSecStart:=max(StartSec,CurSecStart+dc[q].BeginSecond)-StartSec;
                CurSecFinish:=min(StartSec+WholeSecs,SecondsBetween(UnixDateDelta,tmpDay[j])+dc[q].EndSecond)-StartSec;
                CurSecStart:=trunc(CurSecStart/SecsPerPixel);
                CurSecFinish:=trunc(CurSecFinish/SecsPerPixel);
                for i := max(0,CurSecStart) to min(CurSecFinish,2047) do
                  SingleFill.Plot[i]:=true;
              end;
            end;
          end;
          fa:=[];
          tmpDay:=[];
          for i := trunc(FillCommand.BeginTime) to trunc(FillCommand.EndTime) do
          begin
            tmpDay:=tmpDay+[i];
            j:=(YearOf(i)-2000)*10000+MonthOf(i)*100+DayOf(i);
            IndexIdent:=IntToStr(FillCommand.ID_Server)+'_'+IntToStr(FillCommand.ID_Camera)+'_'+IntToStr(j)+'_1';
            if not IndexCache.TryGetValue(IndexIdent,dc) then
            begin
              dc:=ArchManager.DayContent(FillCommand.ID_Server,FillCommand.ID_Camera,j,1);
              if Today<>i then
                IndexCache.Add(IndexIdent,dc);
            end;
            fa:=fa+[dc];
          end;
          for j := 0 to length(fa)-1 do
          begin
            dc:=fa[j];
            for q := 0 to High(dc) do
            begin
              StrNum:='1014';
              if dc[q].BeginSecond+dc[q].EndSecond>0 then
              begin
                CurSecStart:=SecondsBetween(UnixDateDelta,tmpDay[j]);
                CurSecStart:=max(StartSec,CurSecStart+dc[q].BeginSecond)-StartSec;
                CurSecFinish:=min(StartSec+WholeSecs,SecondsBetween(UnixDateDelta,tmpDay[j])+dc[q].EndSecond)-StartSec;
                CurSecStart:=trunc(CurSecStart/SecsPerPixel);
                CurSecFinish:=trunc(CurSecFinish/SecsPerPixel);
                for i := max(0,CurSecStart) to min(CurSecFinish,2047) do
                  SingleFill.Motion[i]:=true;
              end;
            end;
          end;
          fa:=[];
          tmpDay:=[];
          for i := trunc(FillCommand.BeginTime) to trunc(FillCommand.EndTime) do
          begin
            tmpDay:=tmpDay+[i];
            j:=(YearOf(i)-2000)*10000+MonthOf(i)*100+DayOf(i);
            IndexIdent:=IntToStr(FillCommand.ID_Server)+'_'+IntToStr(FillCommand.ID_Camera)+'_'+IntToStr(j)+'_2';
            if not IndexCache.TryGetValue(IndexIdent,dc) then
            begin
              StrNum:='1036';
              dc:=ArchManager.DayContent(FillCommand.ID_Server,FillCommand.ID_Camera,j,2);
              if Today<>i then
                IndexCache.Add(IndexIdent,dc);
            end;
            fa:=fa+[dc];
          end;
          for j := 0 to length(fa)-1 do
          begin
            dc:=fa[j];
            for q := 0 to High(dc) do
            begin
              if dc[q].BeginSecond+dc[q].EndSecond>0 then
              begin
                CurSecStart:=SecondsBetween(UnixDateDelta,tmpDay[j]);
                CurSecStart:=max(StartSec,CurSecStart+dc[q].BeginSecond)-StartSec;
                CurSecFinish:=min(StartSec+WholeSecs,SecondsBetween(UnixDateDelta,tmpDay[j])+dc[q].EndSecond)-StartSec;
                CurSecStart:=trunc(CurSecStart/SecsPerPixel);
                CurSecFinish:=trunc(CurSecFinish/SecsPerPixel);
                for i := max(0,CurSecStart) to min(CurSecFinish,2047) do
                  SingleFill.Alarm[i]:=true;
              end;
            end;
          end;
        end;
      end
      else
      begin
        New(SingleFill);
        Move(sfCache,SingleFill^,SizeOf(TSingleFill));
      end;
      StrNum:='1067';
      if assigned(SingleFill) then
        PostMessage(FillCommand.Handle,WM_MAP_FILL_FINISHED,Integer(SingleFill),0);
    end
    else
      SendErrorMsg('TMapFiller.DoExecute 1079: нет камеры '+IntToStr(FillCommand.ID_Camera));
  except on e: Exception do
    SendErrorMsg('TMapFiller.DoExecute 1081, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
  end;
end;

{ TFillCommandQueue }

procedure TFillCommandQueue.Clear;
begin

end;

function TFillCommandQueue.Pop: Pointer;
begin
  FLock.Enter;
  try
    Result:=Queue.Pop;
    if Count=0 then
    begin
      FWaitItemsEvent.ResetEvent;
      FWaitEmptyItems.SetEvent;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TFillCommandQueue.Push(AItem: Pointer);
var
  FillCommand: PMapFillCommand;
  i: integer;
  CanNotify: boolean;
begin
  FLock.Enter;
  try
    CanNotify:=true;
    for i := 0 to Queue.List.Count-1 do
    begin
      FillCommand:=PMapFillCommand(Queue.List[i]);
      if (FillCommand.ID_Camera=PMapFillCommand(AItem).ID_Camera) and (FillCommand.ID_Server=PMapFillCommand(AItem).ID_Server) then
      begin
        Queue.List.Delete(i);
        CanNotify:=false;
        break;
      end;
    end;
    Queue.Push(AItem);
    if CanNotify then
    begin
      FWaitItemsEvent.SetEvent;
      FWaitEmptyItems.ResetEvent;
      FLastInput:=now;
    end;
  finally
    FLock.Leave;
  end;
end;

{ TOuterControl }

procedure TOuterControl.ResizeMap(Sender: TObject);
begin
  if Assigned(Map) then
    Map.ResizeProc(nil);
end;

initialization
  OuterControl:=TOuterControl.Create;

finalization
  if assigned(OuterControl) then
    FreeAndNil(OuterControl);

end.
