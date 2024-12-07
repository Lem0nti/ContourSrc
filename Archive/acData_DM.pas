unit acData_DM;

interface

uses
  SysUtils, System.Classes, cDBConnector_DM, Data.DB, Data.Win.ADODB, Types, ABL.Core.Debug,
  Generics.Collections, Variants, Windows, DateUtils, acTypes, ABL.Core.TimerThread, Math, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, FireDAC.Comp.Client,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

type
  TContentCacheClear=class(TTimerThread)
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    constructor Create; reintroduce;
  end;

  TDataDM = class(TDBConnectorDM)
    spCamerasListMS: TADOStoredProc;
    spDaysListMS: TADOStoredProc;
    spIndexByDayAndCameraMS: TADOStoredProc;
    spGetFragmentMS: TADOStoredProc;
    spMotionByDayAndCameraMS: TADOStoredProc;
    spAlarmByDayAndCameraMS: TADOStoredProc;
    tArchiveMS: TADOTable;
    tArchiveMSID_Archive: TAutoIncField;
    tArchiveMSPath: TStringField;
    tArchiveMSActive: TBooleanField;
    tArchivePG: TFDTable;
    tCameraPG: TFDTable;
    tCameraMS: TADOTable;
    tCameraMSID_Camera: TAutoIncField;
    tCameraMSConnectionString: TStringField;
    tCameraMSSecondary: TStringField;
    tCameraMSName: TStringField;
    tCameraMSActive: TBooleanField;
    tCameraMSSchedule_Type: TIntegerField;
    tCameraMSDeleted: TBooleanField;
    fnGetFragmentPG: TFDStoredProc;
    fnCamerasListPG: TFDStoredProc;
    fnDaysListPG: TFDStoredProc;
    fnIndexByDayAndCameraPG: TFDStoredProc;
    fnMotionByDayAndCameraPG: TFDStoredProc;
    fnAlarmByDayAndCameraPG: TFDStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    CamerasList, DaysList: string;
    LastCamerasRequest,LastDaysRequest: TDateTime;
    //день умножить на 1000+камера = индекс для этого списка
    Content: TDictionary<integer, string>;
    { Private declarations }
  protected
    procedure Init; override;
  public
    tArchive: TDataSet;
    { Public declarations }
    LastErrorMessage: string;
    procedure DropCacheBefore(ADay: integer);
    procedure InitializeModule;
    function ExecSQL(ASQL: string): boolean;
    function GetArchList: string;
    function GetCamerasList: string;
    function GetDaysList: string;
    function GetFragment(ADateTime: int64; AID_Camera: integer; ANext: TNextType; APrimary: boolean): TFileName;
    function IndexByDayAndCamera(ADay: integer; AID_Camera: integer): string;
  end;

var
  CacheClear: TContentCacheClear;
  DataDM: TDataDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDataDM.DataModuleCreate(Sender: TObject);
begin
  inherited;
  Content:=TDictionary<integer, string>.Create;
  CacheClear:=TContentCacheClear.Create;
end;

procedure TDataDM.DataModuleDestroy(Sender: TObject);
begin
  CacheClear.Free;
  Content.Free;
  inherited;
end;

procedure TDataDM.DropCacheBefore(ADay: integer);
var
  tmpInteger, tmpDay, TodayFolderName: integer;
begin
  Lock;
  try
    tmpDay:=ADay*1000;
    TodayFolderName:=StrToIntDef(FormatDateTime('YYMMDD',now),999999)*1000;
    for tmpInteger in Content.Keys do
      if (tmpInteger<tmpDay)or(tmpInteger>TodayFolderName) then
        Content.Remove(tmpInteger);
  finally
    Unlock;
  end;
end;

function TDataDM.ExecSQL(ASQL: string): boolean;
begin
  Lock;
  try
    result:=false;
    try
      if FConnectionString.Values['Type']='PG' then
      begin
        QueryPG.Close;
        QueryPG.SQL.Text:=ASQL;
        QueryPG.ExecSQL;
      end
      else
      begin
        QueryMS.Close;
        QueryMS.SQL.Text:=ASQL;
        QueryMS.ExecSQL;
      end;
      result:=true;
    except on e: Exception do
      SendErrorMsg('TDataDM.ExecSQL 114: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.GetArchList: string;
var
  tArchive: TDataSet;
begin
  Lock;
  try
    try
      result:='';
      if FConnectionString.Values['Type']='PG' then
        tArchive:=tArchivePG
      else
        tArchive:=tArchiveMS;
      tArchive.Open;
      try
        tArchive.First;
        while not tArchive.EOF do
        begin
          if tArchive.FieldByName('Active').AsBoolean then
            result:=result+tArchive.FieldByName('Path').AsString+#13#10;
          tArchive.Next;
        end;
      finally
        tArchive.Close;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.GetArchList 127: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.GetCamerasList: string;
begin
  Lock;
  try
    try
      if (CamerasList='') or (SecondsBetween(LastCamerasRequest,now)>30) then
      begin
        if FConnectionString.Values['Type']='PG' then
        begin
          fnCamerasListPG.Close;
          fnCamerasListPG.Open;
          CamerasList:=fnCamerasListPG.Fields[0].AsString;
          fnCamerasListPG.Close;
        end
        else
        begin
          spCamerasListMS.Close;
          spCamerasListMS.Open;
          CamerasList:=spCamerasListMS.Fields[0].AsString;
          spCamerasListMS.Close;
        end;
        LastCamerasRequest:=now;
      end;
      result:=CamerasList;
      if result='' then
        result:=' ';
    except on e: Exception do
      begin
        SendErrorMsg('TDataDM.GetCamerasList 149: '+e.ClassName+' - '+e.Message);
        raise;
      end;
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.GetDaysList: string;
var
  ct: TDateTime;
begin
  Lock;
  try
    ct:=now;
    if (DaysList='') or (MinutesBetween(LastDaysRequest,ct)>30) or (trunc(LastDaysRequest)<>trunc(ct)) then
    begin
      if FConnectionString.Values['Type']='PG' then
      begin
        fnDaysListPG.Close;
        fnDaysListPG.Open;
        DaysList:=fnDaysListPG.Fields[0].AsString;
        fnDaysListPG.Close;
      end
      else
      begin
        spDaysListMS.Close;
        spDaysListMS.Open;
        DaysList:=spDaysListMS.Fields[0].AsString;
        spDaysListMS.Close;
      end;
    end;
    result:=DaysList;
  finally
    Unlock;
  end;
end;

function TDataDM.GetFragment(ADateTime: int64; AID_Camera: integer; ANext: TNextType; APrimary: boolean): TFileName;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      fnGetFragmentPG.Close;
      fnGetFragmentPG.Params.ParamByName('DayPoint').Value:=ADateTime;
      fnGetFragmentPG.Params.ParamByName('AID_Camera').Value:=AID_Camera;
      case ANext of
        ntUsual: fnGetFragmentPG.Params.ParamByName('ANext').Value:=Null;
        ntNext: fnGetFragmentPG.Params.ParamByName('ANext').Value:=true;
        ntPrior: fnGetFragmentPG.Params.ParamByName('ANext').Value:=false;
      end;
      fnGetFragmentPG.Params.ParamByName('APrimary').Value:=APrimary;
      fnGetFragmentPG.Open;
      result:=fnGetFragmentPG.Fields[0].AsString;
      fnGetFragmentPG.Close;
    end
    else
    begin
      spGetFragmentMS.Close;
      spGetFragmentMS.Parameters.ParamByName('DayPoint').Value:=ADateTime;
      spGetFragmentMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      case ANext of
        ntUsual: spGetFragmentMS.Parameters.ParamByName('ANext').Value:=Null;
        ntNext: spGetFragmentMS.Parameters.ParamByName('ANext').Value:=true;
        ntPrior: spGetFragmentMS.Parameters.ParamByName('ANext').Value:=false;
      end;
      spGetFragmentMS.Parameters.ParamByName('APrimary').Value:=APrimary;
      spGetFragmentMS.Open;
      result:=spGetFragmentMS.Fields[0].AsString;
      spGetFragmentMS.Close;
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.IndexByDayAndCamera(ADay, AID_Camera: integer): string;
var
  tmpYear,tmpMonth,tmpDay: word;
  tmpFromDT,tmpToDT: int64;
  dayInteger: integer;
begin
  Lock;
  try
    dayInteger:=ADay*1000+AID_Camera;
    if not Content.TryGetValue(dayInteger,result) then
    begin
      tmpYear:=ADay div 10000;
      tmpMonth:=(ADay div 100)-tmpYear*100;
      tmpDay:=ADay-tmpYear*10000-tmpMonth*100;
      tmpFromDT:=MilliSecondsBetween(UnixDateDelta,EncodeDate(tmpYear+2000,tmpMonth,tmpDay));
      tmpToDT:=tmpFromDT+MSecsPerDay;
      if FConnectionString.Values['Type']='PG' then
      begin
        fnIndexByDayAndCameraPG.Close;
        fnIndexByDayAndCameraPG.Params.ParamByName('FromDT').Value:=tmpFromDT;
        fnIndexByDayAndCameraPG.Params.ParamByName('ToDT').Value:=tmpToDT;
        fnIndexByDayAndCameraPG.Params.ParamByName('AID_Camera').Value:=AID_Camera;
        fnIndexByDayAndCameraPG.Open;
        result:=fnIndexByDayAndCameraPG.Fields[0].AsString;
        fnIndexByDayAndCameraPG.Close;
        fnMotionByDayAndCameraPG.Close;
        fnMotionByDayAndCameraPG.Params.ParamByName('FromDT').Value:=tmpFromDT;
        fnMotionByDayAndCameraPG.Params.ParamByName('ToDT').Value:=tmpToDT;
        fnMotionByDayAndCameraPG.Params.ParamByName('AID_Camera').Value:=AID_Camera;
        fnMotionByDayAndCameraPG.Open;
        result:=result+#13#10'--'#13#10+fnMotionByDayAndCameraPG.Fields[0].AsString;
        fnMotionByDayAndCameraPG.Close;
        fnAlarmByDayAndCameraPG.Close;
        fnAlarmByDayAndCameraPG.Params.ParamByName('FromDT').Value:=tmpFromDT;
        fnAlarmByDayAndCameraPG.Params.ParamByName('ToDT').Value:=tmpToDT;
        fnAlarmByDayAndCameraPG.Params.ParamByName('AID_Camera').Value:=AID_Camera;
        fnAlarmByDayAndCameraPG.Open;
        result:=result+#13#10'--'#13#10+fnAlarmByDayAndCameraPG.Fields[0].AsString;
        fnAlarmByDayAndCameraPG.Close;
      end
      else
      begin
        spIndexByDayAndCameraMS.Close;
        spIndexByDayAndCameraMS.Parameters.ParamByName('FromDT').Value:=tmpFromDT;
        spIndexByDayAndCameraMS.Parameters.ParamByName('ToDT').Value:=tmpToDT;
        spIndexByDayAndCameraMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
        spIndexByDayAndCameraMS.Open;
        result:=spIndexByDayAndCameraMS.Fields[0].AsString;
        spIndexByDayAndCameraMS.Close;
        spMotionByDayAndCameraMS.Close;
        spMotionByDayAndCameraMS.Parameters.ParamByName('FromDT').Value:=tmpFromDT;
        spMotionByDayAndCameraMS.Parameters.ParamByName('ToDT').Value:=tmpToDT;
        spMotionByDayAndCameraMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
        spMotionByDayAndCameraMS.Open;
        result:=result+#13#10'--'#13#10+spMotionByDayAndCameraMS.Fields[0].AsString;
        spMotionByDayAndCameraMS.Close;
        spAlarmByDayAndCameraMS.Close;
        spAlarmByDayAndCameraMS.Parameters.ParamByName('FromDT').Value:=tmpFromDT;
        spAlarmByDayAndCameraMS.Parameters.ParamByName('ToDT').Value:=tmpToDT;
        spAlarmByDayAndCameraMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
        spAlarmByDayAndCameraMS.Open;
        result:=result+#13#10'--'#13#10+spAlarmByDayAndCameraMS.Fields[0].AsString;
        spAlarmByDayAndCameraMS.Close;
      end;
      Content.AddOrSetValue(dayInteger,result);
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.Init;
begin
  if FConnectionString.Values['Type']='PG' then
  begin
    tArchive:=tArchivePG;
  end
  else
  begin
    tArchive:=tArchiveMS;
  end;
end;

procedure TDataDM.InitializeModule;
var
  fn: TFileName;
begin
  Lock;
  try
    try
      if CheckConnection then
      begin
        fn:=ExtractFilePath(ParamStr(0))+'tmp\';
        ForceDirectories(fn);
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.InitializeModule 245: '+e.ClassName+' - '+e.Message);
    end;
    LastCamerasRequest:=0;
  finally
    Unlock;
  end;
end;

{ TCacheClear }

constructor TContentCacheClear.Create;
begin
  inherited Create(nil,nil,'TContentCacheClear');
  Interval:=240000;  //4 минуты
  Enabled:=true;
  Active:=true;
end;

procedure TContentCacheClear.DoExecute;
var
  i: integer;
  DriveType: UINT;
  TS: TSearchRec;
  MinFolderName: integer;
  FolderName: string;
  sl: TStringList;
  MaxOfMin: integer;
begin
  sl:=TStringList.Create;
  try
    sl.Text:=DataDM.GetArchList;
    MaxOfMin:=0;
    for I := 0 to sl.Count-1 do
    begin
      FolderName:=sl[i];
      DriveType:=GetDriveType(PChar(FolderName[1]+':\'));
      if not (DriveType in [0,1]) then
      begin
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
        if MinFolderName>MaxOfMin then
          MaxOfMin:=MinFolderName;
      end;
    end;
    DataDM.DropCacheBefore(MaxOfMin);
  finally
    sl.Free;
  end;
end;

procedure TContentCacheClear.DoReceive(var AInputData: Pointer);
begin

end;

end.
