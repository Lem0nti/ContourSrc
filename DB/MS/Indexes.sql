IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Video_ID_Camera_SEnd')
  CREATE NONCLUSTERED INDEX IX_Video_ID_Camera_SEnd ON Video (ID_Camera,SEnd) INCLUDE (ID_Archive,SBegin)
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Plugin_Camera')
  CREATE UNIQUE NONCLUSTERED INDEX IX_Plugin_Camera ON Plugin_Camera (ID_Plugin,ID_Camera)
GO