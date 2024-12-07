unit cData_DM;

interface

uses
  System.SysUtils, System.Classes, cDBConnector_DM, Data.DB, Data.Win.ADODB, Types, ABL.Core.Debug,
  Generics.Collections, Variants, Windows, DateUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

type
  TDataDM = class(TDBConnectorDM)
    tConfigMS: TADOTable;
    spDropArchMS: TADOStoredProc;
    spInsertAlarmMS: TADOStoredProc;
    spInsertMotionMS: TADOStoredProc;
    spInsertVideoMS: TADOStoredProc;
    spInsertLogMS: TADOStoredProc;
    tArchiveMS: TADOTable;
    tCameraMS: TADOTable;
    tScheduleMS: TADOTable;
    tArchiveMSID_Archive: TAutoIncField;
    tArchiveMSPath: TStringField;
    tArchiveMSActive: TBooleanField;
    tCameraMSID_Camera: TAutoIncField;
    tCameraMSConnectionString: TStringField;
    tCameraMSSecondary: TStringField;
    tCameraMSName: TStringField;
    tCameraMSActive: TBooleanField;
    tConfigMSID_Config: TAutoIncField;
    tConfigMSCategory: TStringField;
    tConfigMSName: TStringField;
    tConfigMSData: TMemoField;
    tScheduleMSID_Schedule: TAutoIncField;
    tScheduleMSID_Camera: TIntegerField;
    tScheduleMSDay: TIntegerField;
    tScheduleMSSBegin: TIntegerField;
    tScheduleMSSEnd: TIntegerField;
    spInsertSecondaryVideoMS: TADOStoredProc;
    tCameraMSSchedule_Type: TIntegerField;
    tCameraMSDeleted: TBooleanField;
    tArchivePG: TFDTable;
    tArchivePGID_Archive: TIntegerField;
    tArchivePGPath: TStringField;
    tArchivePGActive: TBooleanField;
    tCameraPG: TFDTable;
    tCameraPGID_Camera: TIntegerField;
    tCameraPGConnectionString: TStringField;
    tCameraPGSecondary: TStringField;
    tCameraPGName: TStringField;
    tCameraPGActive: TBooleanField;
    tCameraPGSchedule_Type: TIntegerField;
    tCameraPGDeleted: TBooleanField;
    tConfigPG: TFDTable;
    tConfigPGID_Config: TIntegerField;
    tConfigPGCategory: TStringField;
    tConfigPGName: TStringField;
    tSchedulePG: TFDTable;
    tConfigPGData: TStringField;
  private
    { Private declarations }
    procedure ExecuteSQLFile(SQLFileName: TFileName);
  public
    { Public declarations }
    LastErrorMessage: string;
    procedure InitializeModule;
    procedure DeleteCamera(AID_Camera: integer);
    function DropArch(ABefore: int64; AID_Archive: integer): boolean;
    function ExecSQL(ASQL: string): boolean;
    function GetArchives: string;
    function GetCamerasByArchive: string;
    function GetCamerasDeleted: string;
    function GetConfigInfo(ACategory, AName, Default: String): String;
    procedure InsertAlarm(AID_Camera: integer; ASBegin, ASEnd: int64; AStartMessage: string);
    procedure InsertLog(AType, ASource_Type, AID_Source: integer; ASTime: int64; AMessage: string);
    procedure InsertMotion(AID_Camera: integer; ASBegin, ASEnd: int64);
    procedure InsertVideo(AID_Archive, AID_Camera: integer; ASBegin, ASEnd: int64; APrimary: boolean);
  end;

var
  DataDM: TDataDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDataDM.DeleteCamera(AID_Camera: integer);
var
  tCamera: TDataSet;
begin
  Lock;
  try
    try
      if FConnectionString.Values['Type']='PG' then
        tCamera:=tCameraPG
      else
        tCamera:=tCameraMS;
      tCamera.Open;
      if tCamera.Locate('ID_Camera',AID_Camera,[]) then
        tCamera.Delete;
    except on e: Exception do
      SendErrorMsg('TDataDM.DeleteCamera 78: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.DropArch(ABefore: int64; AID_Archive: integer): boolean;
begin
  result:=false;
  Lock;
  try
    try
      if FConnectionString.Values['Type']='PG' then
      begin
        QueryPG.Close;
        QueryPG.SQL.Text:='call spDropArch('+IntToStr(ABefore)+','+IntToStr(AID_Archive)+')';
        QueryPG.ExecSQL;
      end
      else
      begin
        spDropArchMS.Parameters.ParamByName('TimeBefore').Value:=ABefore;
        spDropArchMS.Parameters.ParamByName('AID_Archive').Value:=AID_Archive;
        spDropArchMS.ExecProc;
      end;
      result:=true;
    except on e: Exception do
      SendErrorMsg('TDataDM.DropArch 96: '+e.ClassName+' - '+e.Message);
    end;
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

procedure TDataDM.ExecuteSQLFile(SQLFileName: TFileName);
var
  slQry: TStringList;
  j: integer;
begin
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.SQL.LoadFromFile(SQLFileName);
      QueryPG.ExecSQL;
    end
    else
    begin
      slQry:=TStringList.Create;
      try
        slQry.LoadFromFile(SQLFileName);
        for j:=0 to slQry.Count-1 do
          if trim(slQry.Strings[j])='GO' then
            try
              try
                QueryMS.ExecSQL;
              except on e: Exception do
                SendErrorMsg('TDataDM.ExecuteSQLFile 136: '+e.ClassName+' - '+e.Message+#13#10+QueryMS.SQL.Text);
              end;
            finally
              QueryMS.SQL.Clear;
            end
          else
            QueryMS.SQL.AddObject(slQry[j],nil);
      finally
        FreeAndNil(slQry);
      end;
    end;
  except on e: Exception do
    SendErrorMsg('TDataDM.ExecuteSQLFile 147: '+e.ClassName+' - '+e.Message+#13#10+SQLFileName);
  end;
end;

function TDataDM.GetArchives: string;
var
  DList,DDisk: string;
  DriveType: UINT;
  tArchive: TDataSet;
begin
  Lock;
  try
    try
      result:='';
      DList:='';
      if FConnectionString.Values['Type']='PG' then
        tArchive:=tArchivePG
      else
        tArchive:=tArchiveMS;
      tArchive.Open;
      tArchive.First;
      while not tArchive.EOF do
      begin
        if tArchive.FieldByName('Active').AsBoolean then
        begin
          DDisk:=tArchive.FieldByName('Path').AsString;
          DriveType:=GetDriveType(PChar(DDisk[1]+':\'));
          if (Pos(DDisk[1],DList)=0)and(not (DriveType in [0,1,5])) then
          begin
            DList:=DList+DDisk[1];
            if result<>'' then
              result:=result+#13#10;
            if DDisk[length(DDisk)]<>'\' then
              DDisk:=DDisk+'\';
            result:=result+tArchive.FieldByName('ID_Archive').AsString+'='+DDisk;
          end
          else
          begin
            tArchive.Edit;
            tArchive.FieldByName('Active').AsBoolean:=False;
            tArchive.Post;
          end;
        end;
        tArchive.Next;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.GetArchives 189: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.GetCamerasByArchive: string;
var
  Query: TDataSet;
begin
  Lock;
  try
    try
      if FConnectionString.Values['Type']='PG' then
      begin
        QueryPG.Close;
        QueryPG.SQL.Text:='select distinct ID_Camera from Fill';
        QueryPG.Open;
        Query:=QueryPG;
      end
      else
      begin
        QueryMS.Close;
        QueryMS.SQL.Text:='select distinct ID_Camera from Fill';
        QueryMS.Open;
        Query:=QueryMS;
      end;
      while not Query.EOF do
      begin
        if result<>'' then
          result:=result+#13#10;
        result:=result+Query.Fields[0].AsString;
        Query.Next;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.GetCamerasByArchive 212: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.GetCamerasDeleted: string;
var
  tCamera: TDataSet;
begin
  Lock;
  try
    try
      result:='';
      if FConnectionString.Values['Type']='PG' then
        tCamera:=tCameraPG
      else
        tCamera:=tCameraMS;
      tCamera.Open;
      tCamera.First;
      while not tCamera.Eof do
      begin
        if tCamera.FieldByName('Deleted').AsBoolean then
        begin
          if result<>'' then
            result:=result+#13#10;
          result:=result+tCamera.FieldByName('ID_Camera').AsString;
        end;
        tCamera.Next;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.GetCamerasDeleted 238: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.GetConfigInfo(ACategory, AName, Default: String): String;
var
  tConfig: TDataSet;
begin
  if FConnectionString.Values['Type']='PG' then
    tConfig:=tConfigPG
  else
    tConfig:=tConfigMS;
  if not tConfig.Active then
    tConfig.Open;
  if tConfig.Locate('Category;Name',VarArrayOf([ACategory, AName]),[]) then
    result:=tConfig.FieldByName('Data').AsString
  else
    result:=Default;
end;

procedure TDataDM.InitializeModule;
var
  rStream: TResourceStream;
  fStream: TFileStream;
  fn: TFileName;
begin
  Lock;
  try
    try
      if CheckConnection then
      begin
        fn:=ExtractFilePath(ParamStr(0))+'tmp\';
        ForceDirectories(fn);
        fn:=fn+'Create.sql';
        if FileExists(fn) then
          DeleteFile(PChar(fn));
        rStream:=TResourceStream.Create(hInstance,'InstallScript'+FConnectionString.ValueFromIndex[0] ,RT_RCDATA);
        try
          fStream:=TFileStream.Create(fn,fmCreate);
          try
            fStream.CopyFrom(rStream,0);
          finally
            fStream.Free;
          end;
        finally
          rStream.Free;
        end;
        if FileExists(fn) then
        begin
          ExecuteSQLFile(fn);
          DeleteFile(PChar(fn));
        end;
        if FConnectionString.Values['Type']='PG' then
          tConfigPG.Open
        else
          tConfigMS.Open;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.InitializeModule 245: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.InsertAlarm(AID_Camera: integer; ASBegin, ASEnd: int64; AStartMessage: string);
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='call spInsertAlarm('+IntToStr(AID_Camera)+','+IntToStr(ASBegin)+','+IntToStr(ASEnd)+','''+AStartMessage+''')';
      QueryPG.ExecSQL;
    end
    else
    begin
      spInsertAlarmMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      spInsertAlarmMS.Parameters.ParamByName('ASBegin').Value:=ASBegin;
      spInsertAlarmMS.Parameters.ParamByName('ASEnd').Value:=ASEnd;
      spInsertAlarmMS.Parameters.ParamByName('AStartMessage').Value:=AStartMessage;
      spInsertAlarmMS.ExecProc;
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.InsertLog(AType, ASource_Type, AID_Source: integer; ASTime: int64; AMessage: string);
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='call spInsertLog('+IntToStr(AType)+','+IntToStr(ASource_Type)+','+IntToStr(AID_Source)+','+IntToStr(ASTime)+','''+AMessage+''')';
      QueryPG.ExecSQL;
    end
    else
    begin
      spInsertLogMS.Parameters.ParamByName('AType').Value:=AType;
      spInsertLogMS.Parameters.ParamByName('ASource_Type').Value:=ASource_Type;
      spInsertLogMS.Parameters.ParamByName('AID_Source').Value:=AID_Source;
      spInsertLogMS.Parameters.ParamByName('ASTime').Value:=ASTime;
      spInsertLogMS.Parameters.ParamByName('AMessage').Value:=AMessage;
      spInsertLogMS.ExecProc;
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.InsertMotion(AID_Camera: integer; ASBegin, ASEnd: int64);
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='call spInsertMotion('+IntToStr(AID_Camera)+','+IntToStr(ASBegin)+','+IntToStr(ASEnd)+')';
      QueryPG.ExecSQL;
    end
    else
    begin
      spInsertMotionMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      spInsertMotionMS.Parameters.ParamByName('ASBegin').Value:=ASBegin;
      spInsertMotionMS.Parameters.ParamByName('ASEnd').Value:=ASEnd;
      spInsertMotionMS.ExecProc;
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.InsertVideo(AID_Archive, AID_Camera: integer; ASBegin, ASEnd: int64; APrimary: boolean);
var
  ProcMS: TADOStoredProc;
  qry: string;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      qry:='call ';
      if APrimary then
        qry:=qry+'spInsertVideo('
      else
        qry:=qry+'spInsertSecondaryVideo(';
      qry:=qry+IntToStr(AID_Archive)+','+IntToStr(AID_Camera)+',' +IntToStr(ASBegin)+',' +IntToStr(ASEnd)+')';
      QueryPG.Close;
      QueryPG.SQl.Text:=qry;
      QueryPG.ExecSQL;
    end
    else
    begin
      if APrimary then
        ProcMS:=spInsertVideoMS
      else
        ProcMS:=spInsertSecondaryVideoMS;
      ProcMS.Parameters.ParamByName('AID_Archive').Value:=AID_Archive;
      ProcMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      ProcMS.Parameters.ParamByName('ASBegin').Value:=ASBegin;
      ProcMS.Parameters.ParamByName('ASEnd').Value:=ASEnd;
      ProcMS.ExecProc;
    end;
  finally
    Unlock;
  end;
end;

end.
