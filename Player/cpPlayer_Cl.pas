unit cpPlayer_Cl;

interface

uses
  Windows, Vcl.Controls, Classes, Generics.Collections, Messages, ABL.Core.ThreadQueue,
  cpCell_Cl, cpTypes, Forms, cpArchVideo_Cl, cpArchManager_TH,
  ABL.Core.Debug, cpFrameReceiver_TH, Contnrs, Types, Math, SysUtils, ABL.Core.ThreadController;

type
  TPlayer = class(TCustomControl)
  private
    cr: TPoint;
    FCells: TObjectList;
    FInUpdate: byte;
    FSkipUp: boolean;
    FStartMoveZone: byte;
    luFocus: TPoint;
    FOperative: boolean;
    procedure CheckForOperative(Camera: PSCamera);
    procedure FMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    function GetCapacity: integer;
    procedure RequestCurVideo(ACurVideoTime: TDateTime);
    procedure SetCapacity(const Value: integer);
    procedure SetOperative(const Value: boolean);
    function GetPlayState: TPlayState;
  protected
    procedure ResizeProc(Sender: TObject);
    procedure WMSetCurTime(var Message: TMessage); message WM_SET_CURTIME;
  public
    Active: Byte;
    Cameras: TList<PSCamera>;
    Crit: TRTLCriticalSection;
    FCurVideoTime: TDateTime;
    MapHandle: THandle;
    WholeCamerasCount: integer;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function GetArea(x,y: integer): integer;
    procedure InsertCamera(ID_Server, ID_Camera: integer; APosition: byte);
    procedure Pause;
    procedure Play(ASpeed: integer; AForward: boolean);
    procedure SkipUp;
    procedure SetActiveCell(AIndex: integer);
    procedure StepBack;
    procedure StepNext;
    property CurVideoTime: TDateTime read FCurVideoTime;
    property Capacity: integer read GetCapacity write SetCapacity;
    property Operative: boolean read FOperative write SetOperative;
    property PlayState: TPlayState read GetPlayState;
  end;

var
  Player: TPlayer;
  PlayerForm: TForm;
  LayoutArray: array [1..9] of array [0..32] of TRect;  // Индексы координат в расчётной сетке

implementation

{ TPlayer }

procedure TPlayer.CheckForOperative(Camera: PSCamera);
begin
  if assigned(Camera.FrameReceiver) then
    Camera.FrameReceiver.Primary:=Cameras.Count=1
  else
  begin
    Camera.FrameReceiver:=TFrameReceiver.Create(ArchManager[Camera.ID_Server],TThreadQueue(ThreadController.QueueByName('Decoder_'+IntToStr(
        Camera.ID_Server)+'_'+IntToStr(Camera.ID_Camera)+'_Input')));
    Camera.FrameReceiver.SubscribeVideo(Camera.ID_Camera,Cameras.Count=1);
  end;
end;

constructor TPlayer.Create(AOwner: TComponent);
var
  I: integer;
  ACell: TCell;
begin
  inherited Create(AOwner);
  FInUpdate:=0;
  Active:=0;
  FSkipUp:=false;
  FOperative:=false;
  InitializeCriticalSection(Crit);
  FCells:=TObjectList.Create;
  Align:=alClient;
  Cameras:=TList<PSCamera>.Create;
  for I := 0 to 32 do
  begin
    ACell:=TCell.Create(Self,Self);
    ACell.Index:=FCells.Add(ACell);
    ACell.SetMouseEvents(FMouseDown,FMouseUp,FMouseMove);
  end;
  TCell(FCells[0]).Active:=True;
  SetCapacity(1);
  OnResize:=ResizeProc;
end;

destructor TPlayer.Destroy;
begin
  // Удалить проигрыватели
  while Cameras.Count > 0 do
    Cameras.Delete(0);
  Cameras.Free;
  // Удалить ячейки
  while FCells.Count > 0 do
    FCells.Delete(0); // Проверил, в этом варианте TCell.Destroy происходит автоматически
  FCells.Free;
  DeleteCriticalSection(Crit);
  inherited;
end;

procedure TPlayer.InsertCamera(ID_Server, ID_Camera: integer; APosition: byte);
var
  OldPosition: Integer;
  i: integer;
  q: PSCamera;
  tmpPlayThread: TPlayThread;
begin
  // Если новая позиция корректна
  if (APosition < Cameras.Count) then
  begin
    OldPosition:=-1;
    if ID_Camera>0 then
      for i:=0 to Cameras.Count-1 do
        if (Cameras[i].ID_Camera=ID_Camera) and (Cameras[i].ID_Server=ID_Server) then
        begin
          OldPosition:=i;
          break;
        end;
    // Если старая позиция камеры = новая позици¤ камеры то нечего менять
    if (OldPosition <> APosition) then
    begin
      // Если старая позиция корректна
      if (OldPosition>=0) then
      begin
        Cameras.Exchange(OldPosition,APosition);
        tmpPlayThread:=GetPlayThread(Cameras[OldPosition].ID_Server,Cameras[OldPosition].ID_Camera,Cameras[OldPosition].Name);
        TCell(FCells[OldPosition]).SetPlayThread(tmpPlayThread);
      end
      else
      begin
        q:=Cameras[APosition];
        q.ID_Camera:=ID_Camera;
        q.ID_Server:=ID_Server;
        q.Name:=ArchManager.CameraName(ID_Server,ID_Camera);
        if assigned(q.FrameReceiver) then
        begin
          q.FrameReceiver.Stop;
          q.FrameReceiver:=nil;
        end;
      end;
      tmpPlayThread:=GetPlayThread(Cameras[APosition].ID_Server,Cameras[APosition].ID_Camera,Cameras[APosition].Name);
      TCell(FCells[APosition]).SetPlayThread(tmpPlayThread);
      Invalidate;
      if FInUpdate<=0 then
        if FOperative then
          CheckForOperative(Cameras[APosition])
        else
        begin
          tmpPlayThread.Primary:=Cameras.Count=1;
          RequestCurVideo(FCurVideoTime);
        end;
    end;
  end;
end;

procedure TPlayer.Pause;
var
  i: Integer;
begin
  for i := 0 to Cameras.Count-1 do
    GetPlayThread(Cameras[I].ID_Server,Cameras[I].ID_Camera,Cameras[I].Name).PlayState:=psStop;
end;

procedure TPlayer.Play(ASpeed: integer; AForward: boolean);
var
  I: integer;
  PlayThread: TPlayThread;
begin
  for I := 0 to Cameras.Count-1 do
  begin
    PlayThread:=GetPlayThread(Cameras[I].ID_Server,Cameras[I].ID_Camera,Cameras[I].Name);
    if I=Active then
    begin
      PlayThread.Acbf:=Acbf;
      PlayThread.MapHandle:=MapHandle;
    end;
    PlayThread.Speed:=abs(ASpeed);
    if ASpeed>0 then
      PlayThread.PlayState:=psPlay
    else
      PlayThread.PlayState:=psPlayRewind;
  end;
end;

procedure TPlayer.RequestCurVideo(ACurVideoTime: TDateTime);
var
  i: Integer;
begin
  if (ACurVideoTime>44553{EncodeDate(2021,12,23)}) then
  begin
    FCurVideoTime:= ACurVideoTime;
    if FInUpdate>0 then
      exit;
    for i:=0 to Cameras.Count-1 do
      if (Cameras[i].ID_Camera>0)and(Cameras[i].ID_Server>=0) then
        TCell(FCells[i]).FocusVideo(FCurVideoTime);
  end;
end;

procedure TPlayer.ResizeProc(Sender: TObject);
var
  q,w: integer;
  ti, i: Integer;
  FRect: TRect;
  FWidth,FHeight: integer;
  LayOutIndex: integer;
  NetArray: array[-1..35] of TPoint;
  NetCellSqrt: byte;
  PixelStepX,PixelStepY: Extended;
  HaveActive: boolean;
begin
  HaveActive:=false;
  if Width*Height>0 then
  begin
    HaveActive:=false;
    // Пересчитать ¤чейки
    FWidth:=Width-3;
    FHeight:=Height-2;
    ti:=Cameras.Count;
    NetCellSqrt:=1;
    case ti of
      4:
      begin
        LayOutIndex:=1;
        NetCellSqrt:=2;
      end;
      7:
      begin
        LayOutIndex:=2;
        NetCellSqrt:=4;
      end;
      8:
      begin
        LayOutIndex:=3;
        NetCellSqrt:=4;
      end;
      9:
      begin
        LayOutIndex:=4;
        NetCellSqrt:=3;
      end;
      10:
      begin
        LayOutIndex:=5;
        NetCellSqrt:=4;
      end;
      13:
      begin
        LayOutIndex:=6;
        NetCellSqrt:=4;
      end;
      16:
      begin
        LayOutIndex:=7;
        NetCellSqrt:=4;
      end;
      25:
      begin
        LayOutIndex:=8;
        NetCellSqrt:=5;
      end;
      33:
      begin
        LayOutIndex:=9;
        NetCellSqrt:=6;
      end;
    else
      LayOutIndex:=0;
    end;
    if LayOutIndex=0 then
    begin
      TCell(FCells[0]).SetBounds(1,1,FWidth,FHeight);
      TCell(FCells[0]).Visible:=True;
      SetActiveCell(0);
    end
    else
    begin
      // Расчитываем сетку, сохран¤ем её в массив точек
      PixelStepX:=FWidth/NetCellSqrt;
      PixelStepY:=FHeight/NetCellSqrt;
      NetArray[-1]:=Point(0,0);
      q:=0;
      for I := 1 to NetCellSqrt do
        for w := 1 to NetCellSqrt do
        begin
          NetArray[q].X:=min(Round(w*PixelStepX),FWidth-1);
          NetArray[q].Y:=min(Round(I*PixelStepY),FHeight-1);
          inc(q);
        end;
      for i := 0 to ti-1 do
      begin
        FRect:=Rect(NetArray[LayoutArray[LayOutIndex][i].Left].X+1,
            NetArray[LayoutArray[LayOutIndex][i].Top].Y+1,
            NetArray[LayoutArray[LayOutIndex][i].Right].X-NetArray[LayoutArray[LayOutIndex][i].Left].X,
            NetArray[LayoutArray[LayOutIndex][i].Bottom].Y-NetArray[LayoutArray[LayOutIndex][i].Top].Y);
        TCell(FCells[i]).SetBounds(FRect.Left,FRect.Top,FRect.Right,FRect.Bottom);
        TCell(FCells[i]).Visible:=True;
        HaveActive:=HaveActive or TCell(FCells[i]).Active;
      end;
    end;
  end;
  for I := Cameras.Count to FCells.Count-1 do
    TCell(FCells[I]).Visible:=false;
  if not HaveActive then
    TCell(FCells[0]).Active:=true;
  invalidate;
end;

procedure TPlayer.SetActiveCell(AIndex: integer);
var
  i,CIndex: integer;
begin
  EnterCriticalSection(Crit);
  try
    if Active<>AIndex then
    begin
      Active:=AIndex;
      if AIndex<Cameras.Count then
        CIndex:=AIndex
      else
        CIndex:=0;
      for I := 0 to FCells.Count-1 do
        TCell(FCells[i]).Active:=I=CIndex;
      Invalidate;
      Application.ProcessMessages;
      for I := 0 to Cameras.Count-1 do
        GetPlayThread(Cameras[I].ID_Server,Cameras[I].ID_Camera,Cameras[I].Name).UpdateScreen;
    end;
  finally
    LeaveCriticalSection(Crit);
  end;
end;

procedure TPlayer.SetCapacity(const Value: integer);
var
  q: PSCamera;
begin
  if Cameras.Count<>Value then
  begin
    Pause;
    if Value<Cameras.Count then
    begin
      while Value<Cameras.Count do
      begin
        q:=Cameras[Value];
        if assigned(q.FrameReceiver) then
          q.FrameReceiver.Stop;
        Dispose(q);
        Cameras.Delete(Value);
      end;
      if Active>=Cameras.Count then
        SetActiveCell(0);
        //Active:=0;
    end
    else
    begin
      while Value>Cameras.Count do
      begin
        New(q);
        q.ID_Camera:=-1;
        q.Name:='';
        q.FrameReceiver:=nil;
        Cameras.Add(q);
      end;
    end;
    for q in Cameras do
      if FOperative then
      begin
        if assigned(q.FrameReceiver) then
          q.FrameReceiver.Primary:=Cameras.Count=1;
      end
      else
        GetPlayThread(q.ID_Server,q.ID_Camera,q.Name).Primary:=Cameras.Count=1;
    ResizeProc(self);
  end;
end;

procedure TPlayer.SkipUp;
begin
  FSkipUp:=true;
end;

procedure TPlayer.SetOperative(const Value: boolean);
var
  q: integer;
  cCamera: PSCamera;
  tmpPlayThread: TPlayThread;
begin
  if FOperative<>Value then
  begin
    FOperative:=Value;
    for q:=0 to Cameras.Count-1 do
    begin
      cCamera:=Cameras[q];
      if (cCamera.ID_Camera>0) and (cCamera.ID_Server>=0) then
      begin
        tmpPlayThread:=GetPlayThread(cCamera.ID_Server,cCamera.ID_Camera,cCamera.Name);
        tmpPlayThread.Primary:=Cameras.Count=1;
        if FOperative then
        begin
          tmpPlayThread.PlayState:=psStop;
          CheckForOperative(cCamera);
        end
        else if assigned(cCamera.FrameReceiver) then
        begin
          cCamera.FrameReceiver.Stop;
          cCamera.FrameReceiver:=nil;
        end;
      end;
    end;
  end;
end;

function TPlayer.GetArea(x, y: integer): integer;
var
  i: integer;
  q: TCell;
begin
  result:=-1;
  if (x>=0)and(y>=0) then
    for i := 0 to FCells.Count-1 do
    begin
      q:=TCell(FCells[i]);
      if q.Visible then
      begin
        if (x>=q.Left)and(x<=q.Left+q.Width) and (y>=q.Top)and(y<=q.Top+q.Height) then
        begin
          result:=i;
          break;
        end;
      end
      else
        break;
    end;
end;

function TPlayer.GetCapacity: integer;
begin
  result:=Cameras.Count;
end;

function TPlayer.GetPlayState: TPlayState;
begin
  result:=GetPlayThread(Cameras[0].ID_Server,Cameras[0].ID_Camera,Cameras[0].Name).PlayState;
end;

procedure TPlayer.BeginUpdate;
begin
  FInUpdate:=FInUpdate+1;
end;

procedure TPlayer.EndUpdate;
var
  q: PSCamera;
begin
  if FInUpdate>0 then
    FInUpdate:=FInUpdate-1;
  if FInUpdate=0 then
  begin
    for q in Cameras do
      if FOperative then
        CheckForOperative(q)
      else
        GetPlayThread(q.ID_Server,q.ID_Camera,q.Name).Primary:=Cameras.Count=1;
    if not FOperative then
      RequestCurVideo(FCurVideoTime);
  end;
end;

procedure TPlayer.FMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACell: TCell;
begin
  if Button=mbLeft then
  begin
    ACell:=TCell(Sender);
    luFocus.X:=X;
    luFocus.Y:=Y;
    // Запомнить зону
    FStartMoveZone:=ACell.Index
  end;
end;

procedure TPlayer.FMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ACell: TCell;
  tmpPlayThread: TPlayThread;
begin
  if (ssLeft in Shift) then
  begin
    cr.X:=X;
    cr.Y:=Y;
    if  (luFocus.X>0) and (luFocus.Y>0)  then
    begin
      ACell:=TCell(Sender);
      // После даблклика может не быть камеры в изначальной ¤чейке
      if ACell.Index<Cameras.Count then
      begin
        tmpPlayThread:=GetPlayThread(Cameras[ACell.Index].ID_Server,Cameras[ACell.Index].ID_Camera,Cameras[ACell.Index].Name);
        if not tmpPlayThread.Zoomed then
          tmpPlayThread.FocusRect:=Rect(luFocus.X,luFocus.Y,cr.X,cr.Y)
      end
      else
        luFocus:=Point(0,0);
    end;
  end;
end;

procedure TPlayer.FMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  a: integer;
  mp: TPoint;
  tmpPlayThread: TPlayThread;
  ACell: TCell;
begin
  if not FSkipUp then
  begin
    ACell:=TCell(Sender);
    tmpPlayThread:=GetPlayThread(Cameras[ACell.Index].ID_Server,Cameras[ACell.Index].ID_Camera,Cameras[ACell.Index].Name);
    if Button=mbRight then
      tmpPlayThread.DropZoom
    else
    begin
      if (cr.X<>0)and(cr.Y<>0) then
      begin
        mp:=Mouse.CursorPos;
        mp:=ScreenToClient(mp);
        a:=GetArea(mp.X,mp.Y);
        if a>-1 then
          if (cr.X>0)and(cr.Y>0)and(a=FStartMoveZone)and(abs(luFocus.X-X)>4)and(abs(luFocus.Y-Y)>4)  then // Зумить только если не было драга
          begin
            if not tmpPlayThread.Zoomed then
              tmpPlayThread.ZoomFromFocus
          end
          else if (a<>FStartMoveZone)and(FStartMoveZone<>255)then
          begin
            Cameras.Exchange(FStartMoveZone,a);
            tmpPlayThread:=GetPlayThread(Cameras[FStartMoveZone].ID_Server,Cameras[FStartMoveZone].ID_Camera,Cameras[FStartMoveZone].Name);
            tmpPlayThread.FocusRect:=Rect(0,0,0,0);
            TCell(FCells[FStartMoveZone]).SetPlayThread(tmpPlayThread);
            tmpPlayThread:=GetPlayThread(Cameras[a].ID_Server,Cameras[a].ID_Camera,Cameras[a].Name);
            tmpPlayThread.FocusRect:=Rect(0,0,0,0);
            TCell(FCells[a]).SetPlayThread(tmpPlayThread);
            PostMessage(MapHandle,WM_EXCHANGE_CAMERAS,Integer(FStartMoveZone),Integer(a));
            SetActiveCell(a);
          end;
      end
      else
      begin
        a:=TCell(Sender).Index;
        // Сделать ячейку активной
        SetActiveCell(a);
      end;
    end;
  end;
  FSkipUp:=false;
  FStartMoveZone:=255;
  luFocus.X:=0;
  luFocus.Y:=0;
  cr.X:=0;
  cr.Y:=0;
end;

procedure TPlayer.StepBack;
var
  i: integer;
begin
  for i:=0 to Cameras.Count-1 do
    GetPlayThread(Cameras[I].ID_Server,Cameras[I].ID_Camera,Cameras[I].Name).PlayState:=psStepbackward;
end;

procedure TPlayer.StepNext;
var
  i: integer;
begin
  for i:=0 to Cameras.Count-1 do
    GetPlayThread(Cameras[I].ID_Server,Cameras[I].ID_Camera,Cameras[I].Name).PlayState:=psStepforward;
end;

procedure TPlayer.WMSetCurTime(var Message: TMessage);
var
  DT: TDateTime;
  P: PDateTime;
begin
  P:=PDateTime(Message.WParam);
  Move(P^, DT, SizeOf(TDateTime));
  Dispose(P);
  if Message.LParam<=100 then
    RequestCurVideo(DT)
  else
    FCurVideoTime:=DT;
end;

initialization
  LayoutArray[1][0]:=Rect(-1,-1,0,0);
  LayoutArray[1][1]:=Rect(0,-1,1,1);
  LayoutArray[1][2]:=Rect(-1,0,2,2);
  LayoutArray[1][3]:=Rect(0,0,3,3);

  LayoutArray[2][0]:=Rect(-1,-1,5,5);
  LayoutArray[2][1]:=Rect(5,-1,7,7);
  LayoutArray[2][2]:=Rect(-1,5,13,13);
  LayoutArray[2][3]:=Rect(5,5,10,10);
  LayoutArray[2][4]:=Rect(6,6,11,11);
  LayoutArray[2][5]:=Rect(9,9,14,14);
  LayoutArray[2][6]:=Rect(10,10,15,15);

  LayoutArray[3][0]:=Rect(-1,-1,10,10);
  LayoutArray[3][1]:=Rect(2,-1,3,3);
  LayoutArray[3][2]:=Rect(2,2,7,7);
  LayoutArray[3][3]:=Rect(6,6,11,11);
  LayoutArray[3][4]:=Rect(-1,8,12,12);
  LayoutArray[3][5]:=Rect(8,8,13,13);
  LayoutArray[3][6]:=Rect(9,9,14,14);
  LayoutArray[3][7]:=Rect(10,10,15,15);

  LayoutArray[4][0]:=Rect(-1,-1,0,0);
  LayoutArray[4][1]:=Rect(0,-1,1,1);
  LayoutArray[4][2]:=Rect(1,-1,2,2);
  LayoutArray[4][3]:=Rect(-1,0,3,3);
  LayoutArray[4][4]:=Rect(0,0,4,4);
  LayoutArray[4][5]:=Rect(1,1,5,5);
  LayoutArray[4][6]:=Rect(-1,3,6,6);
  LayoutArray[4][7]:=Rect(3,3,7,7);
  LayoutArray[4][8]:=Rect(4,4,8,8);

  LayoutArray[5][0]:=Rect(-1,-1,5,5);
  LayoutArray[5][1]:=Rect(5,-1,7,7);
  LayoutArray[5][2]:=Rect(-1,4,8,8);
  LayoutArray[5][3]:=Rect(4,4,9,9);
  LayoutArray[5][4]:=Rect(5,5,10,10);
  LayoutArray[5][5]:=Rect(6,6,11,11);
  LayoutArray[5][6]:=Rect(-1,8,12,12);
  LayoutArray[5][7]:=Rect(8,8,13,13);
  LayoutArray[5][8]:=Rect(9,9,14,14);
  LayoutArray[5][9]:=Rect(10,10,15,15);

  LayoutArray[6][0]:=Rect(-1,-1,0,0);
  LayoutArray[6][1]:=Rect(0,-1,1,1);
  LayoutArray[6][2]:=Rect(1,-1,2,2);
  LayoutArray[6][3]:=Rect(2,-1,3,3);
  LayoutArray[6][4]:=Rect(-1,0,4,4);
  LayoutArray[6][5]:=Rect(0,0,10,10);
  LayoutArray[6][6]:=Rect(2,2,7,7);
  LayoutArray[6][7]:=Rect(-1,4,8,8);
  LayoutArray[6][8]:=Rect(6,6,11,11);
  LayoutArray[6][9]:=Rect(-1,8,12,12);
  LayoutArray[6][10]:=Rect(8,8,13,13);
  LayoutArray[6][11]:=Rect(9,9,14,14);
  LayoutArray[6][12]:=Rect(10,10,15,15);

  LayoutArray[7][0]:=Rect(-1,-1,0,0);
  LayoutArray[7][1]:=Rect(0,-1,1,1);
  LayoutArray[7][2]:=Rect(1,-1,2,2);
  LayoutArray[7][3]:=Rect(2,-1,3,3);
  LayoutArray[7][4]:=Rect(-1,0,4,4);
  LayoutArray[7][5]:=Rect(0,0,5,5);
  LayoutArray[7][6]:=Rect(1,1,6,6);
  LayoutArray[7][7]:=Rect(2,2,7,7);
  LayoutArray[7][8]:=Rect(-1,4,8,8);
  LayoutArray[7][9]:=Rect(4,4,9,9);
  LayoutArray[7][10]:=Rect(5,5,10,10);
  LayoutArray[7][11]:=Rect(6,6,11,11);
  LayoutArray[7][12]:=Rect(-1,8,12,12);
  LayoutArray[7][13]:=Rect(8,8,13,13);
  LayoutArray[7][14]:=Rect(9,9,14,14);
  LayoutArray[7][15]:=Rect(10,10,15,15);

  LayoutArray[8][0]:=Rect(-1,-1,0,0);
  LayoutArray[8][1]:=Rect(0,-1,1,1);
  LayoutArray[8][2]:=Rect(1,-1,2,2);
  LayoutArray[8][3]:=Rect(2,-1,3,3);
  LayoutArray[8][4]:=Rect(3,-1,4,4);
  LayoutArray[8][5]:=Rect(-1,0,5,5);
  LayoutArray[8][6]:=Rect(0,0,6,6);
  LayoutArray[8][7]:=Rect(1,1,7,7);
  LayoutArray[8][8]:=Rect(2,2,8,8);
  LayoutArray[8][9]:=Rect(3,3,9,9);
  LayoutArray[8][10]:=Rect(-1,5,10,10);
  LayoutArray[8][11]:=Rect(5,5,11,11);
  LayoutArray[8][12]:=Rect(6,6,12,12);
  LayoutArray[8][13]:=Rect(7,7,13,13);
  LayoutArray[8][14]:=Rect(8,8,14,14);
  LayoutArray[8][15]:=Rect(-1,10,15,15);
  LayoutArray[8][16]:=Rect(10,10,16,16);
  LayoutArray[8][17]:=Rect(11,11,17,17);
  LayoutArray[8][18]:=Rect(12,12,18,18);
  LayoutArray[8][19]:=Rect(13,13,19,19);
  LayoutArray[8][20]:=Rect(-1,15,20,20);
  LayoutArray[8][21]:=Rect(15,15,21,21);
  LayoutArray[8][22]:=Rect(16,16,22,22);
  LayoutArray[8][23]:=Rect(17,17,23,23);
  LayoutArray[8][24]:=Rect(18,18,24,24);

  LayoutArray[9][0]:=Rect(-1,-1,0,0);
  LayoutArray[9][1]:=Rect(0,-1,1,1);
  LayoutArray[9][2]:=Rect(1,-1,2,2);
  LayoutArray[9][3]:=Rect(2,-1,3,3);
  LayoutArray[9][4]:=Rect(3,-1,4,4);
  LayoutArray[9][5]:=Rect(4,-1,5,5);
  LayoutArray[9][6]:=Rect(-1,0,6,6);
  LayoutArray[9][7]:=Rect(0,0,7,7);
  LayoutArray[9][8]:=Rect(1,1,8,8);
  LayoutArray[9][9]:=Rect(2,2,9,9);
  LayoutArray[9][10]:=Rect(3,3,10,10);
  LayoutArray[9][11]:=Rect(4,4,11,11);
  LayoutArray[9][12]:=Rect(-1,6,12,12);
  LayoutArray[9][13]:=Rect(6,6,13,13);
  LayoutArray[9][14]:=Rect(7,7,21,21);
  LayoutArray[9][15]:=Rect(9,9,16,16);
  LayoutArray[9][16]:=Rect(10,10,17,17);
  LayoutArray[9][17]:=Rect(-1,12,18,18);
  LayoutArray[9][18]:=Rect(12,12,19,19);
  LayoutArray[9][19]:=Rect(15,15,22,22);
  LayoutArray[9][20]:=Rect(16,16,23,23);
  LayoutArray[9][21]:=Rect(-1,18,24,24);
  LayoutArray[9][22]:=Rect(18,18,25,25);
  LayoutArray[9][23]:=Rect(19,19,26,26);
  LayoutArray[9][24]:=Rect(20,20,27,27);
  LayoutArray[9][25]:=Rect(21,21,28,28);
  LayoutArray[9][26]:=Rect(22,22,29,29);
  LayoutArray[9][27]:=Rect(-1,24,30,30);
  LayoutArray[9][28]:=Rect(24,24,31,31);
  LayoutArray[9][29]:=Rect(25,25,32,32);
  LayoutArray[9][30]:=Rect(26,26,33,33);
  LayoutArray[9][31]:=Rect(27,27,34,34);
  LayoutArray[9][32]:=Rect(28,28,35,35);

  AllowDblClick:=0;

end.