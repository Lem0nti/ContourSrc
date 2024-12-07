IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Alarm') 
BEGIN   
  CREATE TABLE Alarm   
  (   
    ID_Alarm int IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Alarm ADD CONSTRAINT PK_Alarm PRIMARY KEY CLUSTERED (ID_Alarm) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Alarm' AND column_name = 'ID_Camera')   
  ALTER TABLE Alarm ADD ID_Camera INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Alarm' AND column_name = 'SBegin')   
  ALTER TABLE Alarm ADD SBegin BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Alarm' AND column_name = 'SEnd')   
  ALTER TABLE Alarm ADD SEnd BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Alarm' AND column_name = 'StartMessage')   
  ALTER TABLE Alarm ADD StartMessage VARCHAR(512) NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Archive')   
BEGIN   
  CREATE TABLE Archive   
  (   
    ID_Archive int IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Archive ADD CONSTRAINT PK_Archive PRIMARY KEY CLUSTERED (ID_Archive) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Archive' AND column_name = 'Path')   
  ALTER TABLE Archive ADD Path varchar(512) NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Archive' AND column_name = 'Active')   
  ALTER TABLE Archive ADD Active bit NOT NULL default 1   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Camera')   
BEGIN   
  CREATE TABLE Camera   
  (   
    ID_Camera int IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Camera ADD CONSTRAINT PK_Camera PRIMARY KEY CLUSTERED (ID_Camera) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Camera' AND column_name = 'ConnectionString')   
  ALTER TABLE Camera ADD ConnectionString varchar(512) NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Camera' AND column_name = 'Secondary')   
  ALTER TABLE Camera ADD Secondary varchar(512) NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Camera' AND column_name = 'Name')   
  ALTER TABLE Camera ADD Name varchar(128) NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Camera' AND column_name = 'Active')   
  ALTER TABLE Camera ADD Active bit NOT NULL default 1   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Camera' AND column_name = 'Schedule_Type')   
  ALTER TABLE Camera ADD Schedule_Type int NOT NULL default 0   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Camera' AND column_name = 'Deleted')   
  ALTER TABLE Camera ADD Deleted bit NOT NULL default 0   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Config')   
BEGIN   
  CREATE TABLE Config   
  (   
    ID_Config INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Config ADD CONSTRAINT PK_Config PRIMARY KEY CLUSTERED (ID_Config) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Config' AND column_name = 'Category')   
  ALTER TABLE Config ADD Category varchar(50) NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Config' AND column_name = 'Name')   
  ALTER TABLE Config ADD Name varchar(50) NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Config' AND column_name = 'Data')   
  ALTER TABLE Config ADD Data varchar(max) NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Fill')   
BEGIN   
  CREATE TABLE Fill   
  (   
    ID_Fill INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Fill ADD CONSTRAINT PK_Fill PRIMARY KEY CLUSTERED (ID_Fill) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Fill' AND column_name = 'ID_Camera')   
  ALTER TABLE Fill ADD ID_Camera INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Fill' AND column_name = 'ID_Archive')   
  ALTER TABLE Fill ADD ID_Archive INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Fill' AND column_name = 'SBegin')   
  ALTER TABLE Fill ADD SBegin BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Fill' AND column_name = 'SEnd')   
  ALTER TABLE Fill ADD SEnd BIGINT NOT NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Log')   
BEGIN   
  CREATE TABLE Log   
  (   
    ID_Log INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Log ADD CONSTRAINT PK_Log PRIMARY KEY CLUSTERED (ID_Log) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Log' AND column_name = 'Type')   
  ALTER TABLE Log ADD Type INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Log' AND column_name = 'Source_Type')   
  ALTER TABLE Log ADD Source_Type INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Log' AND column_name = 'ID_Source')   
  ALTER TABLE Log ADD ID_Source INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Log' AND column_name = 'STime')   
  ALTER TABLE Log ADD STime BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Log' AND column_name = 'Message')   
  ALTER TABLE Log ADD Message VARCHAR(512) NOT NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Motion')   
BEGIN   
  CREATE TABLE Motion   
  (   
    ID_Motion INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Motion ADD CONSTRAINT PK_Motion PRIMARY KEY CLUSTERED (ID_Motion) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Motion' AND column_name = 'ID_Camera')   
  ALTER TABLE Motion ADD ID_Camera INT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Motion' AND column_name = 'SBegin')   
  ALTER TABLE Motion ADD SBegin BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Motion' AND column_name = 'SEnd')   
  ALTER TABLE Motion ADD SEnd BIGINT NOT NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Plugin')   
BEGIN   
  CREATE TABLE Plugin   
  (   
    ID_Plugin INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Plugin ADD CONSTRAINT PK_Plugin PRIMARY KEY CLUSTERED (ID_Plugin) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin' AND column_name = 'Name')   
  ALTER TABLE Plugin ADD Name VARCHAR(128) NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin' AND column_name = 'FileName')   
  ALTER TABLE Plugin ADD FileName VARCHAR(128) NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin' AND column_name = 'PictureType')   
  ALTER TABLE Plugin ADD PictureType INTEGER NOT NULL default 0   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Plugin_Camera')   
BEGIN   
  CREATE TABLE Plugin_Camera   
  (   
    ID_Plugin_Camera INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Plugin_Camera ADD CONSTRAINT PK_Plugin_Camera PRIMARY KEY CLUSTERED (ID_Plugin_Camera) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin_Camera' AND column_name = 'ID_Plugin')   
  ALTER TABLE Plugin_Camera ADD ID_Plugin INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin_Camera' AND column_name = 'ID_Camera')   
  ALTER TABLE Plugin_Camera ADD ID_Camera INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin_Camera' AND column_name = 'APrimary')   
  ALTER TABLE Plugin_Camera ADD APrimary bit NOT NULL default 0   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Plugin_Param')   
BEGIN   
  CREATE TABLE Plugin_Param   
  (   
    ID_Plugin_Param INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Plugin_Param ADD CONSTRAINT PK_Plugin_Param PRIMARY KEY CLUSTERED (ID_Plugin_Param) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin_Param' AND column_name = 'ID_Plugin_Camera')   
  ALTER TABLE Plugin_Param ADD ID_Plugin_Camera INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin_Param' AND column_name = 'Param')   
  ALTER TABLE Plugin_Param ADD Param VARCHAR(64) NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Plugin_Param' AND column_name = 'Value')   
  ALTER TABLE Plugin_Param ADD Value VARCHAR(64) NOT NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Schedule')   
BEGIN   
  CREATE TABLE Schedule   
  (   
    ID_Schedule INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Schedule ADD CONSTRAINT PK_Schedule PRIMARY KEY CLUSTERED (ID_Schedule) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Schedule' AND column_name = 'ID_Camera')   
  ALTER TABLE Schedule ADD ID_Camera INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Schedule' AND column_name = 'Day')   
  ALTER TABLE Schedule ADD Day INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Schedule' AND column_name = 'SBegin')   
  ALTER TABLE Schedule ADD SBegin INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Schedule' AND column_name = 'SEnd')   
  ALTER TABLE Schedule ADD SEnd INTEGER NOT NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='SecondaryVideo')   
BEGIN   
  CREATE TABLE SecondaryVideo   
  (   
    ID_SecondaryVideo INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE SecondaryVideo ADD CONSTRAINT PK_SecondaryVideo PRIMARY KEY CLUSTERED (ID_SecondaryVideo) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'SecondaryVideo' AND column_name = 'ID_Archive')   
  ALTER TABLE SecondaryVideo ADD ID_Archive INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'SecondaryVideo' AND column_name = 'ID_Camera')   
  ALTER TABLE SecondaryVideo ADD ID_Camera INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'SecondaryVideo' AND column_name = 'SBegin')   
  ALTER TABLE SecondaryVideo ADD SBegin BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'SecondaryVideo' AND column_name = 'SEnd')   
  ALTER TABLE SecondaryVideo ADD SEnd BIGINT NOT NULL   
GO   
IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name='Video')   
BEGIN   
  CREATE TABLE Video   
  (   
    ID_Video INT IDENTITY(1,1) NOT NULL   
  ) ON [PRIMARY]   
  ALTER TABLE Video ADD CONSTRAINT PK_Video PRIMARY KEY CLUSTERED (ID_Video) ON [PRIMARY]   
END   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Video' AND column_name = 'ID_Archive')   
  ALTER TABLE Video ADD ID_Archive INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Video' AND column_name = 'ID_Camera')   
  ALTER TABLE Video ADD ID_Camera INTEGER NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Video' AND column_name = 'SBegin')   
  ALTER TABLE Video ADD SBegin BIGINT NOT NULL   
GO   
IF NOT EXISTS (SELECT column_name FROM information_schema.columns WHERE table_name = 'Video' AND column_name = 'SEnd')   
  ALTER TABLE Video ADD SEnd BIGINT NOT NULL   
GO   
 
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Alarm_Camera') 
  ALTER TABLE Alarm WITH CHECK ADD CONSTRAINT FK_Alarm_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Fill_Archive')   
  ALTER TABLE Fill WITH CHECK ADD CONSTRAINT FK_Fill_Archive FOREIGN KEY(ID_Archive) REFERENCES Archive (ID_Archive)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Fill_Camera')   
  ALTER TABLE Fill WITH CHECK ADD CONSTRAINT FK_Fill_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Motion_Camera')   
  ALTER TABLE Motion WITH CHECK ADD CONSTRAINT FK_Motion_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Plugin_Camera_Camera')   
  ALTER TABLE Plugin_Camera WITH CHECK ADD CONSTRAINT FK_Plugin_Camera_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Plugin_Camera_Plugin')   
  ALTER TABLE Plugin_Camera WITH CHECK ADD CONSTRAINT FK_Plugin_Camera_Plugin FOREIGN KEY(ID_Plugin) REFERENCES Plugin (ID_Plugin)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Plugin_Param_Plugin_Camera')   
  ALTER TABLE Plugin_Param WITH CHECK ADD CONSTRAINT FK_Plugin_Param_Plugin_Camera FOREIGN KEY(ID_Plugin_Camera) REFERENCES Plugin_Camera (ID_Plugin_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Schedule_Camera')   
  ALTER TABLE Schedule WITH CHECK ADD CONSTRAINT FK_Schedule_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_SecondaryVideo_Camera')   
  ALTER TABLE SecondaryVideo WITH CHECK ADD CONSTRAINT FK_SecondaryVideo_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Video_Archive')   
  ALTER TABLE Video WITH CHECK ADD CONSTRAINT FK_Video_Archive FOREIGN KEY(ID_Archive) REFERENCES Archive (ID_Archive)   
GO   
IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Video_Camera')   
  ALTER TABLE Video WITH CHECK ADD CONSTRAINT FK_Video_Camera FOREIGN KEY(ID_Camera) REFERENCES Camera (ID_Camera)   
GO   
 
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Video_ID_Camera_SEnd') 
  CREATE NONCLUSTERED INDEX IX_Video_ID_Camera_SEnd ON Video (ID_Camera,SEnd) INCLUDE (ID_Archive,SBegin)   
GO   
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Plugin_Camera')   
  CREATE UNIQUE NONCLUSTERED INDEX IX_Plugin_Camera ON Plugin_Camera (ID_Plugin,ID_Camera)   
GO   
 
IF NOT EXISTS(SELECT * FROM Config where Category='Main' and Name='TCP') 
  INSERT INTO Config (Category, Name, Data) VALUES ('Main', 'TCP', 2110)   
GO   
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spAlarmByDayAndCamera')
  EXEC('CREATE PROCEDURE spAlarmByDayAndCamera AS')
GO

ALTER PROCEDURE spAlarmByDayAndCamera
  @FromDT BIGINT,@ToDT BIGINT,@AID_Camera INT
AS
  SELECT case when SBegin<@FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>@ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd,
      StartMessage into #tmpAlarm from Alarm where ID_Camera=@AID_Camera and SEnd>@FromDT and SBegin<@ToDT
  DECLARE @Result varchar(max)
  set @Result=''
  SELECT @Result=@Result+CAST(SBegin as varchar)+'-'+CAST(SEnd as varchar)+'='+StartMessage+CHAR(13)+CHAR(10) from #tmpAlarm
  select @Result
GO 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spCameraPlugin')
  EXEC('CREATE PROCEDURE spCameraPlugin AS')
GO

ALTER PROCEDURE spCameraPlugin
  @AID_Camera INT
AS
  SELECT pc.ID_Plugin,p.Name from Plugin_Camera pc inner join Plugin p on p.ID_Plugin=pc.ID_Plugin where pc.ID_Camera=@AID_Camera
GO

 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spCamerasList')
  EXEC('CREATE PROCEDURE spCamerasList AS')
GO

ALTER PROCEDURE spCamerasList
AS
  DECLARE @Result VARCHAR(MAX)
  set @Result=''
  SELECT @Result=@Result+cast(c.ID_Camera as varchar)+'='+c.Name+';'+cast(IsNull(max(f.SEnd),0) as varchar)+CHAR(13)+CHAR(10) from Camera c 
      left join Fill f on f.ID_Camera=c.ID_Camera where c.Deleted=0 and c.Active=1 group by c.ID_Camera,c.Name order by c.ID_Camera
  select @Result
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spDaysList')
  EXEC('CREATE PROCEDURE spDaysList AS')
GO

ALTER PROCEDURE spDaysList
AS
  DECLARE @Result VARCHAR(MAX)
  set @Result=''
  SELECT @Result=@Result+cast((YEAR(dt)-2000)*10000+MONTH(dt)*100+DAY(dt) as varchar)+CHAR(13)+CHAR(10) from 
      (
        select distinct cast(SEnd/86400000+25567 as DateTime) as dt from Fill
      ) a
  select @Result
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spDeleteCamera')
  EXEC('CREATE PROCEDURE spDeleteCamera AS')
GO

ALTER PROCEDURE spDeleteCamera
  @AID_Camera INT
AS
  IF exists(select top 1 * from Video where ID_Camera=@AID_Camera)
    update Camera set Deleted=1 where ID_Camera=@AID_Camera
  ELSE
  begin
    delete from Alarm where ID_Camera=@AID_Camera
    delete from Fill where ID_Camera=@AID_Camera
    delete from Motion where ID_Camera=@AID_Camera
    delete from Schedule where ID_Camera=@AID_Camera
    delete from Slide where ID_Camera=@AID_Camera
    DELETE from Camera where ID_Camera=@AID_Camera
  end
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spDropArch')
  EXEC('CREATE PROCEDURE spDropArch AS')
GO

ALTER PROCEDURE spDropArch
  @TimeBefore BIGINT, @AID_Archive INT
AS
  DELETE FROM Alarm where SEnd<@TimeBefore
  delete from Fill where ID_Archive=@AID_Archive and SEnd<@TimeBefore
  update Fill set SBegin=@TimeBefore where ID_Archive=@AID_Archive and SBegin<@TimeBefore
  delete from Motion where SEnd<@TimeBefore
  delete from Video where ID_Archive=@AID_Archive and SEnd<@TimeBefore
  delete from SecondaryVideo where ID_Archive=@AID_Archive and SEnd<@TimeBefore
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spGetFragment')
  EXEC('CREATE PROCEDURE spGetFragment AS')
GO

ALTER PROCEDURE spGetFragment
  @DayPoint BIGINT,@AID_Camera INT,@ANext BIT,@APrimary BIT
AS
  DECLARE @Day VARCHAR(6),@qry varchar(512)
  select @Day=cast(YEAR(DT)-2000 as varchar)+right('0'+cast(month(DT) as varchar),2)+right('0'+cast(day(DT) as varchar),2) from
      (
        select cast(@DayPoint/86400000+25567 as DateTime) as DT
      ) a
  set @qry=
      'SELECT '+case when @ANext IS not null then 'top 1 ' else '' end+'a.Path+''\'+@Day+'\'+CAST(@AID_Camera as varchar)+
      case @APrimary when 0 then '_2' else '' end+'\''+cast(v.SBegin as varchar)+''_''+cast(v.SEnd as varchar)+''.h264'' from '+
      case @APrimary when 0 then 'Secondary' else '' end+'Video v inner join Archive a on a.ID_Archive=v.ID_Archive where v.ID_Camera='+
      cast(@AID_Camera as varchar)+' and '
  if @ANext=0
    set @qry=@qry+'v.SEnd<'+cast(@DayPoint as varchar)+' order by v.SEnd desc'
  else if @ANext=1
    set @qry=@qry+'v.SBegin>'+cast(@DayPoint as varchar)+' order by v.SEnd'
  else
    set @qry=@qry+cast(@DayPoint as varchar)+' between v.SBegin and v.SEnd'
  exec(@qry)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spIndexByDayAndCamera')
  EXEC('CREATE PROCEDURE spIndexByDayAndCamera AS')
GO

ALTER PROCEDURE spIndexByDayAndCamera
  @FromDT BIGINT,@ToDT BIGINT,@AID_Camera INT
AS
  SELECT CASE when SBegin<@FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>@ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd
      into #tmpFill from Fill where ID_Camera=@AID_Camera and SEnd>@FromDT and SBegin<@ToDT
  --уменьшение строк
  DECLARE @SBegin INT,@SEnd INT,@OldBegin INT,@OldEnd INT
  create table #tmpResult (SBegin int,SEnd int)
  select @OldBegin=0,@OldEnd=0
  DECLARE Cur CURSOR FOR SELECT SBegin,SEnd from #tmpFill order by SEnd
  OPEN Cur
  FETCH NEXT FROM Cur INTO @SBegin,@SEnd
  WHILE @@FETCH_STATUS=0
  BEGIN
    if @OldEnd>0
    begin
      --если предыдущий конец и текущее начало различаются меньше больше чем на 5 секунд, то сохранить
      if @SBegin-@OldEnd>5
      begin
        insert into #tmpResult (SBegin,SEnd) values (@OldBegin,@OldEnd)
        set @OldBegin=0
      end
    end
    if @OldBegin=0
      set @OldBegin=@SBegin
    set @OldEnd=@SEnd
    FETCH NEXT FROM Cur INTO @SBegin,@SEnd
  END
  CLOSE Cur
  DEALLOCATE Cur
  insert into #tmpResult (SBegin,SEnd) values (@OldBegin,@OldEnd)
  drop table #tmpFill
  DECLARE @Result varchar(max)
  set @Result=''
  SELECT @Result=@Result+CAST(SBegin as varchar)+'-'+CAST(SEnd as varchar)+CHAR(13)+CHAR(10) from #tmpResult
  drop table #tmpResult
  select @Result
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertAlarm')
  EXEC('CREATE PROCEDURE spInsertAlarm AS')
GO

ALTER PROCEDURE spInsertAlarm
  @AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT,@AStartMessage VARCHAR(512)
AS
  INSERT into Alarm (ID_Camera,SBegin,SEnd,StartMessage) values (@AID_Camera,@ASBegin,@ASEnd,@AStartMessage)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertLog')
  EXEC('CREATE PROCEDURE spInsertLog AS')
GO

ALTER PROCEDURE spInsertLog
  @AType INT,@ASource_Type INT,@AID_Source INT,@ASTime BIGINT,@AMessage VARCHAR(512)
AS
  INSERT into Log (Type,Source_Type,ID_Source,STime,Message) values (@AType,@ASource_Type,@AID_Source,@ASTime,@AMessage)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertMotion')
  EXEC('CREATE PROCEDURE spInsertMotion AS')
GO

ALTER PROCEDURE spInsertMotion
  @AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT
AS
  INSERT into Motion (ID_Camera,SBegin,SEnd) values (@AID_Camera,@ASBegin,@ASEnd)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertSecondaryVideo')
  EXEC('CREATE PROCEDURE spInsertSecondaryVideo AS')
GO

ALTER PROCEDURE spInsertSecondaryVideo
  @AID_Archive INT,@AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT
AS
  INSERT into SecondaryVideo (ID_Archive,ID_Camera,SBegin,SEnd) values (@AID_Archive,@AID_Camera,@ASBegin,@ASEnd)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertVideo')
  EXEC('CREATE PROCEDURE spInsertVideo AS')
GO

ALTER PROCEDURE spInsertVideo
  @AID_Archive INT,@AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT
AS
  INSERT into Video (ID_Archive,ID_Camera,SBegin,SEnd) VALUES (@AID_Archive,@AID_Camera,@ASBegin,@ASEnd)
  DECLARE @AID_Fill int
  select top 1 @AID_Fill=ID_Fill from Fill where ID_Camera=@AID_Camera and SEnd>=@ASBegin-1000 order by SEnd desc
  if @AID_Fill>0
    update Fill set SEnd=@ASEnd where ID_Fill=@AID_Fill
  else
    insert into Fill (ID_Camera,SBegin,SEnd,ID_Archive) values (@AID_Camera,@ASBegin,@ASEnd,@AID_Archive)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spMotionByDayAndCamera')
  EXEC('CREATE PROCEDURE spMotionByDayAndCamera AS')
GO

ALTER PROCEDURE spMotionByDayAndCamera
  @FromDT BIGINT,@ToDT BIGINT,@AID_Camera INT
AS
  SELECT CASE when SBegin<@FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>@ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd
      into #tmpMotion from Motion where ID_Camera=@AID_Camera and SEnd>@FromDT and SBegin<@ToDT
  --уменьшение строк
  DECLARE @SBegin INT,@SEnd INT,@OldBegin INT,@OldEnd INT
  create table #tmpResult (SBegin int,SEnd int)
  select @OldBegin=0,@OldEnd=0
  DECLARE Cur CURSOR FOR SELECT SBegin,SEnd from #tmpMotion order by SEnd
  OPEN Cur
  FETCH NEXT FROM Cur INTO @SBegin,@SEnd
  WHILE @@FETCH_STATUS=0
  BEGIN
    if @OldEnd>0
    begin
      --если предыдущий конец и текущее начало различаются меньше больше чем на 5 секунд, то сохранить
      if @SBegin-@OldEnd>5
      begin
        insert into #tmpResult (SBegin,SEnd) values (@OldBegin,@OldEnd)
        set @OldBegin=0
      end
    end
    if @OldBegin=0
      set @OldBegin=@SBegin
    set @OldEnd=@SEnd
    FETCH NEXT FROM Cur INTO @SBegin,@SEnd
  END
  CLOSE Cur
  DEALLOCATE Cur
  insert into #tmpResult (SBegin,SEnd) values (@OldBegin,@OldEnd)
  drop table #tmpMotion
  DECLARE @Result varchar(max)
  set @Result=''
  SELECT @Result=@Result+CAST(SBegin as varchar)+'-'+CAST(SEnd as varchar)+CHAR(13)+CHAR(10) from #tmpResult
  drop table #tmpResult
  select @Result
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spPluginCamera')
  EXEC('CREATE PROCEDURE spPluginCamera AS')
GO

ALTER PROCEDURE spPluginCamera
  @AID_Plugin INT
AS
  SELECT DISTINCT c.ID_Camera,CAST(CASE WHEN LEN(c.Name)>0 THEN c.Name ELSE '' END AS VARCHAR(128)) AS Name,c.ConnectionString,c.Secondary,
      CAST(ISNULL(pc.APrimary,0) AS BIT) AS APrimary,CAST(CASE WHEN pc.ID_Plugin IS NULL THEN 0 ELSE 1 END AS BIT) AS Checked INTO #tmpPluginCamera
      FROM Camera c LEFT JOIN Plugin_Camera pc ON c.ID_Camera=pc.ID_Camera AND pc.ID_Plugin=@AID_Plugin WHERE c.Active=1
  SELECT ID_Camera,Name,ConnectionString,Secondary,APrimary,Checked FROM #tmpPluginCamera
  DROP table #tmpPluginCamera
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spPluginParam')
  EXEC('CREATE PROCEDURE spPluginParam AS')
GO

ALTER PROCEDURE spPluginParam
  @AID_Plugin_Camera INT
AS
  SELECT ID_Plugin_Param, Param, Value FROM Plugin_Param WHERE ID_Plugin_Camera = @AID_Plugin_Camera
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spUpdatePluginCamera')
  EXEC('CREATE PROCEDURE spUpdatePluginCamera AS')
GO

ALTER PROCEDURE spUpdatePluginCamera
  @AID_Camera INT,@AID_Plugin INT,@AConnect BIT
AS
  DECLARE @AID_Plugin_Camera INT
  IF @AConnect=0
  BEGIN
    SELECT @AID_Plugin_Camera=ID_Plugin_Camera FROM Plugin_Camera WHERE ID_Camera=@AID_Camera and ID_Plugin=@AID_Plugin
    IF @AID_Plugin_Camera>0
    begin
      delete from Plugin_Param where ID_Plugin_Camera=@AID_Plugin_Camera
      delete from Plugin_Camera where ID_Plugin_Camera=@AID_Plugin_Camera
    end
  END
  ELSE if not exists(select * from Plugin_Camera where ID_Camera=@AID_Camera and ID_Plugin=@AID_Plugin)
    insert into Plugin_Camera (ID_Camera,ID_Plugin,APrimary) values(@AID_Camera,@AID_Plugin,0)
GO
 
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spUpdateVersion')
  EXEC('CREATE PROCEDURE spUpdateVersion AS')
GO

ALTER PROCEDURE spUpdateVersion
  @AVersion VARCHAR(8)
AS
  IF EXISTS(SELECT * FROM Config WHERE Category='Main' AND Name='Version')
    UPDATE Config SET Data=@AVersion WHERE Category='Main' AND Name='Version' and cast(@AVersion as int)>cast(Data as int)
  else
    insert into Config (Category,Name,Data) values ('Main','Version',@AVersion)
GO
 
-- Обновление версии базы
EXEC spUpdateVersion '20400'
GO
 
