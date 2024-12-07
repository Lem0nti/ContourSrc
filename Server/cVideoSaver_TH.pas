unit cVideoSaver_TH;

interface

uses
  SysUtils, Classes, DateUtils, Generics.Collections, cData_DM, Windows,
  ABL.Core.Debug, ABL.Core.DirectThread, cCommon, cFrameList_Cl, ABL.IO.IOTypes;

type
  TVideoSaver = class(TDirectThread)
  private
    FArchiveList: TStringList;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    Constructor Create(AArchives: string); reintroduce;
    Destructor Destroy; override;
    procedure SetArchive(AArchives: string);
  end;

var
  VideoSaver: TVideoSaver;

implementation

{ TVideoSaver }

constructor TVideoSaver.Create(AArchives: string);
var
  ErrCnt: PInteger;
  q: integer;
begin
  inherited Create('TVideoSaver');
  FArchiveList:=TStringList.Create;
  FArchiveList.Text:=trim(AArchives);
  if FArchiveList.Count=0 then
    SendErrorMsg('TVideoSaver.Create 37: Нет путей сохранения.')
  else
    for q:=0 to FArchiveList.Count-1 do
    begin
      New(ErrCnt);
      ErrCnt^:=0;
      FArchiveList.Objects[q]:=TObject(ErrCnt);
    end;
  Active:=true;
end;

destructor TVideoSaver.Destroy;
begin
  FArchiveList.Free;
  inherited;
end;

procedure TVideoSaver.DoExecute(var AInputData, AResultData: Pointer);
var
  FFrame: PTimedDataHeader;
  FrameList: TFrameList;
  Header: TVideoHeader;
  i,ArchIndex,FID_Camera,FID_Archive,AttemptCount: integer;
  FPath: TFileName;
  AEndTime: TDateTime;
  SaveCommand: PSaveCommand;
  FrameHeader: TFrameHeader;
  ErrCnt: PInteger;
  tmpFileName: string;
  tmpFileHandle: THandle;
begin
  FID_Archive:=0;
  FID_Camera:=0;
  ArchIndex:=-1;
  AttemptCount:=0;
  ErrCnt:=nil;
  try
    //сохранение
    FrameList:=TFrameList(AInputData);
    try
      FID_Camera:=FrameList.ID_Camera;
      AInputData:=nil;
      if FArchiveList.Count>0 then
      begin
        ArchIndex:=Random(FArchiveList.Count);
        FPath:=FArchiveList.ValueFromIndex[ArchIndex];
        FID_Archive:=StrToIntDef(FArchiveList.Names[ArchIndex],0);
        if FID_Archive>0 then
        begin
          ErrCnt:=PInteger(FArchiveList.Objects[ArchIndex]);
          if FrameList.Count>0 then
          begin
            AEndTime:=IncMilliSecond(UnixDateDelta,PTimedDataHeader(FrameList[FrameList.Count-1]).Time);
            if Terminated then
              exit;
            FPath:=FPath+FormatDateTime('YYMMDD',AEndTime)+'\'+IntToStr(FID_Camera);
            if not FrameList.Primary then
              FPath:=FPath+'_2';
            FPath:=FPath+'\';
            ForceDirectories(FPath);
            Header.FrameCount:=FrameList.Count;
            Header.FPS:=Round(1000/((PTimedDataHeader(FrameList[FrameList.Count-1]).Time-PTimedDataHeader(FrameList[0]).Time)/FrameList.Count));
            if Terminated then
              exit;
            while AttemptCount<2 do
              try
                inc(AttemptCount);
                tmpFileName:=FPath+IntToStr(PTimedDataHeader(FrameList[0]).Time)+'_'+IntToStr(PTimedDataHeader(FrameList[FrameList.Count-1]).Time)+'.h264';
                tmpFileHandle:=FileCreate(tmpFileName,0,0);  //Это самая долгая операция тут
                try
                  Header.Version:=VideoVersion;
                  FileWrite(tmpFileHandle,Header,SizeOf(Header));
                  // кадры
                  for i := 0 to FrameList.Count - 1 do
                  begin
                    FFrame:=FrameList[i];
                    FrameHeader.TimeStamp:=FFrame.Time;
                    FrameHeader.Size:=FFrame.DataHeader.Size-SizeOf(TTimedDataHeader);
                    FileWrite(tmpFileHandle,FrameHeader,sizeof(TFrameHeader));
                  end;
                  for i := 0 to FrameList.Count-1 do
                  begin
                    FFrame:=FrameList[i];
                    FileWrite(tmpFileHandle,FFrame.Data^,FFrame.DataHeader.Size-SizeOf(TTimedDataHeader));
                  end;
                  if Terminated then
                    exit;
                  if Assigned(FOutputQueue) then
                  begin
                    new(SaveCommand);
                    SaveCommand.ID_Archive:=FID_Archive;
                    SaveCommand.ID_Camera:=FID_Camera;
                    SaveCommand.Begin_Time:=PTimedDataHeader(FrameList[0]).Time;
                    SaveCommand.End_Time:=PTimedDataHeader(FrameList[FrameList.Count-1]).Time;
                    SaveCommand.Primary:=FrameList.Primary;
                    AResultData:=SaveCommand;
                  end;
                  if @ErrCnt<>nil then
                    ErrCnt^:=0;
                finally
                  FileClose(tmpFileHandle);
                end;
                AttemptCount:=255;
              except on e: EFCreateError do
                if AttemptCount>=2 then
                  raise;
              else
                raise;
              end;
          end
          else
            SendErrorMsg('TVideoSaver.DoExecute 165: FrameList.Count=0, ID_Camera='+IntToStr(FID_Camera));
        end
        else
          SendErrorMsg('TVideoSaver.DoExecute 168: ID_Archive=0');
      end;
    finally
      while FrameList.Count>0 do
      begin
        FFrame:=FrameList.First;
        FrameList.Delete(0);
        FreeMem(FFrame);
      end;
      FreeAndNil(FrameList);
    end;
  except on e: EFCreateError do
    begin
      //удалить архив из списка
      if ArchIndex>-1 then
      begin
        if @ErrCnt<>nil then
          if ErrCnt^>=10 then
          begin
            //выключить архив в БД
            DataDM.ExecSQL('update Archive set Active=0 where ID_Archive='+IntToStr(FID_Archive));
            //сообщить об этом в лог
            SendErrorMsg('TVideoSaver.DoExecute 171: '+e.Message+'. Запись остановлена ['+FArchiveList.ValueFromIndex[ArchIndex]+'].');
            FArchiveList.Delete(ArchIndex);
          end
          else
          begin
            inc(ErrCnt^);
            SendErrorMsg('TVideoSaver.DoExecute 176, EFCreateError: '+e.Message+'. Количество попыток - '+IntToStr(AttemptCount)+'. Количество ошибок - '+IntToStr(ErrCnt^)+'.');
          end
        else
          SendErrorMsg('TVideoSaver.DoExecute 179, EFCreateError: '+e.Message+'.');
      end;
    end;
  on e: Exception do
    SendErrorMsg('TVideoSaver.DoExecute 183, ID_Camera='+IntToStr(FID_Camera)+': '+e.ClassName+ ' - '+e.Message);
  end;
end;

procedure TVideoSaver.SetArchive(AArchives: string);
begin
  Lock;
  try
    FArchiveList.Text:=Trim(AArchives);
  finally
    Unlock;
  end;
end;

end.
