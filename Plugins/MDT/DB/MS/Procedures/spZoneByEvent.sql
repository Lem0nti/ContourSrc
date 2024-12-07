IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spZoneByEvent')
  EXEC('CREATE PROCEDURE spZoneByEvent AS')
GO

ALTER PROCEDURE spZoneByEvent
  @AID_Event INT
AS
  select Square_From,Square_To from Zone where ID_Event=@AID_Event
GO
