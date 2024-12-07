program DebugRunner;

{$R 'OutRes.res' 'OutRes.rc'}

uses
  Vcl.Forms,
  drMain_FM in 'drMain_FM.pas' {MainFM},
  cStart_TH in 'cStart_TH.pas',
  cDBConnector_DM in '..\Common\cDBConnector_DM.pas' {DBConnectorDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFM, MainFM);
  Application.Run;
end.
