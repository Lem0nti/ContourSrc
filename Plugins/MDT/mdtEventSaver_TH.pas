unit mdtEventSaver_TH;

interface

uses
  ABL.Core.DirectThread, ABL.IO.IOTypes, ABL.Core.BaseQueue, mdtData_DM, ABL.IA.IATypes, SysUtils,
  mdtCommon;

type
  TEventSaver=class(TDirectThread)
  private
    OldDateTime: int64;
    FID_Camera,FID_Event: integer;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue,AOutputQueue: TBaseQueue; AName: string; AID_Camera: integer); reintroduce;
  end;

implementation

{ TEventSaver }

constructor TEventSaver.Create(AInputQueue,AOutputQueue: TBaseQueue; AName: string; AID_Camera: integer);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FID_Camera:=AID_Camera;
  OldDateTime:=0;
  Start;
end;

procedure TEventSaver.DoExecute(var AInputData, AResultData: Pointer);
var
  TimedDataHeader: PTimedDataHeader;
  Area: TArea;
  Square_From,Square_To: integer;
begin
  TimedDataHeader:=AInputData;
  //если сменилась дата, то записать событие
  if OldDateTime<>TimedDataHeader.Time then
  begin
    FID_Event:=DataDM.SaveEvent(FID_Camera,TimedDataHeader.Time);
    OldDateTime:=TimedDataHeader.Time;
  end;
  //записать зону
  Move(TimedDataHeader.Data^,Area,SizeOf(TArea));
  Square_From:=Area.Rect.Top*100+Area.Rect.Left;
  Square_To:=Area.Rect.Bottom*100+Area.Rect.Right;
  Area.Cnt:=DataDM.SaveZone(FID_Event,Square_From,Square_To);
  Move(Area,TimedDataHeader.Data^,SizeOf(TArea));
  AResultData:=AInputData;
  AInputData:=nil;
end;

end.
