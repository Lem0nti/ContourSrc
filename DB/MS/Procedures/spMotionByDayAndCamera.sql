IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spMotionByDayAndCamera')
  EXEC('CREATE PROCEDURE spMotionByDayAndCamera AS')
GO

ALTER PROCEDURE spMotionByDayAndCamera
  @FromDT BIGINT,@ToDT BIGINT,@AID_Camera INT
AS
  SELECT CASE when SBegin<@FromDT then 0 else (SBegin%86400000)/1000 end as SBegin, case when SEnd>@ToDT then 86400 else (SEnd%86400000)/1000 end as SEnd
      into #tmpMotion from Motion where ID_Camera=@AID_Camera and SEnd>@FromDT and SBegin<@ToDT
  --уменьшение строк
  DECLARE @SBegin INT,@SEnd INT,@OldBegin INT,@OldEnd INT
  create table #tmpResult (SBegin int,SEnd int)
  select @OldBegin=0,@OldEnd=0
  DECLARE Cur CURSOR FOR SELECT SBegin,SEnd from #tmpMotion order by SEnd
  OPEN Cur
  FETCH NEXT FROM Cur INTO @SBegin,@SEnd
  WHILE @@FETCH_STATUS=0
  BEGIN
    if @OldEnd>0
    begin
      --если предыдущий конец и текущее начало различаются меньше больше чем на 5 секунд, то сохранить
      if @SBegin-@OldEnd>5
      begin
        insert into #tmpResult (SBegin,SEnd) values (@OldBegin,@OldEnd)
        set @OldBegin=0
      end
    end
    if @OldBegin=0
      set @OldBegin=@SBegin
    set @OldEnd=@SEnd
    FETCH NEXT FROM Cur INTO @SBegin,@SEnd
  END
  CLOSE Cur
  DEALLOCATE Cur
  insert into #tmpResult (SBegin,SEnd) values (@OldBegin,@OldEnd)
  drop table #tmpMotion
  DECLARE @Result varchar(max)
  set @Result=''
  SELECT @Result=@Result+CAST(SBegin as varchar)+'-'+CAST(SEnd as varchar)+CHAR(13)+CHAR(10) from #tmpResult
  drop table #tmpResult
  select @Result
GO
