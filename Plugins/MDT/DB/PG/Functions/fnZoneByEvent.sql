CREATE OR REPLACE FUNCTION fnZoneByEvent(AID_Event INT)
RETURNS TABLE(Square_From SMALLINT,Square_To SMALLINT) AS
$BODY$
begin
  return QUERY select Square_From,Square_To from Zone where ID_Event=AID_Event;
end;
$BODY$ LANGUAGE 'plpgsql';
