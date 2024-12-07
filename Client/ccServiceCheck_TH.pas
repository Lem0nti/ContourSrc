unit ccServiceCheck_TH;

interface

uses
  Classes, SyncObjs, SysUtils, WinSvc, ABL.Core.Debug, Types, Forms;

type
  TServiceInfo=record
    LastErrorMessage: string;
    Running: boolean;
    Handle: Cardinal;
  end;

  TServiceCheck=class(TThread)
  private
    FWaitForStop: TEvent;
    procedure CheckService(AAlias: string; var AService: Cardinal; var AErrorMessage: string; var ARunning: boolean);
    procedure Redraw;
  protected
    procedure Execute; override;
  public
    scManager: Cardinal;
    ServerInfo,ArchInfo,RetinaInfo: TServiceInfo;
    procedure Stop;
  end;

var
  ServiceCheck: TServiceCheck;

implementation

{ TServeceCheck }

procedure TServiceCheck.CheckService(AAlias: string; var AService: Cardinal; var AErrorMessage: string; var ARunning: boolean);
var
  rsz,rbsz: DWORD;
  rqsc: LPQUERY_SERVICE_CONFIGW;
  scServiceStatus: TServiceStatus;
begin
  AErrorMessage:='';
  if AService<=0 then
    AService:=OpenService(scManager,PChar(AAlias),SERVICE_START+SERVICE_STOP+SERVICE_INTERROGATE+SERVICE_QUERY_CONFIG);
  if AService<=0 then
  begin
    AErrorMessage:='Нет разрешения на управление службами - '+SysErrorMessage(GetLastError);
    AService:=OpenService(scManager,PChar(AAlias),SERVICE_INTERROGATE);
    if AService<=0 then
      AErrorMessage:='Нет разрешения на получение информации о службах - '+SysErrorMessage(GetLastError);
  end;
  ARunning:=false;
  if AService>0 then
  begin
    QueryServiceConfig(AService,nil,0,rsz);
    rbsz:=rsz;
    GetMem(rqsc,rsz);
    try
      if QueryServiceConfig(AService,rqsc,rbsz,rsz) then
      begin
        if rqsc.dwStartType=SERVICE_DISABLED then
          AErrorMessage:='Служба -'+AAlias+'- отключена'
        else
          ControlService(AService,SERVICE_CONTROL_INTERROGATE,scServiceStatus);
      end
      else
      begin
        SendErrorMsg('TServiceCheck.CheckService 63 ('+AAlias+'): '+SysErrorMessage(GetLastError));
        ControlService(AService,SERVICE_CONTROL_INTERROGATE,scServiceStatus);
        //в этой ситуации прекращать обновление
        Terminate;
      end;
    finally
      FreeMem(rqsc);
    end;
    ARunning:=scServiceStatus.dwCurrentState=SERVICE_RUNNING;
  end;
end;

procedure TServiceCheck.Execute;
var
  aStopped: TWaitResult;
begin
  scManager:=0;
  ServerInfo.Handle:=0;
  ArchInfo.Handle:=0;
  RetinaInfo.Handle:=0;
  FreeOnTerminate:=true;
  try
    try
      FWaitForStop:=TEvent.Create(nil,True,False,GUIDToString(TGUID.NewGUID));
      try
        while not Terminated do
          try
            if scManager=0 then
            begin
              scManager:=OpenSCManager(nil,SERVICES_ACTIVE_DATABASE,SC_MANAGER_CONNECT);
              if scManager<=0 then
              begin
                ServerInfo.LastErrorMessage:='Нет подключения к менеджеру служб - '+SysErrorMessage(GetLastError);
                ArchInfo.LastErrorMessage:=ServerInfo.LastErrorMessage;
                RetinaInfo.LastErrorMessage:=ServerInfo.LastErrorMessage;
              end;
            end;
            if scManager>0 then
            begin
              CheckService('abContour',ServerInfo.Handle,ServerInfo.LastErrorMessage,ServerInfo.Running);
              CheckService('abArchContour',ArchInfo.Handle,ArchInfo.LastErrorMessage,ArchInfo.Running);
              CheckService('abRetina',RetinaInfo.Handle,RetinaInfo.LastErrorMessage,RetinaInfo.Running);
            end;
            Synchronize(Redraw);
            if Terminated then
              exit;
            aStopped:=FWaitForStop.WaitFor(10000);
            if aStopped<>wrTimeOut then
              exit;
          except on e: Exception do
            SendErrorMsg('TServeceCheck.Execute 114: '+e.ClassName+' - '+e.Message);
          end;
      finally
        FreeAndNil(FWaitForStop);
      end;
    finally
      if scManager>0 then
        CloseServiceHandle(scManager);
    end;
  finally
    ServiceCheck:=nil;
    Terminate;
  end;
end;

procedure TServiceCheck.Redraw;
begin
  if assigned(Application.MainForm) then
    Application.MainForm.Invalidate;
end;

procedure TServiceCheck.Stop;
begin
  FWaitForStop.SetEvent;
end;

end.
