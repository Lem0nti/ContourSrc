IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spPluginCamera')
  EXEC('CREATE PROCEDURE spPluginCamera AS')
GO

ALTER PROCEDURE spPluginCamera
  @AID_Plugin INT
AS
  SELECT DISTINCT c.ID_Camera,CAST(CASE WHEN LEN(c.Name)>0 THEN c.Name ELSE '' END AS VARCHAR(128)) AS Name,c.ConnectionString,c.Secondary,
      CAST(ISNULL(pc.APrimary,0) AS BIT) AS APrimary,CAST(CASE WHEN pc.ID_Plugin IS NULL THEN 0 ELSE 1 END AS BIT) AS Checked INTO #tmpPluginCamera
      FROM Camera c LEFT JOIN Plugin_Camera pc ON c.ID_Camera=pc.ID_Camera AND pc.ID_Plugin=@AID_Plugin WHERE c.Active=1
  SELECT ID_Camera,Name,ConnectionString,Secondary,APrimary,Checked FROM #tmpPluginCamera
  DROP table #tmpPluginCamera
GO
