IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spMapFill')
  EXEC('CREATE PROCEDURE spMapFill AS')
GO

ALTER PROCEDURE spMapFill
  @SelectDay BIGINT,@AID_Camera INTEGER
AS
  SELECT DISTINCT (Event_Date%86400000)/1000 AS Second FROM Event WHERE Event_Date-@SelectDay between 0 and 86400000 and ID_Camera=@AID_Camera
GO
