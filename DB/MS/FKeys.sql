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


