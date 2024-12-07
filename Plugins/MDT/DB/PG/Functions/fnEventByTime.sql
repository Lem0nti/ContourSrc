CREATE OR REPLACE FUNCTION fnEventByTime(Date_Time BIGINT,AID_Camera INT,Pause INT)
RETURNS TABLE(ID_Event INT) AS
$BODY$
begin
  return QUERY SELECT ID_Event FROM Event WHERE ID_Camera=AID_Camera and abs(Event_Date-Pause)<=Pause*1000
      order by abs(Event_Date-Pause) limit 1;
end;
$BODY$ LANGUAGE 'plpgsql';
