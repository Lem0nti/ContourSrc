unit cpArchManager_TH;

interface

uses
  Windows, Classes, SysUtils, ABL.Core.Debug, Types, Generics.Collections, DateUtils, IdHTTP, acTypes,
  cpCacheClear_TH, IOUtils, acData_DM, IdStack, IniFiles;

type
  TArchFragment=record
    FileName: string;
    BeginMillisecond: int64;
    EndMillisecond: int64;
  end;

  TFragmentArray = array of TArchFragment;

  TServerShort=class
  public
    Cameras: TStringList;
    DataDM: TDataDM;
    Days: TIntegerDynArray;
    constructor Create;
    destructor Destroy; override;
  end;

  TContentFragment=record
    BeginSecond: integer;
    EndSecond: integer;
    Message: string;
  end;

  TDayContent = array of TContentFragment;

  TArchManager=class(TStringList)
  private
    FLock: TRTLCriticalSection;
    idhttpWeb: TIdHTTP;
    tmpDir: TFileName;   //день умножить на 100+камера = индекс для этого списка
    Content: TDictionary<string, TDayContent>;
                         //индекс умножить на 100000000+день умножить на 100+камера = индекс для этого списка
    Fragment: TDictionary<integer, TFragmentArray>;
                             //индекс умножить на 1000+камера = индекс для этого списка
    TodayRequest: TDictionary<integer, TDateTime>;
    function DoGetCameraExists(AIndex, ACamera: integer): boolean;
    function DoGetCamerasList(AIndex: integer): string;
    function DoGetDayContent(AIndex, AID_Camera, ADay: integer; AType: byte): TDayContent;
    function DoGetDaysList(AIndex: integer): TIntegerDynArray;
    function DoGetVideo(AIndex, ACamera: integer; ADateTime: TDateTime; NextType: TNextType; APrimary: boolean): TFileName;
    function DoGetVideoExist(AIndex, ACamera: integer; ADateTime: TDateTime): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const S: string): Integer; override;
    function CameraExists(AIndex, ACamera: integer): boolean; overload;
    function CameraExists(AAddress: string; ACamera: integer): boolean; overload;
    function CameraName(AServer, ACamera: integer): string;
    function CamerasList(AIndex: integer): string; overload;
    function CamerasList(AAddress: string): string; overload;
    procedure ClearTodayCache(AServer: integer);
    function DayContent(AIndex, ACamera, ADay: integer; AType: byte): TDayContent; overload;
    function DayContent(AAddress: string; ACamera, ADay: integer; AType: byte): TDayContent; overload;
    function DaysList(AIndex: integer): TIntegerDynArray; overload;
    function DaysList(AAddress: string): TIntegerDynArray; overload;
    function GetAlarmByPoint(AIndex, AID_Camera: integer; ADateTime: TDateTime): string;
    function GetSlideByPoint(AIndex, AID_Camera: integer; ADateTime: TDateTime): string;
    function Video(AIndex, ACamera: integer; ADateTime: TDateTime; NextType: TNextType; APrimary: boolean): TFileName; overload;
    function VideoExist(AIndex, ACamera: integer; ADateTime: TDateTime): boolean; overload;
    function VideoExist(AAddress: string; ACamera: integer; ADateTime: TDateTime): boolean; overload;
  end;

function ArchManager: TArchManager;

implementation

var
  pArchManager: TArchManager;

function ArchManager: TArchManager;
begin
  if not assigned(pArchManager) then
    pArchManager:=TArchManager.Create;
  result:=pArchManager;
end;

{ TServerShort }

constructor TServerShort.Create;
begin
  inherited Create;
  Days:=[];
  Cameras:=TStringList.Create;
end;

destructor TServerShort.Destroy;
begin
  FreeAndNil(Cameras);
  inherited;
end;

{ TArchManager }

function TArchManager.Add(const S: string): Integer;
var
  ServerShort: TServerShort;
  sl: TStringList;
  q,tmpFileName,tmpCameraFolder: string;
  w,e,r: integer;
  FolderName: TFileNAme;
  TS: TSearchRec;
  FileList,CameraFolderList: TStringDynArray;
  ArchFragment: TArchFragment;
  FragmentArray: TFragmentArray;
  tmpYear,tmpMonth,tmpDay: Word;
  ADateTime: TDateTime;
  FConnectionString: TStringList;
begin
  result:=-1;
  try
    q:='';
    if s='127.0.0.1' then
    begin
      if not assigned(DataDM) then
      begin

        FConnectionString:=TStringList.Create;
        try
          With TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
            try
              ReadSectionValues('CONNECTION',FConnectionString);
            finally
              Free;
            end;
          DataDM:=TDataDM.Create(FConnectionString.Text);
        finally
          FreeAndNil(FConnectionString);
        end;

        //DataDM:=TDataDM.Create(1);
        if DataDM.Connected then
        begin
          DataDM.InitializeModule;
          q:=DataDM.GetCamerasList;
        end
        else
          FreeAndNil(DataDM);
      end;
    end;
    if q='' then
      q:=idhttpWeb.Get('http://'+S+'/?cameraslist');
    if q<>'' then
    begin
      q:=trim(q);
      if q='' then
        SendErrorMsg('TArchManager.Add 155: на сервере '+S+' отсутствуют камеры')
      else
      begin
        //открываем список, это камеры
        ServerShort:=TServerShort.Create;
        ServerShort.Cameras.Text:=q;
        if s='127.0.0.1' then
          ServerShort.DataDM:=DataDM;
        if assigned(ServerShort.DataDM) then
          q:=DataDM.GetDaysList
        else
          q:=idhttpWeb.Get('http://'+S+'/?dayslist');
        if q<>'' then
        begin
          sl:=TStringList.Create;
          try
            sl.Text:=q;
            for q in sl do
            begin
              w:=StrToIntDef(q,0);
              if w>0 then
                ServerShort.Days:=ServerShort.Days+[w];
            end;
          finally
            FreeAndNil(sl);
          end;
        end;
        result:=inherited AddObject(S,ServerShort);
        //какое видео есть в кэше для этого сервера
        FolderName:=tmpDir+S+'\';
        if DirectoryExists(FolderName,false) then
        begin
          if FindFirst(FolderName+'*.*',faDirectory,TS)=0 then
            try
              repeat
                if (TS.Name<>'.')and(TS.Name<>'..') then
                  if (TS.Attr and faDirectory)=0 then
                    DeleteFile(FolderName+TS.Name)
                  else if not assigned(ServerShort.DataDM) then
                  begin
                    e:=StrToIntDef(TS.Name,0);
                    tmpYear:=e div 10000;
                    tmpMonth:=(e-10000*tmpYear) div 100;
                    tmpDay:=e-10000*tmpYear-tmpMonth*100;
                    if TryEncodeDate(tmpYear+2000,tmpMonth,tmpDay,ADateTime) then
                    begin
                      CameraFolderList:=TDirectory.GetDirectories(FolderName+TS.Name);
                      for tmpCameraFolder in CameraFolderList do
                      begin
                        FileList:=TDirectory.GetFiles(tmpCameraFolder);
                        if length(FileList)>0 then
                          for q in FileList do
                          begin
                            tmpFileName:=ExtractFileName(q);
                            r:=pos('_',tmpFileName);
                            if r>0 then
                            begin
                              ArchFragment.FileName:=q;
                              ArchFragment.BeginMillisecond:=StrToInt64Def(copy(tmpFileName,1,r-1),-1);
                              if ArchFragment.BeginMillisecond>-1 then
                              begin
                                w:=pos('.',tmpFileName);
                                if w>0 then
                                begin
                                  ArchFragment.EndMillisecond:=StrToInt64Def(copy(tmpFileName,r+1,w-1-r),-1);
                                  if ArchFragment.EndMillisecond>-1 then
                                  begin
                                    FragmentArray:=[];
                                    r:=result*100000000+trunc(ADateTime)*100+StrToIntDef(ExtractFileName(tmpCameraFolder),0);
                                    Fragment.TryGetValue(r,FragmentArray);
                                    FragmentArray:=FragmentArray+[ArchFragment];
                                    Fragment.AddOrSetValue(r,FragmentArray);
                                  end;
                                end;
                              end;
                            end;
                          end;
                      end;
                    end;
                  end;
              until FindNext(TS)<>0;
            finally
              SysUtils.FindClose(TS);
            end;
        end;
      end;
    end
    else
      SendErrorMsg('TArchManager.Add 243: '+SysErrorMessage(GetLastError));
  except on e: EIdSocketError do
    SendErrorMsg('TArchManager.Add 245: EIdSocketError '+IntToStr(e.LastError)+' - '+e.Message);
  on e: Exception do
    SendErrorMsg('TArchManager.Add 247: '+e.ClassName+' - '+e.Message);
  end;
end;

function TArchManager.CamerasList(AIndex: integer): string;
begin
  EnterCriticalSection(FLock);
  try
    result:=DoGetCamerasList(AIndex);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.CameraExists(AIndex, ACamera: integer): boolean;
begin
  EnterCriticalSection(FLock);
  try
    result:=DoGetCameraExists(AIndex,ACamera);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.CameraExists(AAddress: string; ACamera: integer): boolean;
var
  q: integer;
begin
  EnterCriticalSection(FLock);
  try
    result:=false;
    q:=IndexOf(AAddress);
    if q>=0 then
       result:=DoGetCameraExists(q,ACamera)
    else
      SendErrorMsg('TArchManager.CameraExists 260: неизвестный сервер '+AAddress);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.CameraName(AServer, ACamera: integer): string;
var
  ServerShort: TServerShort;
  q: integer;
begin
  result:='';
//  EnterCriticalSection(FLock);
//  try
  if AServer<Count then
  begin
    ServerShort:=TServerShort(Objects[AServer]);
    if assigned(ServerShort) then
    begin
      result:=ServerShort.Cameras.Values[IntToStr(ACamera)];
      q:=Pos(';',result);
      if q>0 then
        System.Delete(result,q,16);
    end;
  end;
//  finally
//    LeaveCriticalSection(FLock);
//  end;
end;

function TArchManager.CamerasList(AAddress: string): string;
var
  q: integer;
begin
  EnterCriticalSection(FLock);
  try
    result:='';
    q:=IndexOf(AAddress);
    if q>=0 then
       result:=DoGetCamerasList(q)
    else
      SendErrorMsg('TArchManager.CamerasList 277: неизвестный сервер '+AAddress);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TArchManager.ClearTodayCache(AServer: integer);
var
  Keys: TArray<integer>;
  Key: integer;
begin
  Keys:=TodayRequest.Keys.ToArray;
  for Key in Keys do
    if (Key div 1000)=AServer then
      TodayRequest.Remove(Key);
end;

constructor TArchManager.Create;
var
  AFMask,w: integer;
begin
  inherited Create;
  TCacheClear.Create(false);
  tmpDir:=ExtractFilePath(ParamStr(0))+'tmp\';
  ForceDirectories(tmpDir);
  InitializeCriticalSection(FLock);
  Content:=TDictionary<string, TDayContent>.Create;
  idhttpWeb:=TIdHTTP.Create(nil);
  Fragment:=TDictionary<integer, TFragmentArray>.Create;
  TodayRequest:=TDictionary<integer, TDateTime>.Create;
  OwnsObjects:=true;
  //запрет на использование ядра 0
  if System.CPUCount>2 then
  begin
    //значение маски=(2 в_степени <кол-во_процессоров> - 2)
    //(14 для 4 ядер; 62 для 6; 254 для 8 и т.д.)
    AFMask:=2;
    for w:=2 to System.CPUCount do
      AFMask:=AFMask*2;
    AFMask:=AFMask-2;
    SetProcessAffinityMask(GetCurrentProcess,AFMask);
  end;
end;

function TArchManager.DayContent(AIndex, ACamera, ADay: integer; AType: byte): TDayContent;
begin
  EnterCriticalSection(FLock);
  try
    Result:=DoGetDayContent(AIndex, ACamera, ADay,AType);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.DayContent(AAddress: string; ACamera, ADay: integer; AType: byte): TDayContent;
var
  q: integer;
begin
  EnterCriticalSection(FLock);
  try
    result:=[];
    q:=IndexOf(AAddress);
    if q>=0 then
      result:=DoGetDayContent(q,ACamera,ADay, AType)
    else
      SendErrorMsg('TArchManager.DayContent 342: неизвестный сервер '+AAddress);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.DaysList(AAddress: string): TIntegerDynArray;
var
  q: integer;
begin
  EnterCriticalSection(FLock);
  try
    result:=[];
    q:=IndexOf(AAddress);
    if q>=0 then
      result:=DoGetDaysList(q)
    else
      SendErrorMsg('TArchManager.DaysList 359: неизвестный сервер '+AAddress);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.DaysList(AIndex: integer): TIntegerDynArray;
begin
  EnterCriticalSection(FLock);
  try
    Result:=DoGetDaysList(AIndex);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

destructor TArchManager.Destroy;
var
  q: integer;
  ServerShort: TServerShort;
begin
  if assigned(TodayRequest) then
    TodayRequest.Free;
  if assigned(Fragment) then
    Fragment.Free;
  if assigned(idhttpWeb) then
    FreeAndNil(idhttpWeb);
  if assigned(Content) then
    FreeAndNil(Content);
  for q := 0 to Count-1 do
  begin
    ServerShort:=TServerShort(Objects[q]);
    if assigned(ServerShort) then
      FreeAndNil(ServerShort);
  end;
  DeleteCriticalSection(FLock);
  inherited;
end;

function TArchManager.DoGetCameraExists(AIndex, ACamera: integer): boolean;
var
  ServerShort: TServerShort;
begin
  ServerShort:=TServerShort(Objects[AIndex]);
  result:=assigned(ServerShort)and(ServerShort.Cameras.IndexOfName(IntToStr(ACamera))>-1);
end;

function TArchManager.DoGetCamerasList(AIndex: integer): string;
var
  ServerShort: TServerShort;
begin
  result:='';
  if AIndex<GetCount then
  begin
    ServerShort:=TServerShort(Objects[AIndex]);
    if assigned(ServerShort) then
      result:=trim(ServerShort.Cameras.Text);
  end;
end;

function TArchManager.DoGetDayContent(AIndex, AID_Camera, ADay: integer; AType: byte): TDayContent;
var
  ServerShort: TServerShort;
  q,w,NowDay: integer;
  tmpFileName: TFileName;
  sl: TStringList;
  s, dayString, todayString: string;
  ContentFragment: TContentFragment;
  CurContent: TDayContent;
  Can: boolean;
  tmpDateTime: TDateTime;
begin
  result:=[];
  if AIndex<Count then
  begin
    ServerShort:=TServerShort(Objects[AIndex]);
    if assigned(ServerShort) then
    begin
      q:=ServerShort.Cameras.IndexOfName(IntToStr(AID_Camera));
      if q>-1 then
      begin
        dayString:=IntToStr(ADay);
        if Content.TryGetValue(dayString+'_'+Strings[AIndex]+'_'+IntToStr(AID_Camera)+'_'+IntToStr(AType),CurContent) then
          result:=CurContent
        else
        begin
          todayString:=FormatDateTime('yymmdd',now);
          tmpFileName:=tmpDir+Strings[AIndex]+'\';
          ForceDirectories(tmpFileName);
          tmpFileName:=tmpFileName+IntToStr(AID_Camera)+'_'+IntToStr(ADay)+'.day';
          Can:=not FileExists(tmpFileName);
          if not Can then
          begin
            NowDay:=trunc(Now);
            NowDay:=(YearOf(NowDay)-2000)*10000+MonthOf(NowDay)*100+DayOf(NowDay);
            //сегодняшний день перезапрашивать не чаще раза в 3 минуты
            if (ADay=NowDay) and TodayRequest.TryGetValue(AIndex*1000+AID_Camera,tmpDateTime) then
                Can:=SecondsBetween(tmpDateTime,now)>180;
          end;
          if Can then
          begin
            if assigned(ServerShort.DataDM) then
              s:=ServerShort.DataDM.IndexByDayAndCamera(ADay,AID_Camera)
            else
              s:=idhttpWeb.Get('http://'+Strings[AIndex]+'/?content='+dayString+'&camera='+IntToStr(AID_Camera));
            if s='' then
              SendErrorMsg('TArchManager.DoGetDayContent 450: AIndex='+IntToStr(AIndex)+', ACamera='+IntToStr(AID_Camera)+', ADay='+dayString+' - пустой ответ по наполненности')
            else
            begin
              sl:=TStringList.Create;
              try
                sl.Text:=s;
                sl.SaveToFile(tmpFileName);
              finally
                FreeAndNil(sl);
              end;
              TodayRequest.AddOrSetValue(AIndex*1000+AID_Camera,now);
            end;
          end;
          if FileExists(tmpFileName) then
          begin
            sl:=TStringList.Create;
            try
              sl.LoadFromFile(tmpFileName);
              if AType>0 then
                while (sl.Count>0)and(sl[0]<>'--') do
                  sl.Delete(0);
              if (sl.Count>0)and(sl[0]='--') then
                sl.Delete(0);
              if AType>1 then
                while (sl.Count>0)and(sl[0]<>'--') do
                  sl.Delete(0);
              if (sl.Count>0)and(sl[0]='--') then
                sl.Delete(0);
              for w:=0 to sl.Count-1 do
              begin
                s:=sl[w];
                if s<>'' then
                begin
                  if s='--' then
                    break;
                  q:=pos('-',s);
                  if q>0 then
                  begin
                    ContentFragment.BeginSecond:=StrToIntDef(copy(s,1,q-1),0);
                    ContentFragment.EndSecond:=StrToIntDef(copy(s,q+1,5),0);
                  end
                  else
                  begin
                    ContentFragment.BeginSecond:=StrToIntDef(s,0);
                    ContentFragment.EndSecond:=ContentFragment.BeginSecond;
                  end;
                  if AType=2 then
                    ContentFragment.Message:=sl.ValueFromIndex[w];
                  result:=result+[ContentFragment];
                end;
              end;
              if (dayString<>todayString) or (AType=2) then
                Content.AddOrSetValue(dayString+'_'+Strings[AIndex]+'_'+IntToStr(AID_Camera)+'_'+IntToStr(AType),result);
            finally
              FreeAndNil(sl);
            end;
          end;
        end;
      end
      else
        SendErrorMsg('TArchManager.DoGetDayContent 509: неизвестная камера '+IntToStr(AID_Camera)+' на сервере '+Strings[AIndex]);
    end;
  end
  else
    SendErrorMsg('TArchManager.DoGetDayContent 513: неизвестный сервер '+IntToStr(AIndex));
end;

function TArchManager.DoGetDaysList(AIndex: integer): TIntegerDynArray;
var
  ServerShort: TServerShort;
begin
  ServerShort:=TServerShort(Objects[AIndex]);
  if assigned(ServerShort) then
    result:=ServerShort.Days
  else
    result:=[];
end;

function TArchManager.DoGetVideo(AIndex, ACamera: integer; ADateTime: TDateTime; NextType: TNextType; APrimary: boolean): TFileName;
var
  tmpFileName: TFileName;
  tmpStream: TMemoryStream;
  ArchFragment: TArchFragment;
  FragmentArray: TFragmentArray;
  q,w,tmpDay,FragmentIndex: integer;
  curMillisecond: int64;
  ServerShort: TServerShort;
begin
  result:='';
  if DoGetVideoExist(AIndex, ACamera, ADateTime) then
  begin
    FragmentIndex:=AIndex*100000000+trunc(ADateTime)*100+ACamera;
    if not APrimary then
      FragmentIndex:=-FragmentIndex;
    if Fragment.TryGetValue(FragmentIndex,FragmentArray) then
    begin
      curMillisecond:=MilliSecondsBetween(UnixDateDelta,ADateTime);
      if NextType=ntNext then
        curMillisecond:=curMillisecond+200
      else if NextType=ntPrior then
        curMillisecond:=curMillisecond-200;
      for ArchFragment in FragmentArray do
        if (ArchFragment.BeginMillisecond<=curMillisecond)and(ArchFragment.EndMillisecond>=curMillisecond) then
          if FileExists(ArchFragment.FileName) then
          begin
            result:=ArchFragment.FileName;
            exit;
          end;
    end;
    ServerShort:=TServerShort(Objects[AIndex]);
    if assigned(ServerShort.DataDM) then
      tmpFileName:=ServerShort.DataDM.GetFragment(MilliSecondsBetween(UnixDateDelta,ADateTime),ACamera,NextType,APrimary)
    else
    begin
      tmpFileName:='http://'+Strings[AIndex]+'/?video='+IntToStr(MilliSecondsBetween(UnixDateDelta,ADateTime))+'&camera='+IntToStr(ACamera)+
          '&next='+ IntToStr(integer(NextType));
      if not APrimary then
        tmpFileName:=tmpFileName+'&primary=0';
      tmpStream:=TMemoryStream.Create;
      try
        idhttpWeb.Get(tmpFileName,tmpStream);
        if tmpStream.Size>32 then
        begin
          tmpFileName:=idhttpWeb.Response.ContentDisposition;
          q:=pos('filename="',tmpFileName);
          if q>0 then
          begin
            System.Delete(tmpFileName,1,q+9);
            System.Delete(tmpFileName,33,1024);
            tmpDay:=(YearOf(ADateTime)-2000)*10000+MonthOf(ADateTime)*100+DayOf(ADateTime);
            if APrimary then
              tmpFileName:=ExtractFilePath(ParamStr(0))+'tmp\'+Strings[AIndex]+'\'+IntToStr(tmpDay)+'\'+IntToStr(ACamera)+'\'+tmpFileName
            else
              tmpFileName:=ExtractFilePath(ParamStr(0))+'tmp\'+Strings[AIndex]+'\'+IntToStr(tmpDay)+'\'+IntToStr(ACamera)+'_2\'+tmpFileName;
            ForceDirectories(ExtractFilePath(tmpFileName));
            tmpStream.SaveToFile(tmpFileName);
          end;
        end;
      finally
        FreeAndNil(tmpStream);
      end;
    end;
    if FileExists(tmpFileName) then
    begin
      ArchFragment.FileName:=tmpFileName;
      result:=tmpFileName;
      tmpFileName:=ExtractFileName(tmpFileName);
      q:=pos('_',tmpFileName);
      if q>0 then
      begin
        ArchFragment.BeginMillisecond:=StrToInt64Def(copy(tmpFileName,1,q-1),-1);
        if ArchFragment.BeginMillisecond>-1 then
        begin
          w:=pos('.',tmpFileName);
          if w>0 then
          begin
            ArchFragment.EndMillisecond:=StrToInt64Def(copy(tmpFileName,q+1,w-1-q),-1);
            if ArchFragment.EndMillisecond>-1 then
            begin
              FragmentArray:=[];
              FragmentIndex:=AIndex*100000000+trunc(ADateTime)*1000+ACamera;
              if not APrimary then
                FragmentIndex:=-FragmentIndex;
              Fragment.TryGetValue(FragmentIndex,FragmentArray);
              FragmentArray:=FragmentArray+[ArchFragment];
              Fragment.AddOrSetValue(FragmentIndex,FragmentArray);
            end;
          end;
        end
      end;
    end;
  end;
end;

function TArchManager.DoGetVideoExist(AIndex, ACamera: integer; ADateTime: TDateTime): boolean;
var
  DayContent: TDayContent;
  ContentFragment: TContentFragment;
  NeedSecond,tmpDay: integer;
begin
  result:=false;
  tmpDay:=(YearOf(ADateTime)-2000)*10000+MonthOf(ADateTime)*100+DayOf(ADateTime);
  DayContent:=DoGetDayContent(AIndex,ACamera,tmpDay,0);
  if length(DayContent)>0 then
  begin
    NeedSecond:=SecondOfTheDay(ADateTime);
    for ContentFragment in DayContent do
      if (NeedSecond>=ContentFragment.BeginSecond)and(NeedSecond<=ContentFragment.EndSecond) then
      begin
        result:=true;
        break;
      end;
  end;
end;

function TArchManager.GetAlarmByPoint(AIndex, AID_Camera: integer; ADateTime: TDateTime): string;
var
  CurContent: TDayContent;
  ADay,tmpSecond: integer;
  ContentFragment: TContentFragment;
  tmpKey: string;
begin
  EnterCriticalSection(FLock);
  try
    ADay:=(YearOf(ADateTime)-2000)*10000+MonthOf(ADateTime)*100+DayOf(ADateTime);
    tmpKey:=IntToStr(ADay)+'_'+Strings[AIndex]+'_'+IntToStr(AID_Camera)+'_2';
    if Content.TryGetValue(tmpKey,CurContent) then
    begin
      tmpSecond:=SecondOfTheDay(ADateTime);
      for ContentFragment in CurContent do
        if (ContentFragment.BeginSecond<=tmpSecond)and(ContentFragment.EndSecond>=tmpSecond) then
        begin
          result:=ContentFragment.Message;
          break;
        end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.GetSlideByPoint(AIndex, AID_Camera: integer; ADateTime: TDateTime): string;
var
  ADay,tmpSecond,w,q: integer;
  tmpStream: TMemoryStream;
  ServerShort: TServerShort;
begin
  EnterCriticalSection(FLock);
  try
    ADay:=(YearOf(ADateTime)-2000)*10000+MonthOf(ADateTime)*100+DayOf(ADateTime);
    ServerShort:=TServerShort(Objects[AIndex]);
    if assigned(ServerShort.DataDM) then
    begin
      q:=SecondOfTheDay(ADateTime);
      w:=q mod 10;
      q:=q-w;
      if w>=5 then
        q:=q+10;
      DataDM.tArchive.Open;
      DataDM.tArchive.First;
      result:=DataDM.tArchive.FieldByName('Path').AsString+'\'+IntToStr(ADay)+'\'+IntToStr(AID_Camera)+'_0\'+IntToStr(q)+'.jpg';
    end
    else
    begin
      //выясняем имя файла
      result:=ExtractFilePath(ParamStr(0))+'tmp\'+Strings[AIndex]+'\'+IntToStr(ADay)+'\'+IntToStr(AID_Camera)+'_0\';
      tmpSecond:=SecondOfTheDay(ADateTime);
      w:=tmpSecond mod 10;
      tmpSecond:=tmpSecond-w;
      if w>=5 then
        tmpSecond:=tmpSecond+10;
      //результат - имя файла
      result:=result+IntToStr(tmpSecond)+'.jpg';
      //ищем файл в кэше
      if not FileExists(result) then
      begin
        //нет - просим у сервера
        tmpStream:=TMemoryStream.Create;
        try
          idhttpWeb.Get('http://'+Strings[AIndex]+'/?slide='+IntToStr(MilliSecondsBetween(UnixDateDelta,ADateTime))+'&camera='+IntToStr(AID_Camera),tmpStream);
          if tmpStream.Size>32 then
          begin
            ForceDirectories(ExtractFilePath(result));
            tmpStream.SaveToFile(result);
          end;
        finally
          tmpStream.Free;
        end;
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.Video(AIndex, ACamera: integer; ADateTime: TDateTime; NextType: TNextType; APrimary: boolean): TFileName;
begin
  EnterCriticalSection(FLock);
  try
    result:=DoGetVideo(AIndex,ACamera,ADateTime,NextType,APrimary);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.VideoExist(AAddress: string; ACamera: integer; ADateTime: TDateTime): boolean;
var
  q: integer;
begin
  EnterCriticalSection(FLock);
  try
    result:=false;
    q:=IndexOf(AAddress);
    if q>=0 then
      result:=DoGetVideoExist(q,ACamera,ADateTime)
    else
      SendErrorMsg('TArchManager.VideoExist 717: неизвестный сервер '+AAddress);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TArchManager.VideoExist(AIndex, ACamera: integer; ADateTime: TDateTime): boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result:=DoGetVideoExist(AIndex, ACamera, ADateTime);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

end.
