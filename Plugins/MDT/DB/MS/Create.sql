IF not exists(select * from information_schema.tables where table_name='Event')
begin
  CREATE TABLE Event
  (
    ID_Event int IDENTITY(1,1) NOT NULL
  ) ON [PRIMARY]
  ALTER TABLE Event ADD CONSTRAINT PK_Event PRIMARY KEY CLUSTERED (ID_Event) ON [PRIMARY]
end
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Event' AND column_name = 'ID_Camera')
  ALTER TABLE Event ADD ID_Camera INT NOT NULL
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Event' AND column_name = 'Event_Date')
  ALTER TABLE Event ADD Event_Date bigint not null
GO


IF NOT exists(select * from information_schema.tables where table_name='Path')
begin
  CREATE TABLE Path
  (
    ID_Path int IDENTITY(1,1) NOT NULL
  ) ON [PRIMARY]
  ALTER TABLE Path ADD CONSTRAINT PK_Path PRIMARY KEY CLUSTERED (ID_Path) ON [PRIMARY]
end
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Path' AND column_name = 'Name')
  ALTER TABLE Path ADD Name VARCHAR(256) NULL
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Path' AND column_name = 'Distance')
  ALTER TABLE Path ADD Distance INT NULL
GO


IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Zone')
BEGIN
  CREATE TABLE Zone
  (
    ID_Zone INT IDENTITY(1,1) NOT NULL
   ) ON [PRIMARY]
   ALTER TABLE Zone ADD CONSTRAINT PK_Zone PRIMARY KEY CLUSTERED (ID_Zone) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Zone' AND column_name = 'ID_Event')
  ALTER TABLE Zone ADD ID_Event INT NOT NULL
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Zone' AND column_name = 'Square_From')
  ALTER TABLE Zone ADD Square_From smallint NOT NULL
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Zone' AND column_name = 'Square_To')
  ALTER TABLE Zone ADD Square_To smallint NOT NULL
GO

IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Zone' AND column_name = 'ID_Path')
  ALTER TABLE Zone ADD ID_Path INT NULL
GO
 
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Zone_Event')
  ALTER TABLE Zone ADD CONSTRAINT FK_Zone_Event FOREIGN KEY (ID_Event) REFERENCES Event (ID_Event)
GO

IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Zone_Path')
  ALTER TABLE Zone ADD CONSTRAINT FK_Zone_Path FOREIGN KEY (ID_Path) REFERENCES Path (ID_Path)
GO
 
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Event_Camera')
  CREATE NONCLUSTERED INDEX IX_Event_Camera ON Event (ID_Camera) INCLUDE (Event_Date)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Event_Camera_Event_Date')
  CREATE NONCLUSTERED INDEX IX_Event_Camera_Event_Date ON Event (ID_Camera,Event_Date) INCLUDE (ID_Event)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Zone_Event')
  CREATE NONCLUSTERED INDEX IX_Zone_Event ON Zone (ID_Event) INCLUDE (Square_From,Square_To)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Zone_Path')
  CREATE NONCLUSTERED INDEX IX_Zone_Path ON Zone (ID_Path) INCLUDE (ID_Zone,ID_Event)
GO
 
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEventByTime') 
  EXEC('CREATE PROCEDURE spEventByTime AS')
GO

ALTER PROCEDURE spEventByTime
  @Date_Time BIGINT, @AID_Camera INT, @Pause INT
AS
  SELECT TOP 1 ID_Event FROM Event WHERE ID_Camera=@AID_Camera AND abs(@Date_Time-Event_Date) between 0 and @Pause
      order by abs(@Date_Time-Event_Date)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEvents')
  EXEC('CREATE PROCEDURE spEvents AS')
GO

ALTER PROCEDURE spEvents
  @BeginDate BIGINT,@EndDate BIGINT
AS
  SELECT ID_Event,ID_Camera,Event_Date,dateadd(millisecond,Event_Date%1000,dateadd(SECOND, Event_Date/1000, '1970-01-01')) as ShowDate from Event
      where Event_Date between @BeginDate and @EndDate
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEventsBySquare') 
  EXEC('CREATE PROCEDURE spEventsBySquare AS')
GO

ALTER PROCEDURE spEventsBySquare
  @BeginDate BIGINT,@EndDate BIGINT,@AID_Camera INT,@ALeft INT,@ATop INT,@ARight INT,@ABottom INT
AS
  SELECT DISTINCT e.ID_Event,e.Event_Date from Event e INNER join Zone z on z.ID_Event=e.ID_Event
      where e.Event_Date between @BeginDate and @EndDate and e.ID_Camera=@AID_Camera
        and @ALeft<z.Square_To%100 and @ARight>z.Square_From%100 and @ATop<z.Square_To/100 and @ABottom>z.Square_From/100
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEventsForPath') 
  EXEC('CREATE PROCEDURE spEventsForPath AS')
GO

ALTER PROCEDURE spEventsForPath
AS
  DECLARE @Event_Date BIGINT
  select @Event_Date=min(Event_Date) from
      (
        select e.ID_Camera,MAX(Event_Date) as Event_Date from Zone z inner join Event e on e.ID_Event=z.ID_Event where z.ID_Path>0 group by e.ID_Camera
      ) a
  set @Event_Date=ISNULL(@Event_Date,DATEDIFF(SECOND,{d '1970-01-01'}, GETDATE())-86400*1000*60)
  select top 2048 e.ID_Event,e.ID_Camera,e.Event_Date,MIN(z.ID_Zone) as ZMin into #tmpEvent from Event e inner join Zone z on z.ID_Event=e.ID_Event
      where e.Event_Date>@Event_Date and z.ID_Path is null group by e.ID_Event,e.ID_Camera,e.Event_Date order by e.Event_Date
  select e.ID_Event,e.ID_Camera,e.Event_Date,DATEDIFF(MILLISECOND,MAX(e2.Event_Date),e.Event_Date) as MDiff into #tmpEvent2 from #tmpEvent e
      left join #tmpEvent e2 on e2.ID_Camera=e.ID_Camera and e2.Event_Date<e.Event_Date group by e.ID_Event,e.ID_Camera,e.Event_Date
  SELECT e.ID_Event,z.ID_Zone,z.ID_Zone as Zone2,z.Square_To/100 as ToY,z.Square_To%100 as PathX into #tmpEventZone from #tmpEvent2 e
      left join Zone z on z.ID_Event=e.ID_Event
  select ID_Event,ID_Zone,Zone2,ToY,PathX from #tmpEventZone order by ID_Event
  DROP TABLE #tmpEvent2
  DROP TABLE #tmpEvent
  drop table #tmpEventZone
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spMapFill')
  EXEC('CREATE PROCEDURE spMapFill AS')
GO

ALTER PROCEDURE spMapFill
  @SelectDay BIGINT,@AID_Camera INTEGER
AS
  SELECT DISTINCT (Event_Date%86400000)/1000 AS Second FROM Event WHERE Event_Date-@SelectDay between 0 and 86400000 and ID_Camera=@AID_Camera
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spSaveEvent')
  EXEC('CREATE PROCEDURE spSaveEvent AS')
GO

ALTER PROCEDURE spSaveEvent
  @AID_Camera INT,@Event_Time BIGINT
AS
  INSERT INTO Event (ID_Camera,Event_Date) VALUES (@AID_Camera,@Event_Time)
  SELECT @@identity
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spSaveZone')
  EXEC('CREATE PROCEDURE spSaveZone AS')
GO

ALTER PROCEDURE spSaveZone
  @AID_Event INT,@ASquare_From SMALLINT,@ASquare_To SMALLINT
AS
  insert into Zone (ID_Event,Square_From,Square_To) VALUES (@AID_Event,@ASquare_From,@ASquare_To)
  SELECT @@identity
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spZoneByEvent')
  EXEC('CREATE PROCEDURE spZoneByEvent AS')
GO

ALTER PROCEDURE spZoneByEvent
  @AID_Event INT
AS
  select Square_From,Square_To from Zone where ID_Event=@AID_Event
GO
 
 
