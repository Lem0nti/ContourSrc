unit ccPlayer_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, //ccData_DM,
  Math, ccCalendrPopup_FM, IniFiles, SyncObjs, ccEvents_FM,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids, Vcl.DBGrids, Data.Win.ADODB,
  Vcl.ComCtrls, Types, gcHoverButton_Cl, Vcl.StdCtrls, DateUtils, Vcl.Buttons, ccDragThumb_FM, ABL.Core.Debug;

type
  Tcbf = procedure(Server, Camera: integer; DateTime: int64); stdcall;
  Tcbd = procedure(Server, Camera: integer; DateTime: int64; DC: HDC; Width, Height: integer); stdcall;

  TConnectServerProc = function (Address: WideString): integer; stdcall;
  TFocusCameraProc = function (Server, Camera: integer; ATime: TDateTime): boolean;
  TGetAreaProc = function (x,y: integer): integer; stdcall;
  TGetCurTimeProc = function: TDateTime; stdcall;
  TInteger2WideStringProc = function (Server: integer): WideString; stdcall;
  TIntegerProc = procedure (Index: integer); stdcall;
  TPlayProc = function (cbf: Tcbf; cbd: Tcbd; ASpeed: integer): boolean; stdcall;
  TSetCameraInAreaProc = procedure (Server, Camera, Area: integer); stdcall;
  TSetMapRangeProc = procedure (StartDate, EndDate: TDateTime); stdcall;
  TShowSmthProc = function (Parent: HWND): boolean; stdcall;
  TStdCallProc = procedure; stdcall;

  TUpdateCameras=class(TThread)
  private
    FWaitForStop: TEvent;
    sl: TStringList;
    procedure UpdateCameras;
  protected
    procedure Execute; override;
  public
    procedure Stop;
  end;

  TPlayerFM = class(TForm)
    Panel2: TPanel;
    pnlSlider: TPanel;
    pnlPlayer: TPanel;
    pnlButtons: TPanel;
    dsCameras: TDataSource;
    StartTimer: TTimer;
    dsPlayerCameras: TADODataSet;
    dsPlayerCamerasID_Camera: TIntegerField;
    dsPlayerCamerasServer: TIntegerField;
    dsPlayerCamerasNumber: TIntegerField;
    dsPlayerCamerasName: TStringField;
    hbPlay: THoverButton;
    hbStop: THoverButton;
    hbStepBack: THoverButton;
    hbStep: THoverButton;
    hbFast: THoverButton;
    lblTime: TLabel;
    TimeTimer: TTimer;
    dtpArchive: TDateTimePicker;
    cbOperative: TCheckBox;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    DragTimer: TTimer;
    PageControl1: TPageControl;
    tsCameras: TTabSheet;
    lvCameras: TListView;
    tsEvents: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartTimerTimer(Sender: TObject);
    procedure pnlPlayerResize(Sender: TObject);
    procedure hbPlayClick(Sender: TObject);
    procedure hbStopClick(Sender: TObject);
    procedure hbStepClick(Sender: TObject);
    procedure hbStepBackClick(Sender: TObject);
    procedure hbFastClick(Sender: TObject);
    procedure TimeTimerTimer(Sender: TObject);
    procedure lvCamerasDblClick(Sender: TObject);
    procedure cbOperativeClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure dtpArchiveCloseUp(Sender: TObject);
    procedure lvCamerasMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure lvCamerasMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DragTimerTimer(Sender: TObject);
    procedure dtpArchiveMouseEnter(Sender: TObject);
    procedure lvCamerasCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      var DefaultDraw: Boolean);
  private
    { Private declarations }
    FirstTime: boolean;
    HLibrary: THandle;
    BeginUpdate: TStdCallProc;
    ConnectServer: TConnectServerProc;
    DisconnectServer: TIntegerProc;
    EndUpdate,Step,StepBack,Stop,PlayOperative,StopOperative: TStdCallProc;
    FocusCamera: TFocusCameraProc;
    GetCurTime: TGetCurTimeProc;
    GetArchDays: TInteger2WideStringProc;
    GetArea: TGetAreaProc;
    Play: TPlayProc;
    SetCameraInArea: TSetCameraInAreaProc;
    SetMapRange: TSetMapRangeProc;
    SetScreen: TIntegerProc;
    ShowScreen,ShowMap: TShowSmthProc;
    StartP: TPoint;
    VideoRect: TRect;
    procedure MonthClick(Sender: TObject);
    procedure UpdateCameras(sl: TStringList);
  public
    { Public declarations }
    OnReady: TNotifyEvent;
  end;

var
  PlayerFM: TPlayerFM;
  CurrentServer: string = '127.0.0.1';

procedure DrawCallback(Server, Camera: integer; DateTime: int64; DC: HDC; Width, Height: integer); stdcall;
procedure PlayCallback(Server, Camera: integer; DateTime: int64); stdcall;
procedure ScrollCallback(AID_Camera: integer; ADateTime: int64); stdcall;

implementation

var
  GetServerCameras: TInteger2WideStringProc;
  UpdateCamerasThread: TUpdateCameras;

{$R *.dfm}

procedure DrawCallback(Server, Camera: integer; DateTime: int64; DC: HDC; Width, Height: integer);
begin
  if assigned(EventsFM) then
    EventsFM.DrawCallback(Camera,DateTime,DC,Width, Height);
end;

procedure PlayCallback(Server, Camera: integer; DateTime: int64);
begin
  if assigned(PlayerFM) then
    PlayerFM.lblTime.Caption:=DateTimeToStr(IncMilliSecond(UnixDateDelta,DateTime));
  if assigned(EventsFM) then
    EventsFM.VideoCallback(Camera,DateTime);
end;

procedure ScrollCallback(AID_Camera: integer; ADateTime: int64);
begin
  //поставить камеру
  //спозиционироваться на времени
  PlayerFM.FocusCamera(0,AID_Camera,IncMilliSecond(UnixDateDelta,ADateTime));
end;

procedure TPlayerFM.cbOperativeClick(Sender: TObject);
begin
  if cbOperative.Checked then
  begin
    if @PlayOperative<>nil then
      PlayOperative;
  end
  else if @StopOperative<>nil then
    StopOperative;
end;

procedure TPlayerFM.DragTimerTimer(Sender: TObject);
var
  tmpPoint: TPoint;
  CellIndex: integer;
begin
  if DragThumbFM.Visible then
  begin
    tmpPoint:=Mouse.CursorPos;
    if (GetKeyState(VK_LBUTTON) AND 128) = 128 then
    begin
      DragThumbFM.Left:=tmpPoint.X;
      DragThumbFM.Top:=tmpPoint.Y;
      //если под указателем не проигрыватель, то превратить курсор в перечёркнутый
      if (tmpPoint.X>VideoRect.Left)and(tmpPoint.X<VideoRect.Right)and(tmpPoint.Y>VideoRect.Top)and(tmpPoint.Y<VideoRect.Bottom) then
        Screen.Cursor:=crDrag
      else
        Screen.Cursor:=crNoDrop;
    end
    else
    begin
      DragThumbFM.Hide;
      tmpPoint:=pnlPlayer.ScreenToClient(tmpPoint);
      //вставить камеру
      if @GetArea<>nil then
      begin
        CellIndex:=GetArea(tmpPoint.X,tmpPoint.Y);
        if CellIndex>=0 then
        begin
          SetCameraInArea(0,lvCameras.Items[lvCameras.ItemIndex].ImageIndex,CellIndex);
          with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
            try
              WriteInteger('PLAYER',IntToStr(CellIndex),lvCameras.Items[lvCameras.ItemIndex].ImageIndex);
            finally
              Free;
            end;
        end;
      end;
    end;
  end;
end;

procedure TPlayerFM.dtpArchiveCloseUp(Sender: TObject);
begin
  if @SetMapRange<>nil then
    SetMapRange(trunc(dtpArchive.Date),trunc(dtpArchive.Date)+1);
end;

procedure TPlayerFM.dtpArchiveMouseEnter(Sender: TObject);
var
  tmpPoint: TPoint;
begin
  CalendarPopupFM.MonthCalendar.OnClick:=MonthClick;
  tmpPoint:=dtpArchive.ClientToScreen(Point(0,0));
  CalendarPopupFM.Left:=tmpPoint.X;
  CalendarPopupFM.Top:=tmpPoint.Y-CalendarPopupFM.Height+dtpArchive.Height;
  CalendarPopupFM.MonthCalendar.Date:=dtpArchive.Date;
  CalendarPopupFM.Show;
end;

procedure TPlayerFM.FormCreate(Sender: TObject);
begin
  FirstTime:=true;
  //dsPlayerCameras.Connection:=DataDM.Connection;
  CalendarPopupFM:=TCalendarPopupFM.Create(nil);
  if FileExists('ContourPlayer.dll') then
  begin
    HLibrary:=LoadLibrary('ContourPlayer.dll');
    if HLibrary>0 then
    begin
      BeginUpdate:=GetProcAddress(HLibrary,'BeginUpdate');
      ConnectServer:=GetProcAddress(HLibrary,'ConnectServer');
      DisconnectServer:=GetProcAddress(HLibrary,'DisconnectServer');
      EndUpdate:=GetProcAddress(HLibrary,'EndUpdate');
      FocusCamera:=GetProcAddress(HLibrary,'FocusCamera');
      GetArchDays:=GetProcAddress(HLibrary,'GetArchDays');
      GetArea:=GetProcAddress(HLibrary,'GetArea');
      GetCurTime:=GetProcAddress(HLibrary,'GetCurTime');
      GetServerCameras:=GetProcAddress(HLibrary,'GetServerCameras');
      Play:=GetProcAddress(HLibrary,'Play');
      PlayOperative:=GetProcAddress(HLibrary,'PlayOperative');
      SetCameraInArea:=GetProcAddress(HLibrary,'SetCameraInArea');
      SetMapRange:=GetProcAddress(HLibrary,'SetMapRange');
      SetScreen:=GetProcAddress(HLibrary,'SetScreen');
      ShowMap:=GetProcAddress(HLibrary,'ShowMap');
      ShowScreen:=GetProcAddress(HLibrary,'ShowScreen');
      Step:=GetProcAddress(HLibrary,'Step');
      StepBack:=GetProcAddress(HLibrary,'StepBack');
      Stop:=GetProcAddress(HLibrary,'Stop');
      StopOperative:=GetProcAddress(HLibrary,'StopOperative');
      StartTimer.Enabled:=true;
    end;
  end;
  dtpArchive.DateTime:=now;
  DragThumbFM:=TDragThumbFM.Create(nil);
  DragTimer.Enabled:=true;
  EventsFM:=TEventsFM.Create(nil);
  EventsFM.Parent:=tsEvents;
  EventsFM.Show;
end;

procedure TPlayerFM.FormDestroy(Sender: TObject);
begin
  DragTimer.Enabled:=false;
  if assigned(UpdateCamerasThread) then
    UpdateCamerasThread.Stop;
  if assigned(DragThumbFM) then
    DragThumbFM.Free;
  if @DisconnectServer<>nil then
    DisconnectServer(0);
  CalendarPopupFM.Free;
end;

procedure TPlayerFM.hbFastClick(Sender: TObject);
begin
  if @Play<>nil then
    Play(PlayCallback,DrawCallback,3);
end;

procedure TPlayerFM.hbPlayClick(Sender: TObject);
begin
  if @Play<>nil then
    Play(PlayCallback,DrawCallback,1);
end;

procedure TPlayerFM.hbStepBackClick(Sender: TObject);
begin
  if @StepBack<>nil then
    StepBack;
end;

procedure TPlayerFM.hbStepClick(Sender: TObject);
begin
  if @Step<>nil then
    Step;
end;

procedure TPlayerFM.hbStopClick(Sender: TObject);
begin
  if @Stop<>nil then
    Stop;
end;

procedure TPlayerFM.lvCamerasCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  var DefaultDraw: Boolean);
var
  tmpTime: int64;
begin
  tmpTime:=MilliSecondsBetween(UnixDateDelta,now)-int64(Item.Data);
  if tmpTime<90000 then
    Sender.Canvas.Font.Color := clGreen
  else if tmpTime<300000 then
    Sender.Canvas.Font.Color := clBlue
  else
    Sender.Canvas.Font.Color := clLtGray;
end;

procedure TPlayerFM.lvCamerasDblClick(Sender: TObject);
var
  q: TDateTime;
  sl: TStringList;
begin
  if assigned(lvCameras.Selected) then
  begin
    if @GetCurTime<>nil then
    begin
      q:=GetCurTime;
      FocusCamera(0,lvCameras.Selected.ImageIndex,IncHour(q,-1));
    end;
  end
  else
  begin
    sl:=TStringList.Create;
    try
      sl.Text:=GetServerCameras(0);
      if trim(sl.Text)<>'' then
        UpdateCameras(sl);
    finally
      sl.Free;
    end;
  end;
end;

procedure TPlayerFM.lvCamerasMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
  begin
    StartP:=TControl(Sender).ClientToScreen(Point(X,Y));
    VideoRect.TopLeft:=ClientToScreen(Point(pnlPlayer.Left,pnlPlayer.Top));
    VideoRect.BottomRight:=ClientToScreen(Point(pnlPlayer.Width,pnlPlayer.Height));
  end;
  DragThumbFM.Hide;
end;

procedure TPlayerFM.lvCamerasMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if csDestroying in ComponentState then
    exit;
  if (ssLeft in Shift) then
  begin
    if ((x<>StartP.X) or (y<>Startp.Y)) then
    begin
      P:=TControl(Sender).ClientToScreen(Point(X,Y));
      if DragThumbFM.Visible then
      begin
        DragThumbFM.Left:=P.X;
        DragThumbFM.Top:=P.Y;
        //если под указателем не проигрыватель, то превратить курсор в перечёркнутый
        if (P.X>VideoRect.Left)and(P.X<VideoRect.Right)and(P.Y>VideoRect.Top)and(P.Y<VideoRect.Bottom) then
          Screen.Cursor:=crDrag
        else
          Screen.Cursor:=crNoDrop;
      end
      else if lvCameras.ItemIndex>-1 then
      begin
        DragThumbFM.lblCaption.Caption:=lvCameras.Items[lvCameras.ItemIndex].Caption;
        DragThumbFM.Width:=DragThumbFM.lblCaption.Canvas.TextWidth(DragThumbFM.lblCaption.Caption)+16;
        DragThumbFM.Height:=20;
        DragThumbFM.Left:=P.X;
        DragThumbFM.Top:=P.Y;
        DragThumbFM.Show;
      end;
    end;
  end;
end;

procedure TPlayerFM.MonthClick(Sender: TObject);
var
  tmpPoint: TPoint;
begin
  //клик на дне?
  //где мышь?
  tmpPoint:=Mouse.CursorPos;
  tmpPoint:=CalendarPopupFM.MonthCalendar.ScreenToClient(tmpPoint);
  if (tmpPoint.Y>49)and(tmpPoint.Y<138)and(tmpPoint.X>5)and(tmpPoint.X<157)and(dtpArchive.Date<>CalendarPopupFM.MonthCalendar.Date) then
  begin
    if @SetMapRange<>nil then
      SetMapRange(trunc(CalendarPopupFM.MonthCalendar.Date),trunc(CalendarPopupFM.MonthCalendar.Date)+1);
    dtpArchive.Date:=CalendarPopupFM.MonthCalendar.Date;
    CalendarPopupFM.Hide;
  end;
end;

procedure TPlayerFM.pnlPlayerResize(Sender: TObject);
var
  wc: HWND;
  SRect: TRect;
begin
  //поискать на себе ещё окно и если есть, то ресайзить по своим размерам
  wc:=GetWindow(TPanel(Sender).Handle,GW_CHILD);
  if wc>0 then
  begin
    SRect.TopLeft:=Point(0,0);
    SRect.BottomRight:=Point(TPanel(Sender).Width,TPanel(Sender).Height);
    SetWindowPos(wc,HWND_TOP,SRect.Left,SRect.Top,SRect.Right,SRect.Bottom,SWP_NOZORDER);
  end;
end;

procedure TPlayerFM.SpeedButton1Click(Sender: TObject);
begin
  if @SetScreen<>nil then
    SetScreen(TSpeedButton(Sender).Tag);
  with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
    try
      WriteInteger('PLAYER','Screen',TSpeedButton(Sender).Tag);
    finally
      Free;
    end;
  TSpeedButton(Sender).Down:=true;
end;

procedure TPlayerFM.StartTimerTimer(Sender: TObject);
var
  sl: TStringList;
  q,w: integer;
  tmpYear,tmpMonth,tmpDay,ScreenType: integer;
begin
  StartTimer.Enabled:=false;
  Screen.Cursor:=crHourGlass;
  try
    try
      if @DisconnectServer<>nil then
        DisconnectServer(0);
      Application.ProcessMessages;
      if @ConnectServer<>nil then
      begin
        ShowMap(pnlSlider.Handle);
        Application.ProcessMessages;
        ShowScreen(pnlPlayer.Handle);
        Application.ProcessMessages;
        lvCameras.Groups.Clear;
        if ConnectServer(CurrentServer)>=0 then
        begin
          lvCameras.Groups.Add.Header:=CurrentServer;
          sl:=TStringList.Create;
          try
            sl.Text:=GetServerCameras(0);
            UpdateCameras(sl);
            BeginUpdate;
            try
              with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
                try
                  ScreenType:=ReadInteger('PLAYER','Screen',1);
                  SetScreen(ScreenType);
                  ReadSectionValues('PLAYER',sl);
                  case ScreenType of
                    1: ScreenType:=4;
                    2: ScreenType:=7;
                    3: ScreenType:=8;
                    4: ScreenType:=9;
                    5: ScreenType:=10;
                    6: ScreenType:=13;
                    7: ScreenType:=16;
                    8: ScreenType:=25;
                    9: ScreenType:=33;
                  else
                    ScreenType:=1;
                  end;
                  if sl.Count>1 then
                    for q := 0 to ScreenType-1 do
                      SetCameraInArea(0,StrToIntDef(sl.Values[IntToStr(q)],0),q)
                  else
                    for q := 0 to min(lvCameras.Items.Count,ScreenType)-1 do
                      SetCameraInArea(0,lvCameras.Items[q].ImageIndex,q);
                finally
                  Free;
                end;
            finally
              EndUpdate;
            end;
            Application.ProcessMessages;
            sl.Text:=GetArchDays(0);
            CalendarPopupFM.Days:=[];
            for q := 0 to sl.Count-1 do
            begin
              w:=StrToInt(sl[q]);
              tmpYear:=w div 10000;
              tmpMonth:=(w-tmpYear*10000) div 100;
              tmpDay:=w-tmpYear*10000-tmpMonth*100;
              tmpYear:=tmpYear+2000;
              CalendarPopupFM.Days:=CalendarPopupFM.Days+[trunc(EncodeDate(tmpYear,tmpMonth,tmpDay))];
            end;
          finally
            sl.Free;
          end;
        end
        else
          ShowMessage('Нет соединения с сервером -'+CurrentServer+'-');
      end;
    except on e: Exception do
      SendErrorMsg('TPlayerFM.StartTimerTimer 424: '+e.ClassName+' - '+e.Message);
    end;
  finally
    Screen.Cursor:=crDefault
  end;
  FirstTime:=false;
  UpdateCamerasThread:=TUpdateCameras.Create(false);
  if assigned(OnReady) then
    OnReady(Self);
  EventsFM.Init(ScrollCallback);
end;

procedure TPlayerFM.TimeTimerTimer(Sender: TObject);
begin
  if @GetCurTime<>nil then
    lblTime.Caption:=DateTimeToStr(GetCurTime);
end;

procedure TPlayerFM.UpdateCameras(sl: TStringList);
var
  q,w: integer;
  ListItem: TListItem;
  nVal: string;
  tmpTime: int64;
begin
  try
    lvCameras.Items.Clear;
    for q := 0 to sl.Count-1 do
    begin
      ListItem:=lvCameras.Items.Add;
      ListItem.GroupID:=0;
      ListItem.ImageIndex:=StrToIntDef(sl.Names[q],0);
      nVal:=sl.ValueFromIndex[q];
      tmpTime:=0;
      w:=Pos(';',nVal);
      if w>1 then
      begin
        tmpTime:=StrToInt64Def(copy(nVal,w+1,16),0);
        Delete(nVal,w,16);
      end;
      ListItem.Data:=Pointer(tmpTime);
      ListItem.Caption:=nVal;
    end;
    Application.ProcessMessages;
  except on e: Exception do
    SendErrorMsg('TPlayerFM.UpdateCameras 539: '+e.ClassName+' - '+e.Message);
  end;
end;

{ TUpdateCameras }

procedure TUpdateCameras.Execute;
var
  aStopped: TWaitResult;
begin
  FreeOnTerminate:=true;
  try
    FWaitForStop:=TEvent.Create(nil,True,False,'');
    try
      sl:=TStringList.Create;
      try
        while not Terminated do
          try
            aStopped:=FWaitForStop.WaitFor(30000);
            if aStopped<>wrTimeOut then
              exit;
            sl.Text:=GetServerCameras(0);
            if trim(sl.Text)<>'' then
              Synchronize(UpdateCameras);
          except on e: Exception do
            SendErrorMsg('TUpdateCameras.Execute 545: '+e.ClassName+' - '+e.Message);
          end;
      finally
        sl.Free;
      end;
    finally
      FWaitForStop.Free;
    end;
  finally
    Terminate;
  end;
end;

procedure TUpdateCameras.Stop;
begin
  Terminate;
  FWaitForStop.SetEvent;
end;

procedure TUpdateCameras.UpdateCameras;
begin
  if assigned(PlayerFM) then
    PlayerFM.UpdateCameras(sl);
end;

end.
