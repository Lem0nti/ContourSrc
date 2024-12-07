unit ccEvents_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Types,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.ComCtrls, ccData_DM,
  rPlugin_Cl, sdkCntPlugin_I;

type
  TEventsFM = class(TForm)
    PageControl: TPageControl;
  private
    { Private declarations }
    procedure tsResize(Sender: TObject);
  public
    { Public declarations }
    procedure DrawCallback(Camera: integer; DateTime: int64; DC: HDC; Width, Height: integer);
    procedure Init(ScrollCallback: TScrollCallback);
    procedure VideoCallback(AID_Camera: integer; ADateTime: int64);
  end;

var
  EventsFM: TEventsFM;

implementation

{$R *.dfm}

procedure TEventsFM.DrawCallback(Camera: integer; DateTime: int64; DC: HDC; Width, Height: integer);
begin
  PluginList.Items[0].API.DrawCallback(Camera,DateTime,DC,Width,Height);
end;

procedure TEventsFM.Init(ScrollCallback: TScrollCallback);
var
  DataSet: TDataSet;
  tmpPlugin: TPlugin;
  tsdock: TTabSheet;
  AHandle: THandle;
  FtmpFM: TForm;
begin
  DataSet:=DataDM.PluginDataSet;
  DataSet.Open;
  DataSet.First;
  while not DataSet.Eof do
  begin
    tmpPlugin:=PluginList.PluginByFileName(DataSet.FieldByName('FileName').AsString);
    if tmpPlugin.Active then
    begin
      tsdock:=TTabSheet.Create(PageControl);
      tsdock.PageControl:=PageControl;
      FtmpFM:=TForm.Create(nil);
      FtmpFM.DragKind:=dkDock;
      FtmpFM.Name:='FtmpFM_'+StringReplace(DataSet.FieldByName('FileName').AsString,'.','_',[rfReplaceAll]);
      FtmpFM.DragMode:=dmAutomatic;
      tsdock.Caption:=DataSet.FieldByName('Name').AsString;
      FtmpFM.Show;
      FtmpFM.Dock(PageControl,rect(0,0,tsdock.width,tsdock.height));
      FtmpFM.Parent:=tsdock;
      FtmpFM.Align:=alClient;
      tmpPlugin.API.RegisterScrollCallback(ScrollCallback);
      tmpPlugin.API.ShowEvents(FtmpFM.Handle,AHandle);
      FtmpFM.OnResize:=tsResize;
      tsResize(FtmpFM);
    end;
    DataSet.Next;
  end;
end;

procedure TEventsFM.tsResize(Sender: TObject);
var
  wc: HWND;
  SRect: TRect;
begin
  //поискать на себе ещё окно и если есть, то ресайзить по своим размерам
  wc:=GetWindow(TWinControl(Sender).Handle,GW_CHILD);
  if wc>0 then
  begin
    SRect.Left:=0;
    SRect.Top:=0;
    SRect.BottomRight:=Point(TWinControl(Sender).Width,TWinControl(Sender).Height);
    SetWindowPos(wc,HWND_TOP,SRect.Left,SRect.Top,SRect.Right,SRect.Bottom,SWP_NOZORDER);
  end;
end;

procedure TEventsFM.VideoCallback(AID_Camera: integer; ADateTime: int64);
var
  q: integer;
begin
  for q := 0 to PluginList.Count-1 do
    PluginList.Items[q].API.VideoCallback(AID_Camera,ADateTime);
end;

end.
