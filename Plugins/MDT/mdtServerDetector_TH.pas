unit mdtServerDetector_TH;

interface

uses
  mdtMotionDetector_TH, mdtEventSaver_TH, mdtTracker_TH, ABL.Core.ThreadController, SysUtils,
  Generics.Collections, ABL.VS.VSTypes;

type
  TServerDetector=class
  private
    MotionDetector: TMotionDetector;
    EventSaver: TEventSaver;
    Tracker: TTracker;
  public
    constructor Create(AID_Camera: integer);
    destructor Destroy; override;
    procedure Push(AFrame: PImageDataHeader);
  end;

var
  DetectorList: TObjectList<TServerDetector>;

implementation

{ TServerDetector }

constructor TServerDetector.Create(AID_Camera: integer);
begin
  MotionDetector:=TMotionDetector.Create(AID_Camera);
  EventSaver:=TEventSaver.Create(MotionDetector.OutputQueue,ThreadController.QueueByName('EventSaver_'+IntToStr(AID_Camera)),'EventSaver_'+IntToStr(AID_Camera),AID_Camera);
  Tracker:=TTracker.Create(EventSaver.OutputQueue,ThreadController.QueueByName('Tracker_'+IntToStr(AID_Camera)),'Tracker_'+IntToStr(AID_Camera));
  DetectorList.Add(Self);
end;

destructor TServerDetector.Destroy;
begin
  DetectorList.Remove(Self);
  MotionDetector.Destroy;
  EventSaver.Destroy;
  Tracker.Destroy;
  inherited;
end;

procedure TServerDetector.Push(AFrame: PImageDataHeader);
begin
  MotionDetector.InputQueue.Push(AFrame);
end;

initialization
  DetectorList:=TObjectList<TServerDetector>.Create;
  DetectorList.OwnsObjects:=false;

finalization
  DetectorList.Free;

end.
