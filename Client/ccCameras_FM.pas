unit ccCameras_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  ссScheduler_Cl, Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls, Vcl.ExtCtrls,
  ABL.IO.IOTypes, ccData_DM, RegularExpressions, ccServiceCheck_TH, ShellAPI, UITypes, ccPing, ABL.VS.URI,
  cScheduleTypes, ABL.VS.RTSPReceiver, ABL.VS.VideoDecoder, ABL.Core.ThreadQueue, ABL.VS.FFMPEG, ABL.VS.VSTypes,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, cxButtons, IdURI, System.Actions, Vcl.ActnList,
  Vcl.CheckLst;

type
  TGrabStart=class(TThread)
  private
    bmp: TBitmap;
    FConnectionString: string;
    Picture: PImageDataHeader;
    procedure Draw;
  protected
    procedure Execute; override;
  public
    constructor Create(AConnectionString: string); reintroduce;
  end;

  TCamerasFM = class(TForm)
    Panel1: TPanel;
    gCameras: TDBGrid;
    pCameraButton: TPanel;
    bAddCamera: TcxButton;
    bDeleteCamera: TcxButton;
    pnlControls: TPanel;
    iFrame: TImage;
    lblWarning: TLabel;
    lblError: TLabel;
    leName: TLabeledEdit;
    lePrimary: TLabeledEdit;
    leSecondary: TLabeledEdit;
    cbActive: TCheckBox;
    pShedule: TPanel;
    pRadioShedule: TPanel;
    rgSchedule: TRadioGroup;
    bSave: TButton;
    bWeb: TButton;
    dsCameras: TDataSource;
    Timer: TTimer;
    ErrorTimer: TTimer;
    ActionList: TActionList;
    aSave: TAction;
    bPing: TButton;
    gPlugins: TDBGrid;
    dsPlugins: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure lePrimaryChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure leNameChange(Sender: TObject);
    procedure lePrimaryDblClick(Sender: TObject);
    procedure rgScheduleClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure bAddCameraClick(Sender: TObject);
    procedure leSecondaryChange(Sender: TObject);
    procedure bDeleteCameraClick(Sender: TObject);
    procedure bWebClick(Sender: TObject);
    procedure ErrorTimerTimer(Sender: TObject);
    procedure aSaveExecute(Sender: TObject);
    procedure bPingClick(Sender: TObject);
    procedure leNameKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    spBmp: TBitmap;
    ScreenFrames: TDictionary<integer,TBitmap>;
    procedure CameraScroll(DataSet: TDataSet);
    procedure SchedulerChanged;
  public
    { Public declarations }
    procedure ApplyFrame(ABitmap: TBitmap);
    function ChekSave: boolean;
  end;

var
  CamerasFM: TCamerasFM;

implementation

var
  RTSPReceiver: TRTSPReceiver = nil;
  VideoDecoder: TVideoDecoder = nil;

{$R *.dfm}

procedure TCamerasFM.ApplyFrame(ABitmap: TBitmap);
var
  bmp: TBitmap;
  id: integer;
begin
  id:=DataDM.tCamera.Fields[0].AsInteger;
  if ScreenFrames.TryGetValue(id,bmp) then
  begin
    ScreenFrames.Remove(DataDM.tCamera.Fields[0].AsInteger);
    bmp.Free;
  end;
  ScreenFrames.Add(DataDM.tCamera.Fields[0].AsInteger,ABitmap);
  iFrame.Picture.Assign(ABitmap);
end;

procedure TCamerasFM.aSaveExecute(Sender: TObject);
begin
  bSave.Click;
end;

procedure TCamerasFM.bAddCameraClick(Sender: TObject);
begin
  DataDM.tCamera.AfterScroll:=nil;
  try
    DataDM.AddCamera;
  finally
    DataDM.tCamera.AfterScroll:=CameraScroll;
  end;
  CameraScroll(DataDM.tCamera);
  pnlControls.Enabled:=true;
  lePrimary.SetFocus;
end;

procedure TCamerasFM.bDeleteCameraClick(Sender: TObject);
var
  q: integer;
begin
  q:=MessageBoxEx(Handle,'Удалить вместе с архивом?','Подтверждение удаления',MB_YESNOCANCEL,RUSSIAN_CHARSET);
  if q=IDCANCEL then
    exit;
  DataDM.DeleteCurrentCamera(q=IDYES);
  pnlControls.Enabled:=not DataDM.tCamera.IsEmpty;
end;

procedure TCamerasFM.bPingClick(Sender: TObject);
var
  Link: TURI;
  AStatus: Integer;
begin
  Link:=TURI.Create;
  Link.Apply(lePrimary.Text);
  if Ping(AnsiString(Link.Host),1,AStatus) then
    lblError.Caption:='OK'
  else
    lblError.Caption:='NO';
end;

procedure TCamerasFM.bSaveClick(Sender: TObject);
var
  lWeekDay: TWeekDay;
  q: integer;
begin
  DataDM.tCamera.Edit;
  DataDM.tCamera.FieldByName('Name').AsString:=leName.Text;
  DataDM.tCamera.FieldByName('ConnectionString').AsString:=lePrimary.Text;
  DataDM.tCamera.FieldByName('Secondary').AsString:=leSecondary.Text;
  DataDM.tCamera.FieldByName('Active').Value:=cbActive.Checked;
  DataDM.tCamera.FieldByName('Schedule_Type').Value:=rgSchedule.ItemIndex;
  DataDM.tCamera.Post;
  if rgSchedule.ItemIndex=3 then
  begin
    DataDM.tSchedule.Open;
    DataDM.tSchedule.Filter:='ID_Camera='+DataDM.tCamera.FieldByName('ID_Camera').AsString;
    DataDM.tSchedule.Filtered:=true;
    while not DataDM.tSchedule.IsEmpty do
      DataDM.tSchedule.Delete;
    lWeekDay:=Scheduler.GetSchedule;
    for q := 1 to 7 do
    begin
      DataDM.tSchedule.Append;
      DataDM.tSchedule.FieldByName('ID_Camera').AsInteger:=DataDM.tCamera.FieldByName('ID_Camera').AsInteger;
      DataDM.tSchedule.FieldByName('Day').Value:=q;
      DataDM.tSchedule.FieldByName('SBegin').Value:=lWeekDay[q].DayBegin;
      DataDM.tSchedule.FieldByName('SEnd').Value:=lWeekDay[q].DayEnd;
      DataDM.tSchedule.Post;
    end;
  end;
  bSave.Font.Style:=[];
  if assigned(ServiceCheck) and ServiceCheck.ServerInfo.Running then
    lblWarning.Show;
end;

procedure TCamerasFM.bWebClick(Sender: TObject);
var
  tmpURI: TIdURI;
  tmpConnectionString: string;
begin
  tmpConnectionString:=DataDM.tCamera.FieldByName('ConnectionString').AsString;
  if tmpConnectionString<>'' then
  begin
    tmpURI:=TIdURI.Create(tmpConnectionString);
    try
      ShellExecute(0, 'open', PChar('http://'+tmpURI.Host), nil, nil, SW_SHOW);
    finally
      tmpURI.Free;
    end;
  end;
end;

procedure TCamerasFM.CameraScroll(DataSet: TDataSet);
var
  lWeekDay: TWeekDay;
  bmp: TBitmap;
begin
  lblError.Caption:='';
  lePrimary.Font.Color:=clWindowText;
  leSecondary.Font.Color:=clWindowText;
  if assigned(DataSet) then
  begin
    leName.Text:=DataDM.tCamera.FieldByName('Name').AsString;
    lePrimary.Text:=DataDM.tCamera.FieldByName('ConnectionString').AsString;
    leSecondary.Text:=DataDM.tCamera.FieldByName('Secondary').AsString;
    cbActive.Checked:=DataDM.tCamera.FieldByName('Active').AsBoolean;
    rgSchedule.ItemIndex:=DataDM.tCamera.FieldByName('Schedule_Type').AsInteger;
    if rgSchedule.ItemIndex=3 then
    begin
      DataDM.tSchedule.Open;
      DataDM.tSchedule.Filter:='ID_Camera='+DataDM.tCamera.FieldByName('ID_Camera').AsString;
      DataDM.tSchedule.Filtered:=true;
      DataDM.tSchedule.First;
      FillChar(lWeekDay,Sizeof(TWeekDay),0);
      while not DataDM.tSchedule.Eof do
      begin
        lWeekDay[DataDM.tSchedule.FieldByName('Day').AsInteger].DayBegin:=DataDM.tSchedule.FieldByName('SBegin').AsInteger;
        lWeekDay[DataDM.tSchedule.FieldByName('Day').AsInteger].DayEnd:=DataDM.tSchedule.FieldByName('SEnd').Value;
        DataDM.tSchedule.Next;
      end;
      Scheduler.SetSchedule(3,lWeekDay);
    end;
    bSave.Font.Style:=[];
    if ScreenFrames.TryGetValue(DataDM.tCamera.Fields[0].AsInteger,bmp) then
      iFrame.Picture.Assign(bmp)
    else
      iFrame.Picture.Assign(nil);
    //плугины
    DataDM.OpenCameraPlugin(DataDM.tCamera.FieldByName('ID_Camera').AsInteger);
  end;
end;

function TCamerasFM.ChekSave: boolean;
begin
  result:=true;
  if bSave.Font.Style=[fsBold] then
    case MessageBoxEx(Handle,'Есть несохранённые данные. Сохранить?','Подтверждение перехода.',MB_YESNOCANCEL+MB_ICONQUESTION,RUSSIAN_CHARSET) of
      IDYES: bSave.Click;
      IDCANCEL: result:=false;
    end;
end;

procedure TCamerasFM.ErrorTimerTimer(Sender: TObject);
var
  LastError: string;
begin
  if assigned(RTSPReceiver) then
  begin
    LastError:=RTSPReceiver.LastError;
    if LastError<>'' then
      lblError.Caption:=LastError;
  end;
end;

procedure TCamerasFM.FormCreate(Sender: TObject);
var
  tmpEnable: boolean;
begin
  Scheduler:=TScheduler.Create(nil);
  Scheduler.Color:=clRed;
  Scheduler.BeginUpdate;
  try
    Scheduler.Parent:=pShedule;
    Scheduler.Width:=pShedule.ClientWidth;
    Scheduler.Height:=pShedule.ClientHeight;
    Scheduler.SetChangedCallback(SchedulerChanged);
  finally
    Scheduler.EndUpdate;
  end;
  Scheduler.SetSchedule(0);
  spBmp:=TBitmap.Create;
  spBmp.PixelFormat:=pf24bit;
  spBmp.SetSize(1,1);
  spBmp.Canvas.Pixels[0,0]:=clWhite;
  ScreenFrames:=TDictionary<integer,TBitmap>.Create;
  if assigned(DataDM.tCamera) then
  begin
    DataDM.tCamera.Open;
    DataDM.tCamera.AfterScroll:=CameraScroll;
  end;
  dsCameras.DataSet:=DataDM.tCamera;
  CameraScroll(DataDM.tCamera);
  tmpEnable:=DataDM.IsUserAdmin;
  leName.ReadOnly:=not tmpEnable;
  lePrimary.ReadOnly:=not tmpEnable;
  leSecondary.ReadOnly:=not tmpEnable;
  cbActive.Enabled:=tmpEnable;
  pShedule.Enabled:=tmpEnable;
  pCameraButton.Enabled:=tmpEnable;
  pnlControls.Enabled:=assigned(DataDM.tCamera) and (not DataDM.tCamera.IsEmpty);
  bAddCamera.Enabled:=DataDM.Connected;
  bDeleteCamera.Enabled:=DataDM.Connected;;
  //наполнение комбо
  dsPlugins.DataSet:=DataDM.CameraPluginDataSet;
end;

procedure TCamerasFM.FormDestroy(Sender: TObject);
begin
  if assigned(DataDM.tCamera) then
    DataDM.tCamera.AfterScroll:=nil;
  spBmp.Free;
  ScreenFrames.Free;
end;

procedure TCamerasFM.leNameChange(Sender: TObject);
begin
  bSave.Enabled:=trim(leName.Text)<>'';
  bSave.Font.Style:=[fsBold];
end;

procedure TCamerasFM.leNameKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=';' then
    Key:=#0;
end;

procedure TCamerasFM.lePrimaryChange(Sender: TObject);
begin
  Timer.Enabled:=false;
  Timer.Enabled:=true;
  bSave.Font.Style:=[fsBold];
end;

procedure TCamerasFM.lePrimaryDblClick(Sender: TObject);
begin
  Timer.Enabled:=true;
end;

procedure TCamerasFM.leSecondaryChange(Sender: TObject);
begin
  Timer.Enabled:=true;
  bSave.Font.Style:=[fsBold];
  if rgSchedule.ControlCount>4 then
    rgSchedule.Controls[4].Enabled:=(trim(leSecondary.Text)<>'');
end;

procedure TCamerasFM.rgScheduleClick(Sender: TObject);
var
  FScheduleType: byte;
begin
  FScheduleType:=rgSchedule.ItemIndex;
  if dsCameras.DataSet.FieldByName('Schedule_Type').AsInteger<>FScheduleType then
  begin
    dsCameras.DataSet.Edit;
    dsCameras.DataSet.FieldByName('Schedule_Type').Value:=FScheduleType;
    dsCameras.DataSet.Post;
  end;
  Scheduler.SetSchedule(FScheduleType);
  bSave.Font.Style:=[fsBold];
end;

procedure TCamerasFM.SchedulerChanged;
begin
  bSave.Font.Style:=[fsBold];
  rgSchedule.ItemIndex:=3;
end;

procedure TCamerasFM.TimerTimer(Sender: TObject);
var
  lRegex: TRegEx;
  lRTSP: string;
  le: TLabeledEdit;
  AColor: TColor;
begin
  Timer.Enabled:=false;
  lRegex:= TRegex.Create('(rtsp):\/\/(?:([^\s@\/]+?)[@])?((\d{1,3}[\.]\d{1,3}[\.]\d{1,3}[\.]+\d{1,3})+)');
  if lePrimary.Focused then
    le:=lePrimary
  else if leSecondary.Focused then
    le:=leSecondary
  else
    le:=nil;
  if assigned(le) then
  begin
    lRTSP:=le.Text;
    AColor:=clRed;
    if (lRTSP<>'') and (lRegex.IsMatch(lRTSP)) then
    begin
      lblError.Caption:='';
      TGrabStart.Create(lRTSP);
      AColor:=clWindowText;
    end;
    le.Font.Color:=AColor;
  end;
end;

{ TGrabStart }

constructor TGrabStart.Create(AConnectionString: string);
begin
  inherited Create(false);
  FConnectionString:=AConnectionString;
end;

procedure TGrabStart.Draw;
begin
  if assigned(CamerasFM) and ((CamerasFM.lePrimary.Text=FConnectionString) or (CamerasFM.leSecondary.Text=FConnectionString)) then
    CamerasFM.ApplyFrame(bmp);
end;

procedure TGrabStart.Execute;
var
  Receiver2DecoderQueue,DecoderOutput: TThreadQueue;
  q: integer;
  tmpData: Pointer;
begin
  if assigned(VideoDecoder) then
  begin
    VideoDecoder.Stop;
    VideoDecoder.SetInputQueue(nil);
  end;
  if assigned(RTSPReceiver) then
    FreeAndNil(RTSPReceiver);
  if assigned(VideoDecoder) then
    FreeAndNil(VideoDecoder);
  Receiver2DecoderQueue:=TThreadQueue.Create;
  DecoderOutput:=TThreadQueue.Create;
  RTSPReceiver:=TRTSPReceiver.Create(Receiver2DecoderQueue,'',FConnectionString);
  VideoDecoder:=TVideoDecoder.Create(Receiver2DecoderQueue,DecoderOutput,AV_CODEC_ID_H264);
  DecoderOutput.WaitForItems(5000);
  if assigned(RTSPReceiver) then
    RTSPReceiver.Active:=false;
  if DecoderOutput.Count>0 then
  begin
    Picture:=DecoderOutput.Pop;
    try
      bmp:=TBitmap.Create;
      bmp.PixelFormat:=pf24bit;
      bmp.SetSize(Picture.Width,Picture.Height);
      for q := 0 to Picture.Height-1 do
        Move(PByte(NativeUInt(Picture.Data)+Picture.Width*q*3)^,bmp.ScanLine[q]^,Picture.Width*3);
      Synchronize(Draw);
    finally
      FreeMem(Picture);
    end;
  end;
  if assigned(RTSPReceiver) then
    FreeAndNil(RTSPReceiver);
  if assigned(VideoDecoder) then
    FreeAndNil(VideoDecoder);
  while Receiver2DecoderQueue.Count>0 do
  begin
    tmpData:=Receiver2DecoderQueue.Pop;
    FreeMem(tmpData);
  end;
  Receiver2DecoderQueue.Free;
  while DecoderOutput.Count>0 do
  begin
    tmpData:=DecoderOutput.Pop;
    FreeMem(tmpData);
  end;
  DecoderOutput.Free;
end;

end.
