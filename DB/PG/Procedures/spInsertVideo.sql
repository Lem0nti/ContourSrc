CREATE OR REPLACE PROCEDURE spInsertVideo(AID_Archive INT,AID_Camera INT,ASBegin BIGINT,ASEnd BIGINT)
LANGUAGE 'plpgsql'
AS $BODY$
  DECLARE Fill_cur record; AID_Fill int;
begin
  INSERT INTO Video (ID_Archive,ID_Camera,SBegin,SEnd) VALUES (AID_Archive,AID_Camera,ASBegin,ASEnd);
  AID_Fill:=0;
  FOR Fill_cur in select ID_Fill from Fill where ID_Camera=AID_Camera and SEnd>=ASBegin-1000 order by SEnd desc limit 1
  loop
    AID_Fill:=Fill_cur.ID_Fill;
  end loop;
  if AID_Fill>0 then
    update Fill set SEnd=ASEnd where ID_Fill=AID_Fill;
  else
    insert into Fill (ID_Camera,SBegin,SEnd,ID_Archive) values (AID_Camera,ASBegin,ASEnd,AID_Archive);
  end if;
end;
$BODY$;