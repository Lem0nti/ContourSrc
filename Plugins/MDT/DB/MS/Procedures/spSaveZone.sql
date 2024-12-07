IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spSaveZone')
  EXEC('CREATE PROCEDURE spSaveZone AS')
GO

ALTER PROCEDURE spSaveZone
  @AID_Event INT,@ASquare_From SMALLINT,@ASquare_To SMALLINT
AS
  insert into Zone (ID_Event,Square_From,Square_To) VALUES (@AID_Event,@ASquare_From,@ASquare_To)
  SELECT @@identity
GO
