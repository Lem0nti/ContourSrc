unit cAlarmer_TH;

interface

uses
  SysUtils, Classes, Types, DateUtils, Contnrs, ABL.Core.ThreadQueue, cCommon, cCamera_Cl, cData_DM, ABL.Core.Debug;

type
  PAlarmRecord=^TAlarmRecord;
  TAlarmRecord=record
    ID_Camera: integer;
    SBegin, SEnd: int64;
    StartMessage: string;
  end;

  TAlarmer=class(TThread)
  private
    DelCount: integer;
    AlarmRecord: TList;
  protected
    procedure Execute; override;
  public
    FInputQueue: TThreadQueue;
    constructor Create(AInputQueue: TThreadQueue); reintroduce;
    Destructor Destroy; override;
    procedure Stop;
  end;

var
  Alarmer: TAlarmer;

implementation

{ TAlarmer }

constructor TAlarmer.Create(AInputQueue: TThreadQueue);
begin
  inherited Create;
  AlarmRecord:=TList.Create;
  FInputQueue:=AInputQueue;
  DelCount:=0;
end;

destructor TAlarmer.Destroy;
begin
  if assigned(AlarmRecord) then
    FreeAndNil(AlarmRecord);
  inherited;
end;

procedure TAlarmer.Execute;
var
  q,w: integer;
  AlarmPoint: PCameraTimePoint;
  mr: PAlarmRecord;
  ACamera: TCamera;
  tmpMillisecond: int64;
begin
  FreeOnTerminate:=True;
  try
    try
      try
        while not Terminated do
        begin
          FInputQueue.WaitForItems(60000);
          while FInputQueue.Count>0 do
          begin
            if Terminated then
              exit;
            AlarmPoint:=PCameraTimePoint(FInputQueue.Pop);
            try
              //�������� ������ �������� �� �������
              mr:=nil;
              for q:=0 to AlarmRecord.Count-1 do
                if PAlarmRecord(AlarmRecord[q]).ID_Camera=AlarmPoint.ID_Camera then
                begin
                  mr:=AlarmRecord[q];
                  break;
                end;
              if assigned(mr) then
              begin
                //�������� ����� ��� ��������� ������ �������
                //���� ����� ������� ������ 45 ������, �� ���������� ������� ���������� �� ����������
                if AlarmPoint.Time-mr.SEnd<=45000 then
                  mr.SEnd:=AlarmPoint.Time
                else
                begin
                  //�� ��������� ����� ������� ��� ������ ����� ���������
                  if mr.SEnd>mr.SBegin then
                    //� �������� ������ ������ ������ ������
                    DataDM.InsertAlarm(mr.ID_Camera,mr.SBegin,mr.SEnd,mr.StartMessage);
                  mr.SBegin:=AlarmPoint.Time;
                  mr.SEnd:=AlarmPoint.Time;
                end;
              end
              else
              begin
                new(mr);
                mr.ID_Camera:=AlarmPoint.ID_Camera;
                mr.SBegin:=AlarmPoint.Time;
                mr.SEnd:=AlarmPoint.Time;
                mr.StartMessage:=AlarmPoint.Message;
                AlarmRecord.Add(mr);
              end;
            finally
              Dispose(AlarmPoint);
            end;
          end;
          if Terminated then
            exit;
          //������ ��������� ���������
          for q:=AlarmRecord.Count-1 downto 0 do
          begin
            mr:=AlarmRecord[q];
            ACamera:=nil;
            for w:=0 to AllCameras.Count-1 do
              if mr.ID_Camera=TCamera(AllCameras[w]).ID_Camera then
              begin
                ACamera:=TCamera(AllCameras[w]);
                tmpMillisecond:=MilliSecondsBetween(UnixDateDelta,ACamera.LastInput);
                //���� ������ �����
                if tmpMillisecond>mr.SEnd then
                begin
                  //���� ����� � ��������� ������, �� ���������
                  if mr.SEnd>mr.SBegin then
                    DataDM.InsertAlarm(mr.ID_Camera,mr.SBegin,mr.SEnd,mr.StartMessage);
                  //������� ���������
                  Dispose(mr);
                  AlarmRecord.Delete(q);
                end
                else  //���� ������ �� �����
                begin
                  //���� ������� ����������� ������ 256, �� ��������� ������� ����� ����� ���������
                  if ACamera.ConnectTryCount<256 then
                    mr.SEnd:=MilliSecondsBetween(UnixDateDelta,now)
                  else  //���� ������� ����������� ������ 256, �� ��������� � ������� ���������
                  begin
                    //���� ����� � ��������� ������, �� ���������
                    if mr.SEnd>mr.SBegin then
                      DataDM.InsertAlarm(mr.ID_Camera,mr.SBegin,mr.SEnd,mr.StartMessage);
                    //������� ���������
                    Dispose(mr);
                    AlarmRecord.Delete(q);
                  end;
                end;
                break;
              end;
            //���� ������ ��� - ������� ���������
            if not assigned(ACamera) then
            begin
              Dispose(mr);
              AlarmRecord.Delete(q);
            end;
          end;
        end;
      finally
        if not Terminated then
          for q:=AlarmRecord.Count-1 downto 0 do
          begin
            mr:=AlarmRecord[q];
            if mr.SEnd>mr.SBegin then
              DataDM.InsertAlarm(mr.ID_Camera,mr.SBegin,mr.SEnd,mr.StartMessage);
            //������� ���������
            Dispose(mr);
            AlarmRecord.Delete(q);
            inc(DelCount);
          end;
      end;
    except on e: Exception do
      SendErrorMsg('TAlarmer.Execute 172: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Alarmer:=nil;
    Terminate;
  end;
end;

procedure TAlarmer.Stop;
begin
  Terminate;
  FInputQueue.SetEvent;
end;

end.
