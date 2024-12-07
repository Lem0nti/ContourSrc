IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spAlarmByDayAndCamera')
  EXEC('CREATE PROCEDURE spAlarmByDayAndCamera AS')
GO

ALTER PROCEDURE spAlarmByDayAndCamera
  @FromDT BIGINT,@ToDT BIGINT,@AID_Camera INT
AS
  SELECT case when SBegin<@FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>@ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd,
      StartMessage into #tmpAlarm from Alarm where ID_Camera=@AID_Camera and SEnd>@FromDT and SBegin<@ToDT
  DECLARE @Result varchar(max)
  set @Result=''
  SELECT @Result=@Result+CAST(SBegin as varchar)+'-'+CAST(SEnd as varchar)+'='+StartMessage+CHAR(13)+CHAR(10) from #tmpAlarm
  select @Result
GO