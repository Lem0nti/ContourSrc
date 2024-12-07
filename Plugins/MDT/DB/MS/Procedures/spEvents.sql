IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spEvents')
  EXEC('CREATE PROCEDURE spEvents AS')
GO

ALTER PROCEDURE spEvents
  @BeginDate BIGINT,@EndDate BIGINT
AS
  SELECT ID_Event,ID_Camera,Event_Date,dateadd(millisecond,Event_Date%1000,dateadd(SECOND, Event_Date/1000, '1970-01-01')) as ShowDate from Event
      where Event_Date between @BeginDate and @EndDate
GO
