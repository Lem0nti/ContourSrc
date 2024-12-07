unit cCutVideo_TH;

interface

uses
  Classes, SyncObjs, ABL.Core.Debug, SysUtils, Windows, Math,
  IOUtils, cData_DM, DateUtils, ABL.Core.TimerThread;

type
  TCutVideo=class(TTimerThread)
  private
    sl: TStringList;
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    Constructor Create(AArchives: string); reintroduce;
    Destructor Destroy; override;
    procedure SetArchive(AArchives: string);
  end;

var
  CutVideo: TCutVideo;

implementation

{ TCutVideo }

constructor TCutVideo.Create(AArchives: string);
begin
  inherited Create(nil,nil);//,'TCutVideo');
  sl:=TStringList.Create;
  sl.Text:=trim(AArchives);
  FInterval:=150000;  //3 минуты
  Enabled:=true;
  Active:=true;
end;

destructor TCutVideo.Destroy;
begin
  if assigned(sl) then
    FreeAndNil(sl);
  inherited;
end;

procedure TCutVideo.DoExecute;
var
  i, j: integer;
  DriveType: UINT;
  Free_Bytes: TLargeInteger;
  FreeSize: TLargeInteger;
  TotalSize: TLargeInteger;
  TS: TSearchRec;
  MinFolderName: integer;
  FolderName, DayFolderName: string;
  CutIndex: boolean;
  DirList: TStringList;
  CamList, IDList: TStringList;
  tmpYear,tmpMonth,tmpDay: Word;
begin
  for I := 0 to sl.Count-1 do
  begin
    FolderName:=sl.ValueFromIndex[i];
    DriveType:=GetDriveType(PChar(FolderName[1]+':\'));
    if not (DriveType in [0,1]) then
    begin
      CutIndex:=false;
      GetDiskFreeSpaceEx(PChar(FolderName[1]+':'),Free_Bytes,Totalsize,@FreeSize);
      Free_Bytes:=Free_Bytes div (1024*1024);
      while Free_Bytes<16384 do  //если меньше чем 16 гигов - чистим
      begin
        if Terminated then
          exit;
        SendDebugMsg('TCutVideo.DoExecute 74, '+FolderName+': Free_Bytes(MB)='+IntToStr(Free_Bytes));
        MinFolderName:=StrToIntDef(FormatDateTime('YYMMDD',now),999999);
        //ищем самый ранний день в архиве
        if FindFirst(FolderName+'*.*',faDirectory,TS)=0 then
          try
            repeat
              if (TS.Name<>'.')and(TS.Name<>'..') then
                MinFolderName:=min(MinFolderName,StrToIntDef(TS.Name,MinFolderName));
            until FindNext(TS)<>0;
          finally
            SysUtils.FindClose(TS);
          end;
        if MinFolderName<StrToIntDef(FormatDateTime('YYMMDD',now),999999) then
        begin
          //удаляем из индекса самый ранний
          tmpYear:=MinFolderName div 10000;
          tmpMonth:=(MinFolderName-10000*tmpYear) div 100;
          tmpDay:=MinFolderName-10000*tmpYear-tmpMonth*100;
          SendDebugMsg('TCutVideo.DoExecute 101: ID_Archive='+sl.Names[i]+', '+FolderName+IntToStr(MinFolderName)+', '+DateTimeToStr(Encodedate(tmpYear+2000,tmpMonth,tmpDay)));
          if DataDM.DropArch(MilliSecondsBetween(UnixDateDelta,Encodedate(tmpYear+2000,tmpMonth,tmpDay)+1),StrToIntDef(sl.Names[i],0)) then
          begin
            //удаляем самый ранний
            DayFolderName:=FolderName+IntToStr(MinFolderName)+'\';
            try
              DirList:=TStringList.Create;
              try
                //запускать отдельно по каждой камере, чтобы реагировать на терминэйтед
                if FindFirst(DayFolderName+'*.*',faDirectory,TS)=0 then
                  try
                    repeat
                      if (TS.Name<>'.')and(TS.Name<>'..') then
                        DirList.AddObject(TS.Name,nil);
                    until FindNext(TS)<>0;
                  finally
                    SysUtils.FindClose(TS);
                  end;
                while DirList.Count>0 do
                begin
                  if DirectoryExists(DayFolderName+DirList[0]+'\') then
                    TDirectory.Delete(DayFolderName+DirList[0]+'\',True)
                  else
                    DeleteFile(PChar(DayFolderName+DirList[0]));
                  //если пришли сюда, значит потом надо будет что-то менять в индексе
                  CutIndex:=true;
                  DirList.Delete(0);
                  if Terminated then
                    exit;
                end;
                TDirectory.Delete(DayFolderName,True);
                //если после этого папка существует - сообщить об этом в лог и переименовать папку
                if DirectoryExists(DayFolderName) then
                begin
                  SendErrorMsg('TCutVideo.DoExecute 135: не удаляется архив '+DayFolderName);
                  if DayFolderName[length(DayFolderName)]='\' then
                    Delete(DayFolderName,length(DayFolderName),1);
                  RenameFile(DayFolderName,DayFolderName+'_');
                end;
              finally
                FreeAndNil(DirList);
              end;
            except on E: Exception do
              begin
                SendErrorMsg('TCutVideo.DoExecute 145, '+SysErrorMessage(GetLastError)+': '+e.ClassName+' - '+e.Message+#13#10+FolderName+' __ '+DayFolderName);
                exit;
              end;
            end;
          end
          else
            SendErrorMsg('TCutVideo.DoExecute 151: IndexProviderDM.DropDayArch('+IntToStr(MinFolderName)+')=false');
        end
        else
        begin
          SendErrorMsg('TCutVideo.DoExecute 155: не хватает места даже для записи одного дня');
          break;
        end;
        GetDiskFreeSpaceEx(PChar(FolderName[1]+':'),Free_Bytes,Totalsize,@FreeSize);
        Free_Bytes:=Free_Bytes div (1024*1024);
      end;
      if CutIndex then
      begin
        //Удаление камер без архивов
        CamList:= TStringList.Create;
        try
          IDList:= TStringList.Create;
          try
            CamList.Text:=trim(DataDM.GetCamerasDeleted);
            if CamList.Count>0 then
            begin
              IDList.Text:=trim(DataDM.GetCamerasByArchive);
              if IDList.Text<>'' then
              begin
                while IDList.Count > 0 do
                begin
                  for j := 0 to CamList.Count - 1 do
                    if CamList[j] = IDList[0] then
                    begin
                      CamList.Delete(j); // Если ID камеры присутствует в архиве то удаляем из списка
                      break;
                    end;
                  IDList.Delete(0);
                end;
                //Удаляем все камеры которые остались в списке. Если они остались в списке значит архивов не существует
                for j := 0 to CamList.Count - 1 do
                  DataDM.DeleteCamera(StrToInt(CamList[j]));
              end;
            end;
          finally
            FreeAndNil(IDList);
          end;
        finally
          FreeAndNil(CamList);
        end;
      end;
    end;
  end;
end;

procedure TCutVideo.DoReceive(var AInputData: Pointer);
begin

end;

procedure TCutVideo.SetArchive(AArchives: string);
begin
  FLock.Enter;
  try
    sl.Text:=trim(AArchives);
  finally
    FLock.Leave;
  end;
end;

end.
