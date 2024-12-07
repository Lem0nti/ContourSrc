unit cMotionSaver_TH;

interface

uses
  ABL.Core.DirectThread, ABL.Core.BaseQueue, ABL.Core.Debug, SysUtils, Generics.Collections, cCommon, cData_DM;

type
  PMotionRecord=^TMotionRecord;
  TMotionRecord=record
    ID_Camera: integer;
    SBegin, SEnd: int64;
  end;

  TMotionSaver=class(TDirectThread)
  private
    MotionRecord: TList<PMotionRecord>;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    Destructor Destroy; override;
  end;

var
  MotionSaver: TMotionSaver;

implementation

{ TMotionIndexSaver }

constructor TMotionSaver.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  MotionRecord:=TList<PMotionRecord>.Create;
  Active:=true;
end;

destructor TMotionSaver.Destroy;
begin
  if assigned(MotionRecord) then
    FreeAndNil(MotionRecord);
  inherited;
end;

procedure TMotionSaver.DoExecute(var AInputData, AResultData: Pointer);
var
  q: integer;
  MotionPoint: PCameraTimePoint;
  mr: PMotionRecord;
begin
  try
    MotionPoint:=PCameraTimePoint(AInputData);
    //собирать индекс отдельно по камерам
    mr:=nil;
    for q:=0 to MotionRecord.Count-1 do
      if MotionRecord[q].ID_Camera=MotionPoint.ID_Camera then
      begin
        mr:=MotionRecord[q];
        break;
      end;
    if assigned(mr) then
    begin
      //сдвигать время при получении нового сигнала
      //если сдвиг времени больше 2 секунд, то отправлять текущую информацию на сохранение
      //если общее время движения более 5 минут, то отправлять текущую информацию на сохранение
      if (MotionPoint.Time-mr.SEnd<=2000) and (mr.SEnd-mr.SBegin<300000) then
        mr.SEnd:=MotionPoint.Time
      else
      begin
        //не сохранять точку времени где начало равно окончанию
        if mr.SEnd>mr.SBegin then
          DataDM.InsertMotion(mr.ID_Camera,mr.SBegin,mr.SEnd);
        mr.SBegin:=MotionPoint.Time;
        mr.SEnd:=MotionPoint.Time;
      end;
    end
    else
    begin
      new(mr);
      mr.ID_Camera:=MotionPoint.ID_Camera;
      mr.SBegin:=MotionPoint.Time;
      mr.SEnd:=MotionPoint.Time;
      MotionRecord.Add(mr);
    end;
  except on e: Exception do
    SendErrorMsg('TMotionSaver.DoExecute 97: '+e.ClassName+' - '+e.Message);
  end;
end;

end.
