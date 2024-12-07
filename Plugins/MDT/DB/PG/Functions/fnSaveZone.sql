CREATE OR REPLACE FUNCTION fnSaveZone(AID_Event INT,ASquare_From SMALLINT,ASquare_To SMALLINT)
RETURNS INT AS
$BODY$
DECLARE AID_Zone INT;
begin
  insert into Zone (ID_Event,Square_From,Square_To) VALUES (AID_Event,ASquare_From,ASquare_To) returning ID_Zone into AID_Zone;
  return AID_Zone ;
end;
$BODY$ LANGUAGE 'plpgsql';
