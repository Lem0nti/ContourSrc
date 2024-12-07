CREATE OR REPLACE FUNCTION fnMapFill(SelectDay BIGINT,AID_Camera INT)
RETURNS TABLE(Second INT) AS
$BODY$
begin
  return QUERY SELECT DISTINCT (Event_Date%86400000)/1000 AS Second FROM Event WHERE Event_Date-SelectDay>=0 and Event_Date-SelectDay<86400000 and ID_Camera=AID_Camera;
end;
$BODY$ LANGUAGE 'plpgsql';
