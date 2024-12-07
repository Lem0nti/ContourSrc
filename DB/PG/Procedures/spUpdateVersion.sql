CREATE OR REPLACE PROCEDURE spUpdateVersion(AVersion character varying(8))
LANGUAGE 'plpgsql'
AS $BODY$
begin
  IF EXISTS(SELECT * FROM Config WHERE Category='Main' AND Name='Version') then
    UPDATE Config SET Data=AVersion WHERE Category='Main' AND Name='Version' and cast(AVersion as int)>cast(Data as int);
  else
    insert into Config (Category,Name,Data) values ('Main','Version',AVersion);
  end if;
end;
$BODY$;
