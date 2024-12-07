unit rPlugin_Cl;

interface

uses
  SysUtils, sdkCntPlugin_I, Windows, Generics.Collections, ABL.Core.Debug, ABL.Core.DirectThread,
  ABL.Core.BaseQueue, ABL.Core.ThreadController;

type
  TPluginInstance=class(TDirectThread)
  private
    FObject: Pointer;
    FAPI: ICntPligin;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AID_Camera: integer; APrimary: boolean; AObject: Pointer; AAPI: ICntPligin; AName: string = ''); reintroduce;
  end;

  TPlugin=class//(TDirectThread)
  private
    FActive: boolean;
    //библиотека
    FHandle: THandle;
    //файл
    FFileName: TFileName;
    function GetName: string;
  //protected
  //  procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer);
  public
    //интерфейс
    API: ICntPligin;
    ConnectionList: TObjectList<TPluginInstance>;
    constructor Create(AFileName: TFileName);
    destructor Destroy; override;
    function TryConnect(AID_Camera: integer; APrimary: boolean): Pointer;
    property Active: boolean read FActive;
    property FileName: TFileName read FFileName;
    property Handle: THandle read FHandle;
    property Name: string read GetName;
  end;

  TPluginList=class(TObjectList<TPlugin>)
  public
    Destructor Destroy; override;
    function PluginByFileName(AFileName: TFileName): TPlugin;
  end;

var
  PluginList: TPluginList;

implementation

{ TPlugin }

constructor TPlugin.Create(AFileName: TFileName);
var
  PliginProc: TCntPliginProc;

  function GetFileStringVersion(AFileName: TFileNAme): string;
  var
    Size: Integer;
    Buffer: PChar;
    AHandle: Cardinal;
    FileVersion: PVSFixedFileInfo;
  begin
    Result:='';
    if FileExists(AFileName) then
    begin
      Size:=GetFileVersionInfoSize(PChar(AFileName),AHandle);
      Buffer:=AllocMem(Size+1);
      try
        if GetFileVersionInfo(PChar(AFileName),AHandle,Size,Buffer) then
          if VerQueryValue(Buffer,'\',Pointer(FileVersion),UINT(Size)) then
            if Size>=SizeOf(TVSFixedFileInfo) then
              Result:=IntToStr(HIWORD(FileVersion.dwFileVersionMS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionMS))+'.'+
                  IntToStr(HIWORD(FileVersion.dwFileVersionLS))+'.'+IntToStr(LOWORD(FileVersion.dwFileVersionLS));
      finally
        FreeMem(Buffer,Size+1);
      end;
    end;
  end;

begin
  FActive:=false;
  FFileName:=AFileName;
  if FileExists(FFileName) then
  begin
    //версия
    SendDebugMsg('TPlugin.Create 84: '+FFileName+' - '+GetFileStringVersion(AFileName));
    FHandle := LoadLibrary(PWideChar(AFileName));
    if FHandle>0 then
    begin
      PliginProc := GetProcAddress(FHandle, 'PliginProc');
      if Assigned(PliginProc) then
      begin
        PliginProc(ICntPligin,API);
        API.InitPlugin(nil);
        FActive:=true;
        ConnectionList:=TObjectList<TPluginInstance>.Create;
        ConnectionList.OwnsObjects:=false;
      end;
    end;
  end;
end;

destructor TPlugin.Destroy;
var
  tp: TPluginInstance;
begin
  try
    if FHandle>0 then
    begin
      if FActive then
      begin
        while ConnectionList.Count>0 do
        begin
          tp:=ConnectionList[0];
          ConnectionList.Delete(0);
          tp.Destroy;
          //Dispose(tp);
        end;
        FreeAndNil(ConnectionList);
        API.DonePlugin;
      end;
      FreeLibrary(FHandle);
    end;
  except on e: Exception do
    SendErrorMsg('TPlugin.Destroy 121: '+e.ClassName+' - '+e.Message);
  end;
//  inherited;
end;
//
//procedure TPlugin.DoExecute(var AInputData, AResultData: Pointer);
//begin
//  API.PushFrame(AInputData,);
//end;

function TPlugin.GetName: string;
begin
  if assigned(API) then
    result:=string(API.GetName);
end;

function TPlugin.TryConnect(AID_Camera: integer; APrimary: boolean): Pointer;
var
  //PluginPoint: PPluginPoint;
  PluginInstance: TPluginInstance;
begin
  API.CreateObject(AID_Camera,APrimary,Result);
  if Result<>nil then
  begin
    //New(PluginPoint);
    //PluginPoint.ID_Camera:=AID_Camera;
    //PluginPoint.Primary:=APrimary;
    //PluginPoint.AObject:=Result;
    //ConnectionList.Add(PluginPoint);
    PluginInstance:=TPluginInstance.Create(AID_Camera,APrimary,Result,API,'PluginInstance_'+IntToStr(AID_Camera)+'_'+BoolToStr(APrimary,true));
    ConnectionList.Add(PluginInstance);
  end;
end;

{ TPluginInstance }

constructor TPluginInstance.Create(AID_Camera: integer; APrimary: boolean; AObject: Pointer; AAPI: ICntPligin;
    AName: string);
begin
  inherited Create(ThreadController.QueueByName('TVideoDecoder_Output_'+IntToStr(AID_Camera)+'_'+BoolToStr(APrimary,true)),nil,AName);
  FObject:=AObject;
  FAPI:=AAPI;
  Start;
end;

procedure TPluginInstance.DoExecute(var AInputData, AResultData: Pointer);
begin
  FAPI.PushFrame(AInputData,FObject);
  AInputData:=nil;
end;

{ TPluginList }

destructor TPluginList.Destroy;
var
  td: TPlugin;
  tmpFileName: TFileName;
begin
  try
    while Count>0 do
    begin
      td:=Items[0];
      Delete(0);
      if assigned(td) then
      begin
        tmpFileName:=td.FFileName;
        SendDebugMsg('TPluginList.Destroy 158: '+tmpFileName);
        FreeAndNil(td);
        SendDebugMsg('TPluginList.Destroy 160: '+tmpFileName+' destroyed');
      end;
    end;
  except on e: Exception do
    SendErrorMsg('TPluginList.Destroy 161: '+e.ClassName+' - '+e.Message);
  end;
  inherited;
end;

function TPluginList.PluginByFileName(AFileName: TFileName): TPlugin;
var
  I: integer;
begin
  result:=nil;
  for I := 0 to Count-1 do
    if Items[I].FFileName=AFileName then
    begin
      result:=Items[I];
      break;
    end;
  if not assigned(result) then
  begin
    result:=TPlugin.Create(ExtractFilePath(ParamStr(0))+AFileName);
    Add(result);
  end;
end;

initialization
  PluginList:=TPluginList.Create(false);

end.
