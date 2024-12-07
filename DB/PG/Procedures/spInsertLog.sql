CREATE OR REPLACE PROCEDURE spInsertLog(AType INT,ASource_Type INT,AID_Source INT,ASTime BIGINT,AMessage character varying(512))
LANGUAGE 'plpgsql'
AS $BODY$
begin
  INSERT into Log (Type,Source_Type,ID_Source,STime,Message) values (AType,ASource_Type,AID_Source,ASTime,AMessage);
end;
$BODY$;
