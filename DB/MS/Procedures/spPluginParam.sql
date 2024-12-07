IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spPluginParam')
  EXEC('CREATE PROCEDURE spPluginParam AS')
GO

ALTER PROCEDURE spPluginParam
  @AID_Plugin_Camera INT
AS
  SELECT ID_Plugin_Param, Param, Value FROM Plugin_Param WHERE ID_Plugin_Camera = @AID_Plugin_Camera
GO
