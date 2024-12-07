IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spSaveEvent')
  EXEC('CREATE PROCEDURE spSaveEvent AS')
GO

ALTER PROCEDURE spSaveEvent
  @AID_Camera INT,@Event_Time BIGINT
AS
  INSERT INTO Event (ID_Camera,Event_Date) VALUES (@AID_Camera,@Event_Time)
  SELECT @@identity
GO
