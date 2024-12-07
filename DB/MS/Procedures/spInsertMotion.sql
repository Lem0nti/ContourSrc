IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertMotion')
  EXEC('CREATE PROCEDURE spInsertMotion AS')
GO

ALTER PROCEDURE spInsertMotion
  @AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT
AS
  INSERT into Motion (ID_Camera,SBegin,SEnd) values (@AID_Camera,@ASBegin,@ASEnd)
GO
