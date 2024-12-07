CREATE OR REPLACE PROCEDURE spPluginCamera(AID_Plugin INT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  CREATE TEMP TABLE tmpPluginCamera AS
      SELECT DISTINCT c.ID_Camera,CAST(CASE WHEN LEN(c.Name)>0 THEN c.Name ELSE '' END AS VARCHAR(128)) AS Name,c.ConnectionString,c.Secondary,
      CAST(ISNULL(pc.APrimary,0) AS BIT) AS APrimary,CASE WHEN pc.ID_Plugin IS NULL THEN false ELSE true END AS Checked FROM Camera c
      LEFT JOIN Plugin_Camera pc ON c.ID_Camera=pc.ID_Camera AND pc.ID_Plugin=AID_Plugin WHERE c.Active=true;
  SELECT ID_Camera,Name,ConnectionString,Secondary,APrimary,Checked from tmpPluginCamera;
end;
$BODY$;