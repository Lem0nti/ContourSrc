CREATE OR REPLACE PROCEDURE spInsertSecondaryVideo(AID_Archive INT,AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT INTO SecondaryVideo (ID_Archive,ID_Camera,SBegin,SEnd) values (AID_Archive,AID_Camera,ASBegin,ASEnd);
end;
$BODY$;
