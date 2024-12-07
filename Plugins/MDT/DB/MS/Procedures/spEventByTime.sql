IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEventByTime') 
  EXEC('CREATE PROCEDURE spEventByTime AS')
GO

ALTER PROCEDURE spEventByTime
  @Date_Time BIGINT, @AID_Camera INT, @Pause INT
AS
  SELECT TOP 1 ID_Event FROM Event WHERE ID_Camera=@AID_Camera AND abs(@Date_Time-Event_Date) between 0 and @Pause
      order by abs(@Date_Time-Event_Date)
GO
