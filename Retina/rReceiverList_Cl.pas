unit rReceiverList_Cl;

interface

uses
  Generics.Collections, cpFrameReceiver_TH, ABL.Core.ThreadController, SysUtils, ABL.Core.ThreadQueue;

type

  TReceiverList=class(TObjectList<TFrameReceiver>)
  public
    Destructor Destroy; override;
    function ReceiverByCamera(AID_Camera: integer; APrimary: boolean): TFrameReceiver;
  end;

var
  ReceiverList: TReceiverList;

implementation

{ TReceiverList }

destructor TReceiverList.Destroy;
var
  tr: TFrameReceiver;
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

function TReceiverList.ReceiverByCamera(AID_Camera: integer; APrimary: boolean): TFrameReceiver;
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
    result:=TFrameReceiver.Create('127.0.0.1',TThreadQueue(ThreadController.QueueByName('TFrameReceiver_Output_'+IntToStr(AID_Camera)+'_'+BoolToStr(APrimary,true))));
    result.SubscribeVideo(AID_Camera,APrimary);
    Add(result);
  end;
end;

end.
