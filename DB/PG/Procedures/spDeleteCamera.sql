CREATE OR REPLACE PROCEDURE spDeleteCamera(AID_Camera INTEGER)
LANGUAGE 'plpgsql'
AS $BODY$
begin
  IF exists(select * from Video where ID_Camera=AID_Camera limit 1) then
    update Camera set Deleted=1 where ID_Camera=AID_Camera;
  ELSE
    delete from Alarm where ID_Camera=AID_Camera;
    delete from Fill where ID_Camera=AID_Camera;
    delete from Motion where ID_Camera=AID_Camera;
    delete from Schedule where ID_Camera=AID_Camera;
    delete from Slide where ID_Camera=AID_Camera;
    DELETE from Camera where ID_Camera=AID_Camera;
  end if;
end;
$BODY$;