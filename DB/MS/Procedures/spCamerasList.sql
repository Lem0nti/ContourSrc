IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spCamerasList')
  EXEC('CREATE PROCEDURE spCamerasList AS')
GO

ALTER PROCEDURE spCamerasList
AS
  DECLARE @Result VARCHAR(MAX)
  set @Result=''
  SELECT @Result=@Result+cast(c.ID_Camera as varchar)+'='+c.Name+';'+cast(IsNull(max(f.SEnd),0) as varchar)+CHAR(13)+CHAR(10) from Camera c 
      left join Fill f on f.ID_Camera=c.ID_Camera where c.Deleted=0 and c.Active=1 group by c.ID_Camera,c.Name order by c.ID_Camera
  select @Result
GO
