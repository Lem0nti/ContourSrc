program ArchContour;

uses
  Vcl.SvcMgr,
  acMain_SM in 'acMain_SM.pas' {abArchContour: TService},
  acStart_TH in 'acStart_TH.pas',
  acHTTPReceiver_DM in 'acHTTPReceiver_DM.pas' {HTTPReceiverDM: TDataModule},
  acData_DM in 'acData_DM.pas',
  cDBConnector_DM in '..\Common\cDBConnector_DM.pas',
  acTypes in 'acTypes.pas';

{$R *.RES}

begin
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TabArchContour, abArchContour);
  Application.Run;
end.
