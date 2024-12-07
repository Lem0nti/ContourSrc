unit ccPlugins_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Data.DB, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, ccData_DM, sdkCntPlugin_I;

type
  TPluginsFM = class(TForm)
    pMain: TPanel;
    pnlPluginParams: TPanel;
    gbPluginSettings: TGroupBox;
    Panel1: TPanel;
    pnlPluginOptions: TPanel;
    dsPlugin: TDataSource;
    dsPluginCamera: TDataSource;
    dsPluginParam: TDataSource;
    cbSecondPath: TCheckBox;
    Button1: TButton;
    gCameras: TDBGrid;
    gPlugins: TDBGrid;
    cbCameraName: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbCameraNameClick(Sender: TObject);
  private
    { Private declarations }
    FPluginHandle: THandle;
    CurPligin: ICntPligin;
    procedure CameraScroll(ADataSet: TDataSet);
    procedure PluginScroll(ADataSet: TDataSet);
  public
    { Public declarations }
  end;

var
  PluginsFM: TPluginsFM;

implementation

{$R *.dfm}

procedure TPluginsFM.CameraScroll(ADataSet: TDataSet);
var
  FOptionsHandle: THandle;
begin
  cbCameraName.Caption:=ADataSet.FieldByName('Name').AsString;
  cbCameraName.OnClick:=nil;
  try
    cbCameraName.Checked:=ADataSet.FieldByName('Checked').AsBoolean;
  finally
    cbCameraName.OnClick:=cbCameraNameClick;
  end;
  cbSecondPath.Checked:=not ADataSet.FieldByName('APrimary').AsBoolean;
  Application.ProcessMessages;
  if assigned(CurPligin) then
    CurPligin.ShowOptions(pnlPluginOptions.Handle,FOptionsHandle,ADataSet.FieldByName('Secondary').AsWideString);
end;

procedure TPluginsFM.cbCameraNameClick(Sender: TObject);
begin
  DataDM.UpdatePluginCamera(dsPluginCamera.DataSet.FieldByName('ID_Camera').AsInteger,dsPlugin.DataSet.FieldByName('ID_Plugin').AsInteger,
      cbCameraName.Checked);
end;

procedure TPluginsFM.FormCreate(Sender: TObject);
var
  tmpEnable: boolean;
begin
  FPluginHandle:=0;
  dsPlugin.DataSet:=DataDM.PluginDataSet;
  dsPluginCamera.DataSet:=DataDM.PluginCameraDataSet;
  dsPlugin.DataSet.AfterScroll:=PluginScroll;
  dsPluginCamera.DataSet.AfterScroll:=CameraScroll;
  tmpEnable:=DataDM.IsUserAdmin;
  pnlPluginParams.Enabled:=tmpEnable;
  pnlPluginOptions.Enabled:=tmpEnable;
end;

procedure TPluginsFM.FormDestroy(Sender: TObject);
begin
  dsPlugin.DataSet.AfterScroll:=nil;
  dsPluginCamera.DataSet.AfterScroll:=nil;
end;

procedure TPluginsFM.PluginScroll(ADataSet: TDataSet);
var
  API: TCntPliginProc;
  Done: TCntPliginDone;
begin
  if (FPluginHandle>0) then
  begin
    CurPligin.HideOptions;
    CurPligin.DonePlugin;
    CurPligin:=nil;
    Done:=GetProcAddress(FPluginHandle,'PliginDone');
    Done;
    FPluginHandle:=0;
  end;
  FPluginHandle:=LoadLibrary(PChar(dsPlugin.DataSet.FieldByName('FileName').AsString));
  if FPluginHandle>0 then
  begin
    API:=GetProcAddress(FPluginHandle, 'PliginProc');
    API(ICntPligin,CurPligin);
  end;
  DataDM.OpenPluginCamera(dsPlugin.DataSet.FieldByName('ID_Plugin').AsInteger);
end;

end.
