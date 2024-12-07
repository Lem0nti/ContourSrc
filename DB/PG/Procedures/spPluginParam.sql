CREATE OR REPLACE PROCEDURE spPluginParam(AID_Plugin_Camera INT)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  SELECT ID_Plugin_Param, Param, Value FROM Plugin_Param WHERE ID_Plugin_Camera = AID_Plugin_Camera;
end;
$BODY$;
