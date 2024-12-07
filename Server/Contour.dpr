program Contour;

{$R 'OutRes.res' 'OutRes.rc'}

uses
  Vcl.SvcMgr,
  cMain_SM in 'cMain_SM.pas' {abContour: TService},
  cStart_TH in 'cStart_TH.pas',
  cFrameCollector_TH in 'cFrameCollector_TH.pas',
  cFrameList_Cl in 'cFrameList_Cl.pas',
  cCommon in 'cCommon.pas',
  cMotionDetector_TH in 'cMotionDetector_TH.pas',
  cMotionSaver_TH in 'cMotionSaver_TH.pas',
  cData_DM in 'cData_DM.pas',
  cDBConnector_DM in '..\Common\cDBConnector_DM.pas' {DBConnectorDM: TDataModule},
  cCamera_Cl in 'cCamera_Cl.pas',
  cFrameGrabber_TH in 'cFrameGrabber_TH.pas',
  cVideoSaver_TH in 'cVideoSaver_TH.pas',
  cIndexSaver_TH in 'cIndexSaver_TH.pas',
  cSlider_TH in 'cSlider_TH.pas',
  cConnectoionController_TH in 'cConnectoionController_TH.pas',
  cAlarmer_TH in 'cAlarmer_TH.pas',
  cCutVideo_TH in 'cCutVideo_TH.pas',
  cClient_Cl in 'cClient_Cl.pas',
  cPrepareSlide_TH in 'cPrepareSlide_TH.pas',
  cScheduleTypes in 'cScheduleTypes.pas',
  cHalter_TH in 'cHalter_TH.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TabContour, abContour);
  Application.Run;
end.
