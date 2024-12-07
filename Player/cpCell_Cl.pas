unit cpCell_Cl;

interface

uses
  Vcl.Controls, Messages, Classes, Vcl.Graphics, SysUtils, ABL.Core.Debug, Types, Windows,
  cCommon,
  Generics.Collections, Vcl.Forms, WinSock,
  cpArchVideo_Cl,
  ExtCtrls;

type
  TDblClick = procedure(ALayout: integer);

  TCell = class(TCustomControl)
  private
    FCurCamera: TPoint;
    FActive: boolean;
    procedure CBDraw(DC: HDC; Width, Height: integer; DateTime: int64);
    function GetRect: TRect;
    procedure SetActive(const Value: boolean);
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    Index: byte;
    PlayThread: TPlayThread;
    procedure WMPaintEx(var Message: TWMPaint); message WM_ERASEBKGND;
    constructor Create(AOwner: TComponent; AParent: TCustomControl); reintroduce;
    procedure FDblClick(Sender: TObject);
    procedure SetMouseEvents(MouseDown, MouseUp: TMouseEvent; MouseMove: TMouseMoveEvent);
    procedure SetPlayThread(APlayThread: TPlayThread);
    procedure FocusVideo(ATime: TDateTime);
    property Active: boolean read FActive write SetActive;
    property Rect: TRect read GetRect;
  end;

var
  Acbf: Tcbf;              //сервер*100+камера
  Acbd: Tcbd;
  CellManager: TDictionary<integer, TCell>;
  AllowDblClick: UInt64 = 0;
  FDblClickCB: TDblClick;
  tmpPointer: Pointer;

implementation

var
  WSAReady: boolean = false;

{ TCell }

procedure TCell.CBDraw(DC: HDC; Width, Height: integer; DateTime: int64);
begin
  if (@Acbd<>nil) then
    Acbd(FCurCamera.X,FCurCamera.Y,DateTime,DC,Width,Height);
end;

constructor TCell.Create(AOwner: TComponent; AParent: TCustomControl);
begin
  inherited Create(AOwner);
  Parent:=AParent;
  BorderWidth:=1;
  Color:=clLtGray;
  OnDblClick:=FDblClick;
end;

function TCell.GetRect: TRect;
begin
  GetWindowRect(Handle,result);
end;

procedure TCell.SetActive(const Value: boolean);
begin
  if FActive<>Value then
  begin
    FActive:=Value;
    if FActive then
    begin
      Color:=clRed;
      PlayThread.OnDraw:=CBDraw;
    end
    else
    begin
      Color:=clSkyBlue;
      PlayThread.OnDraw:=nil;
    end;
  end;
end;

procedure TCell.SetMouseEvents(MouseDown, MouseUp: TMouseEvent; MouseMove: TMouseMoveEvent);
begin
  OnMouseDown:=MouseDown;
  OnMouseUp:=MouseUp;
  OnMouseMove:=MouseMove;
end;

procedure TCell.SetPlayThread(APlayThread: TPlayThread);
begin
  if PlayThread<>APlayThread then
  begin
    if PlayThread<>nil then
      PlayThread.Handle:=0;
    PlayThread:=APlayThread;
  end;
  if PlayThread<>nil then
  begin
    FCurCamera.X:=PlayThread.ID_Server;
    FCurCamera.Y:=PlayThread.ID_Camera;
    PlayThread.Handle:=Handle;
  end
  else
    FCurCamera:=Point(0,0);
end;

procedure TCell.WndProc(var Message: TMessage);
begin
  Dispatch(Message);
end;

procedure TCell.WMPaintEx(var Message: TWMPaint);
begin  // Не убирать этот метод, это защита от затирания первого кадра
  tag:=tag;
end;

procedure TCell.FDblClick(Sender: TObject);
begin
  if GetTickCount64>AllowDblClick then
  begin
    if @FDblClickCB<>nil then
      FDblClickCB(Index);
    AllowDblClick:=GetTickCount64+500;
  end;
end;

procedure TCell.FocusVideo(ATime: TDateTime);
begin
  PlayThread.LoadVideo(ATime);
end;

end.
