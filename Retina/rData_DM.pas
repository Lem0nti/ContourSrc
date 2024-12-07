unit rData_DM;

interface

uses
  System.SysUtils, System.Classes, cDBConnector_DM, Data.DB, Data.Win.ADODB, Types, ABL.Core.Debug,
  Generics.Collections, Variants, Windows, DateUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

type
  TDataDM = class(TDBConnectorDM)
    spInsertLogMS: TADOStoredProc;
    tConfigPG: TFDTable;
    tConfigPGID_Config: TIntegerField;
    tConfigPGCategory: TStringField;
    tConfigPGName: TStringField;
    tConfigPGData: TStringField;
    tConfigMS: TADOTable;
    tConfigMSID_Config: TAutoIncField;
    tConfigMSCategory: TStringField;
    tConfigMSName: TStringField;
    tConfigMSData: TMemoField;
    tPluginMS: TADOTable;
    tPluginMSID_Plugin: TAutoIncField;
    tPluginMSName: TStringField;
    tPluginMSFileName: TStringField;
    tPluginMSPictureType: TIntegerField;
    tPluginPG: TFDTable;
    tPluginPGID_Plugin: TIntegerField;
    tPluginPGName: TStringField;
    tPluginPGFileName: TStringField;
    tPluginPGPictureType: TIntegerField;
    qPluginPG: TFDQuery;
    qPluginPGFileName: TStringField;
    qPluginPGID_Camera: TIntegerField;
    qPluginPGAPrimary: TIntegerField;
    qPluginMS: TADOQuery;
  private
    { Private declarations }
    procedure ExecuteSQLFile(SQLFileName: TFileName);
  public
    { Public declarations }
    LastErrorMessage: string;
    procedure InitializeModule;
    function ExecSQL(ASQL: string): boolean;
    function GetConfigInfo(ACategory, AName, Default: String): String;
    procedure InsertLog(AType, ASource_Type, AID_Source: integer; ASTime: int64; AMessage: string);
  end;

var
  DataDM: TDataDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

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
        rStream:=TResourceStream.Create(hInstance,'InstallScript'+FConnectionString.ValueFromIndex[0],RT_RCDATA);
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

end.
