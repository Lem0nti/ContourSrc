IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Zone_Event')
  ALTER TABLE Zone ADD CONSTRAINT FK_Zone_Event FOREIGN KEY (ID_Event) REFERENCES Event (ID_Event)
GO

IF NOT EXISTS (select * from sys.foreign_keys WHERE name = 'FK_Zone_Path')
  ALTER TABLE Zone ADD CONSTRAINT FK_Zone_Path FOREIGN KEY (ID_Path) REFERENCES Path (ID_Path)
GO
