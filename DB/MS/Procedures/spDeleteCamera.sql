IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spDeleteCamera')
  EXEC('CREATE PROCEDURE spDeleteCamera AS')
GO

ALTER PROCEDURE spDeleteCamera
  @AID_Camera INT
AS
  IF exists(select top 1 * from Video where ID_Camera=@AID_Camera)
    update Camera set Deleted=1 where ID_Camera=@AID_Camera
  ELSE
  begin
    delete from Alarm where ID_Camera=@AID_Camera
    delete from Fill where ID_Camera=@AID_Camera
    delete from Motion where ID_Camera=@AID_Camera
    delete from Schedule where ID_Camera=@AID_Camera
    delete from Slide where ID_Camera=@AID_Camera
    DELETE from Camera where ID_Camera=@AID_Camera
  end
GO
