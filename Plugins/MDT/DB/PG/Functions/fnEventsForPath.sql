CREATE OR REPLACE FUNCTION fnEventsForPath(Date_Time BIGINT,AID_Camera INT,Pause INT)
RETURNS TABLE(ID_Event INT) AS
$BODY$
DECLARE AEvent_Date BIGINT;
begin
  select min(Event_Date) from
      (
        select e.ID_Camera,MAX(Event_Date) as Event_Date from Zone z inner join Event e on e.ID_Event=z.ID_Event where z.ID_Path>0 group by e.ID_Camera
      ) a into AEvent_Date;
  if AEvent_Date is null then
    AEvent_Date:=(extract(epoch from now())-86400*60)*1000;
  end if;
  CREATE TEMP TABLE tmpEvent AS
      select e.ID_Event,e.ID_Camera,e.Event_Date,MIN(z.ID_Zone) as ZMin from Event e inner join Zone z on z.ID_Event=e.ID_Event
	  where e.Event_Date>AEvent_Date and z.ID_Path is null group by e.ID_Event,e.ID_Camera,e.Event_Date order by e.Event_Date limit 2048;
  CREATE TEMP TABLE tmpEvent2 AS
      select e.ID_Event,e.ID_Camera,e.Event_Date,DATEDIFF(MILLISECOND,MAX(e2.Event_Date),e.Event_Date) as MDiff from tmpEvent e left join tmpEvent e2
	  on e2.ID_Camera=e.ID_Camera and e2.Event_Date<e.Event_Date group by e.ID_Event,e.ID_Camera,e.Event_Date;
  CREATE TEMP TABLE tmpEventZone AS  
      SELECT e.ID_Event,z.ID_Zone,z.ID_Zone as Zone2,z.Square_To/100 as ToY,z.Square_To%100 as PathX from tmpEvent2 e left join Zone z on z.ID_Event=e.ID_Event;
  DROP TABLE tmpEvent2;
  DROP TABLE tmpEvent;
  return QUERY select ID_Event,ID_Zone,Zone2,ToY,PathX from tmpEventZone order by ID_Event;
end;
$BODY$ LANGUAGE 'plpgsql';

