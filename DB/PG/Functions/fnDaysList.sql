CREATE OR REPLACE FUNCTION fnDaysList()
RETURNS TABLE(DaysList character varying(4000)) AS
$BODY$
  declare
    f record;
    tmpResult character varying(4000);
begin
  tmpResult:='';  
  for f in select distinct TO_CHAR(TO_TIMESTAMP(SEnd / 1000), 'YYMMDD') as dt from Fill order by dt
  loop 
    tmpResult:=tmpResult||f.dt||E'\r\n';
  end loop;
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE plpgsql;