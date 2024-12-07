IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEventsBySquare') 
  EXEC('CREATE PROCEDURE spEventsBySquare AS')
GO

ALTER PROCEDURE spEventsBySquare
  @BeginDate BIGINT,@EndDate BIGINT,@AID_Camera INT,@ALeft INT,@ATop INT,@ARight INT,@ABottom INT
AS
  SELECT DISTINCT e.ID_Event,e.Event_Date from Event e INNER join Zone z on z.ID_Event=e.ID_Event
      where e.Event_Date between @BeginDate and @EndDate and e.ID_Camera=@AID_Camera
        and @ALeft<z.Square_To%100 and @ARight>z.Square_From%100 and @ATop<z.Square_To/100 and @ABottom>z.Square_From/100
GO
