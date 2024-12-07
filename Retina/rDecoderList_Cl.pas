unit rDecoderList_Cl;

interface

uses
  Generics.Collections, ABL.VS.VideoDecoder, ABL.Core.ThreadController, SysUtils, ABL.Core.ThreadQueue,
  ABL.VS.FFMPEG, SyncObjs;

type
  TCameraDecoder=class(TVideoDecoder)
  private
    FID_Camera: integer;
    FPrimary: boolean;
    function GetCamera: integer;
    function GetPrimary: boolean;
  public
    constructor Create(AID_Camera: integer; APrimary: boolean); reintroduce;
    property Camera: integer read GetCamera;
    property Primary: boolean read GetPrimary;
  end;

  TDecoderList=class(TObjectList<TCameraDecoder>)
  public
    Destructor Destroy; override;
    function DecoderByCamera(AID_Camera: integer; APrimary: boolean): TCameraDecoder;
  end;

var
  DecoderList: TDecoderList;

implementation

{ TCameraDecoder }

constructor TCameraDecoder.Create(AID_Camera: integer; APrimary: boolean);
begin
  inherited Create(ThreadController.QueueByName('TFrameReceiver_Output_'+IntToStr(AID_Camera)+'_'+BoolToStr(APrimary,true)),
      ThreadController.QueueByName('TVideoDecoder_Output_'+IntToStr(AID_Camera)+'_'+BoolToStr(APrimary,true)),AV_CODEC_ID_H264,
      'TVideoDecoder_'+IntToStr(AID_Camera)+'_'+BoolToStr(APrimary,true));
  FID_Camera:=AID_Camera;
  FPrimary:=APrimary;
end;

function TCameraDecoder.GetCamera: integer;
begin
  FLock.Enter;
  result:=FID_Camera;
  FLock.Leave;
end;

function TCameraDecoder.GetPrimary: boolean;
begin
  FLock.Enter;
  result:=FPrimary;
  FLock.Leave;
end;

{ TDecoderList }

function TDecoderList.DecoderByCamera(AID_Camera: integer; APrimary: boolean): TCameraDecoder;
var
  I: integer;
begin
  result:=nil;
  for I := 0 to Count-1 do
    if (Items[I].Camera=AID_Camera) and (Items[I].Primary=APrimary) then
    begin
      result:=Items[I];
      break;
    end;
  if not assigned(result) then
  begin
    result:=TCameraDecoder.Create(AID_Camera,APrimary);
    Add(result);
  end;
end;

destructor TDecoderList.Destroy;
var
  tr: TVideoDecoder;
begin
  while Count>0 do
  begin
    tr:=Items[0];
    Delete(0);
    if assigned(tr) then
      tr.Free;
  end;
  inherited;
end;

end.
