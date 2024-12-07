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
