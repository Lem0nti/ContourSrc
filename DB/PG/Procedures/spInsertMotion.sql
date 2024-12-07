CREATE OR REPLACE PROCEDURE spInsertMotion(AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT into Motion (ID_Camera,SBegin,SEnd) values (AID_Camera,ASBegin,ASEnd);
end;
$BODY$;
