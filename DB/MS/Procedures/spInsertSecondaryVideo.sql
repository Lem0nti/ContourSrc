IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertSecondaryVideo')
  EXEC('CREATE PROCEDURE spInsertSecondaryVideo AS')
GO

ALTER PROCEDURE spInsertSecondaryVideo
  @AID_Archive INT,@AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT
AS
  INSERT into SecondaryVideo (ID_Archive,ID_Camera,SBegin,SEnd) values (@AID_Archive,@AID_Camera,@ASBegin,@ASEnd)
GO
