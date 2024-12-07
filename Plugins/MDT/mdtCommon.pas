unit mdtCommon;

interface

uses
  Types, Messages;

type
  PTrackItem=^TTrackItem;
  TTrackItem=record
    ID_Path: integer;
    CurRect: TRect;
    LastUpdate: TDateTime;
  end;

const
  IcoSize = 64;
  WM_SCROLLPLUGINEVENTS = WM_USER+300;

implementation

end.
