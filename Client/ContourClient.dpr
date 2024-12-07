program ContourClient;



uses
  Vcl.Forms,
  ccMain_FM in 'ccMain_FM.pas' {MainFM},
  cDBConnector_DM in '..\Common\cDBConnector_DM.pas',
  ccData_DM in 'ccData_DM.pas' {DataDM: TDataModule},
  ccServiceCheck_TH in 'ccServiceCheck_TH.pas',
  ccCameras_FM in 'ccCameras_FM.pas' {CamerasFM},
  ññScheduler_Cl in 'ññScheduler_Cl.pas',
  cScheduleTypes in '..\Server\cScheduleTypes.pas',
  ccStatusBox_FM in 'ccStatusBox_FM.pas' {StatusBoxFM},
  ccArchiveDisk_FM in 'ccArchiveDisk_FM.pas' {ArchiveDiskFM},
  ccArchive_FM in 'ccArchive_FM.pas' {ArchiveFM},
  ccPlayer_FM in 'ccPlayer_FM.pas' {PlayerFM},
  gcHoverButton_Cl in '..\GraphicControls\gcHoverButton_Cl.pas',
  ccDragThumb_FM in 'ccDragThumb_FM.pas',
  ccCalendrPopup_FM in 'ccCalendrPopup_FM.pas' {CalendarPopupFM},
  ccDBSelect_FM in 'ccDBSelect_FM.pas' {DBSelectFM},
  ccPing in 'ccPing.pas',
  ccPlugins_FM in 'ccPlugins_FM.pas' {PluginsFM},
  sdkCntPlugin_I in '..\SDK\sdkCntPlugin_I.pas',
  ccEvents_FM in 'ccEvents_FM.pas' {EventsFM},
  rPlugin_Cl in '..\Retina\rPlugin_Cl.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFM, MainFM);
  Application.Run;
end.
