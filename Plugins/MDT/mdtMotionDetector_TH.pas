unit mdtMotionDetector_TH;

interface

uses
  SysUtils, ABL.Core.ThreadController, ABL.IA.ImageResize, ABL.VS.VSTypes, mdtEventSaver_TH,
  Windows, Classes, Math, DateUtils, Types, SyncObjs, ABL.IA.OnlyMotion, ABL.IA.ImageConverter,
  ABL.IA.LinkComponent, mdtTracker_TH, mdtCommon, ABL.Core.BaseQueue;

const
  Sensivity = 16;

type
  TMotionDetector=class
  private
    FID_Camera: integer;
    OnlyMotion: TOnlyMotion;
    ImageConverter: TImageConverter;
    ImageResize: TImageResize;
    LinkComponent: TLinkComponent;
  public
    constructor Create(AID_Camera: integer);
    destructor Destroy; override;
    function InputQueue: TBaseQueue;
    function OutputQueue: TBaseQueue;
  end;

implementation

{ TMotionDetector }

constructor TMotionDetector.Create(AID_Camera: integer);
begin
  FID_Camera:=AID_Camera;
  ImageResize:=TImageResize.Create(ThreadController.QueueByName('ImageResizeInput_'+IntToStr(FID_Camera)),ThreadController.QueueByName('ImageResizeOutput_'+IntToStr(FID_Camera)),
      'ImageResize_'+IntToStr(FID_Camera));
  ImageResize.SetSize(IcoSize,IcoSize);
  ImageResize.Algorythm:=raAverageBright;
  OnlyMotion:=TOnlyMotion.Create(ImageResize.OutputQueue,ThreadController.QueueByName('IfMotionOutput_'+IntToStr(FID_Camera)),'IfMotion_'+IntToStr(FID_Camera));
  OnlyMotion.SetGrid(IcoSize,IcoSize);
  OnlyMotion.Sensivity:=Sensivity;
  ImageConverter:=TImageConverter.Create(OnlyMotion.OutputQueue,ThreadController.QueueByName('ImageConverterOutput_'+IntToStr(FID_Camera)),'ImageConverter_'+IntToStr(FID_Camera));
  ImageConverter.ResultType:=itBit;
  ImageConverter.Threshold:=254;
  LinkComponent:=TLinkComponent.Create(ImageConverter.OutputQueue,ThreadController.QueueByName('LinkComponentOutput_'+IntToStr(FID_Camera)),
      'LinkComponent_'+IntToStr(FID_Camera));
  LinkComponent.MinSize:=1;
end;

destructor TMotionDetector.Destroy;
begin
  ImageResize.Free;
  OnlyMotion.Free;
  ImageConverter.Free;
  LinkComponent.Free;
  inherited Destroy;
end;

function TMotionDetector.InputQueue: TBaseQueue;
begin
  result:=ImageResize.InputQueue;
end;

function TMotionDetector.OutputQueue: TBaseQueue;
begin
  result:=LinkComponent.OutputQueue;
end;

end.
