CREATE OR REPLACE PROCEDURE spInsertAlarm(AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT,AStartMessage character varying(512))
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT into Alarm (ID_Camera,SBegin,SEnd,StartMessage) values (AID_Camera,ASBegin,ASEnd,AStartMessage);
end;
$BODY$;
