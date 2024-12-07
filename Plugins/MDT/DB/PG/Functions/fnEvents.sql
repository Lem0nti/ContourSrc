CREATE OR REPLACE FUNCTION fnEvents(BeginDate BIGINT,EndDate BIGINT)
RETURNS TABLE(ID_Event INT,ID_Camera INT,Event_Date bigint) AS
$BODY$
begin
  return QUERY select ID_Event,ID_Camera,Event_Date,dateadd(millisecond,Event_Date%1000,dateadd(SECOND, Event_Date/1000, '1970-01-01')) as ShowDate from Event
      where Event_Date>=BeginDate and Event_Date<=EndDate;
end;
$BODY$ LANGUAGE 'plpgsql';
