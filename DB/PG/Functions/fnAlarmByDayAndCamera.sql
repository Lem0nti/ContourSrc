CREATE OR REPLACE FUNCTION fnAlarmByDayAndCamera(FromDT BIGINT,ToDT BIGINT,AID_Camera INTEGER)
RETURNS TABLE(AlarmIndex text) AS
$BODY$
  DECLARE tmpResult text;
    Alarm_cur record;
begin
  tmpResult:='';
  for Alarm_cur in
      SELECT CASE when SBegin<FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd,
        StartMessage from Alarm where ID_Camera=AID_Camera and SEnd>FromDT and SBegin<ToDT order by SBegin,SEnd
  LOOP
    tmpResult:=tmpResult||CAST(Alarm_cur.SBegin as varchar)||'-'||CAST(Alarm_cur.SEnd as varchar)||'='||Alarm_cur.StartMessage||E'\r\n';
  END LOOP;
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE 'plpgsql';