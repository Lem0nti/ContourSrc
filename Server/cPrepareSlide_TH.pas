unit cPrepareSlide_TH;

interface

uses
  ABL.Core.DirectThread, cCommon, ABL.VS.VSTypes, ABL.Core.BaseQueue, DateUtils, SysUtils;

type
  TPrepareSlide=class(TDirectThread)
  private
    LastSlide: TDatetime;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    ID_Camera: integer;
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
  end;

implementation

{ TPrepareSlide }

constructor TPrepareSlide.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  LastSlide:=0;
end;

procedure TPrepareSlide.DoExecute(var AInputData, AResultData: Pointer);
var
  SlideFrame: PSlideFrame;
  DecodedFrame: PImageDataHeader;
  WSeq: int64;
begin
  DecodedFrame:=AInputData;
  WSeq:=DecodedFrame.TimedDataHeader.Time div 1000;
  if ((WSeq mod 10)=0) and (IncMilliSecond(LastSlide,5000)<now) then
  begin
    LastSlide:=now;
    New(SlideFrame);
    SlideFrame.ID_Camera:=ID_Camera;
    SlideFrame.DecodedFrame:=DecodedFrame;
    AInputData:=nil;
    AResultData:=SlideFrame;
  end;
end;

end.
