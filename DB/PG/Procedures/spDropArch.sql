CREATE OR REPLACE PROCEDURE spDropArch(TimeBefore BIGINT, AID_Archive INTEGER)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  DELETE FROM Alarm where SEnd<TimeBefore;
  delete from Fill where ID_Archive=AID_Archive and SEnd<TimeBefore;
  update Fill set SBegin=TimeBefore where ID_Archive=AID_Archive and SBegin<TimeBefore;
  delete from Motion where SEnd<TimeBefore;
  delete from Video where ID_Archive=AID_Archive and SEnd<TimeBefore;
  delete from SecondaryVideo where ID_Archive=AID_Archive and SEnd<TimeBefore;
end;
$BODY$;
