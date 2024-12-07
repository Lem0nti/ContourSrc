CREATE TABLE IF NOT EXISTS Alarm (ID_Alarm serial, PRIMARY KEY (ID_Alarm)); 
ALTER TABLE IF EXISTS Alarm ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Alarm ADD COLUMN IF NOT EXISTS SBegin bigint NOT NULL;   
ALTER TABLE IF EXISTS Alarm ADD COLUMN IF NOT EXISTS SEnd bigint NOT NULL;   
ALTER TABLE IF EXISTS Alarm ADD COLUMN IF NOT EXISTS StartMessage character varying(512) NULL;   
CREATE TABLE IF NOT EXISTS Archive (ID_Archive serial, PRIMARY KEY (ID_Archive));   
ALTER TABLE IF EXISTS Archive ADD COLUMN IF NOT EXISTS Path character varying(512) NOT NULL;   
ALTER TABLE IF EXISTS Archive ADD COLUMN IF NOT EXISTS Active boolean NOT NULL DEFAULT True;   
CREATE TABLE IF NOT EXISTS Camera (ID_Camera serial, PRIMARY KEY (ID_Camera));   
ALTER TABLE IF EXISTS Camera ADD COLUMN IF NOT EXISTS ConnectionString character varying(512) NOT NULL;   
ALTER TABLE IF EXISTS Camera ADD COLUMN IF NOT EXISTS Secondary character varying(512) NULL;   
ALTER TABLE IF EXISTS Camera ADD COLUMN IF NOT EXISTS Name character varying(128) NULL;   
ALTER TABLE IF EXISTS Camera ADD COLUMN IF NOT EXISTS Active boolean NOT NULL DEFAULT True;   
ALTER TABLE IF EXISTS Camera ADD COLUMN IF NOT EXISTS Schedule_Type integer NOT NULL DEFAULT 0;   
ALTER TABLE IF EXISTS Camera ADD COLUMN IF NOT EXISTS Deleted boolean NOT NULL DEFAULT False;   
CREATE TABLE IF NOT EXISTS Config (ID_Config serial, PRIMARY KEY (ID_Config));   
ALTER TABLE IF EXISTS Config ADD COLUMN IF NOT EXISTS Category character varying(50) NULL;   
ALTER TABLE IF EXISTS Config ADD COLUMN IF NOT EXISTS Name character varying(50) NULL;   
ALTER TABLE IF EXISTS Config ADD COLUMN IF NOT EXISTS Data character varying(8000) NULL;   
CREATE TABLE IF NOT EXISTS Fill (ID_Fill serial, PRIMARY KEY (ID_Fill));   
ALTER TABLE IF EXISTS Fill ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Fill ADD COLUMN IF NOT EXISTS ID_Archive integer NOT NULL;   
ALTER TABLE IF EXISTS Fill ADD COLUMN IF NOT EXISTS SBegin bigint NOT NULL;   
ALTER TABLE IF EXISTS Fill ADD COLUMN IF NOT EXISTS SEnd bigint NOT NULL;   
CREATE TABLE IF NOT EXISTS Log (ID_Log serial, PRIMARY KEY (ID_Log));   
ALTER TABLE IF EXISTS Log ADD COLUMN IF NOT EXISTS Type integer NOT NULL;   
ALTER TABLE IF EXISTS Log ADD COLUMN IF NOT EXISTS Source_Type integer NOT NULL;   
ALTER TABLE IF EXISTS Log ADD COLUMN IF NOT EXISTS ID_Source integer NOT NULL;   
ALTER TABLE IF EXISTS Log ADD COLUMN IF NOT EXISTS STime bigint NOT NULL;   
ALTER TABLE IF EXISTS Log ADD COLUMN IF NOT EXISTS Message character varying(512) NOT NULL;   
CREATE TABLE IF NOT EXISTS Motion (ID_Motion serial, PRIMARY KEY (ID_Motion));   
ALTER TABLE IF EXISTS Motion ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Motion ADD COLUMN IF NOT EXISTS SBegin bigint NOT NULL;   
ALTER TABLE IF EXISTS Motion ADD COLUMN IF NOT EXISTS SEnd bigint NOT NULL;   
CREATE TABLE IF NOT EXISTS Plugin (ID_Plugin serial, PRIMARY KEY (ID_Plugin));   
ALTER TABLE IF EXISTS Plugin ADD COLUMN IF NOT EXISTS Name character varying(128) NOT NULL;   
ALTER TABLE IF EXISTS Plugin ADD COLUMN IF NOT EXISTS FileName character varying(128) NOT NULL;   
ALTER TABLE IF EXISTS Plugin ADD COLUMN IF NOT EXISTS PictureType integer NOT NULL DEFAULT 0;   
CREATE TABLE IF NOT EXISTS Plugin_Camera (ID_Plugin_Camera serial, PRIMARY KEY (ID_Plugin_Camera));   
ALTER TABLE IF EXISTS Plugin_Camera ADD COLUMN IF NOT EXISTS ID_Plugin integer NOT NULL;   
ALTER TABLE IF EXISTS Plugin_Camera ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Plugin_Camera ADD COLUMN IF NOT EXISTS APrimary boolean NOT NULL DEFAULT False;   
CREATE TABLE IF NOT EXISTS Plugin_Param (ID_Plugin_Param serial, PRIMARY KEY (ID_Plugin_Param));   
ALTER TABLE IF EXISTS Plugin_Param ADD COLUMN IF NOT EXISTS ID_Plugin_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Plugin_Param ADD COLUMN IF NOT EXISTS Param character varying(64) NOT NULL;   
ALTER TABLE IF EXISTS Plugin_Param ADD COLUMN IF NOT EXISTS Value character varying(64) NOT NULL;   
CREATE TABLE IF NOT EXISTS Schedule (ID_Schedule serial, PRIMARY KEY (ID_Schedule));   
ALTER TABLE IF EXISTS Schedule ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Schedule ADD COLUMN IF NOT EXISTS Day integer NOT NULL;   
ALTER TABLE IF EXISTS Schedule ADD COLUMN IF NOT EXISTS SBegin integer NOT NULL;   
ALTER TABLE IF EXISTS Schedule ADD COLUMN IF NOT EXISTS SEnd integer NOT NULL;   
CREATE TABLE IF NOT EXISTS SecondaryVideo (ID_SecondaryVideo serial, PRIMARY KEY (ID_SecondaryVideo));   
ALTER TABLE IF EXISTS SecondaryVideo ADD COLUMN IF NOT EXISTS ID_Archive integer NOT NULL;   
ALTER TABLE IF EXISTS SecondaryVideo ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS SecondaryVideo ADD COLUMN IF NOT EXISTS SBegin bigint NOT NULL;   
ALTER TABLE IF EXISTS SecondaryVideo ADD COLUMN IF NOT EXISTS SEnd bigint NOT NULL;   
CREATE TABLE IF NOT EXISTS Video (ID_Video serial, PRIMARY KEY (ID_Video));   
ALTER TABLE IF EXISTS Video ADD COLUMN IF NOT EXISTS ID_Archive integer NOT NULL;   
ALTER TABLE IF EXISTS Video ADD COLUMN IF NOT EXISTS ID_Camera integer NOT NULL;   
ALTER TABLE IF EXISTS Video ADD COLUMN IF NOT EXISTS SBegin bigint NOT NULL;   
ALTER TABLE IF EXISTS Video ADD COLUMN IF NOT EXISTS SEnd bigint NOT NULL;   
 
DO $$ 
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_alarm_camera') THEN   
        ALTER TABLE IF EXISTS Alarm ADD CONSTRAINT FK_Alarm_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_fill_archive') THEN   
        ALTER TABLE IF EXISTS Fill ADD CONSTRAINT FK_Fill_Archive FOREIGN KEY (ID_Archive) REFERENCES Archive (ID_Archive);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_fill_camera') THEN   
        ALTER TABLE IF EXISTS Fill ADD CONSTRAINT FK_Fill_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_motion_camera') THEN   
        ALTER TABLE IF EXISTS Motion ADD CONSTRAINT FK_Motion_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_plugin_camera_camera') THEN   
        ALTER TABLE IF EXISTS Plugin_Camera ADD CONSTRAINT FK_Plugin_Camera_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_plugin_camera_plugin') THEN   
        ALTER TABLE IF EXISTS Plugin_Camera ADD CONSTRAINT FK_Plugin_Camera_Plugin FOREIGN KEY (ID_Plugin) REFERENCES Plugin (ID_Plugin);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_plugin_param_plugin_camera') THEN   
        ALTER TABLE IF EXISTS Plugin_Param ADD CONSTRAINT FK_Plugin_Param_Plugin_Camera FOREIGN KEY (ID_Plugin_Camera) REFERENCES Plugin_Camera (ID_Plugin_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_schedule_camera') THEN   
        ALTER TABLE IF EXISTS Schedule ADD CONSTRAINT FK_Schedule_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_secondaryvideo_archive') THEN   
        ALTER TABLE IF EXISTS SecondaryVideo ADD CONSTRAINT FK_SecondaryVideo_Archive FOREIGN KEY (ID_Archive) REFERENCES Archive (ID_Archive);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_secondaryvideo_camera') THEN   
        ALTER TABLE IF EXISTS SecondaryVideo ADD CONSTRAINT FK_SecondaryVideo_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_video_archive') THEN   
        ALTER TABLE IF EXISTS Video ADD CONSTRAINT FK_Video_Archive FOREIGN KEY (ID_Archive) REFERENCES Archive (ID_Archive);   
    END IF;   
END;   
$$;   
DO $$   
BEGIN   
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_video_camera') THEN   
        ALTER TABLE IF EXISTS Video ADD CONSTRAINT FK_Video_Camera FOREIGN KEY (ID_Camera) REFERENCES Camera (ID_Camera);   
    END IF;   
END;   
$$;   
 
CREATE UNIQUE INDEX IF NOT EXISTS IX_Config ON Config (Category,Name); 
CREATE INDEX IF NOT EXISTS IX_Video_ID_Camera_SEnd ON Video (ID_Camera,SEnd) INCLUDE (ID_Archive,SBegin);   
CREATE UNIQUE INDEX IF NOT EXISTS IX_Plugin_Camera ON Plugin_Camera (ID_Plugin,ID_Camera);   
 
INSERT INTO Config (Category, Name, Data) VALUES ('Main', 'TCP', 2110) ON CONFLICT DO NOTHING; 
drop procedure if exists spAlarmByDayAndCamera;   
drop procedure if exists spDeleteCamera;   
drop procedure if exists spDropArch;   
drop procedure if exists spGetFragment;   
drop procedure if exists spIndexByDayAndCamera;   
drop procedure if exists spInsertAlarm;   
drop procedure if exists spInsertLog;   
drop procedure if exists spInsertMotion;   
drop procedure if exists spInsertSecondaryVideo;   
drop procedure if exists spInsertVideo;   
drop procedure if exists spMotionByDayAndCamera;   
drop procedure if exists spUpdateVersion;   
 
CREATE OR REPLACE FUNCTION fnAlarmByDayAndCamera(FromDT BIGINT,ToDT BIGINT,AID_Camera INTEGER)
RETURNS TABLE(AlarmIndex text) AS
$BODY$
  DECLARE tmpResult text;
    Alarm_cur record;
begin
  tmpResult:='';
  for Alarm_cur in
      SELECT CASE when SBegin<FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd,
        StartMessage from Alarm where ID_Camera=AID_Camera and SEnd>FromDT and SBegin<ToDT order by SBegin,SEnd
  LOOP
    tmpResult:=tmpResult||CAST(Alarm_cur.SBegin as varchar)||'-'||CAST(Alarm_cur.SEnd as varchar)||'='||Alarm_cur.StartMessage||E'\r\n';
  END LOOP;
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE 'plpgsql'; 
CREATE OR REPLACE FUNCTION fnCamerasList()
RETURNS TABLE(CamerasList character varying(4000)) AS
$BODY$
  declare
    cr record;
    tmpResult character varying(4000);
begin
  tmpResult:='';  
  for cr in select c.ID_Camera,c.Name,max(f.SEnd) as SEnd from Camera c left join Fill f on f.ID_Camera=c.ID_Camera where c.Deleted=false and c.Active=true
      group by c.ID_Camera,c.Name order by c.ID_Camera 
  loop 
    tmpResult:=tmpResult || cast(cr.ID_Camera as varchar)||'='||cr.Name||';'||cr.SEnd||E'\r\n';
  end loop;
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE plpgsql; 
CREATE OR REPLACE FUNCTION fnDaysList()
RETURNS TABLE(DaysList character varying(4000)) AS
$BODY$
  declare
    f record;
    tmpResult character varying(4000);
begin
  tmpResult:='';  
  for f in select distinct TO_CHAR(TO_TIMESTAMP(SEnd / 1000), 'YYMMDD') as dt from Fill order by dt
  loop 
    tmpResult:=tmpResult||f.dt||E'\r\n';
  end loop;
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE plpgsql; 
CREATE OR REPLACE FUNCTION fnGetFragment(DayPoint BIGINT,AID_Camera INT,ANext boolean,APrimary boolean)
RETURNS TABLE(filename text) AS
$BODY$
  DECLARE ADay character varying(6); qry character varying(512);
begin
  ADay:=TO_CHAR(TO_TIMESTAMP(DayPoint/1000), 'YYMMDD');
  qry:=
      'SELECT ' || 'a.Path||''\' || ADay || '\' || CAST(AID_Camera as varchar) ||
      case APrimary when false then '_2' else '' end || '\''||cast(v.SBegin as varchar)||''_''||cast(v.SEnd as varchar)||''.h264'' from ' ||
      case APrimary when false then 'Secondary' else '' end || 'Video v inner join Archive a on a.ID_Archive=v.ID_Archive where v.ID_Camera=' ||
      cast(AID_Camera as varchar) || ' and ';
  if ANext=false then
    qry:=qry || 'v.SEnd<' || cast(DayPoint as varchar) || ' order by v.SEnd desc limit 1';
  elseif ANext=true then
    qry:=qry || 'v.SBegin>'||cast(DayPoint as varchar)||' order by v.SEnd limit 1';
  else
    qry:=qry || DayPoint||' between v.SBegin and v.SEnd';
  end if;
  RETURN QUERY execute qry;
end;
$BODY$ LANGUAGE plpgsql; 
CREATE OR REPLACE FUNCTION fnIndexByDayAndCamera(FromDT BIGINT,ToDT BIGINT,AID_Camera INTEGER)
RETURNS TABLE(CameraIndex text) AS
$BODY$
  DECLARE OldBegin INT; OldEnd INT; tmpResult text;
    Fill_cur record;
begin
  OldBegin:=0;
  OldEnd:=0;
  tmpResult:='';
  for Fill_cur in
      SELECT CASE when SBegin<FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd
        from Fill where ID_Camera=AID_Camera and SEnd>FromDT and SBegin<ToDT order by SBegin,SEnd
  LOOP
    --если предыдущий конец и текущее начало различаются меньше больше чем на 5 секунд, то сохранить
    if OldEnd>0 and Fill_cur.SBegin-OldEnd>5 then
      tmpResult:=tmpResult||CAST(OldBegin as varchar)||'-'||CAST(OldEnd as varchar)||E'\r\n';
      OldBegin:=0;
    end if;
    if OldBegin=0 then
      OldBegin:=Fill_cur.SBegin;
	end if;
    OldEnd:=Fill_cur.SEnd;
  END LOOP;
  tmpResult:=tmpResult||CAST(OldBegin as varchar)||'-'||CAST(OldEnd as varchar)||E'\r\n';
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE 'plpgsql'; 
CREATE OR REPLACE FUNCTION fnMotionByDayAndCamera(FromDT BIGINT,ToDT BIGINT,AID_Camera INTEGER)
RETURNS TABLE(MotionIndex text) AS
$BODY$
  DECLARE OldBegin INT; OldEnd INT; tmpResult text;
    Motion_cur record;
begin
  OldBegin:=0;
  OldEnd:=0;
  tmpResult:='';
  for Motion_cur in
      SELECT CASE when SBegin<FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd
        from Motion where ID_Camera=AID_Camera and SEnd>FromDT and SBegin<ToDT order by SBegin,SEnd
  LOOP
    --если предыдущий конец и текущее начало различаются меньше больше чем на 5 секунд, то сохранить
    if OldEnd>0 and Motion_cur.SBegin-OldEnd>5 then
      tmpResult:=tmpResult||CAST(OldBegin as varchar)||'-'||CAST(OldEnd as varchar)||E'\r\n';
      OldBegin:=0;
    end if;
    if OldBegin=0 then
      OldBegin:=Motion_cur.SBegin;
    end if;
    OldEnd:=Motion_cur.SEnd;
  END LOOP;
  tmpResult:=tmpResult||CAST(OldBegin as varchar)||'-'||CAST(OldEnd as varchar)||E'\r\n';
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE 'plpgsql'; 
CREATE OR REPLACE PROCEDURE spCameraPlugin(AID_Camera INT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  SELECT pc.ID_Plugin,p.Name from Plugin_Camera pc inner join Plugin p on p.ID_Plugin=pc.ID_Plugin where pc.ID_Camera=AID_Camera;
end;
$BODY$; 
CREATE OR REPLACE PROCEDURE spDeleteCamera(AID_Camera INTEGER)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  IF exists(select * from Video where ID_Camera=AID_Camera limit 1) then
    update Camera set Deleted=1 where ID_Camera=AID_Camera;
  ELSE
    delete from Alarm where ID_Camera=AID_Camera;
    delete from Fill where ID_Camera=AID_Camera;
    delete from Motion where ID_Camera=AID_Camera;
    delete from Schedule where ID_Camera=AID_Camera;
    delete from Slide where ID_Camera=AID_Camera;
    DELETE from Camera where ID_Camera=AID_Camera;
  end if;
end;
$BODY$; 
CREATE OR REPLACE PROCEDURE spDropArch(TimeBefore BIGINT, AID_Archive INTEGER)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  DELETE FROM Alarm where SEnd<TimeBefore;
  delete from Fill where ID_Archive=AID_Archive and SEnd<TimeBefore;
  update Fill set SBegin=TimeBefore where ID_Archive=AID_Archive and SBegin<TimeBefore;
  delete from Motion where SEnd<TimeBefore;
  delete from Video where ID_Archive=AID_Archive and SEnd<TimeBefore;
  delete from SecondaryVideo where ID_Archive=AID_Archive and SEnd<TimeBefore;
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spInsertAlarm(AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT,AStartMessage character varying(512))
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT into Alarm (ID_Camera,SBegin,SEnd,StartMessage) values (AID_Camera,ASBegin,ASEnd,AStartMessage);
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spInsertLog(AType INT,ASource_Type INT,AID_Source INT,ASTime BIGINT,AMessage character varying(512))
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT into Log (Type,Source_Type,ID_Source,STime,Message) values (AType,ASource_Type,AID_Source,ASTime,AMessage);
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spInsertMotion(AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT into Motion (ID_Camera,SBegin,SEnd) values (AID_Camera,ASBegin,ASEnd);
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spInsertSecondaryVideo(AID_Archive INT,AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT INTO SecondaryVideo (ID_Archive,ID_Camera,SBegin,SEnd) values (AID_Archive,AID_Camera,ASBegin,ASEnd);
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spInsertVideo(AID_Archive INT,AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT)
LANGUAGE 'plpgsql'
AS $BODY$
  DECLARE Fill_cur record; AID_Fill int;
begin
  INSERT INTO Video (ID_Archive,ID_Camera,SBegin,SEnd) VALUES (AID_Archive,AID_Camera,ASBegin,ASEnd);
  AID_Fill:=0;
  FOR Fill_cur in select ID_Fill from Fill where ID_Camera=AID_Camera and SEnd>=ASBegin-1000 order by SEnd desc limit 1
  loop
    AID_Fill:=Fill_cur.ID_Fill;
  end loop;
  if AID_Fill>0 then
    update Fill set SEnd=ASEnd where ID_Fill=AID_Fill;
  else
    insert into Fill (ID_Camera,SBegin,SEnd,ID_Archive) values (AID_Camera,ASBegin,ASEnd,AID_Archive);
  end if;
end;
$BODY$; 
CREATE OR REPLACE PROCEDURE spPluginCamera(AID_Plugin INT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  CREATE TEMP TABLE tmpPluginCamera AS
      SELECT DISTINCT c.ID_Camera,CAST(CASE WHEN LEN(c.Name)>0 THEN c.Name ELSE '' END AS VARCHAR(128)) AS Name,c.ConnectionString,c.Secondary,
      CAST(ISNULL(pc.APrimary,0) AS BIT) AS APrimary,CASE WHEN pc.ID_Plugin IS NULL THEN false ELSE true END AS Checked FROM Camera c
      LEFT JOIN Plugin_Camera pc ON c.ID_Camera=pc.ID_Camera AND pc.ID_Plugin=AID_Plugin WHERE c.Active=true;
  SELECT ID_Camera,Name,ConnectionString,Secondary,APrimary,Checked from tmpPluginCamera;
end;
$BODY$; 
CREATE OR REPLACE PROCEDURE spPluginParam(AID_Plugin_Camera INT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  SELECT ID_Plugin_Param, Param, Value FROM Plugin_Param WHERE ID_Plugin_Camera = AID_Plugin_Camera;
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spUpdatePluginCamera(AID_Camera INT,AID_Plugin INT,AConnect BIT)
LANGUAGE 'plpgsql'
AS $BODY$
  DECLARE Fill_cur record; AID_Plugin_Camera int;
begin
  if AConnect=0 then
    AID_Plugin_Camera:=0;
    FOR Fill_cur in SELECT ID_Plugin_Camera FROM Plugin_Camera WHERE ID_Camera=AID_Camera and ID_Plugin=AID_Plugin
    loop
      AID_Plugin_Camera:=Fill_cur.ID_Plugin_Camera;
    end loop;
    IF AID_Plugin_Camera>0 then
      delete from Plugin_Param where ID_Plugin_Camera=AID_Plugin_Camera;
      delete from Plugin_Camera where ID_Plugin_Camera=AID_Plugin_Camera;
    end if;
  else 
    if not exists(select * from Plugin_Camera where ID_Camera=AID_Camera and ID_Plugin=AID_Plugin) then
      insert into Plugin_Camera (ID_Camera,ID_Plugin,APrimary) values(AID_Camera,AID_Plugin,false);
    end if;
  end if;
end;
$BODY$;
 
CREATE OR REPLACE PROCEDURE spUpdateVersion(AVersion character varying(8))
LANGUAGE 'plpgsql'
AS $BODY$
begin
  IF EXISTS(SELECT * FROM Config WHERE Category='Main' AND Name='Version') then
    UPDATE Config SET Data=AVersion WHERE Category='Main' AND Name='Version' and cast(AVersion as int)>cast(Data as int);
  else
    insert into Config (Category,Name,Data) values ('Main','Version',AVersion);
  end if;
end;
$BODY$;
 
-- Обновление версии базы
CALL spUpdateVersion('20400');
 
