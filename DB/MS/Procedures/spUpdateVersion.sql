IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spUpdateVersion')
  EXEC('CREATE PROCEDURE spUpdateVersion AS')
GO

ALTER PROCEDURE spUpdateVersion
  @AVersion VARCHAR(8)
AS
  IF EXISTS(SELECT * FROM Config WHERE Category='Main' AND Name='Version')
    UPDATE Config SET Data=@AVersion WHERE Category='Main' AND Name='Version' and cast(@AVersion as int)>cast(Data as int)
  else
    insert into Config (Category,Name,Data) values ('Main','Version',@AVersion)
GO
