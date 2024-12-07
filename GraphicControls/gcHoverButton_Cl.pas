unit gcHoverButton_Cl;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Messages, Graphics, Math, Types;

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  THoverButton = class(TCustomControl)
  private
    FClicked: boolean;
    FDrawBitmap,FHoverDrawBitmap,FPattern, FCurDrawBmp, FOldDrawBmp: TBitmap;
    FHoverColor: TColor;
    procedure RebuildBmp;
    procedure SetPattern(const Value: TBitmap);
    procedure SetHoverColor(const Value: TColor);
    { Private declarations }
  protected
    { Protected declarations }
    procedure MouseDown({Sender: TObject; }Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave(var msg: TMessage); message CM_MOUSELEAVE;
    procedure MouseUp({Sender: TObject; }Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
  published
    { Published declarations }
    property Color;
    property HoverColor: TColor read FHoverColor write SetHoverColor;
    property OnClick;
    property Pattern: TBitmap read FPattern write SetPattern;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('ABItems', [THoverButton]);
end;

{ THoverButton }

constructor THoverButton.Create(AOwner: TComponent);
begin
  inherited;
  FDrawBitmap:=TBitmap.Create;
  FDrawBitmap.PixelFormat:=pf24bit;
  FHoverDrawBitmap:=TBitmap.Create;
  FHoverDrawBitmap.PixelFormat:=pf24bit;
  FPattern:=TBitmap.Create;
  FCurDrawBmp:=FDrawBitmap;
  FClicked:=false;
  //OnMouseDown:=MouseDown;
  //OnMouseUp:=MouseUp;
end;

procedure THoverButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FClicked:=True;
  RebuildBmp;
  Invalidate;
end;

procedure THoverButton.MouseLeave(var msg: TMessage);
begin
  FCurDrawBmp:=FDrawBitmap;
  RebuildBmp;
  Invalidate;
end;

procedure THoverButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FClicked:=False;
  RebuildBmp;
  Invalidate;
end;

procedure THoverButton.Paint;
begin
  if FDrawBitmap.Width<>Width then
    RebuildBmp;
  Canvas.Draw(0,0,FCurDrawBmp);
end;

procedure THoverButton.RebuildBmp;
var
  x,y,increment: integer;
begin
  if FClicked then
    increment:=1
  else
    increment:=0;
  FDrawBitmap.SetSize(Width,Height);
  FHoverDrawBitmap.SetSize(Width,Height);
  FDrawBitmap.Canvas.Brush.Color:=clBtnFace;
  FDrawBitmap.Canvas.FillRect(Rect(0,0,Width,Height));
  FHoverDrawBitmap.Canvas.Brush.Color:=clBtnFace;
  FHoverDrawBitmap.Canvas.FillRect(Rect(0,0,Width,Height));
  for y := 0 to min(FPattern.Height,Height)-1 do
    for x := 0 to min(FPattern.Width,Width)-1 do
    begin
      if FPattern.Canvas.Pixels[x,y]=0 then
      begin
        FDrawBitmap.Canvas.Pixels[x+increment,y+increment]:=Color;
        FHoverDrawBitmap.Canvas.Pixels[x+increment,y+increment]:=Color;
        FDrawBitmap.Canvas.Pixels[x+increment+1,y+increment+1]:=clGray;
        FHoverDrawBitmap.Canvas.Pixels[x+increment+1,y+increment+1]:=clGray;
      end
      else if FPattern.Canvas.Pixels[x,y]<>clWhite then
        FHoverDrawBitmap.Canvas.Pixels[x+increment,y+increment]:=FHoverColor;
    end;
end;

procedure THoverButton.SetHoverColor(const Value: TColor);
begin
  if FHoverColor<>Value then
  begin
    FHoverColor:=Value;
    //if not (csCreating in ControlState) then
    //  RebuildBmp;
  end;
end;

procedure THoverButton.SetPattern(const Value: TBitmap);
begin
  FPattern.Assign(Value);
  RebuildBmp;
end;

procedure THoverButton.WMNCHitTest(var Message: TWMNCHitTest);
var
  tmpPoint: TPoint;
begin
  tmpPoint:=ScreenToClient(Point(Message.XPos,Message.YPos));
  if FPattern.Canvas.Pixels[tmpPoint.X,tmpPoint.Y]=0 then
    FCurDrawBmp:=FHoverDrawBitmap
  else
    FCurDrawBmp:=FDrawBitmap;
  if FOldDrawBmp<>FCurDrawBmp then
  begin
    FOldDrawBmp:=FCurDrawBmp;
    invalidate;
  end;
  Inherited;
end;

end.
