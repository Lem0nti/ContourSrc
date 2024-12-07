CREATE OR REPLACE FUNCTION fnMotionByDayAndCamera(FromDT BIGINT,ToDT BIGINT,AID_Camera INTEGER)
RETURNS TABLE(MotionIndex text) AS
$BODY$
  DECLARE OldBegin INT; OldEnd INT; tmpResult text;
    Motion_cur record;
begin
  OldBegin:=0;
  OldEnd:=0;
  tmpResult:='';
  for Motion_cur in
      SELECT CASE when SBegin<FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd
        from Motion where ID_Camera=AID_Camera and SEnd>FromDT and SBegin<ToDT order by SBegin,SEnd
  LOOP
    --если предыдущий конец и текущее начало различаются меньше больше чем на 5 секунд, то сохранить
    if OldEnd>0 and Motion_cur.SBegin-OldEnd>5 then
      tmpResult:=tmpResult||CAST(OldBegin as varchar)||'-'||CAST(OldEnd as varchar)||E'\r\n';
      OldBegin:=0;
    end if;
    if OldBegin=0 then
      OldBegin:=Motion_cur.SBegin;
    end if;
    OldEnd:=Motion_cur.SEnd;
  END LOOP;
  tmpResult:=tmpResult||CAST(OldBegin as varchar)||'-'||CAST(OldEnd as varchar)||E'\r\n';
  return QUERY select tmpResult;
end;
$BODY$ LANGUAGE 'plpgsql';