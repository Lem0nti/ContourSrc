CREATE OR REPLACE PROCEDURE spCameraPlugin(AID_Camera INT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  SELECT pc.ID_Plugin,p.Name from Plugin_Camera pc inner join Plugin p on p.ID_Plugin=pc.ID_Plugin where pc.ID_Camera=AID_Camera;
end;
$BODY$;