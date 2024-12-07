IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertLog')
  EXEC('CREATE PROCEDURE spInsertLog AS')
GO

ALTER PROCEDURE spInsertLog
  @AType INT,@ASource_Type INT,@AID_Source INT,@ASTime BIGINT,@AMessage VARCHAR(512)
AS
  INSERT into Log (Type,Source_Type,ID_Source,STime,Message) values (@AType,@ASource_Type,@AID_Source,@ASTime,@AMessage)
GO
