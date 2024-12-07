unit cSlider_TH;

interface

uses
  ABL.Core.DirectThread, Windows, Classes, JPEG, Graphics, ABL.Core.BaseQueue, SysUtils, ABL.Core.Debug,
  ABL.VS.VSTypes, DateUtils, cCommon;

type
  pRGBArray = ^TRGBArray;
  TRGBArray = array [0..16383] of TRGBTriple;

  TSlider=class(TDirectThread)
  private
    bmp: TBitmap;
    FArchiveList: TStringList;
    jpg: TJpegImage;
    oCounter: byte;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AArchives: string); reintroduce;
    destructor Destroy; override;
  end;

var
  Slider: TSlider;

const
  SlideSize = 320;

implementation

{ TSlider }

constructor TSlider.Create(AInputQueue: TBaseQueue; AArchives: string);
begin
  inherited Create(AInputQueue,nil,'TSlider');
  oCounter:=0;
  bmp:=TBitmap.Create;
  bmp.PixelFormat:=pf24bit;
  bmp.Canvas.Brush.Style:=bsClear;
  bmp.Canvas.Font.Size:=8;
  bmp.Canvas.Font.Style:=[fsBold];
  bmp.Canvas.Font.Color:=clLime;
  jpg:=TJpegImage.Create;
  FArchiveList:=TStringList.Create;
  FArchiveList.Text:=trim(AArchives);
  if FArchiveList.Count=0 then
    SendErrorMsg('TSlider.Create 50: Нет путей сохранения.')
  else
    Active:=true;
end;

destructor TSlider.Destroy;
begin
  if assigned(FArchiveList) then
    FreeAndNil(FArchiveList);
  if assigned(jpg) then
    FreeAndNil(jpg);
  if assigned(bmp) then
    FreeAndNil(bmp);
end;

procedure TSlider.DoExecute(var AInputData, AResultData: Pointer);
var
  SlideFrame: PSlideFrame;
  NHeight,FID_Archive,AttemptCount,STime: integer;
  FPath: TFileName;
  SlideTime: TDateTime;
begin
  AttemptCount:=0;
  try
    SlideFrame:=PSlideFrame(AInputData);
    try
      if FArchiveList.Count>0 then
      begin
        FPath:=FArchiveList.ValueFromIndex[0];
        FID_Archive:=StrToIntDef(FArchiveList.Names[0],0);
        if FID_Archive>0 then
        begin
          //добываем картинку
          bmp.SetSize(SlideFrame.DecodedFrame.Width,SlideFrame.DecodedFrame.Height);
          for NHeight := 0 to SlideFrame.DecodedFrame.Height-1 do
            Move(PByte(NativeUInt(SlideFrame.DecodedFrame.Data)+SlideFrame.DecodedFrame.Width*NHeight*3)^,bmp.ScanLine[NHeight]^,SlideFrame.DecodedFrame.Width*3);
          // размер
          if bmp.Width>SlideSize then
          begin
            NHeight:=Round(SlideSize/bmp.Width*bmp.Height);
            bmp.Canvas.StretchDraw(Rect(0,0,SlideSize-1,NHeight-1),bmp);
            bmp.Canvas.Lock;
            bmp.SetSize(SlideSize,NHeight);
            bmp.Canvas.Unlock;
          end;
          SlideTime:=IncMilliSecond(UnixDateDelta,SlideFrame.DecodedFrame.TimedDataHeader.Time);
          bmp.Canvas.TextOut(4,4,FormatDateTime('DD.MM.YYYY HH:mm:ss',SlideTime));
          jpg.Assign(bmp);
          jpg.CompressionQuality:=100;
          jpg.Compress;
          FPath:=FPath+FormatDateTime('YYMMDD',SlideTime)+'\'+IntToStr(SlideFrame.ID_Camera)+'_0\';
          ForceDirectories(FPath);
          STime:=SecondsBetween(trunc(SlideTime),SlideTime);
          while AttemptCount<2 do
            try
              inc(AttemptCount);
              jpg.SaveToFile(FPath+IntToStr(STime)+'.jpg');
              AttemptCount:=255;
            except on e: EFCreateError do
              if AttemptCount>=2 then
                raise
            else
              raise;
            end;
        end;
      end;
    finally
      FreeMem(SlideFrame.DecodedFrame);
      Dispose(SlideFrame);
      AInputData:=nil;
    end;
  except on e: Exception do
    SendErrorMsg('TSlider.DoExecute 121, AttemptCount='+IntToStr(AttemptCount)+': '+e.ClassName+' - '+e.Message);
  end;
end;

end.
