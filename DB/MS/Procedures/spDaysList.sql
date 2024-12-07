IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spDaysList')
  EXEC('CREATE PROCEDURE spDaysList AS')
GO

ALTER PROCEDURE spDaysList
AS
  DECLARE @Result VARCHAR(MAX)
  set @Result=''
  SELECT @Result=@Result+cast((YEAR(dt)-2000)*10000+MONTH(dt)*100+DAY(dt) as varchar)+CHAR(13)+CHAR(10) from 
      (
        select distinct cast(SEnd/86400000+25567 as DateTime) as dt from Fill
      ) a
  select @Result
GO
