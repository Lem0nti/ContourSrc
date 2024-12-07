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
