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
