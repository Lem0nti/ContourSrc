CREATE OR REPLACE PROCEDURE spUpdatePluginCamera(AID_Camera INT,AID_Plugin INT,AConnect BIT)
LANGUAGE 'plpgsql'
AS $BODY$
  DECLARE Fill_cur record; AID_Plugin_Camera int;
begin
  if AConnect=0 then
    AID_Plugin_Camera:=0;
    FOR Fill_cur in SELECT ID_Plugin_Camera FROM Plugin_Camera WHERE ID_Camera=AID_Camera and ID_Plugin=AID_Plugin
    loop
      AID_Plugin_Camera:=Fill_cur.ID_Plugin_Camera;
    end loop;
    IF AID_Plugin_Camera>0 then
      delete from Plugin_Param where ID_Plugin_Camera=AID_Plugin_Camera;
      delete from Plugin_Camera where ID_Plugin_Camera=AID_Plugin_Camera;
    end if;
  else 
    if not exists(select * from Plugin_Camera where ID_Camera=AID_Camera and ID_Plugin=AID_Plugin) then
      insert into Plugin_Camera (ID_Camera,ID_Plugin,APrimary) values(AID_Camera,AID_Plugin,false);
    end if;
  end if;
end;
$BODY$;
