unit cpFrameReceiver_TH;

interface

uses
  Classes, WinSock, SysUtils, ABL.Core.Debug, DateUtils, ABL.Core.ThreadQueue, cCommon,
  ABL.IO.IOTypes, ABL.IO.TCPReader, ABL.Core.DirectThread, SyncObjs;

type
  TFrameReceiver=class(TDirectThread)
  private
    FTCPQueue: TThreadQueue;
    FID_Camera: integer;
    FPrimary: boolean;
    FSock: TSocket;
    TCPReader: TTCPReader;
    InputBuffer: TBytes;
    procedure SendCommand(ACommand: integer);
    procedure SetPrimary(const Value: boolean);
    function GetCamera: integer;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    Constructor Create(AServer: string; AOutputQueue: TThreadQueue); reintroduce;
    procedure SubscribeVideo(AID_Camera: integer; APrimary: boolean);
    procedure Unsubscribe;
    procedure Stop; override;
    property Camera: integer read GetCamera;
    property Primary: boolean read FPrimary write SetPrimary;
  end;

implementation

{ TFrameReceiver }

constructor TFrameReceiver.Create(AServer: string; AOutputQueue: TThreadQueue);
var
  Addr: sockaddr_in;
begin
  inherited Create(nil,nil);
  FTCPQueue:=TThreadQueue.Create;
  TCPReader:=TTCPReader.Create(FTCPQueue);
  FInputQueue:=FTCPQueue;
  FOutputQueue:=AOutputQueue;
  FSock:=Socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
  if FSock=INVALID_SOCKET then
    SendErrorMsg('TFrameReceiver.Create 45: '+AServer+' - '+SysErrorMessage(WSAGetLastError))
  else
  begin
    Addr.sin_family:=AF_INET;
    Addr.sin_port:=htons(50200);
    Addr.sin_addr.S_addr:=inet_addr(PAnsiChar(AnsiString(AServer))); // ip
    if WinSock.connect(FSock,Addr,SizeOf(Addr))=SOCKET_ERROR then
      SendErrorMsg('TFrameReceiver.Create 52: '+AServer+' - '+SysErrorMessage(WSAGetLastError))
    else
      TCPReader.SetAcceptedSocket(FSock);
  end;
  Active:=true;
end;

procedure TFrameReceiver.DoExecute(var AInputData: Pointer; var AResultData: Pointer);
var
  DataPassed, HeaderSize, tmpDataSize: integer;
  ReadedData,InputFrame: PTimedDataHeader;
  Header: TClientPacketHeader;
  tmpData: Pointer;
begin
  DataPassed:=0;
  try
    ReadedData:=AInputData;
    //SendDebugMsg('TFrameReceiver.DoExecute 71: '+IntToStr(ReadedData^.DataHeader.Size));
    tmpDataSize:=ReadedData^.DataHeader.Size-SizeOf(TTimedDataHeader);
    SetLength(InputBuffer,length(InputBuffer)+tmpDataSize);
    Move(ReadedData^.Data^,InputBuffer[length(InputBuffer)-tmpDataSize],tmpDataSize);
    while DataPassed<length(InputBuffer) do
    begin
      if Terminated then
        exit;
      HeaderSize:=SizeOf(TClientPacketHeader);
      Move(InputBuffer[DataPassed],Header,HeaderSize);
      if Header.Magic=37 then
      begin
        if DataPassed+HeaderSize+Header.Length>length(InputBuffer) then  //это значит что данные для этого кадра будут позже
          break
        else
        begin
          DataPassed:=DataPassed+HeaderSize;
          tmpDataSize:=Header.Length+SizeOf(TTimedDataHeader);
          GetMem(tmpData,tmpDataSize);
          Move(AInputData^,tmpData^,SizeOf(TTimedDataHeader));
          InputFrame:=tmpData;
          InputFrame.DataHeader.Size:=tmpDataSize;
          InputFrame.Time:=Header.TimeStamp;
          InputFrame.Reserved:=0;
          Move(InputBuffer[DataPassed],InputFrame.Data^,Header.Length);
          FOutputQueue.Push(InputFrame);
          DataPassed:=DataPassed+Header.Length;
        end;
      end;
    end;
  except on e: Exception do
    SendErrorMsg('TFrameReceiver.DoExecute 99 length(InputBuffer)='+IntToStr(length(InputBuffer))+', DataPassed='+IntToStr(DataPassed)+': '+e.ClassName+' - '+e.Message);
  end;
  try
    //отрезаем лишний буффер
    {$IFDEF UNIX}
    q:=length(InputBuffer)-DataPassed;
    Move(InputBuffer[DataPassed],InputBuffer[0],q);
    SetLength(InputBuffer,q);
    {$ELSE}
    delete(InputBuffer,0,DataPassed);
    {$ENDIF}
  except on e: Exception do
    SendErrorMsg('TFrameReceiver.DoExecute 111, DataPassed='+IntToStr(DataPassed)+': '+e.ClassName+' - '+e.Message);
  end;
end;

function TFrameReceiver.GetCamera: integer;
begin
  FLock.Enter;
  try
    result:=FID_Camera;
  finally
    FLock.Leave;
  end;
end;

procedure TFrameReceiver.SendCommand(ACommand: integer);
var
  ConnectCommand: TConnectCommand;
  Buf: TBytes;
begin
  SendDebugMsg('TFrameReceiver.SendCommand 120: '+IntToStr(FID_Camera)+':'+BoolToStr(FPrimary,true)+' - '+IntToStr(ACommand));
  ConnectCommand.Command:=ACommand;
  ConnectCommand.Channel:=FID_Camera;
  if FPrimary then
    ConnectCommand.Flag:=0
  else
    ConnectCommand.Flag:=1;
  SetLength(Buf,SizeOf(TConnectCommand));
  move(ConnectCommand,Buf[0],SizeOf(TConnectCommand));
  send(FSock,Buf[0],sizeof(TConnectCommand),0);
end;

procedure TFrameReceiver.SetPrimary(const Value: boolean);
begin
  if FPrimary<>Value then
  begin
    FPrimary:=Value;
    SendCommand(CC_CONNECT);
  end;
end;

procedure TFrameReceiver.Stop;
begin
  Unsubscribe;
  inherited Stop;
end;

procedure TFrameReceiver.SubscribeVideo(AID_Camera: integer; APrimary: boolean);
begin
  FID_Camera:=AID_Camera;
  FPrimary:=APrimary;
  SendCommand(CC_CONNECT);
end;

procedure TFrameReceiver.Unsubscribe;
begin
  SendCommand(CC_DISCONNECT);
end;

end.
