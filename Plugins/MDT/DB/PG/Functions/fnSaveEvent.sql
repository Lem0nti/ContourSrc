CREATE OR REPLACE FUNCTION fnSaveEvent(AID_Camera INT,AEvent_Time bigint)
RETURNS INT AS
$BODY$
DECLARE AID_Event INT;
begin
  INSERT INTO Event (ID_Camera,Event_Date) VALUES (AID_Camera,AEvent_Time) returning ID_Event into AID_Event;
  return AID_Event ;
end;
$BODY$ LANGUAGE 'plpgsql';
