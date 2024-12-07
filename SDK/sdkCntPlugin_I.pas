unit sdkCntPlugin_I;

interface

uses
  ABL.VS.VSTypes, Windows;

type
  BSTR = WideString;
  LPWSTR = PWideChar;
  {$IFNDEF UNICODE}
  UnicodeString = WideString;
  NativeInt = Integer;
  NativeUInt = Cardinal;
  {$ENDIF}

  TScrollCallback = procedure(AID_Camera: integer; ADateTime: int64); stdcall;

  ICntPligin = interface
  ['{6746B6CC-4C0E-4023-A789-4738ECA16961}']
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

  TCntPliginDone = function: HRESULT; stdcall;
  TCntPliginProc = function(const AIID: TGUID; var Intf): HRESULT; stdcall;

implementation

end.
