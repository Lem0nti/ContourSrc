CREATE OR REPLACE FUNCTION fnGetFragment(DayPoint BIGINT,AID_Camera INT,ANext boolean,APrimary boolean)
RETURNS TABLE(filename text) AS
$BODY$
  DECLARE ADay character varying(6); qry character varying(512);
begin
  ADay:=TO_CHAR(TO_TIMESTAMP(DayPoint/1000), 'YYMMDD');
  qry:=
      'SELECT ' || 'a.Path||''\' || ADay || '\' || CAST(AID_Camera as varchar) ||
      case APrimary when false then '_2' else '' end || '\''||cast(v.SBegin as varchar)||''_''||cast(v.SEnd as varchar)||''.h264'' from ' ||
      case APrimary when false then 'Secondary' else '' end || 'Video v inner join Archive a on a.ID_Archive=v.ID_Archive where v.ID_Camera=' ||
      cast(AID_Camera as varchar) || ' and ';
  if ANext=false then
    qry:=qry || 'v.SEnd<' || cast(DayPoint as varchar) || ' order by v.SEnd desc limit 1';
  elseif ANext=true then
    qry:=qry || 'v.SBegin>'||cast(DayPoint as varchar)||' order by v.SEnd limit 1';
  else
    qry:=qry || DayPoint||' between v.SBegin and v.SEnd';
  end if;
  RETURN QUERY execute qry;
end;
$BODY$ LANGUAGE plpgsql;