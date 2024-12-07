library ContourPlayer;

uses
  System.SysUtils,
  System.Classes,
  cpArchManager_TH in 'cpArchManager_TH.pas',
  acTypes in '..\Archive\acTypes.pas',
  cpArchVideo_Cl in 'cpArchVideo_Cl.pas',
  cCommon in '..\Server\cCommon.pas',
  cpCell_Cl in 'cpCell_Cl.pas',
  cpFrameReceiver_TH in 'cpFrameReceiver_TH.pas',
  cpPlayer_Cl in 'cpPlayer_Cl.pas',
  cpFunctions in 'cpFunctions.pas',
  cpMap_Cl in 'cpMap_Cl.pas',
  cpTypes in 'cpTypes.pas',
  cpCacheClear_TH in 'cpCacheClear_TH.pas',
  cpThumb_FM in 'cpThumb_FM.pas',
  acData_DM in '..\Archive\acData_DM.pas' {DataDM: TDataModule},
  cDBConnector_DM in '..\Common\cDBConnector_DM.pas' {DBConnectorDM: TDataModule};

{$R *.res}

exports
  BeginUpdate,
  ConnectServer,
  DisconnectServer,
  EndUpdate,
  FocusCamera,
  GetArchDays,
  GetArea,
  GetCurTime,
  GetServerCameras,
  GetScreen,
  Play,
  PlayOperative,
  SetCameraInArea,
  SetMapRange,
  SetScreen,
  ShowScreen,
  ShowMap,
  Step,
  StepBack,
  Stop,
  StopOperative;

begin
end.
