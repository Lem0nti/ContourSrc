unit cMain_SM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr,
  Vcl.Dialogs, WinSvc, cStart_TH;

type
  // для SERVICE_CONFIG_FAILURE_ACTIONS
  {$A+}  //Это обязательно, иначе неверный размер структур для команды менеджеру сервисов
  SC_ACTION_TYPE = (SC_ACTION_NONE, SC_ACTION_RESTART, SC_ACTION_REBOOT, SC_ACTION_RUN_COMMAND);

  _SC_ACTION = record
    Type_:SC_ACTION_TYPE;
    Delay: DWord;
  end;

  SC_ACTION = _SC_ACTION;
  TSC_Action = _SC_ACTION;
  PSC_Action = ^_SC_ACTION;

  _SERVICE_FAILURE_ACTIONS = record
    dwResetPeriod: DWord;
    lpRebootMsg: PWideChar;
    lpCommand: PWideChar;
    cActions: DWord;
    lpsaActions: PSC_Action;
  end;
  {$A-}

  TServiceFailureActions = _SERVICE_FAILURE_ACTIONS;

  TChangeServiceConfig2 = function(scHandle: SC_HANDLE; dwInfoLevel: DWord; lpInfo: pointer): BOOL; stdcall;
  TabContour = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  abContour: TabContour;
  advapi32: THandle; // хендл библиотеки, содержащей нужную функцию
  ChangeServiceConfig2: TChangeServiceConfig2; // сама функция

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  abContour.Controller(CtrlCode);
end;

function TabContour.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TabContour.ServiceAfterInstall(Sender: TService);
var
  sfa: TServiceFailureActions;
  hSCM, hService: THandle;
  tmpActions: array of TSC_Action;
begin
  advapi32 := LoadLibrary('advapi32.dll');
  if advapi32 <> 0 then
    try
      ChangeServiceConfig2 := GetProcAddress(advapi32, 'ChangeServiceConfig2W');
      hSCM:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
      if hSCM <> 0 then
        try
          hService:=OpenService(hSCM,PChar(Name),SERVICE_ALL_ACCESS);
          try
            SetLength(tmpActions,1);
            FillChar(tmpActions[0],SizeOf(TSC_Action),0);
            tmpActions[0].Type_:=SC_ACTION_RESTART;
            tmpActions[0].Delay:=1000;
            sfa.dwResetPeriod:=0;
            sfa.lpRebootMsg:='';
            sfa.lpCommand:='';
            sfa.cActions:=1;
            sfa.lpsaActions:= Pointer(tmpActions);
            ChangeServiceConfig2(hService, SERVICE_CONFIG_FAILURE_ACTIONS, @sfa);
          finally
            CloseServiceHandle(hService);
          end;
        finally
          CloseServiceHandle(hSCM);
        end;
    finally
      FreeLibrary(advapi32);
    end;
end;

procedure TabContour.ServiceStart(Sender: TService; var Started: Boolean);
begin
  TStartTH.Create;
end;

procedure TabContour.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  StopAllStarted;
end;

end.
