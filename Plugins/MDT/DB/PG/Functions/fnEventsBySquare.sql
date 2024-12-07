CREATE OR REPLACE FUNCTION fnEventsBySquare(BeginDate BIGINT,EndDate BIGINT,AID_Camera INT,ALeft INT,ATop INT,ARight INT,ABottom INT)
RETURNS TABLE(ID_Event INT,Event_Date bigint) AS
$BODY$
begin
  return QUERY SELECT DISTINCT e.ID_Event,e.Event_Date from Event e inner join Zone z on z.ID_Event=e.ID_Event
      where e.Event_Date>=BeginDate and e.Event_Date<=EndDate and e.ID_Camera=AID_Camera and ALeft<z.Square_To%100 and ARight>z.Square_From%100 and
	  ATop<z.Square_To/100 and ABottom>z.Square_From/100;
end;
$BODY$ LANGUAGE 'plpgsql';
