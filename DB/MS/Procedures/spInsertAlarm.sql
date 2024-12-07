IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertAlarm')
  EXEC('CREATE PROCEDURE spInsertAlarm AS')
GO

ALTER PROCEDURE spInsertAlarm
  @AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT,@AStartMessage VARCHAR(512)
AS
  INSERT into Alarm (ID_Camera,SBegin,SEnd,StartMessage) values (@AID_Camera,@ASBegin,@ASEnd,@AStartMessage)
GO
