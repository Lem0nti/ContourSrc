CREATE OR REPLACE FUNCTION fnCamerasList()
RETURNS TABLE(CamerasList character varying(4000)) AS
$BODY$
  declare
    cr record;
    tmpResult character varying(4000);
begin
  tmpResult:='';  
  for cr in select c.ID_Camera,c.Name,ISNULL(max(f.SEnd),0) as SEnd from Camera c left join Fill f on f.ID_Camera=c.ID_Camera
      where c.Deleted=false and c.Active=true
      group by c.ID_Camera,c.Name order by c.ID_Camera 
  loop 
    tmpResult:=tmpResult || cast(cr.ID_Camera as varchar)||'='||cr.Name||';'||cr.SEnd||E'\r\n';
  end loop;
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE plpgsql;