unit cDBConnector_DM;

interface

uses
  System.SysUtils, System.Classes, Windows, Data.DB, DateUtils, ComObj, ABL.Core.Debug, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Phys.PGDef, FireDAC.Phys.PG,
  Data.Win.ADODB, Variants, Registry, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet;

type
  TBooleanMethod = function: boolean of object;

  TDBConnectorDM = class(TDataModule)
    FDConnection: TFDConnection;
    FDPhysPgDriverLink: TFDPhysPgDriverLink;
    ADOConnection: TADOConnection;
    QueryPG: TFDQuery;
    QueryMS: TADOQuery;
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FLock: TRTLCriticalSection;
    ALastCheck: TDateTime;
    FLastError: string;
    function CheckMSConnection: boolean;
    function CheckPGConnection: boolean;
    function GetLastError: string;
    function GetConnectionString: string;
    function GetDBType: string;
    function GetConnected: boolean;
  protected
    FConnectionString: TStringList;
    procedure Init; virtual;
    procedure Lock;
    procedure SendError(AMessage: string);
    procedure Unlock;
  public
    { Public declarations }
    CheckConnection: TBooleanMethod;
    constructor Create(AConnectionString: string; AReconnectCount: byte = 4); reintroduce;
    //Процедура обновления Набора данных с востановлением позиции,
    // Если не передать ключевое поле, то по-умолчанию берется первое поле как ключевое
    procedure DataSetRefresh(ADataSet: TDataSet; aFieldKey: String = ''; aLookupValue: Integer = 0);
    property Connected: boolean read GetConnected;
    property ConnectionString: string read GetConnectionString;
    property LastError: string read GetLastError;
    property DBType: string read GetDBType;
  end;

implementation

{$R *.dfm}

{ TDBConnectorDM }

function TDBConnectorDM.CheckMSConnection: boolean;
var
  tmpConnectionString,tmpDatabase: string;
begin
  EnterCriticalSection(FLock);
  try
    result:=false;
    try
      if (not ADOConnection.Connected)and(ALastCheck<IncMinute(now,-2)) then
      begin
        tmpConnectionString:='Provider=SQLNCLI10.1;Data Source='+FConnectionString.Values['Server'];
        if FConnectionString.Values['User']='' then
          tmpConnectionString:=tmpConnectionString+';Integrated Security=SSPI'
        else
          tmpConnectionString:=tmpConnectionString+';User ID='+FConnectionString.Values['User']+';Password='+FConnectionString.Values['Password'];
        ADOConnection.ConnectionString:=tmpConnectionString+';Initial Catalog=master';
        try
          ADOConnection.Connected:=true;
          tmpDatabase:=FConnectionString.Values['Database'];
          QueryMS.SQL.Text:='select * from sys.databases where name='''+tmpDatabase+'''';
          QueryMS.Open;
          if QueryMS.IsEmpty then
            ADOConnection.Connected:=false
          else
          begin
            ADOConnection.Connected:=false;
            ADOConnection.ConnectionString:=tmpConnectionString+';Initial Catalog='+tmpDatabase;
            ADOConnection.Connected:=true;
          end;
        except on e: EOleException do
          SendError('TDBConnectorDM.CheckMSConnection EOleException 71: '+IntToStr(int64(e.ErrorCode))+' - '+e.Message);
        on e: Exception do
          SendError('TDBConnectorDM.CheckMSConnection 73: '+e.ClassName+' - '+e.Message);
        end;
        ALastCheck:=now;
      end;
      result:=ADOConnection.Connected;
      if result then
        Init;
    except on e: Exception do
      SendError('TDBConnectorDM.CheckMSConnection 79: '+e.ClassName+' - '+e.Message);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TDBConnectorDM.CheckPGConnection: boolean;
var
  Reg: TRegistry;
  sl: TStringList;
  tmpDatabase: string;
begin
  EnterCriticalSection(FLock);
  try
    result:=false;
    try
      if (not FDConnection.Connected)and(ALastCheck<IncMinute(now,-2)) then
      begin
        Reg:=TRegistry.Create(KEY_READ);
        try
          Reg.RootKey:=HKEY_LOCAL_MACHINE;
          if Reg.OpenKey('SOFTWARE\PostgreSQL\Installations', false) then
          begin
            sl:=TStringList.Create;
            try
              Reg.GetKeyNames(sl);
              Reg.CloseKey;
              if sl.Count>0 then
              begin
                if Reg.OpenKey('SOFTWARE\PostgreSQL\Installations\'+sl[0], false) then
                begin
                  FDPhysPgDriverLink.VendorLib:=Reg.ReadString('Base Directory')+'\bin\libpq.dll';
                  FDConnection.Params.Values['Server']:=FConnectionString.Values['Server'];
                  FDConnection.Params.Values['Database']:='postgres';
                  FDConnection.Params.Values['User_Name']:=FConnectionString.Values['User'];
                  FDConnection.Params.Values['Password']:=FConnectionString.Values['Password'];
                  try
                    FDConnection.Connected:=true;
                    tmpDatabase:=LowerCase(FConnectionString.Values['Database']);
                    QueryPG.SQL.Text:='SELECT * FROM pg_database WHERE datname='''+tmpDatabase+'''';
                    QueryPG.Open;
                    if QueryPG.IsEmpty then
                      FDConnection.Connected:=false
                    else
                    begin
                      FDConnection.Connected:=false;
                      FDConnection.Params.Values['Database']:=tmpDatabase;
                      FDConnection.Connected:=true;
                    end;
                  except on e: Exception do
                    SendError('TDBConnectorDM.CheckPGConnection 101: '+e.ClassName+' - '+e.Message);
                  end;
                end
                else
                  SendError('TDBConnectorDM.CheckPGConnection 126: '+SysErrorMessage(Windows.GetLastError));
              end;
            finally
              sl.Free;
            end;
          end
          else
            SendError('TDBConnectorDM.CheckPGConnection 134: '+SysErrorMessage(Windows.GetLastError));
        finally
          Reg.Free;
        end;
        ALastCheck:=now;
      end;
      result:=FDConnection.Connected;
      if result then
        Init;
    except on e: Exception do
      SendError('TDBConnectorDM.CheckPGConnection 141: '+e.ClassName+' - '+e.Message);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

constructor TDBConnectorDM.Create(AConnectionString: string; AReconnectCount: byte = 4);
var
  i: Integer;
begin
  try
    inherited Create(nil);
    InitializeCriticalSection(FLock);
    FConnectionString:=TStringList.Create;
    FConnectionString.Text:=AConnectionString;
    for I := 0 to ComponentCount - 1 do    // Iterate
      if Components[I] is TFDCustomQuery then
        TFDCustomQuery(Components[I]).Connection:=FDConnection
      else if Components[I] is TCustomADODataSet then
        TCustomADODataSet(Components[I]).Connection:=ADOConnection;
    i:=AReconnectCount;
    if FConnectionString.Values['Type']='PG' then
      CheckConnection:=CheckPGConnection
    else
      CheckConnection:=CheckMSConnection;
    while not CheckConnection and (i > 0) do
    begin
      if i=1 then
        exit;
      SendError(ClassName+'.Create 174: Нет подключения, ждём 30 секунд. '+FConnectionString.Text);
      Sleep(15000);
      Sleep(15000);
      ALastCheck:=0;
      dec(i);
    end;
  except on e: Exception do
    SendError(ClassName+'.Create 181, '+FConnectionString.Text+': '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TDBConnectorDM.DataModuleDestroy(Sender: TObject);
begin
  DeleteCriticalSection(FLock);
end;

procedure TDBConnectorDM.DataSetRefresh(ADataSet: TDataSet; aFieldKey: String;
  aLookupValue: Integer);
Var
  aKey: Variant;
begin
  if aFieldKey = '' then
    aFieldKey := ADataSet.Fields[0].FieldName;
  if ADataSet.Active then
    aKey := ADataSet.FieldByName(aFieldKey).Value
  else
    aKey := Null;
  ADataSet.DisableControls;
  try
    try
      ADataSet.Active := False;
      ADataSet.Active := True;
      if aLookupValue <> 0 then
        ADataSet.Locate(aFieldKey, aLookupValue, [])
      else if not VarIsNull(aKey) then
        ADataSet.Locate(aFieldKey, aKey, []);
    except on E: Exception do
      SendError(ClassName+'.DataSetRefresh 211, <'+aDataSet.Name+'> : '+e.ClassName+' - '+E.Message);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

function TDBConnectorDM.GetConnected: boolean;
begin
  if FConnectionString.Values['Type']='PG' then
    result:=FDConnection.Connected
  else
    result:=ADOConnection.Connected;
end;

function TDBConnectorDM.GetConnectionString: string;
begin
  result:=FConnectionString.Text;
end;

function TDBConnectorDM.GetDBType: string;
begin
  Lock;
  try
    Result:=FConnectionString.Values['Type'];
  finally
    Unlock;
  end;
end;

function TDBConnectorDM.GetLastError: string;
begin
  Lock;
  try
    Result:=FLastError;
  finally
    Unlock;
  end;
end;

procedure TDBConnectorDM.Init;
begin

end;

procedure TDBConnectorDM.Lock;
begin
  EnterCriticalSection(FLock);
end;

procedure TDBConnectorDM.SendError(AMessage: string);
begin
  FLastError:=AMessage;
  SendErrorMsg(AMessage);
end;

procedure TDBConnectorDM.Unlock;
begin
  LeaveCriticalSection(FLock);
end;

end.
