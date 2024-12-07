unit mdtCutDatabase_TH;

interface

uses
  Classes, SysUtils, ABL.IO.IOTypes, ABL.Core.TimerThread, mdtData_DM, ABL.Core.Debug, DateUtils;

type
  TCutDatabase=class(TTimerThread)
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    Constructor Create; reintroduce;
  end;

var
  CutDatabase: TCutDatabase;

implementation

{ TCutVideo }

constructor TCutDatabase.Create;
begin
  inherited Create(nil,nil,'TCutVideo');
  FInterval:=180000;  //3 минуты
  Enabled:=true;
  Active:=true;
end;

procedure TCutDatabase.DoExecute;
var
  NTime: int64;
  tmpLTimeStamp: TTimeStamp;
  ID_Event: integer;
begin
  //60 дней назад
  tmpLTimeStamp := DateTimeToTimeStamp(now-60);
  NTime:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
  //берём 1000 событий младше даты
  if DataDM.DBType='PG' then
    ID_Event:=DataDM.SelectInteger('select max(ID_Event) from (select ID_Event from Event where Event_Date<'+IntToStr(NTime)+' order by ID_Event limit 1000) a')
  else
    ID_Event:=DataDM.SelectInteger('select max(ID_Event) from (select top 1000 ID_Event from Event where Event_Date<'+IntToStr(NTime)+' order by ID_Event) a');
  if ID_Event>0 then
  begin
    //удаляем пути
    DataDM.ExecSQL('delete from Path where ID_Path in (select ID_Path from Zone where ID_Event<='+IntToStr(ID_Event)+')');
    //удаляем зоны для этих событий
    DataDM.ExecSQL('delete from Zone where ID_Event<='+IntToStr(ID_Event));
    //удаляем события
    DataDM.ExecSQL('delete from Event where ID_Event<='+IntToStr(ID_Event));
    SendDebugMsg('TCutDatabase.DoExecute 54: deleted till '+DateTimeToStr(IncMilliSecond(UnixDateDelta,NTime)));
  end;
end;

procedure TCutDatabase.DoReceive(var AInputData: Pointer);
begin

end;

end.
