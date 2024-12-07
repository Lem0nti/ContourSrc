unit mdtData_DM;

interface

uses
  System.SysUtils, System.Classes, cDBConnector_DM, Data.DB, Data.Win.ADODB, Types, ABL.Core.Debug,
  Generics.Collections, Variants, Windows, DateUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, sdkCntPlugin_I, Vcl.ExtCtrls;

type
  TDataDM = class(TDBConnectorDM)
    spSaveEventMS: TADOStoredProc;
    spSaveZoneMS: TADOStoredProc;
    spEventsMS: TADOStoredProc;
    qEventsPG: TFDQuery;
    qEventsPGFileName: TStringField;
    qEventsPGID_Camera: TIntegerField;
    qEventsPGAPrimary: TIntegerField;
    tEventsScroll: TTimer;
    spEventByTimeMS: TADOStoredProc;
    spZoneByEventMS: TADOStoredProc;
    qZoneByEventPG: TFDQuery;
    StringField1: TStringField;
    IntegerField1: TIntegerField;
    IntegerField2: TIntegerField;
    procedure spEventsMSAfterOpen(DataSet: TDataSet);
    procedure spEventsMSAfterScroll(DataSet: TDataSet);
    procedure tEventsScrollTimer(Sender: TObject);
  private
    { Private declarations }
    procedure ExecuteSQLFile(SQLFileName: TFileName);
  public
    { Public declarations }
    LastErrorMessage: string;
    function AddPath: integer;
    procedure InitializeModule;
    function EventByTime(ADateTime: int64; AID_Camera: integer): integer;
    function ExecSQL(ASQL: string): boolean;
    function SaveEvent(AID_Camera: integer; AEvent_Time: int64): integer;
    function SaveZone(AID_Event: integer; ASquare_From, ASquare_To: SmallInt): integer;
    procedure SelectEvents(SelectDate: TDate);
    function SelectInteger(ASQL: string): integer;
    function spEvents: TDataSet;
    function spZones: TDataSet;
  end;

var
  DataDM: TDataDM;
  FCallback: TScrollCallback = nil;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TDataDM.AddPath: integer;
begin
  Lock;
  try
    result:=0;
    try
      if FConnectionString.Values['Type']='PG' then
      begin
        QueryPG.Close;
        QueryPG.SQL.Text:='insert into Path (Name) VALUES (NULL) returning ID_Path';
        QueryPG.Open;
        result:=QueryPG.Fields[0].AsInteger;
      end
      else
      begin
        QueryMS.Close;
        QueryMS.SQL.Text:='insert into Path (Name) VALUES (NULL)'#13#10'SELECT @@identity';
        QueryMS.Open;
        result:=QueryMS.Fields[0].AsInteger;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.AddPath 60: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.EventByTime(ADateTime: int64; AID_Camera: integer): integer;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='select fnEventByTime('+IntToStr(ADateTime)+','+IntToStr(AID_Camera)+',300)';
      QueryPG.Open;
      result:=QueryPG.Fields[0].AsInteger;
    end
    else
    begin
      spEventByTimeMS.Close;
      spEventByTimeMS.Parameters.ParamByName('DateTime').Value:=ADateTime;
      spEventByTimeMS.Parameters.ParamByName('ID_Camera').Value:=AID_Camera;
      spEventByTimeMS.Open;
      result:=spEventByTimeMS.Fields[0].AsInteger;
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
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.InitializeModule 245: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.SaveEvent(AID_Camera: integer; AEvent_Time: int64): integer;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='select fnSaveEvent('+IntToStr(AID_Camera)+','+IntToStr(AEvent_Time)+')';
      QueryPG.Open;
      result:=QueryPG.Fields[0].AsInteger;
    end
    else
    begin
      spSaveEventMS.Close;
      spSaveEventMS.Parameters.ParamByName('AID_Camera').Value:=AID_Camera;
      spSaveEventMS.Parameters.ParamByName('Event_Time').Value:=AEvent_Time;
      spSaveEventMS.Open;
      result:=spSaveEventMS.Fields[0].AsInteger;
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.SaveZone(AID_Event: integer; ASquare_From, ASquare_To: SmallInt): integer;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
    begin
      QueryPG.Close;
      QueryPG.SQL.Text:='select fnSaveZone('+IntToStr(AID_Event)+','+IntToStr(ASquare_From)+','+IntToStr(ASquare_To)+')';
      QueryPG.Open;
      result:=QueryPG.Fields[0].AsInteger;
    end
    else
    begin
      spSaveZoneMS.Close;
      spSaveZoneMS.Parameters.ParamByName('AID_Event').Value:=AID_Event;
      spSaveZoneMS.Parameters.ParamByName('ASquare_From').Value:=ASquare_From;
      spSaveZoneMS.Parameters.ParamByName('ASquare_To').Value:=ASquare_To;
      spSaveZoneMS.Open;
      result:=spSaveZoneMS.Fields[0].AsInteger;
    end;
  finally
    Unlock;
  end;
end;

procedure TDataDM.SelectEvents(SelectDate: TDate);
var
  BeginDate: int64;
begin
  Lock;
  try
    try
      BeginDate:=MilliSecondsBetween(trunc(SelectDate),UnixDateDelta);
      if FConnectionString.Values['Type']='PG' then
      begin
        qEventsPG.AfterScroll:=nil;
        qEventsPG.Close;
        qEventsPG.SQL.Text:='select fnEvents('+IntToStr(BeginDate)+','+IntToStr(BeginDate+86400000)+')';
        qEventsPG.Open;
        qEventsPG.AfterScroll:=spEventsMSAfterScroll;
        spEventsMSAfterScroll(qEventsPG);
      end
      else
      begin
        spEventsMS.AfterScroll:=nil;
        spEventsMS.Close;
        spEventsMS.Parameters.ParamByName('BeginDate').Value:=BeginDate;
        spEventsMS.Parameters.ParamByName('EndDate').Value:=BeginDate+86400000;
        spEventsMS.Open;
        spEventsMS.AfterScroll:=spEventsMSAfterScroll;
        spEventsMSAfterScroll(spEventsMS);
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.SelectEvents 250: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.SelectInteger(ASQL: string): integer;
begin
  Lock;
  try
    result:=0;
    try
      if FConnectionString.Values['Type']='PG' then
      begin
        QueryPG.Close;
        QueryPG.SQL.Text:=ASQL;
        QueryPG.Open;
        result:=QueryPG.Fields[0].AsInteger;
      end
      else
      begin
        QueryMS.Close;
        QueryMS.SQL.Text:=ASQL;
        QueryMS.Open;
        result:=QueryMS.Fields[0].AsInteger;
      end;
    except on e: Exception do
      SendErrorMsg('TDataDM.SelectInteger 278: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Unlock;
  end;
end;

function TDataDM.spEvents: TDataSet;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
      result:=qEventsPG
    else
      result:=spEventsMS;
  finally
    Unlock;
  end;
end;

procedure TDataDM.spEventsMSAfterOpen(DataSet: TDataSet);
begin
  DataSet.FieldByName('ID_Event').Visible:=false;
  DataSet.FieldByName('Event_Date').Visible:=false;
end;

procedure TDataDM.spEventsMSAfterScroll(DataSet: TDataSet);
begin
  if assigned(FCallback) then
    if not DataSet.IsEmpty then
    begin
      if FConnectionString.Values['Type']='PG' then
      begin
        qZoneByEventPG.Close;
        qZoneByEventPG.SQL.Text:='select fnZoneByEvent('+DataSet.FieldByName('ID_Event').AsString+')';
        qZoneByEventPG.Open;
      end
      else
      begin
        spZoneByEventMS.Close;
        spZoneByEventMS.Parameters.ParamByName('AID_Event').Value:=DataSet.FieldByName('ID_Event').AsInteger;
        spZoneByEventMS.Open;
      end;
      FCallback(DataSet.FieldByName('ID_Camera').AsInteger,DataSet.FieldByName('Event_Date').AsLargeInt);
    end;
//  tEventsScroll.Enabled:=false;
//  tEventsScroll.Enabled:=true;
end;

function TDataDM.spZones: TDataSet;
begin
  Lock;
  try
    if FConnectionString.Values['Type']='PG' then
      result:=qZoneByEventPG
    else
      result:=spZoneByEventMS;
  finally
    Unlock;
  end;
end;

procedure TDataDM.tEventsScrollTimer(Sender: TObject);
var
  DataSet: TDataSet;
begin
  tEventsScroll.Enabled:=false;
  if assigned(FCallback) then
  begin
    DataSet:=spEvents;
    if not DataSet.IsEmpty then
      FCallback(DataSet.FieldByName('ID_Camera').AsInteger,DataSet.FieldByName('Event_Date').AsLargeInt);
  end;
end;

end.
