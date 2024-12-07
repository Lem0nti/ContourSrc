unit ccMain_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, ccCameras_FM,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, ccData_DM, ccServiceCheck_TH, Vcl.Menus, WinSvc, ccPlugins_FM,
  ccArchive_FM, ccPlayer_FM, IniFiles, Data.Win.ADODB, ccDBSelect_FM, DB, ABL.Core.Debug, Vcl.ExtCtrls;

type
  TMainFM = class(TForm)
    PageControl: TPageControl;
    tsPlayer: TTabSheet;
    tsCameras: TTabSheet;
    tsArchive: TTabSheet;
    sbStatus: TStatusBar;
    ppmServiceStarted: TPopupMenu;
    miStopService: TMenuItem;
    miRestartService: TMenuItem;
    ppmSwitchServer: TPopupMenu;
    miCurrentServer: TMenuItem;
    miSwitchServer: TMenuItem;
    miInstall: TMenuItem;
    tsPlugins: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure sbStatusDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
    procedure sbStatusMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure sbStatusMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure sbStatusMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure miStopServiceClick(Sender: TObject);
    procedure miRestartServiceClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure PageControlChanging(Sender: TObject; var AllowChange: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure miCurrentServerAdvancedDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; State: TOwnerDrawState);
    procedure ppmSwitchServerPopup(Sender: TObject);
    procedure miSwitchServerClick(Sender: TObject);
    procedure miInstallClick(Sender: TObject);
    procedure miCurrentServerMeasureItem(Sender: TObject; ACanvas: TCanvas; var Width, Height: Integer);
  private
    { Private declarations }
    FHintshow: Boolean;
    FHint: THintWindow;
    FHintText: string;
    FHintWidth: Integer;
    procedure HideWarning;
    procedure PlayerReady(Sender: TObject);
    procedure ShowArchive;
    procedure ShowCameras;
    procedure ShowPlayer;
    procedure ShowPlugins;
  public
    { Public declarations }
  end;

var
  MainFM: TMainFM;

implementation

{$R *.dfm}

function WinExecAndWait32(FileName: string; Visibility: integer): integer;
{ returns -1 if the Exec failed, otherwise returns the process' }
{ exit code when the process terminates.                        }
var
  zAppName: array[0..512] of char;
  zCurDir : array[0..255] of char;
  WorkDir : string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  {$IFNDEF Delphi3Below}
    CardinalResult: cardinal;
  {$ENDIF}
begin
  StrPCopy(zAppName, FileName);
  GetDir(0, WorkDir);
  StrPCopy(zCurDir, WorkDir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;
  if not CreateProcess(nil,
                       zAppName, { pointer to command line string }
                       nil, { pointer to process security attributes }
                       nil, { pointer to thread security attributes }
                       false, { handle inheritance flag }
                       CREATE_NEW_CONSOLE or { creation flags }
                       NORMAL_PRIORITY_CLASS,
                       nil, { pointer to new environment block }
                       nil, { pointer to current directory name }
                       StartupInfo, { pointer to STARTUPINFO }
                       ProcessInfo) then { pointer to PROCESS_INF }
    Result := -1
  else
    begin
      WaitforSingleObject(ProcessInfo.hProcess, INFINITE);
      {$IFDEF Delphi3Below}
        GetExitCodeProcess(ProcessInfo.hProcess, Result);
      {$ELSE}
        GetExitCodeProcess(ProcessInfo.hProcess, CardinalResult);
        Result := CardinalResult;
      {$ENDIF}
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end;
end;

procedure TMainFM.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=true;
  if (Assigned(CamerasFM) and CamerasFM.lblWarning.Visible)or(Assigned(ArchiveFM) and ArchiveFM.lblWarning.Visible) then
  begin
    ppmServiceStarted.Tag:=0;
    case MessageBoxEx(Handle,'Для вступления изменений в силу, необходимо перезапустить службу сервера. Перезапустить сейчас?','Подтверждение выхода',MB_YESNOCANCEL+MB_ICONQUESTION,
        RUSSIAN_CHARSET) of
      IDYES: miRestartServiceClick(miRestartService);
      IDCANCEL: CanClose:=false;
    end;
  end;
end;

procedure TMainFM.FormCreate(Sender: TObject);
var
  VerString: string;
  AHandle,vSize: Cardinal;
  Buffer: PChar;
  FileVersion: PVSFixedFileInfo;
  FConnectionString: TStringList;
begin
  ServiceCheck:=TServiceCheck.Create;
  VerString:='<версия не известна>';
  vSize:=GetFileVersionInfoSize(PChar(ParamStr(0)),AHandle);
  Buffer:=AllocMem(vSize+1);
  try
    if GetFileVersionInfo(PChar(ParamStr(0)),AHandle,vSize,Buffer) then
      if VerQueryValue(Buffer,'\',Pointer(FileVersion),UINT(vSize)) then
        if vSize>=SizeOf(TVSFixedFileInfo) then
          VerString:=IntToStr(HIWORD(FileVersion.dwFileVersionMS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionMS))+'.'+
              IntToStr(HIWORD(FileVersion.dwFileVersionLS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionLS));
    sbStatus.Panels[0].Text:='Клиент: '+VerString;
    VerString:='<версия не известна>';
    vSize:=GetFileVersionInfoSize(PChar(ExtractFilePath(ParamStr(0))+'Contour.exe'),AHandle);
    if GetFileVersionInfo(PChar(ExtractFilePath(ParamStr(0))+'Contour.exe'),AHandle,vSize,Buffer) then
      if VerQueryValue(Buffer,'\',Pointer(FileVersion),UINT(vSize)) then
        if vSize>=SizeOf(TVSFixedFileInfo) then
          VerString:=IntToStr(HIWORD(FileVersion.dwFileVersionMS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionMS))+'.'+
              IntToStr(HIWORD(FileVersion.dwFileVersionLS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionLS));
    sbStatus.Panels[2].Text:='Сервер: '+VerString;
    VerString:='<версия не известна>';
    vSize:=GetFileVersionInfoSize(PChar(ExtractFilePath(ParamStr(0))+'ArchContour.exe'),AHandle);
    if GetFileVersionInfo(PChar(ExtractFilePath(ParamStr(0))+'ArchContour.exe'),AHandle,vSize,Buffer) then
      if VerQueryValue(Buffer,'\',Pointer(FileVersion),UINT(vSize)) then
        if vSize>=SizeOf(TVSFixedFileInfo) then
          VerString:=IntToStr(HIWORD(FileVersion.dwFileVersionMS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionMS))+'.'+
              IntToStr(HIWORD(FileVersion.dwFileVersionLS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionLS));
    sbStatus.Panels[4].Text:='Архив: '+VerString;
    VerString:='<версия не известна>';
    vSize:=GetFileVersionInfoSize(PChar(ExtractFilePath(ParamStr(0))+'Retina.exe'),AHandle);
    if GetFileVersionInfo(PChar(ExtractFilePath(ParamStr(0))+'ArchContour.exe'),AHandle,vSize,Buffer) then
      if VerQueryValue(Buffer,'\',Pointer(FileVersion),UINT(vSize)) then
        if vSize>=SizeOf(TVSFixedFileInfo) then
          VerString:=IntToStr(HIWORD(FileVersion.dwFileVersionMS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionMS))+'.'+
              IntToStr(HIWORD(FileVersion.dwFileVersionLS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionLS));
    sbStatus.Panels[6].Text:='Аналитика: '+VerString;
  finally
    FreeMem(Buffer,vSize+1);
  end;
  FHint := THintWindow.Create(Self);
  FHint.Color := clInfoBk;
  FConnectionString:=TStringList.Create;
  try
    With TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
      try
        ReadSectionValues('CONNECTION',FConnectionString);
      finally
        Free;
      end;
    DataDM:=TDataDM.Create(FConnectionString.Text,1);
  finally
    FreeAndNil(FConnectionString);
  end;
  sbStatus.Panels[7].Text:='БД: '+DataDM.DBVersion;
  PageControl.OnChange:=nil;
  try
    with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
      try
        PageControl.TabIndex:=ReadInteger('MAIN','Page',0);
      finally
        Free;
      end;
    PageControlChange(PageControl);
  finally
    PageControl.OnChange:=PageControlChange;
  end;
end;

procedure TMainFM.HideWarning;
begin
  if assigned(CamerasFM) then
    CamerasFM.lblWarning.Hide;
  if assigned(ArchiveFM) then
    ArchiveFM.lblWarning.Hide;
end;

procedure TMainFM.miCurrentServerAdvancedDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  State: TOwnerDrawState);
var
  Txt: TCaption;
  TxtRect, BannerRect: TRect;
begin
  Txt := TMenuItem( Sender ).Caption;
  TxtRect := ARect;
  BannerRect := ARect;
  TxtRect.Left := ARect.Left + 25;
  BannerRect.Right := BannerREct.Left + 25;
  with ACanvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(BannerRect);
    if TMenuItem( Sender ).Default then
      ACanvas.Font.Style := [fsBold]
    else
      ACanvas.Font.Style := [];
    Brush.Color := clWindow;
    if odSelected in State then
    begin
      if odDisabled in State then
        Font.Color := clBlack
      else
      begin
        Brush.Color := clNavy;
        Font.Color := clWhite;
      end;
      Pen.Style := psSolid;
      Pen.Color := clBtnShadow;
      Rectangle( ARect );
    end
    else
      FillRect( TxtRect );
    if Txt = '-' then
    begin
      Brush.Color := clBlack;
      Pen.Color := clBtnShadow;
      MoveTo(32,TxtRect.Top+(TxtRect.Bottom-TxtRect.Top)div 2);
      LineTo(TxtRect.Right,TxtRect.Top+(TxtRect.Bottom-TxtRect.Top)div 2);
    end
    else
    begin
      TextOut( TxtRect.Left + 4, TxtRect.Top + 2, Txt );
      if TMenuItem( Sender ).ShortCut <> 0 then
      begin
        Txt:=ShortCutToText(TMenuItem(Sender).ShortCut);
        TxtRect.Top:=TxtRect.Top+2;
        TxtRect.Left:=TxtRect.Right-TextWidth(Txt)-5;
        TextOut(TxtRect.Left,TxtRect.Top,Txt);
      end;
    end;
  end;
end;

procedure TMainFM.miCurrentServerMeasureItem(Sender: TObject; ACanvas: TCanvas; var Width, Height: Integer);
begin
  Width:=Width+27;
end;

procedure TMainFM.miInstallClick(Sender: TObject);
var
  slbat: TStringList;
  AType, AServer, ADatabase, AUser, APass: string;
  FConnectionString: TStringList;
begin
  Screen.Cursor:=crHourGlass;
  try
    //выбор БД
    DBSelectFM:=TDBSelectFM.Create(nil);
    try
      AType:='MS';
      AServer:='.';
      ADatabase:='Contour';
      AUser:='';
      APass:='';
      if DBSelectFM.Execute(AType,AServer,ADatabase,AUser,APass) then
      begin
        FConnectionString:=TStringList.Create;
        try
          with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
            try
              WriteString('CONNECTION','Type',AType);
              WriteString('CONNECTION','Server',AServer);
              WriteString('CONNECTION','Database',IfThen(AType='PG','postgres','master'));
              WriteString('CONNECTION','User',AUser);
              WriteString('CONNECTION','Password',APass);
              ReadSectionValues('CONNECTION',FConnectionString);
              //создание БД
              if assigned(DataDM) then
                DataDM.Free;
              DataDM:=TDataDM.Create(FConnectionString.Text,0);
              try
                if AType='PG' then
                begin
                  DataDM.QueryPG.Close;
                  DataDM.QueryPG.SQL.Text:='SELECT * FROM pg_database WHERE datname='''+lowercase(ADatabase)+'''';
                  DataDM.QueryPG.Open;
                  if DataDM.QueryPG.IsEmpty then
                    DataDM.ExecSQL('create database '+lowercase(ADatabase));
                end
                else
                  DataDM.ExecSQL('if not exists(select * from sys.databases where name='''+ADatabase+''') create database '+ADatabase);
              finally
                DataDM.Free;
              end;
              //запись в свой ини
              WriteString('CONNECTION','Database',ADatabase);
            finally
              Free;
            end;
          //запись в ини служб
          with TIniFile.Create(ExtractFilePath(ParamStr(0))+'Contour.ini') do
            try
              WriteString('CONNECTION','Type',AType);
              WriteString('CONNECTION','Server',AServer);
              WriteString('CONNECTION','Database',ADatabase);
              WriteString('CONNECTION','User',AUser);
              WriteString('CONNECTION','Password',APass);
            finally
              Free;
            end;
          with TIniFile.Create(ExtractFilePath(ParamStr(0))+'ArchContour.ini') do
            try
              WriteString('CONNECTION','Type',AType);
              WriteString('CONNECTION','Server',AServer);
              WriteString('CONNECTION','Database',ADatabase);
              WriteString('CONNECTION','User',AUser);
              WriteString('CONNECTION','Password',APass);
            finally
              Free;
            end;
          //регистрация и запуск служб
          slbat:=TStringList.Create;
          try
            slbat.AddObject('cd /d %~dp0',nil);
            slbat.AddObject('Contour -install -silent',nil);
            slbat.AddObject('net start abContour',nil);
            slbat.AddObject('ArchContour -install -silent',nil);
            slbat.AddObject('net start abArchContour',nil);
            slbat.SaveToFile(ExtractFilePath(ParamStr(0))+'install.bat');
          finally
            slbat.Free;
          end;
          WinExecAndWait32(ExtractFilePath(ParamStr(0))+'install.bat',SW_HIDE);
          DataDM:=TDataDM.Create(FConnectionString.Text);
        finally
          FreeAndNil(FConnectionString);
        end;
      end;
    finally
      DBSelectFM.Free;
    end;
  finally
    Screen.Cursor:=crDefault;
  end;
end;

procedure TMainFM.miRestartServiceClick(Sender: TObject);
var
  st: TServiceStatus;
  VarPar: PChar;
  LEM: string;
  FService: Cardinal;
begin
  if ppmServiceStarted.Tag=0 then
    LEM:=ServiceCheck.ServerInfo.LastErrorMessage
  else if ppmServiceStarted.Tag=1 then
    LEM:=ServiceCheck.ArchInfo.LastErrorMessage
  else
    LEM:=ServiceCheck.RetinaInfo.LastErrorMessage;
  if LEM='' then
  begin
    if ppmServiceStarted.Tag=0 then
      FService:=ServiceCheck.ServerInfo.Handle
    else if ppmServiceStarted.Tag=1 then
      FService:=ServiceCheck.ArchInfo.Handle
    else
      FService:=ServiceCheck.RetinaInfo.Handle;
    Screen.Cursor:=crHourGlass;
    try
      ControlService(FService,SERVICE_CONTROL_STOP,st);
      Sleep(1000);
      StartService(FService,0,VarPar);
      if ppmServiceStarted.Tag=0 then
      begin
        ServiceCheck.ServerInfo.Running:=true;
        HideWarning;
      end
      else if ppmServiceStarted.Tag=1 then
        ServiceCheck.ArchInfo.Running:=true
      else
        ServiceCheck.RetinaInfo.Running:=true;
      Invalidate;
    finally
      Screen.Cursor:=crDefault;
    end;
  end;
end;

procedure TMainFM.miStopServiceClick(Sender: TObject);
var
  st: TServiceStatus;
  LEM: string;
  FService: Cardinal;
begin
  if ppmServiceStarted.Tag=0 then
    LEM:=ServiceCheck.ServerInfo.LastErrorMessage
  else if ppmServiceStarted.Tag=1 then
    LEM:=ServiceCheck.ArchInfo.LastErrorMessage
  else
    LEM:=ServiceCheck.RetinaInfo.LastErrorMessage;
  if LEM='' then
  begin
    if ppmServiceStarted.Tag=0 then
      FService:=ServiceCheck.ServerInfo.Handle
    else if ppmServiceStarted.Tag=1 then
      FService:=ServiceCheck.ArchInfo.Handle
    else
      FService:=ServiceCheck.RetinaInfo.Handle;
    ControlService(FService,SERVICE_CONTROL_STOP,st);
    if ppmServiceStarted.Tag=0 then
      ServiceCheck.ServerInfo.Running:=false
    else if ppmServiceStarted.Tag=1 then
      ServiceCheck.ArchInfo.Running:=false
    else
      ServiceCheck.RetinaInfo.Running:=false;
    sbStatus.Invalidate;
  end;
end;

procedure TMainFM.miSwitchServerClick(Sender: TObject);
var
  NewCurrentServer: string;
begin
  NewCurrentServer:=InputBox('Смена подключения','Введите адрес сервера',CurrentServer);
  if NewCurrentServer<>CurrentServer then
  begin
    CurrentServer:=NewCurrentServer;
    if assigned(PlayerFM) and (PageControl.TabIndex=0) then
      PlayerFM.StartTimer.Enabled:=true
    else
    begin
      PageControl.OnChange:=nil;
      try
        PageControl.TabIndex:=0;
        PageControlChange(PageControl);
      finally
        PageControl.OnChange:=PageControlChange;
      end;
    end;
    tsCameras.TabVisible:=CurrentServer='127.0.0.1';
    tsArchive.TabVisible:=CurrentServer='127.0.0.1';
  end;
end;

procedure TMainFM.PageControlChange(Sender: TObject);
begin
  if PageControl.ActivePage=tsPlayer then
    ShowPlayer
  else if PageControl.ActivePage=tsCameras then
    ShowCameras
  else if PageControl.ActivePage=tsPlugins then
    ShowPlugins
  else if PageControl.ActivePage=tsArchive then
    ShowArchive;
  with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
    try
      WriteInteger('MAIN','Page',PageControl.TabIndex);
    finally
      Free;
    end;
end;

procedure TMainFM.PageControlChanging(Sender: TObject; var AllowChange: Boolean);
begin
  if PageControl.ActivePage=tsCameras then
    AllowChange:=CamerasFM.ChekSave
  else if PageControl.ActivePage=tsArchive then
    AllowChange:=ArchiveFM.ChekSave;
end;

procedure TMainFM.PlayerReady(Sender: TObject);
begin
  sbStatus.Invalidate;
end;

procedure TMainFM.ppmSwitchServerPopup(Sender: TObject);
begin
  try
    miCurrentServer.Caption:='Текущее подключение: '+CurrentServer;
    if miInstall.Visible then
    begin
      miInstall.Visible:=IsUserWindowsAdmin;
      if miInstall.Visible then
      begin
        //есть доступ к управлению службами
        miInstall.Visible:=assigned(ServiceCheck) and (ServiceCheck.scManager>0);
        if miInstall.Visible then
          //нет служб
          //можно устанавливать
          miInstall.Visible:=(ServiceCheck.ServerInfo.Handle=0) or (ServiceCheck.ArchInfo.Handle=0);
      end;
    end;
  except on e: Exception do
    ShowMessage('TMainFM.ppmSwitchServerPopup 463: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TMainFM.sbStatusDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
var
  cColor: TColor;
  tmpRect: TRect;
begin
  cColor:=clRed;
  if assigned(ServiceCheck) then
  begin
    if Panel.Index=1 then  //захват
    begin
      if (ServiceCheck.ServerInfo.LastErrorMessage='')and ServiceCheck.ServerInfo.Running then
        cColor:=clSkyBlue;
    end
    else if Panel.Index=3 then  //архив
    begin
      if (ServiceCheck.ArchInfo.LastErrorMessage='')and ServiceCheck.ArchInfo.Running then  //
        cColor:=clSkyBlue;
    end
    else if (ServiceCheck.RetinaInfo.LastErrorMessage='')and ServiceCheck.RetinaInfo.Running then  //аналитика
        cColor:=clSkyBlue;
  end;
  sbStatus.Canvas.Brush.Color:=cColor;
  tmpRect:=Rect;
  if Panel.Bevel=pbLowered then
  begin
    tmpRect.Left:=tmpRect.Left+1;
    tmpRect.Top:=tmpRect.Top+1;
  end;
  sbStatus.Canvas.FillRect(tmpRect);
end;

procedure TMainFM.sbStatusMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  tmpLeft: integer;
begin
  if (X>sbStatus.Panels[0].Width) and (X<sbStatus.Panels[0].Width+sbStatus.Panels[1].Width) then
    sbStatus.Panels[1].Bevel:=pbLowered
  else
  begin
    tmpLeft:=sbStatus.Panels[0].Width+sbStatus.Panels[1].Width+sbStatus.Panels[2].Width;
    if (X>tmpLeft) and (X<tmpLeft+sbStatus.Panels[3].Width) then
      sbStatus.Panels[3].Bevel:=pbLowered
    else
    begin
      tmpLeft:=tmpLeft+sbStatus.Panels[3].Width+sbStatus.Panels[4].Width;
      if (X>tmpLeft) and (X<tmpLeft+sbStatus.Panels[5].Width) then
        sbStatus.Panels[5].Bevel:=pbLowered;
    end;
  end;
end;

procedure TMainFM.sbStatusMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  tmpLeft: integer;
begin
  FHintText:='';
  if assigned(ServiceCheck) then
  begin
    if (X>sbStatus.Panels[0].Width) and (X<sbStatus.Panels[0].Width+sbStatus.Panels[1].Width) then
      FHintText:=ServiceCheck.ServerInfo.LastErrorMessage
    else
    begin
      tmpLeft:=sbStatus.Panels[0].Width+sbStatus.Panels[1].Width+sbStatus.Panels[2].Width;
      if (X>tmpLeft) and (X<tmpLeft+sbStatus.Panels[3].Width) then
        FHintText:=ServiceCheck.ArchInfo.LastErrorMessage
      else
      begin
        tmpLeft:=tmpLeft+sbStatus.Panels[3].Width+sbStatus.Panels[4].Width;
        if (X>tmpLeft) and (X<tmpLeft+sbStatus.Panels[5].Width) then
          FHintText:=ServiceCheck.RetinaInfo.LastErrorMessage;
      end;
    end;
  end;
  FHintWidth := FHint.Canvas.TextWidth(FHintText);
  if (FHintshow = false) and (length(trim(FHintText)) <> 0) then
    FHint.ActivateHint(Rect(Mouse.CursorPos.X, Mouse.CursorPos.Y - 20, Mouse.CursorPos.X + FHintWidth + 10, Mouse.CursorPos.Y - 5), FHintText);
  FHintshow := FHintWidth > 0;
  if not FHintshow then
    FHint.ReleaseHandle;
end;

procedure TMainFM.sbStatusMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  VarPar: PChar;
  tmpLeft: integer;
begin
  try
    sbStatus.Panels[1].Bevel:=pbRaised;
    sbStatus.Panels[3].Bevel:=pbRaised;
    sbStatus.Panels[5].Bevel:=pbRaised;
    if assigned(ServiceCheck) then
    begin
      if (Button=mbRight)and(X<sbStatus.Panels[0].Width)  then
        ppmSwitchServer.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y)
      else if (X>sbStatus.Panels[0].Width) and(X<sbStatus.Panels[0].Width+sbStatus.Panels[1].Width)and(ServiceCheck.ServerInfo.LastErrorMessage='') then
      begin
        if ServiceCheck.ServerInfo.Running then
        begin
          ppmServiceStarted.Tag:=0;
          ppmServiceStarted.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y)
        end
        else
        begin
          StartService(ServiceCheck.ServerInfo.Handle,0,VarPar);
          ServiceCheck.ServerInfo.Running:=true;
          HideWarning;
        end;
      end
      else
      begin
        tmpLeft:=sbStatus.Panels[0].Width+sbStatus.Panels[1].Width+sbStatus.Panels[2].Width;
        if (X>tmpLeft) and (X<tmpLeft+sbStatus.Panels[3].Width) then
        begin
          if ServiceCheck.ArchInfo.Running then
          begin
            ppmServiceStarted.Tag:=1;
            ppmServiceStarted.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y)
          end
          else
          begin
            StartService(ServiceCheck.ArchInfo.Handle,0,VarPar);
            ServiceCheck.ArchInfo.Running:=true;
          end;
        end
        else
        begin
          tmpLeft:=tmpLeft+sbStatus.Panels[3].Width+sbStatus.Panels[4].Width;
          if (X>tmpLeft) and (X<tmpLeft+sbStatus.Panels[5].Width) then
          begin
            if ServiceCheck.RetinaInfo.Running then
            begin
              ppmServiceStarted.Tag:=2;
              ppmServiceStarted.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y)
            end
            else
            begin
              StartService(ServiceCheck.RetinaInfo.Handle,0,VarPar);
              ServiceCheck.RetinaInfo.Running:=true;
            end;
          end;
        end;
      end;
    end;
    Invalidate;
  except on e: Exception do
    ShowMessage('TMainFM.sbStatusMouseUp 500: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TMainFM.ShowArchive;
begin
  if not assigned(ArchiveFM) then
  begin
    ArchiveFM:=TArchiveFM.Create(tsCameras);
    ArchiveFM.Parent:=tsArchive;
  end;
  if assigned(DataDM.tArchive) then
    DataDM.tArchive.Open;
  ArchiveFM.Show;
end;

procedure TMainFM.ShowCameras;
begin
  if not assigned(CamerasFM) then
  begin
    CamerasFM:=TCamerasFM.Create(tsCameras);
    CamerasFM.Parent:=tsCameras;
  end;
  if assigned(DataDM.tCamera) then
    DataDM.tCamera.Open;
  CamerasFM.Show;
end;

procedure TMainFM.ShowPlayer;
begin
  if not assigned(PlayerFM) then
  begin
    PlayerFM:=TPlayerFM.Create(tsPlayer);
    PlayerFM.Parent:=tsPlayer;
  end;
  if assigned(DataDM.tCamera) then
    DataDM.tCamera.Open;
  PlayerFM.OnReady:=PlayerReady;
  PlayerFM.Show;
end;

procedure TMainFM.ShowPlugins;
var
  DataSet: TDataSet;
begin
  if not assigned(PluginsFM) then
  begin
    PluginsFM:=TPluginsFM.Create(tsPlugins);
    PluginsFM.Parent:=tsPlugins;
  end;
  DataSet:=DataDM.PluginDataSet;
  if assigned(DataSet) then
    DataSet.Open;
  PluginsFM.Show;
end;

end.
