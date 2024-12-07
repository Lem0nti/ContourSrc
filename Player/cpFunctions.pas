unit cpFunctions;

interface

uses
  cpPlayer_Cl, Windows, cpArchManager_TH, cpCell_Cl, cpMap_Cl, SysUtils, ABL.Core.Debug, Forms, Controls,
  cpArchVideo_Cl, cpTypes, DateUtils, Types;

procedure BeginUpdate; stdcall;
function ConnectServer(Address: WideString): integer; stdcall;
procedure DisconnectServer(Index: integer); stdcall;
procedure EndUpdate; stdcall;
function FocusCamera(Server, Camera: integer; ATime: TDateTime): boolean; stdcall;
function GetArchDays(Server: integer): WideString; stdcall;
function GetArea(x,y: integer): integer; stdcall;
function GetCurTime: TDateTime; stdcall;
function GetScreen: integer; stdcall;
function GetServerCameras(Server: integer): WideString; stdcall;
function Play(cbf: Tcbf; cbd: Tcbd; ASpeed: integer): boolean; stdcall;
procedure PlayOperative; stdcall;
procedure SetCameraInArea(Server, Camera, Area: integer); stdcall;
procedure SetMapRange(StartDate, EndDate: TDateTime); stdcall;
procedure SetScreen(Layout: integer); stdcall;
procedure ShowMap(Parent: HWND); stdcall;
procedure ShowScreen(Parent: HWND); stdcall;
procedure Step; stdcall;
procedure StepBack; stdcall;
procedure Stop; stdcall;
procedure StopOperative; stdcall;

implementation

var
  FInUpdate: byte = 0;
  FBeforeDblClickScreen: integer = 0;
  FBeforeCameras: array of TPoint;

procedure DblClickCB(AIndex: integer);
var
  i,q: integer;
  OldState: TPlayState;
  OldCamera,OldServer: integer;
begin
  //текущую камеру поставить на весь экран
  if assigned(Player) and (AIndex<Player.Cameras.Count) then
  begin
    if Player.Cameras[AIndex].ID_Camera>-1 then
    begin
      OldState:=Player.PlayState;
      Player.Pause;
      q:=FBeforeDblClickScreen;
      i:=GetScreen;
      BeginUpdate;
      try
        if (q>0)and(i=0) then
        begin
          OldCamera:=Player.Cameras[0].ID_Camera;
          OldServer:=Player.Cameras[0].ID_Server;
          SetScreen(q);
          //восстановить камеры
          for i := 0 to high(FBeforeCameras) do
          begin
            SetCameraInArea(FBeforeCameras[i].X,FBeforeCameras[i].Y,i);
            if (FBeforeCameras[i].X=OldServer)and(FBeforeCameras[i].Y=OldCamera) then
              Player.SetActiveCell(i);
          end;
        end
        else
        begin
          //запомнить камеры
          SetLength(FBeforeCameras,Player.Capacity);
          for q := 0 to Player.Capacity-1 do
          begin
            FBeforeCameras[q].X:=Player.Cameras[q].ID_Server;
            FBeforeCameras[q].Y:=Player.Cameras[q].ID_Camera;
          end;
          SetScreen(0);
          SetCameraInArea(FBeforeCameras[AIndex].X,FBeforeCameras[AIndex].Y,0);
          FBeforeDblClickScreen:=i;
        end;
        Player.SkipUp;
      finally
        Endupdate;
      end;
      if OldState<>psStop then
        Player.Play(1,OldState=psPlay);
    end;
  end;
end;

procedure BeginUpdate;
begin
  try
    FInUpdate:=FInUpdate+1;
    if assigned(Map) then
      Map.BeginUpdate;
    if assigned(Player) then
      Player.BeginUpdate;
  except on e: Exception do
    SendErrorMsg('cpFunctions.BeginUpdate 100: '+e.ClassName+' - '+e.Message);
  end;
end;

function ConnectServer(Address: WideString): integer;
begin
  result:=-1;
  try
    result:=ArchManager.Add(Address);
  except on e: Exception do
    SendErrorMsg('cpFunctions.ConnectServer 109: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure DisconnectServer(Index: integer);
var
  q: integer;
  cCamera: PSCamera;
begin
  try
    if Index<ArchManager.Count then
    begin
      if Assigned(Player) then
        //все оперативные камеры этого сервера - выключить
        for q:=0 to Player.Cameras.Count-1 do
        begin
          cCamera:=Player.Cameras[q];
          if (cCamera.ID_Server=Index)then
          begin
            if assigned(cCamera.FrameReceiver) then
            begin
              cCamera.FrameReceiver.Stop;
              cCamera.FrameReceiver.Free;
              cCamera.FrameReceiver:=nil;
            end;
            cCamera.ID_Server:=-1;
          end;
        end;
      if assigned(Map) then
      begin
        for q:=0 to Map.Cameras.Count-1 do
          if (Map.Cameras[q].ID_Server=Index)then
            Map.Cameras[q].ID_Server:=-1;
        Map.ClearIndexCache(Index);
      end;
      ArchManager.ClearTodayCache(Index);
      ArchManager.Objects[Index].Destroy;
      ArchManager.Objects[Index]:=nil;
      ArchManager.Delete(Index);
    end;
  except on e: Exception do
    SendErrorMsg('cpFunctions.DisconnectServer 150: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure EndUpdate;
begin
  try
    if FInUpdate>0 then
      FInUpdate:=FInUpdate-1;
    if assigned(Player) then
      Player.EndUpdate;
    if assigned(Map) then
      Map.EndUpdate;
  except on e: Exception do
    SendErrorMsg('cpFunctions.EndUpdate 164: '+e.ClassName+' - '+e.Message);
  end;
end;

function FocusCamera(Server, Camera: integer; ATime: TDateTime): boolean;
var
  i: integer;
  tmpCamera: PSCamera;
begin
  result:=false;
  try
    if (Camera>0) and assigned(Player) then
    begin
      if ATime<0 then
        tmpCamera:=tmpCamera;
      tmpCamera:=nil;
      for i := 0 to Player.Cameras.Count-1 do
        if (Player.Cameras[i].ID_Server=Server)and(Player.Cameras[i].ID_Camera=Camera) then
        begin
          tmpCamera:=Player.Cameras[i];
          Player.SetActiveCell(i);
          break;
        end;
      if not assigned(tmpCamera) then
      begin
        SetScreen(0);
        SetCameraInArea(Server,Camera,0);
      end;
      if (ATime<Map.BeginTime)or(ATime>Map.EndTime) then
        Map.SetRange(incHour(ATime,-3),IncHour(ATime,3));
      Map.CurTime:=ATime;
    end;
  except on e: Exception do
    SendErrorMsg('cpFunctions.FocusCamera 195: '+e.ClassName+' - '+e.Message);
  end;
end;

function GetArchDays(Server: integer): WideString;
var
  q: TIntegerDynArray;
  w: integer;
begin
  result:='';
  try
    q:=ArchManager.DaysList(Server);
    for w in q do
      result:=result+IntToStr(w)+#13#10;
  except on e: Exception do
    SendErrorMsg('cpFunctions.GetArchDays 210: '+e.ClassName+' - '+e.Message);
  end;
end;

function GetArea(x,y: integer): integer;
begin
  result:=-1;
  try
    if assigned(Player) then
      result:=Player.GetArea(x,y);
  except on e: Exception do
    SendErrorMsg('cpFunctions.GetArea 222: '+e.ClassName+' - '+e.Message);
  end;
end;

function GetCurTime: TDateTime;
begin
  result:=0;
  try
    if assigned(Map) then
      result:=Map.CurTime;
  except on e: Exception do
    SendErrorMsg('cpFunctions.GetCurTime 234: '+e.ClassName+' - '+e.Message);
  end;
end;

function GetScreen: integer;
begin
  result:=0;
  try
    if assigned(Map) then
      case Map.Capacity of
        4: result:=1;
        7: result:=2;
        8: result:=3;
        9: result:=4;
        10: result:=5;
        13: result:=6;
        16: result:=7;
        25: result:=8;
        33: result:=9;
      end;
  except on e: Exception do
    SendErrorMsg('cpFunctions.GetScreen 255: '+e.ClassName+' - '+e.Message);
  end;
end;

function GetServerCameras(Server: integer): WideString;
begin
  try
    result:=ArchManager.CamerasList(Server);
  except on e: Exception do
    SendErrorMsg('cpFunctions.GetServerCameras 264: '+e.ClassName+' - '+e.Message);
  end;
end;

function Play(cbf: Tcbf; cbd: Tcbd; ASpeed: integer): boolean;
begin
  result:=false;
  Acbf:=cbf;
  Acbd:=cbd;
  if Assigned(Player) then // Если значение ASpeed отрицательное, идёт перемотра назад
  begin
    Player.Play(ASpeed, True);
    result:=true;
  end;
end;

procedure PlayOperative;
begin
  try
    if Assigned(Player) then
      Player.Operative:=true;
    if Assigned(Map) then
      Map.Enabled:=false;
  except on e: Exception do
    SendErrorMsg('cpFunctions.PlayOperative 291: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure SetCameraInArea(Server, Camera, Area: integer);
begin
  try
    //отправили камеру в экран
    if assigned(Player) and (Area<Player.Cameras.Count) then
      Player.InsertCamera(Server,Camera,Area);
    if assigned(Map)and(Area<Map.Cameras.Count) then
      Map.InsertCamera(Server,Camera,Area);
  except on e: Exception do
    SendErrorMsg('cpFunctions.SetCameraInArea 304: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure SetMapRange(StartDate, EndDate: TDateTime);
begin
  try
    if assigned(Map) then
      Map.SetRange(StartDate, EndDate);
  except on e: Exception do
    SendErrorMsg('cpFunctions.SetCameraInArea 314: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure SetScreen(Layout: integer);
var
  NCap: integer;
begin
  try
    FBeforeDblClickScreen:=0;
    if assigned(Map) then
    begin
      case Layout of
        1: NCap:=4;
        2: NCap:=7;
        3: NCap:=8;
        4: NCap:=9;
        5: NCap:=10;
        6: NCap:=13;
        7: NCap:=16;
        8: NCap:=25;
        9: NCap:=33;
      else
        NCap:=1;
      end;
      //SendDebugMsg('cpFunctions.SetScreen 284');
      Map.Capacity:=NCap;
      //SendDebugMsg('cpFunctions.SetScreen 338');
      Player.Capacity:=NCap;
      Player.EndUpdate;
    end
    else
      SendErrorMsg('SetScreen 342: отсутствует Map');
  except on e: Exception do
    SendErrorMsg('cpFunctions.SetScreen 348: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure ShowMap(Parent: HWND);
var
  ppRect: TRect;
begin
  try
    if assigned(MapForm) then
    begin
      if GetParent(MapForm.Handle)=Parent then
        exit;
      SetParent(MapForm.Handle,Parent);
    end
    else
    begin
      MapForm:=TForm(TForm.CreateParentedControl(Parent));
      MapForm.BorderStyle:=bsNone;
      Map:=TMap.Create(nil);
      Map.Align:=alClient;
      Map.Parent:=MapForm;
    end;
    GetWindowRect(Parent,ppRect);
    MapForm.SetBounds(ppRect.Left,ppRect.Top,ppRect.Width,ppRect.Height);
    MapForm.Show;
    Map.Show;
    if Assigned(Player) then
    begin
      Map.ScreenHandle:=Player.Handle;
      Player.MapHandle:=Map.Handle;
    end;
  except on e: Exception do
    SendErrorMsg('cpFunctions.ShowMap 382: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure ShowScreen(Parent: HWND);
var
  ppRect: TRect;
begin
  try
    if Assigned(PlayerForm) then
    begin
      if GetParent(PlayerForm.Handle)=Parent then
        exit;
      SetParent(PlayerForm.Handle,Parent)
    end
    else
    begin
      PlayerForm:=TForm(TForm.CreateParentedControl(Parent));
      PlayerForm.Color:=$003F4145;
      PlayerForm.BorderStyle:=bsNone;
      Player:=TPlayer.Create(nil);
      Player.Parent:=PlayerForm;
    end;
    GetWindowRect(Parent,ppRect);
    PlayerForm.SetBounds(ppRect.Left,ppRect.Top,ppRect.Width,ppRect.Height);
    PlayerForm.Show;
    Player.Show;
    FDblClickCB:=DblClickCB;
    if Assigned(Map) then
    begin
      Map.ScreenHandle:=Player.Handle;
      Player.MapHandle:=Map.Handle;
    end;
  except on e: Exception do
    SendErrorMsg('cpFunctions.ShowScreen 416: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure Step;
begin
  try
    if Assigned(Player) then
      Player.StepNext;
  except on e: Exception do
    SendErrorMsg('cpFunctions.Step 426: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure StepBack;
begin
  try
    if Assigned(Player) then
      Player.StepBack;
  except on e: Exception do
    SendErrorMsg('cpFunctions.StepBack 436: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure Stop;
begin
  try
    if Assigned(Player) then
      Player.Pause;
  except on e: Exception do
    SendErrorMsg('cpFunctions.Stop 446: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure StopOperative;
begin
  try
    if Assigned(Player) then
      Player.Operative:=false;
    if Assigned(Map) then
      Map.Enabled:=true;
  except on e: Exception do
    SendErrorMsg('cpFunctions.StopOperative 458: '+e.ClassName+' - '+e.Message);
  end;
end;

end.
