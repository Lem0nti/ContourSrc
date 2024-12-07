unit cFrameGrabber_TH;

interface

uses
  ABL.Core.DirectThread, ABL.IO.IOTypes, ABL.Core.ThreadQueue, cFrameList_Cl, cCommon, ABL.Core.Debug, SysUtils,
  DateUtils, SyncObjs;

type
  TFrameGrabber=class(TDirectThread)
  private
    FrameList: TFrameList;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TThreadQueue; AID_Camera: integer; APrimary: boolean; AName: string = ''); reintroduce;
    procedure DropList;
  end;

implementation

uses
  cClient_Cl;

{ TFrameGrabber }

constructor TFrameGrabber.Create(AInputQueue, AOutputQueue: TThreadQueue; AID_Camera: integer; APrimary: boolean; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  FrameList:=TFrameList.Create(AID_Camera,APrimary);
  Active:=true;
end;

procedure TFrameGrabber.DoExecute(var AInputData, AResultData: Pointer);
var
  //DataFrame: PTimedDataHeader;
  InputFrame: PTimedDataHeader;
  OldFrameList: TFrameList;
begin
  InputFrame:=AInputData;
  AInputData:=nil;
  //отправка подключённым клиентам
  SendClient(InputFrame,FrameList.ID_Camera,FrameList.Primary);
  //new(InputFrame);
  //InputFrame.Data:=AInputData;
  InputFrame.Reserved:=PByte(NativeUInt(InputFrame.Data)+3)^ AND $1F;
  //если фрейм ключевой, то сбросить список
  FLock.Enter;
  try
    if (InputFrame.Reserved=7) and (FrameList.Count>0) then
    begin
      OldFrameList:=FrameList;
      FrameList:=TFrameList.Create(OldFrameList.ID_Camera,OldFrameList.Primary);
      AResultData:=OldFrameList;
    end;
//    InputFrame.DataHeader.Size:=DataFrame.DataHeader.Size;
//    InputFrame.TimeStamp:=DataFrame.Time;
    FrameList.Add(InputFrame);
  finally
    FLock.Leave;
  end;
end;

procedure TFrameGrabber.DropList;
var
  OldFrameList: TFrameList;
begin
  FLock.Enter;
  try
    SendDebugMsg('TFrameGrabber.DropList 68: ID_Camera='+IntToStr(FrameList.ID_Camera)+', FrameList.Count='+IntToStr(FrameList.Count));
    OldFrameList:=FrameList;
    FrameList:=TFrameList.Create(OldFrameList.ID_Camera,OldFrameList.Primary);
    OldFrameList.ID_Camera:=-1;
    OutputQueue.Push(OldFrameList);
  finally
    FLock.Leave;
  end;
end;

end.
