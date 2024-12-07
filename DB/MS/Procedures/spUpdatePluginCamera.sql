IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spUpdatePluginCamera')
  EXEC('CREATE PROCEDURE spUpdatePluginCamera AS')
GO

ALTER PROCEDURE spUpdatePluginCamera
  @AID_Camera INT,@AID_Plugin INT,@AConnect BIT
AS
  DECLARE @AID_Plugin_Camera INT
  IF @AConnect=0
  BEGIN
    SELECT @AID_Plugin_Camera=ID_Plugin_Camera FROM Plugin_Camera WHERE ID_Camera=@AID_Camera and ID_Plugin=@AID_Plugin
    IF @AID_Plugin_Camera>0
    begin
      delete from Plugin_Param where ID_Plugin_Camera=@AID_Plugin_Camera
      delete from Plugin_Camera where ID_Plugin_Camera=@AID_Plugin_Camera
    end
  END
  ELSE if not exists(select * from Plugin_Camera where ID_Camera=@AID_Camera and ID_Plugin=@AID_Plugin)
    insert into Plugin_Camera (ID_Camera,ID_Plugin,APrimary) values(@AID_Camera,@AID_Plugin,0)
GO
