IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name='spInsertVideo')
  EXEC('CREATE PROCEDURE spInsertVideo AS')
GO

ALTER PROCEDURE spInsertVideo
  @AID_Archive INT,@AID_Camera INT,@ASBegin BIGINT,@ASEnd BIGINT
AS
  INSERT into Video (ID_Archive,ID_Camera,SBegin,SEnd) VALUES (@AID_Archive,@AID_Camera,@ASBegin,@ASEnd)
  DECLARE @AID_Fill int
  select top 1 @AID_Fill=ID_Fill from Fill where ID_Camera=@AID_Camera and SEnd>=@ASBegin-1000 order by SEnd desc
  if @AID_Fill>0
    update Fill set SEnd=@ASEnd where ID_Fill=@AID_Fill
  else
    insert into Fill (ID_Camera,SBegin,SEnd,ID_Archive) values (@AID_Camera,@ASBegin,@ASEnd,@AID_Archive)
GO
