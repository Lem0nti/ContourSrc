unit cpThumb_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, ComObj,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Math, ShlObj,
  Vcl.StdCtrls, ABL.Core.ThreadItem, ABL.Core.Debug, cpArchManager_TH, jpeg;

const
  WM_SHOW_SLIDE = WM_USER+150;
  WM_SHOW_ALARM = WM_USER+151;

type
  PVideoPoint=^TVideoPoint;
  TVideoPoint=record
    DateTime: TDateTime;
    ID_Server: integer;
    ID_Camera: integer;
    Handle: THandle;
    Alarm: boolean;
  end;

  PANSIFileName=^TANSIFileName;
  TANSIFileName=record
    FileName: array [0..511] of AnsiChar;
  end;

  TSlideLoader=class(TThread)
  protected
    procedure Execute; override;
  end;

  TDelayProc = procedure of object;

  TThumbFM = class(TForm)
    Image: TImage;
    lblAlarm: TLabel;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
    FCurDate, FMinSec, FMaxSec, FCurID_Camera, FCurServer: integer;
    SlideLoader: TSlideLoader;
    DelatMethod: TDelayProc;
    FAllowHandle: THandle;
    procedure DelayExecute(AMethod: TDelayProc; APause: Cardinal);
    procedure WMShowSlide(var Message: TMessage); message WM_SHOW_SLIDE;
    procedure WMShowAlarm(var Message: TMessage); message WM_SHOW_ALARM;
  protected
    procedure CreateWnd; override;
  public
    { Public declarations }
    procedure ShowAlarm(AAlarm: string);
    procedure ShowSlide(AFileName: TFileName);
    procedure TryShow(AIndex, AID_Camera: Integer; ADateTime: TDateTime; AllowHandle: THandle; AAlarm: boolean);
    procedure TryHide;
  end;

var
  ThumbFM: TThumbFM;
  FRequestQueue: TThreadItem;

implementation

{$R *.dfm}

procedure TThumbFM.CreateWnd;
var
  Taskbar: ITaskbarList;
begin
  inherited;
  Taskbar := CreateComObject(CLSID_TaskbarList) as ITaskbarList;
  Taskbar.HrInit;
  Taskbar.DeleteTab(Handle);
end;

procedure TThumbFM.DelayExecute(AMethod: TDelayProc; APause: Cardinal);
begin
  DelatMethod:=AMethod;
  Timer.Interval:=APause;
  Timer.Enabled:=true;
end;

procedure TThumbFM.FormCreate(Sender: TObject);
var
  WRegion: HRGN;
begin
  WRegion:=CreateRoundRectRgn(0,0,Width,Height-8,4,4);
  SetWindowRgn(Handle, WRegion, True);
  DeleteObject(WRegion);
  FRequestQueue:=TThreadItem.Create('SlideRequest');
  SlideLoader:=TSlideLoader.Create(false);
end;

procedure TThumbFM.FormDestroy(Sender: TObject);
begin
  SlideLoader.Terminate;
  FreeAndNil(FRequestQueue);
end;

procedure TThumbFM.FormHide(Sender: TObject);
begin
  tag:=tag;
end;

procedure TThumbFM.FormShow(Sender: TObject);
begin
  DelayExecute(Hide,3000);
end;

procedure TThumbFM.ShowAlarm(AAlarm: string);
begin
  lblAlarm.Caption:=AAlarm;
  lblAlarm.Visible:=true;
  lblAlarm.BringToFront;
  Left:=Mouse.CursorPos.X-Width div 2;
  Top:=Mouse.CursorPos.Y-Height-2;
  Image.Picture.Bitmap.Canvas.Brush.Color:=clCream;
  Image.Picture.Bitmap.Canvas.FillRect(Rect(0,0,Image.Picture.Bitmap.Width,Image.Picture.Bitmap.Height));
  Show;
end;

procedure TThumbFM.ShowSlide(AFileName: TFileName);
var
  CSec: integer;
  TmpStr,CamNum: string;
begin
  lblAlarm.Visible:=false;
  try
    if FileExists(AFileName) then
    begin
      Image.Picture.LoadFromFile(AFileName);
      CSec:=StrToIntDef(ChangeFileExt(ExtractFileName(AFileName),''),0);
      FMinSec:=max(CSec-6,1);
      FMaxSec:=min(CSec+6,86399);
      TmpStr:=ExtractFileDir(AFileName);
      delete(TmpStr,Length(TmpStr)-1,2);  //убираем суффикс _0
      while (Length(TmpStr)>5)and(TmpStr[Length(TmpStr)]<>'\') do
      begin
        CamNum:=TmpStr[Length(TmpStr)]+CamNum;
        delete(TmpStr,Length(TmpStr),1);
      end;
      FCurID_Camera:=StrToIntDef(CamNum,0);
      FCurDate:=StrToIntDef(copy(TmpStr,length(TmpStr)-5,5),0);
      Left:=Mouse.CursorPos.X-Width div 2;
      Top:=Mouse.CursorPos.Y-Height-2;
      Show;
    end
    else
      TryHide;
  except on e: Exception do
    SendErrorMsg('TThumbFM.ShowSlide 133: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TThumbFM.TimerTimer(Sender: TObject);
begin
  Timer.Enabled:=false;;
  if @DelatMethod<>nil then
    DelatMethod;
end;

procedure TThumbFM.TryHide;
begin
  DelayExecute(Hide,200);
end;

procedure TThumbFM.TryShow(AIndex, AID_Camera: Integer; ADateTime: TDateTime; AllowHandle: THandle; AAlarm: boolean);
var
  CSec: integer;
  NeedRequest: boolean;
  NDT: PVideoPoint;
begin
  if ADateTime>0 then
  begin
    NeedRequest:=true;
    if (FCurDate=trunc(ADateTime))and(FCurID_Camera=AID_Camera)and(FCurServer=AIndex) then
    begin
      CSec:=Round(frac(ADateTime)*MSecsPerDay) div 1000;
      if (CSec<FMaxSec)and(CSec>FMinSec) then
      begin
        Timer.Enabled:=false;
        NeedRequest:=false;
        Show;
      end;
    end;
    if NeedRequest then
    begin
      FAllowHandle:=AllowHandle;
      new(NDT);
      NDT.DateTime:=ADateTime;
      NDT.ID_Server:=AIndex;
      NDT.ID_Camera:=AID_Camera;
      NDT.Handle:=Handle;
      NDT.Alarm:=AAlarm;
      FRequestQueue.Push(NDT);
    end;
  end
  else
  begin
    TryHide;
    FMaxSec:=0;
    FMinSec:=0;
  end;
end;

procedure TThumbFM.WMShowAlarm(var Message: TMessage);
var
  FNPointer: PANSIFileName;
  FAlarm: string;
  hwp: TPoint;
begin
  FNPointer:=PANSIFileName(Message.WParam);
  try
    FAlarm:=trim(string(FNPointer.FileName));
  finally
    Dispose(FNPointer);
  end;
  GetCursorPos(hwp);
  if WindowFromPoint(hwp)=FAllowHandle then
    if FAlarm<>'' then
      ThumbFM.ShowAlarm(FAlarm)
    else
      ThumbFM.TryShow(0,0,0,FAllowHandle,false)
  else
    TryHide;
end;

procedure TThumbFM.WMShowSlide(var Message: TMessage);
var
  FNPointer: PANSIFileName;
  FileName: TFileName;
  hwp: TPoint;
begin
  FNPointer:=PANSIFileName(Message.WParam);
  try
    FileName:=trim(string(FNPointer.FileName));
  finally
    Dispose(FNPointer);
  end;
  GetCursorPos(hwp);
  if WindowFromPoint(hwp)=FAllowHandle then
    if FileExists(FileName) then
      ThumbFM.ShowSlide(FileName)
    else
      ThumbFM.TryShow(0,0,0,FAllowHandle,false)
  else
    TryHide;
end;

{ TSlideLoader }

procedure TSlideLoader.Execute;
var
  NDT: PVideoPoint;
  FNPointer: PANSIFileName;
  FileName: AnsiString;
  F: THandle;
  SlideSize: Cardinal;
begin
  FreeOnTerminate:=true;
  try
    while not Terminated do
      try
        if assigned(FRequestQueue) then
        begin
          try
            FRequestQueue.WaitForItems(INFINITE);
            NDT:=FRequestQueue.Pop;
            try
              Sleep(100);
              if FRequestQueue.Count=0 then  //пока ждём может придти новая команда
              begin
                if NDT.Alarm then
                begin
                  FileName:=AnsiString(ArchManager.GetAlarmByPoint(NDT.ID_Server,NDT.ID_Camera,NDT.DateTime));
                  if (FileName<>'') then
                  begin
                    new(FNPointer);
                    FillChar(FNPointer.FileName,512,#32);
                    Move(FileName[1],FNPointer.FileName[0],Length(FileName));
                    PostMessage(NDT.Handle,WM_SHOW_ALARM,Integer(FNPointer),0);
                  end;
                end
                else
                begin
                  FileName:=AnsiString(ArchManager.GetSlideByPoint(NDT.ID_Server,NDT.ID_Camera,NDT.DateTime));
                  //отправлять команду если файл есть и его размер больше 1 кб
                  if (FileName<>'')and(FileExists(string(FileName))) then
                  begin
                    F:=FileOpen(string(FileName),fmOpenRead or fmShareDenyNone);
                    try
                      SlideSize:=GetFileSize(F,nil);
                    finally
                      FileClose(F);
                    end;
                    if SlideSize>1024 then
                    begin
                      new(FNPointer);
                      FillChar(FNPointer.FileName,512,#32);
                      Move(FileName[1],FNPointer.FileName[0],Length(FileName));
                      PostMessage(NDT.Handle,WM_SHOW_SLIDE,Integer(FNPointer),0);
                    end;
                  end;
                end;
              end;
            finally
              Dispose(NDT);
            end;
          except on e: Exception do
            SendErrorMsg('TSlideLoader.Execute 210: '+e.ClassName+' - '+e.Message);
          end;
        end
        else
          Sleep(500);
      except on e: Exception do
        SendErrorMsg('TSlideLoader.Execute 216: '+e.ClassName+' - '+e.Message);
      end;
  finally
    Terminate;
  end;
end;

end.
