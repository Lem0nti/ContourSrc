unit mdtMainClass_Cl;

interface

uses
  sdkCntPlugin_I, ABL.VS.VSTypes, SysUtils, ABL.Core.Debug, Classes, IniFiles, mdtData_DM,
  ABL.IO.IOTypes, ABL.Core.ThreadController, DB,
  mdtServerDetector_TH, mdtCutDatabase_TH, mdtOptions_FM, Windows, mdtEvents_FM, DateUtils, mdtScroll_TH;

type
  TMDTPlugin = class(TInterfacedObject, ICntPligin)
    procedure CreateObject(AID_Camera: integer; APrimary: boolean; out AObject: Pointer); safecall;
    procedure DeleteObject(AObject: Pointer); safecall;
    procedure DonePlugin; safecall;
    procedure DrawCallback(AID_Camera: integer; ADateTime: int64; DC: HDC; Width, Height: integer); safecall;
    function GetName: BSTR; safecall;
    function GetParamList: BSTR; safecall;
    procedure HideEvents; safecall;
    procedure HideOptions; safecall;
    procedure InitPlugin(AOptions: IUnknown); safecall;
    procedure PushEvent(AEvent: BSTR); safecall;
    procedure PushFrame(AFrame: PImageDataHeader; AObject: Pointer); safecall;
    procedure RegisterScrollCallback(ACallback: TScrollCallback); safecall;
    procedure ShowEvents(AParent: THandle; out AHandle: THandle); safecall;
    procedure ShowOptions(AParent: THandle; out AHandle: THandle; AConnectionString: WideString); safecall;
    procedure SwitchMode(AMode: integer); safecall;
    procedure VideoCallback(AID_Camera: integer; ADateTime: int64); safecall;
  end;

var
  GAPI: ICntPligin;
  lPrevDateTime: TDateTime = 0;

implementation

{ TMDTPlugin }

procedure TMDTPlugin.CreateObject(AID_Camera: integer; APrimary: boolean; out AObject: Pointer);
var
  ServerDetector: TServerDetector;
begin
  ServerDetector:=TServerDetector.Create(AID_Camera);
  AObject:=ServerDetector;
end;

procedure TMDTPlugin.DeleteObject(AObject: Pointer);
var
  tmpDetector: TServerDetector;
begin
  tmpDetector:=AObject;
  tmpDetector.Free;
end;

procedure TMDTPlugin.DonePlugin;
begin

end;

procedure TMDTPlugin.DrawCallback(AID_Camera: integer; ADateTime: int64; DC: HDC; Width, Height: integer);
var
  DataSet: TDataSet;
  Rect: TRect;
  tmpInt: SmallInt;
begin
  DataSet:=DataDM.spEvents;
  //если текущее положение мало отличается от переданного, то рисовать
  if abs(ADateTime-DataSet.FieldByName('Event_Date').AsLargeInt)<300 then
  begin
    DataSet:=DataDM.spZones;
    //ячейки
    tmpInt:=DataSet.FieldByName('Square_From').AsInteger;
    Rect.Left:=tmpInt mod 100;
    Rect.Top:=tmpInt div 100;
    tmpInt:=DataSet.FieldByName('Square_To').AsInteger;
    Rect.Right:=tmpInt mod 100;
    Rect.Bottom:=tmpInt div 100;
    //координаты
    //рисовать
  end;
end;

function TMDTPlugin.GetName: BSTR;
begin
  result:='Детектор движения';
end;

function TMDTPlugin.GetParamList: BSTR;
begin
  result:='Night=4;Работать ночью;0';
end;

procedure TMDTPlugin.HideEvents;
begin

end;

procedure TMDTPlugin.HideOptions;
begin
  if Assigned(OptionsFM) then
  begin
    OptionsFM.StopPreview;
    SetParent(OptionsFM.Handle,0);
    FreeAndNil(OptionsFM);
  end;
end;

procedure TMDTPlugin.InitPlugin(AOptions: IInterface);
begin

end;

procedure TMDTPlugin.PushEvent(AEvent: BSTR);
begin
  //добавление события в форму событий
end;

procedure TMDTPlugin.PushFrame(AFrame: PImageDataHeader; AObject: Pointer);
var
  tmpDetector: TServerDetector;
begin
  tmpDetector:=AObject;
  tmpDetector.Push(AFrame);
end;

procedure TMDTPlugin.RegisterScrollCallback(ACallback: TScrollCallback);
begin
  FCallback:=ACallback;
end;

procedure TMDTPlugin.ShowEvents(AParent: THandle; out AHandle: THandle);
begin
  if not Assigned(EventsFM) then
  begin
    EventsFM:=TEventsFM.Create(nil);
  end;
  SetParent(EventsFM.Handle,AParent);
  EventsFM.Show;
  AHandle:=EventsFM.Handle;
  if not assigned(Scroll) then
    Scroll:=TScroll.Create(ThreadController.ItemByName('ScrollInput'),AHandle);
end;

procedure TMDTPlugin.ShowOptions(AParent: THandle; out AHandle: THandle; AConnectionString: WideString);
begin
  if not Assigned(OptionsFM) then
    OptionsFM:=TOptionsFM.Create(nil);
  SetParent(OptionsFM.Handle,AParent);
  OptionsFM.Show;
  OptionsFM.Preview(AConnectionString);
  AHandle:=OptionsFM.Handle;
end;

procedure TMDTPlugin.SwitchMode(AMode: integer);
begin

end;

procedure TMDTPlugin.VideoCallback(AID_Camera: integer; ADateTime: int64);
var
  TimedDataHeader: PTimedDataHeader;
  tmpPointer: Pointer;
  tmpInt: PInteger;
begin
  if Assigned(EventsFM) and assigned(DataDM) and assigned(Scroll) and (AID_Camera>0) and (ADateTime>0) and
      (MilliSecondsBetween(IncMilliSecond(UnixDateDelta,ADateTime),lPrevDateTime)>500) then
  begin
    GetMem(tmpPointer,SizeOf(TTimedDataHeader)+4);
    TimedDataHeader:=tmpPointer;
    TimedDataHeader.Time:=ADateTime;
    tmpInt:=TimedDataHeader.Data;
    tmpInt^:=AID_Camera;
    Scroll.Push(tmpPointer);
    lPrevDateTime := ADateTime;
  end;
end;

function PliginDone: HRESULT; stdcall;
var
  tmpDetector: TServerDetector;
begin
  try
    while DetectorList.Count>0 do
    begin
      tmpDetector:=DetectorList[0];
      tmpDetector.Free;
    end;
    GAPI.DonePlugin;
    GAPI:=nil;
    DataDM.Free;
    CutDatabase.Free;
    Result := S_OK;
  except on E: Exception do
    begin
      SendErrorMsg('mdtMainClass_Cl.PliginDone 123: '+e.ClassName+' - '+e.Message);
      Result := S_FALSE;
    end;
  end;
end;

function PliginProc(const AIID: TGUID; var Intf): HRESULT; stdcall;
var
  IID: TGUID;
  FConnectionString: TStringList;
begin
  try
    IID := ICntPligin;
    if GAPI = nil then
      GAPI := TMDTPlugin.Create;
    Pointer(Intf) := nil;
    ICntPligin(Intf) := GAPI;
    FConnectionString:=TStringList.Create;
    try
      With TIniFile.Create(ExtractFilePath(ParamStr(0))+'Retina.ini') do
        try
          ReadSectionValues('CONNECTION',FConnectionString);
        finally
          Free;
        end;
      FConnectionString.Values['Database']:=FConnectionString.Values['Database']+'_MDT';
      DataDM:=TDataDM.Create(FConnectionString.Text);
      CutDatabase:=TCutDatabase.Create;
    finally
      FreeAndNil(FConnectionString);
    end;
    Result := S_OK;
  except on E: Exception do
    begin
      SendErrorMsg('mdtMainClass_Cl.PliginProc 128: '+e.ClassName+' - '+e.Message);
      Result := S_FALSE;
    end;
  end;
end;

exports
  PliginDone,
  PliginProc;

end.
