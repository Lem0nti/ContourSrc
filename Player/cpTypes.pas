unit cpTypes;

interface

uses
  Messages, cpFrameReceiver_TH;

type
  PSCamera=^TSCamera;
  TSCamera=record
    ID_Server: integer;
    ID_Camera: integer;
    Name: string;
    SingleFill: Pointer;
    FrameReceiver: TFrameReceiver;
  end;

const
  WM_SET_CURTIME          = WM_USER+140;
  WM_AVI_READY            = WM_USER+141;
  WM_EXCHANGE_CAMERAS     = WM_USER+142;

implementation

end.
