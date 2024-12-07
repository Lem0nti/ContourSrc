IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spCameraPlugin')
  EXEC('CREATE PROCEDURE spCameraPlugin AS')
GO

ALTER PROCEDURE spCameraPlugin
  @AID_Camera INT
AS
  SELECT pc.ID_Plugin,p.Name from Plugin_Camera pc inner join Plugin p on p.ID_Plugin=pc.ID_Plugin where pc.ID_Camera=@AID_Camera
GO

