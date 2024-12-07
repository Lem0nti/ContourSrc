IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spGetFragment')
  EXEC('CREATE PROCEDURE spGetFragment AS')
GO

ALTER PROCEDURE spGetFragment
  @DayPoint BIGINT,@AID_Camera INT,@ANext BIT,@APrimary BIT
AS
  DECLARE @Day VARCHAR(6),@qry varchar(512)
  select @Day=cast(YEAR(DT)-2000 as varchar)+right('0'+cast(month(DT) as varchar),2)+right('0'+cast(day(DT) as varchar),2) from
      (
        select cast(@DayPoint/86400000+25567 as DateTime) as DT
      ) a
  set @qry=
      'SELECT '+case when @ANext IS not null then 'top 1 ' else '' end+'a.Path+''\'+@Day+'\'+CAST(@AID_Camera as varchar)+
      case @APrimary when 0 then '_2' else '' end+'\''+cast(v.SBegin as varchar)+''_''+cast(v.SEnd as varchar)+''.h264'' from '+
      case @APrimary when 0 then 'Secondary' else '' end+'Video v inner join Archive a on a.ID_Archive=v.ID_Archive where v.ID_Camera='+
      cast(@AID_Camera as varchar)+' and '
  if @ANext=0
    set @qry=@qry+'v.SEnd<'+cast(@DayPoint as varchar)+' order by v.SEnd desc'
  else if @ANext=1
    set @qry=@qry+'v.SBegin>'+cast(@DayPoint as varchar)+' order by v.SEnd'
  else
    set @qry=@qry+cast(@DayPoint as varchar)+' between v.SBegin and v.SEnd'
  exec(@qry)
GO
