library cpMDT;

{$R 'OutRes.res' 'OutRes.rc'}

uses
  System.SysUtils,
  System.Classes,
  mdtMainClass_Cl in 'mdtMainClass_Cl.pas',
  sdkCntPlugin_I in '..\..\SDK\sdkCntPlugin_I.pas',
  cDBConnector_DM in '..\..\Common\cDBConnector_DM.pas' {DBConnectorDM: TDataModule},
  mdtData_DM in 'mdtData_DM.pas' {DataDM: TDataModule},
  mdtMotionDetector_TH in 'mdtMotionDetector_TH.pas',
  mdtEventSaver_TH in 'mdtEventSaver_TH.pas',
  mdtTracker_TH in 'mdtTracker_TH.pas',
  mdtCommon in 'mdtCommon.pas',
  mdtCutDatabase_TH in 'mdtCutDatabase_TH.pas',
  mdtOptions_FM in 'mdtOptions_FM.pas',
  mdtServerDetector_TH in 'mdtServerDetector_TH.pas',
  mdtEvents_FM in 'mdtEvents_FM.pas' {EventsFM},
  mdtScroll_TH in 'mdtScroll_TH.pas';

{$R *.res}

begin
end.
