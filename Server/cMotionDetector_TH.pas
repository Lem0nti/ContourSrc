unit cMotionDetector_TH;

interface

uses
  SysUtils, Generics.Collections, ABL.Core.Debug, ABL.Core.DirectThread, cCommon,
  Windows, Classes, Math, DateUtils, Types, ABL.VS.VSTypes, SyncObjs;

const
  Sensivity = 40;
  IcoSize = 16;

type
  TMotionDetector=class(TDirectThread)
  private
    Ethalon: array of byte;
    FIncSave: TThreadMethod;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    ID_Camera: integer;
    procedure ApplyIncSave(AProc: TThreadMethod);
  end;

implementation

{ TMotionDetector }

procedure TMotionDetector.ApplyIncSave(AProc: TThreadMethod);
begin
  FLock.Enter;
  try
    FIncSave:=AProc;
  finally
    FLock.Leave
  end;
end;

procedure TMotionDetector.DoExecute(var AInputData, AResultData: Pointer);
var
  DecodedFrame: PImageDataHeader;
  Offset,x,y: integer;
  rcWidth,rcHeight: Real;
  Can: integer;
  CameraTimePoint: PCameraTimePoint;
  RGBTriple: PRGBTriple;

  procedure ApplyAsEthalon;
  var
    ax,ay: integer;
  begin
    Offset:=0;
    SetLength(Ethalon,IcoSize*IcoSize);
    for ay := 0 to IcoSize-1 do
      for ax := 0 to IcoSize-1 do
      begin
        RGBTriple:=PRGBTriple(NativeUInt(DecodedFrame.Data)+(Round(ay*rcHeight)*DecodedFrame.Width+Round(ax*rcWidth))*3);
        Ethalon[Offset]:=RGBTriple.rgbtGreen;
        inc(Offset);
      end;
  end;

begin
  if ID_Camera>0 then
  begin
    DecodedFrame:=AInputData;
    if Length(Ethalon)=0 then
      ApplyAsEthalon
    else
    begin
      rcWidth:=DecodedFrame.Width/IcoSize;
      rcHeight:=DecodedFrame.Height/IcoSize;
      //движение
      Can:=0;
      Offset:=0;
      for y := 0 to IcoSize-1 do
      begin
        for x := 0 to IcoSize-1 do
        begin
          RGBTriple:=PRGBTriple(NativeUInt(DecodedFrame.Data)+(Round(y*rcHeight)*DecodedFrame.Width+Round(x*rcWidth))*3);
          if abs(Ethalon[Offset]-RGBTriple.rgbtGreen)>Sensivity then
          begin
            inc(Can);
            if Can>1 then
              break;
          end;
          inc(Offset);
        end;
        if Can>1 then
          break;
      end;
      if Can>1 then
      begin
        ApplyAsEthalon;
        if assigned(FOutputQueue) then
        begin
          new(CameraTimePoint);
          CameraTimePoint.Time:=DecodedFrame.TimedDataHeader.Time;
          CameraTimePoint.ID_Camera:=ID_Camera;
          AResultData:=CameraTimePoint;
        end;
        //продолжить запись видео
        if assigned(FIncSave) then
          FIncSave;
      end;
    end;
  end;
end;

end.
