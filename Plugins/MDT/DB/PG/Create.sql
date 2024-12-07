CREATE TABLE IF NOT EXISTS Event (ID_Event serial, PRIMARY KEY (ID_Event));

ALTER TABLE IF EXISTS Event ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;

ALTER TABLE IF EXISTS Event ADD COLUMN IF NOT EXISTS Event_Date bigint NOT NULL;


CREATE TABLE IF NOT EXISTS Path (ID_Path serial, PRIMARY KEY (ID_Path));

ALTER TABLE IF EXISTS Path ADD COLUMN IF NOT EXISTS Name character varying(256) NULL;   

ALTER TABLE IF EXISTS Path ADD COLUMN IF NOT EXISTS Distance int NOT NULL;


CREATE TABLE IF NOT EXISTS Zone (ID_Zone serial, PRIMARY KEY (ID_Zone));

ALTER TABLE IF EXISTS Zone ADD COLUMN IF NOT EXISTS ID_Event integer NOT NULL;

ALTER TABLE IF EXISTS Zone ADD COLUMN IF NOT EXISTS Square_From smallint NOT NULL;

ALTER TABLE IF EXISTS Zone ADD COLUMN IF NOT EXISTS Square_To smallint NOT NULL;

ALTER TABLE IF EXISTS Zone ADD COLUMN IF NOT EXISTS ID_Path int NOT NULL;

 
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_zone_event') THEN   
        ALTER TABLE IF EXISTS Zone ADD CONSTRAINT FK_Zone_Event FOREIGN KEY (ID_Event) REFERENCES Event (ID_Event);   
    END IF;   
END;   
$$;

DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_zone_path') THEN   
        ALTER TABLE IF EXISTS Zone ADD CONSTRAINT FK_Zone_Path FOREIGN KEY (ID_Path) REFERENCES Path (ID_Path);
    END IF;
END;
$$;

 
CREATE UNIQUE INDEX IF NOT EXISTS IX_Event_Camera ON Event (ID_Camera) INCLUDE (Event_Date);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Event_Camera_Event_Date ON Event (ID_Camera,Event_Date) INCLUDE (ID_Event);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Zone_Event ON Zone (ID_Event) INCLUDE (Square_From,Square_To);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Zone_Path ON Zone (ID_Path) INCLUDE (ID_Zone,ID_Event);


 
 
CREATE OR REPLACE FUNCTION fnEventByTime(Date_Time BIGINT,AID_Camera INT,Pause INT)
RETURNS TABLE(ID_Event INT) AS
$BODY$
begin
  return QUERY SELECT ID_Event FROM Event WHERE ID_Camera=AID_Camera and abs(Event_Date-Pause)<=Pause*1000
      order by abs(Event_Date-Pause) limit 1;
end;
$BODY$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION fnEvents(BeginDate BIGINT,EndDate BIGINT)
RETURNS TABLE(ID_Event INT,ID_Camera INT,Event_Date bigint) AS
$BODY$
begin
  return QUERY select ID_Event,ID_Camera,Event_Date,dateadd(millisecond,Event_Date%1000,dateadd(SECOND, Event_Date/1000, '1970-01-01')) as ShowDate from Event
      where Event_Date>=BeginDate and Event_Date<=EndDate;
end;
$BODY$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION fnEventsBySquare(BeginDate BIGINT,EndDate BIGINT,AID_Camera INT,ALeft INT,ATop INT,ARight INT,ABottom INT)
RETURNS TABLE(ID_Event INT,Event_Date bigint) AS
$BODY$
begin
  return QUERY SELECT DISTINCT e.ID_Event,e.Event_Date from Event e inner join Zone z on z.ID_Event=e.ID_Event
      where e.Event_Date>=BeginDate and e.Event_Date<=EndDate and e.ID_Camera=AID_Camera and ALeft<z.Square_To%100 and ARight>z.Square_From%100 and
	  ATop<z.Square_To/100 and ABottom>z.Square_From/100;
end;
$BODY$ LANGUAGE 'plpgsql';
 
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

 
CREATE OR REPLACE FUNCTION fnMapFill(SelectDay BIGINT,AID_Camera INT)
RETURNS TABLE(Second INT) AS
$BODY$
begin
  return QUERY SELECT DISTINCT (Event_Date%86400000)/1000 AS Second FROM Event WHERE Event_Date-SelectDay>=0 and Event_Date-SelectDay<86400000 and ID_Camera=AID_Camera;
end;
$BODY$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION fnSaveEvent(AID_Camera INT,AEvent_Time bigint)
RETURNS INT AS
$BODY$
DECLARE AID_Event INT;
begin
  INSERT INTO Event (ID_Camera,Event_Date) VALUES (AID_Camera,AEvent_Time) returning ID_Event into AID_Event;
  return AID_Event ;
end;
$BODY$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION fnSaveZone(AID_Event INT,ASquare_From SMALLINT,ASquare_To SMALLINT)
RETURNS INT AS
$BODY$
DECLARE AID_Zone INT;
begin
  insert into Zone (ID_Event,Square_From,Square_To) VALUES (AID_Event,ASquare_From,ASquare_To) returning ID_Zone into AID_Zone;
  return AID_Zone ;
end;
$BODY$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION fnZoneByEvent(AID_Event INT)
RETURNS TABLE(Square_From SMALLINT,Square_To SMALLINT) AS
$BODY$
begin
  return QUERY select Square_From,Square_To from Zone where ID_Event=AID_Event;
end;
$BODY$ LANGUAGE 'plpgsql';
 
 
