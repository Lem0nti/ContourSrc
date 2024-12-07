unit ccData_DM;

interface

uses
  System.SysUtils, System.Classes, cDBConnector_DM, Data.DB, Data.Win.ADODB, Types, ABL.Core.Debug,
  Generics.Collections, Variants, Windows, DateUtils, ccStatusBox_FM, IOUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

type
  TDataDM = class(TDBConnectorDM)
    tCameraMS: TADOTable;
    tCameraMSID_Camera: TAutoIncField;
    tCameraMSConnectionString: TStringField;
    tCameraMSSecondary: TStringField;
    tCameraMSName: TStringField;
    tCameraMSActive: TBooleanField;
    tCameraMSSchedule_Type: TIntegerField;
    tCameraMSDeleted: TBooleanField;
    tScheduleMS: TADOTable;
    tScheduleMSID_Schedule: TAutoIncField;
    tScheduleMSID_Camera: TIntegerField;
    tScheduleMSDay: TIntegerField;
    tScheduleMSSBegin: TIntegerField;
    tScheduleMSSEnd: TIntegerField;
    tArchiveMS: TADOTable;
    tArchiveMSID_Archive: TAutoIncField;
    tArchiveMSPath: TStringField;
    tArchiveMSActive: TBooleanField;
    tArchivePG: TFDTable;
    tCameraPG: TFDTable;
    tSchedulePG: TFDTable;
    tPluginMS: TADOTable;
    tPluginMSID_Plugin: TAutoIncField;
    tPluginMSName: TStringField;
    tPluginMSFileName: TStringField;
    tPluginMSPictureType: TIntegerField;
    tPluginPG: TFDTable;
    tPlugin_CameraPG: TFDTable;
    tPlugin_CameraMS: TADOTable;
    tPlugin_CameraMSID_Plugin_Camera: TAutoIncField;
    tPlugin_CameraMSID_Plugin: TIntegerField;
    tPlugin_CameraMSID_Camera: TIntegerField;
    tPlugin_CameraMSAPrimary: TBooleanField;
    spPluginCameraMS: TADOStoredProc;
    spPluginParam: TADOStoredProc;
    spPluginCameraMSID_Camera: TIntegerField;
    spPluginCameraMSName: TStringField;
    spPluginCameraMSAPrimary: TBooleanField;
    spPluginParamID_Plugin_Param: TAutoIncField;
    spPluginParamParam: TStringField;
    spPluginParamValue: TStringField;
    spUpdatePluginCameraMS: TADOStoredProc;
    spPluginCameraMSConnectionString: TStringField;
    spPluginCameraMSSecondary: TStringField;
    spPluginCameraPG: TFDQuery;
    spPluginCameraMSChecked: TBooleanField;
    spCameraPluginMS: TADOStoredProc;
    spCameraPluginMSID_Plugin: TIntegerField;
    spCameraPluginMSName: TStringField;
    spCameraPluginPG: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure tCameraPGAfterPost(DataSet: TDataSet);
    procedure tCameraPGAfterDelete(DataSet: TDataSet);
  private
    { Private declarations }
  protected
    procedure Init; override;
  public
    { Public declarations }
    tArchive,tCamera,tSchedule: TDataSet;
    IsUserAdmin: boolean;
    LastErrorMessage: string;
    procedure AddCamera;
    procedure ArchiveUpdate(APath: string; IsActive: boolean);
    function CameraPluginDataSet: TDataSet;  //плугины камеры
    procedure DeleteCurrentCamera(ADropArchive: boolean);
    function ExecSQL(ASQL: string): boolean;
    function DBVersion: string;
    procedure OpenCameraPlugin(AID_Camera: integer);
    procedure OpenPluginCamera(AID_Plugin: integer);
    function PluginDataSet: TDataSet;
    function PluginCameraDataSet: TDataSet;  //камеры плугина
    procedure UpdatePluginCamera(AID_Camera,AID_Plugin: integer; AConnect: boolean);
  end;

var
  DataDM: TDataDM;

const
  // Константы для работы с Windows
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS     = $00000220;

function IfThen(ACondition: boolean; ATrue: string; AFalse: string=''): string;
function IsUserWindowsAdmin: Boolean;
//procedure ScrollCallback(AID_Camera: integer; ADateTime: int64); stdcall;

implementation

function IfThen(ACondition: boolean; ATrue: string; AFalse: string=''): string;
begin
  if ACondition then
    Result:=ATrue
  else
    Result:=AFalse;
end;

function IsUserWindowsAdmin: Boolean;
var
  hAccessToken: THandle;
  ptgGroups: PTokenGroups;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  g: Integer;
  bSuccess: BOOL;
begin
  Result:= False;
  bSuccess:= OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
  if (not bSuccess) and (GetLastError=ERROR_NO_TOKEN) then
    bSuccess:=OpenProcessToken(GetCurrentProcess,TOKEN_QUERY,hAccessToken);
  if bSuccess then
  begin
    GetMem(ptgGroups, 1024);
    try
      bSuccess:= GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize);
      CloseHandle(hAccessToken);
      if bSuccess then
      begin
        AllocateAndInitializeSid(SECURITY_NT_AUTHORITY,2,SECURITY_BUILTIN_DOMAIN_RID,DOMAIN_ALIAS_RID_ADMINS,0,0,0,0,0,0,psidAdministrators);
        {$R-}
        for g:= 0 to ptgGroups.GroupCount - 1 do
          if EqualSid(psidAdministrators, ptgGroups.Groups[g].Sid) then
          begin
            Result:= True;
            Break;
          end;
        {$R+}
        FreeSid(psidAdministrators);
      end;
    finally
      FreeMem(ptgGroups);
    end;
  end;
end;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDataDM.AddCamera;
var
  q: integer;
begin
  if FConnectionString.Values['Type']='PG' then
  begin
    QueryPG.Close;
    QueryPG.SQL.Text:='insert into Camera (ConnectionString,Secondary,Name,Active,Schedule_Type,Deleted) values ('''','''','''',false,4,false) RETURNING ID_Camera';
    QueryPG.Open;
    q:=QueryPG.Fields[0].AsInteger;
    QueryPG.SQL.Text:='update Camera set Name=''Camera '+IntToStr(q)+''' where ID_Camera='+IntToStr(q);
    QueryPG.Close;
    QueryPG.ExecSQL;
    tCameraPG.Close;
    tCameraPG.Open;
    tCameraPG.Locate('ID_Camera',q);
  end
  else
  begin
    tCameraMS.Append;
    tCameraMSName.Value:=' ';
    tCameraMSActive.Value:=false;
    tCameraMSDeleted.Value:=false;
    tCameraMSSchedule_Type.Value:=4;
    tCameraMSConnectionString.Value:='';
    tCameraMS.Post;
    tCameraMS.Edit;
    tCameraMSName.AsString:='Camera '+DataDM.tCameraMSID_Camera.AsString;
    tCameraMS.Post;
  end;
end;

procedure TDataDM.ArchiveUpdate(APath: string; IsActive: boolean);
begin
  if FConnectionString.Values['Type']='PG' then
  begin
    QueryPG.Close;
    QueryPG.SQL.Text:= 'SELECT ID_Archive FROM Archive WHERE Path LIKE ''' + APath + '%''';
    QueryPG.Open;
    if QueryPG.IsEmpty then
      QueryPG.SQL.Text:= Format('INSERT INTO Archive (Path, Active) VALUES (''%s\Video'', %s)', [APath, ifthen(IsActive,'true','false')])
    else
      QueryPG.SQL.Text:= Format('UPDATE Archive SET Active = %s WHERE ID_Archive = %d', [ifthen(IsActive,'true','false'), QueryPG.Fields[0].AsInteger]);
    QueryPG.Close;
    QueryPG.ExecSQL;
  end
  else
  begin
    QueryMS.Close;
    QueryMS.SQL.Text:= 'SELECT ID_Archive FROM Archive WHERE Path LIKE ''' + APath + '%''';
    QueryMS.Open;
    if QueryMS.IsEmpty then
      QueryMS.SQL.Text:= Format('INSERT INTO Archive (Path, Active) VALUES (''%s\Video'', %d)', [APath, Integer(IsActive)])
    else
      QueryMS.SQL.Text:= Format('UPDATE Archive SET Active = %d WHERE ID_Archive = %d', [Integer(IsActive), QueryMS.Fields[0].AsInteger]);
    QueryMS.Close;
    QueryMS.ExecSQL;
  end;
end;

function TDataDM.CameraPluginDataSet: TDataSet;
begin
  if FConnectionString.Values['Type']='PG' then
    result:=spCameraPluginPG
  else
    result:=spCameraPluginMS;
end;

procedure TDataDM.DataModuleCreate(Sender: TObject);
begin
  inherited;
  IsUserAdmin:=IsUserWindowsAdmin;
end;

function TDataDM.DBVersion: string;
var
  Query: TDataSet;
begin
  if Connected then
  begin
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:=
          'select substring(Data,1,1)||''.''||cast(cast(substring(Data,2,2) as int) as varchar)||''.''||cast(cast(substring(Data,4,2) as int) as varchar) from Config '+
          'where Category=''Main'' and Name=''Version''';
      Query:=QueryPG;
    end
    else
    begin
      QueryMS.Close;
      QueryMS.SQL.Text:='select substring(Data,1,1)+''.''+cast(cast(substring(Data,2,2) as int) as varchar)+''.''+'+
          'cast(cast(substring(Data,4,2) as int) as varchar) from Config where Category=''Main'' and Name=''Version''';
      Query:=QueryMS;
    end;
    try
      Query.Open;
      result:=FConnectionString.Values['Type']+' '+Query.Fields[0].AsString;
    except on e: Exception do
      begin
        result:='TDataDM.DBVersion 177: '+e.ClassName+' - '+e.Message;
        SendErrorMsg(result);
      end;
    end;
  end;
end;

procedure TDataDM.DeleteCurrentCamera(ADropArchive: boolean);
var
  lListDay: TStringList;
  i: integer;
  sID_Camera,lPath: string;
  Query: TDataSet;
begin
  if ADropArchive then
  begin
    sID_Camera:=tCamera.FieldByName('ID_Camera').AsString;
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='select distinct a.Path||''\''||TO_CHAR(TO_TIMESTAMP(v.SEnd / 1000), ''YYMMDD'')||''\''||v.ID_Camera as VDay from Video v inner join Archive a '+
          'on a.ID_Archive=v.ID_Archive where v.ID_Camera='+sID_Camera+' order by VDay';
      Query:=QueryPG;
    end
    else
    begin
      QueryMS.Close;
      QueryMS.SQL.Text:='select a.Path+''\''+CAST(year(v.VDay)-2000 as varchar)+CAST(month(v.VDay) as varchar)+CAST(day(v.VDay) as varchar)+''\'''+sID_Camera+' from'#13#10+
          '    ('#13#10+
          '      select distinct ID_Archive,cast(SEnd/86400000+25567 as datetime) as VDay from Video where ID_Camera='+sID_Camera+#13#10+
          '    ) v inner join Archive a on a.ID_Archive=v.ID_Archive';
      Query:=QueryMS;
    end;
    Query.Open;
    if not Query.IsEmpty then
    begin
      lListDay:=TStringList.Create;
      try
        while not Query.Eof do
        begin
          lListDay.AddObject(Query.Fields[0].AsString,nil);
          Query.Next;
        end;
        StatusBoxFM:=TStatusBoxFM.Create(nil);
        try
          StatusBoxFM.SetMax(lListDay.Count*3 - 1);
          StatusBoxFM.SetStatus('Подготовка удаления...');
          StatusBoxFM.Show;
          for i := 0 to lListDay.Count - 1 do
          begin
            lPath:=lListDay[i];
            StatusBoxFM.SetStatus(Format('Удаление... [%s]', [lPath]));
            if TDirectory.Exists(lPath) then
              TDirectory.Delete(lPath, True);
            StatusBoxFM.SetProgress(i*3+1);
            lPath:=lListDay[i]+'_0';
            StatusBoxFM.SetStatus(Format('Удаление... [%s]', [lPath]));
            if TDirectory.Exists(lPath) then
              TDirectory.Delete(lPath, True);
            StatusBoxFM.SetProgress(i*3+2);
            lPath:=lListDay[i]+'_2';
            StatusBoxFM.SetStatus(Format('Удаление... [%s]', [lPath]));
            if TDirectory.Exists(lPath) then
              TDirectory.Delete(lPath, True);
            StatusBoxFM.SetProgress(i*3+3);
          end;
          StatusBoxFM.SetStatus('Удаление индекса в БД... ');
          if FConnectionString.Values['Type']='PG' then
          begin
            QueryPG.Close;
            QueryPG.SQL.Text:='DELETE FROM Video WHERE ID_Camera = '+sID_Camera;
            QueryPG.ExecSQL;
            QueryPG.SQL.Text:='DELETE FROM Fill WHERE ID_Camera = '+sID_Camera;
            QueryPG.ExecSQL;
          end
          else
          begin
            QueryMS.Close;
            QueryMS.SQL.Text:='DELETE FROM Video WHERE ID_Camera = '+sID_Camera;
            QueryMS.ExecSQL;
            QueryMS.SQL.Text:='DELETE FROM Fill WHERE ID_Camera = '+sID_Camera;
            QueryMS.ExecSQL;
          end;
        finally
          FreeAndNil(StatusBoxFM);
        end;
      finally
        FreeAndNil(lListDay);
      end;
    end;
    Query.Close;
    tCamera.Delete;
  end
  else
  begin
    tCamera.Edit;
    tCamera.FieldByName('Deleted').AsBoolean:=true;
    tCamera.Post;
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
      SendErrorMsg('TDataDM.ExecSQL 43: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.Init;
begin
  if FConnectionString.Values['Type']='PG' then
  begin
    QueryPG.Close;
    QueryPG.Open('SELECT count(*) FROM information_schema.tables where table_name in (''config'',''camera'',''schedule'')');
    if QueryPG.Fields[0].AsInteger=3 then
    begin
      tArchive:=tArchivePG;
      tCamera:=tCameraPG;
      tSchedule:=tSchedulePG;
    end;
  end
  else
  begin
    tArchive:=tArchiveMS;
    tCamera:=tCameraMS;
    tSchedule:=tScheduleMS;
  end
end;

procedure TDataDM.OpenCameraPlugin(AID_Camera: integer);
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      spCameraPluginPG.Close;
      spCameraPluginPG.SQL.Text:='call spCameraPlugin('+IntToStr(AID_Camera)+')';
      spCameraPluginPG.ExecSQL;
    end
    else
    begin
      spCameraPluginMS.Close;
      spCameraPluginMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      spCameraPluginMS.Open;
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.OpenPluginCamera(AID_Plugin: integer);
var
  AfterScroll: TDataSetNotifyEvent;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      AfterScroll:=spPluginCameraPG.AfterScroll;
      spPluginCameraPG.AfterScroll:=nil;
      spPluginCameraPG.Close;
      spPluginCameraPG.SQL.Text:='call spPluginCamera('+IntToStr(AID_Plugin)+')';
      spPluginCameraPG.ExecSQL;
      spPluginCameraPG.AfterScroll:=AfterScroll;
    end
    else
    begin
      AfterScroll:=spPluginCameraMS.AfterScroll;
      spPluginCameraMS.AfterScroll:=nil;
      spPluginCameraMS.Close;
      spPluginCameraMS.Parameters.ParamByName('AID_Plugin').Value:=AID_Plugin;
      spPluginCameraMS.Open;
      spPluginCameraMS.AfterScroll:=AfterScroll;
    end;
    if @AfterScroll<>nil then
      if FConnectionString.Values['Type']='PG' then
        AfterScroll(spPluginCameraPG)
      else
        AfterScroll(spPluginCameraMS);
  finally
    Unlock;
  end;
end;

function TDataDM.PluginCameraDataSet: TDataSet;
begin
  if FConnectionString.Values['Type']='PG' then
    result:=spPluginCameraPG
  else
    result:=spPluginCameraMS;
end;

function TDataDM.PluginDataSet: TDataSet;
begin
  if FConnectionString.Values['Type']='PG' then
    result:=tPluginPG
  else
    result:=tPluginMS;
end;

procedure TDataDM.tCameraPGAfterDelete(DataSet: TDataSet);
begin
  tCameraPG.ApplyUpdates;
  tCameraPG.CommitUpdates;
end;

procedure TDataDM.tCameraPGAfterPost(DataSet: TDataSet);
begin
  tCameraPG.ApplyUpdates;
end;

procedure TDataDM.UpdatePluginCamera(AID_Camera, AID_Plugin: integer; AConnect: boolean);
var
  DataSet: TDataSet;
  AfterScroll: TDataSetNotifyEvent;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='call spUpdatePluginCamera('+IntToStr(AID_Camera)+','+IntToStr(AID_Plugin)+','+BoolToStr(AConnect,true)+')';
      QueryPG.ExecSQL;
    end
    else
    begin
      spUpdatePluginCameraMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      spUpdatePluginCameraMS.Parameters.ParamByName('AID_Plugin').Value:=AID_Plugin;
      spUpdatePluginCameraMS.Parameters.ParamByName('AConnect').Value:=AConnect;//ifthen(AConnect,'1','0');
      spUpdatePluginCameraMS.ExecProc;
    end;
    DataSet:=PluginCameraDataSet;
    DataSet.Close;
    AfterScroll:=DataSet.AfterScroll;
    DataSet.AfterScroll:=nil;
    try
      DataSet.Open;
      DataSet.Locate('ID_Camera',AID_Camera,[]);
    finally
      DataSet.AfterScroll:=AfterScroll;
    end;
  finally
    Unlock;
  end;
end;

end.
