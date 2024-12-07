unit cClient_Cl;

interface

uses
  WinSock, SysUtils, ABL.Core.Debug, Classes, IniFiles, Generics.Collections, ABL.Core.ThreadController,
  Windows, Contnrs, ABL.IO.IOTypes, ABL.Core.DirectThread, cCommon, cCamera_Cl, SyncObjs, Types;

type
  /// <summary>
  /// Клиентский пакет.
  /// </summary>
  /// <param name="Header: TClientPacketHeader">
  /// Заголовок
  /// </param>
  /// <param name="Data: Pointer">
  /// Содержимое
  /// </param>
  PClientPacket=^TClientPacket;
  /// <summary>
  /// Клиентский пакет.
  /// </summary>
  /// <param name="Header: TClientPacketHeader">
  /// Заголовок
  /// </param>
  /// <param name="Data: Pointer">
  /// Содержимое
  /// </param>
  TClientPacket=record
   Header: TClientPacketHeader;
   Data: Pointer;
  end;

  PSSocket=^TSSocket;
  TSSocket=record
    Socket: TSocket;
    sin_addr: TInAddr;
  end;

  /// <summary>
  /// Задание на обработку пакета.
  /// </summary>
  /// <param name="InputFrame: PInputFrame">
  /// Указатель на пакет
  /// </param>
  /// <param name="ID_Camera: integer">
  /// Номер камеры
  /// </param>
  PPacketTask=^TPacketTask;
  /// <summary>
  /// Задание на обработку пакета.
  /// </summary>
  /// <param name="InputFrame: PInputFrame">
  /// Указатель на пакет
  /// </param>
  /// <param name="ID_Camera: integer">
  /// Номер камеры
  /// </param>
  TPacketTask=record
    InputFrame: PTimedDataHeader;
    ID_Camera: integer;
    Primary: boolean;
  end;

  TClientSender=class;

  /// <summary>
  /// Поток для получения команд уже подключённых клиентов.
  /// </summary>
  TCommandReceiver=class(TThread)
    FSender: TClientSender;
    FSocket: TSocket;
  protected
    procedure Execute; override;
  public
    /// <summary>
    /// Конструктор.
    /// </summary>
    /// <param name="ASender: TClientSender">
    /// Отправитель, на которого должны действовать команды.
    /// </param>
    /// <param name="ASocket: TSocket">
    /// Сокет, на котором ожидаются команды.
    /// </param>
    constructor Create(ASender: TClientSender; ASocket: TSocket); reintroduce;
  end;

  TClientManager=class;

  /// <summary>
  /// Поток для отправки кадров клиентам.
  /// </summary>
  TClientSender=class(TDirectThread)
  private
    FSelfString: string;
    FID_Camera: integer;
    FOnyIDR: boolean;
    FPrimary: boolean;
    Manager: TClientManager;
    Socket: TSocket;
    HSize: Integer;
    /// <summary>
    /// Чистка очереди. Стоит использовать при изменении параметров отправляемых данных: качество, IDR.
    /// </summary>
    procedure ClearInput;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    /// <summary>
    /// Конструктор.
    /// </summary>
    /// <param name="ASocket: TSocket">
    /// Сокет, на который нужно слать пакеты.
    /// </param>
    /// <param name="AID_Camera: integer">
    /// Номер камеры, необходимо для идентификации получателя.
    /// </param>
    /// <param name="APrimary: boolean">
    /// Признак первичности видеопотока.
    /// </param>
    /// <param name="AManager: TClientManager">
    /// Менеджер клиентов. Необходимо для автоматичекого удаления самого себя из списка подключённых клиентов при окончании работы с клиентом.
    /// </param>
    constructor Create(ASocket: TSocket; AID_Camera: integer; APrimary: boolean; AManager: TClientManager); reintroduce;
    destructor Destroy; override;
    /// <summary>
    /// Применить инструкции в команде от клиента
    /// </summary>
    /// <param name="ConnectCommand: TConnectCommand">
    /// Команда, инструкции которой надо применить
    /// </param>
    procedure ParseCommand(ConnectCommand: TConnectCommand);
    procedure Stop; override;
  end;

  /// <summary>
  /// Поток, ожидающий подключений клиентов
  /// </summary>
  TConnectWaitThread=class(TThread)
  private
    vListenSocket: TSocket;
  protected
    procedure Execute; override;
  public
    procedure Terminate;
  end;

  /// <summary>
  /// Менеджер клиентов. Централизованное управление посылкой пакетов
  /// </summary>
  TClientManager=class(TDirectThread)
  private
    AClients: TList<TClientSender>;
    CameraNeeded: TIntegerDynArray;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    /// <summary>
    /// Метод для добавления клиента
    /// </summary>
    /// <param name="ASocket: TSocket">
    /// Сокет, на котором произошло соединение с клиентом.
    /// </param>
    /// <param name="AID_Camera: integer">
    /// Идентификатор камеры, для которой запрошено видео.
    /// </param>
    /// <param name="APrimary: boolean">
    /// Признак первичности запрошенного видео.
    /// </param>
    procedure AddClient(ASocket: TSocket; AID_Camera: integer; APrimary: boolean);
    /// <summary>
    /// Метод для отправки пакетов подключённым клиентам
    /// </summary>
    /// <param name="APacket: PInputFrame">
    /// Кадр, подлежащий отправке.
    /// </param>
    /// <param name="AID_Camera: integer">
    /// Идентификатор камеры, от которой принят кадр.
    /// </param>
    procedure AddPacket(APacket: PTimedDataHeader; AID_Camera: integer; APrimary: boolean);
    /// <summary>
    /// Метод для удаления клиента из списка.
    /// </summary>
    procedure Remove(ClientSender: TClientSender);
  end;

var
  ClientManager: TClientManager;
  ConnectWaitThread: TConnectWaitThread;

/// <summary>
/// Процедура для добавления клиента
/// </summary>
/// <param name="ASocket: TSocket">
/// Сокет, на котором произошло соединение с клиентом.
/// </param>
/// <param name="AID_Camera: integer">
/// Идентификатор камеры, для которой запрошено видео.
/// </param>
/// <param name="APrimary: boolean">
/// Признак первичности запрошенного видео.
/// </param>
procedure AddClient(ASocket: TSocket; AID_Camera: integer; APrimary: boolean);
/// <summary>
/// Процедура для отправки пакета подключённым клиентам
/// </summary>
/// <param name="APacket: PInputFrame">
/// Кадр, подлежащий отправке.
/// </param>
/// <param name="AID_Camera: integer">
/// Идентификатор камеры, от которой принят кадр.
/// </param>
procedure SendClient(APacket: PTimedDataHeader; AID_Camera: integer; APrimary: boolean);

implementation

procedure SocketThread(SSocket: PSSocket);
var
  s: TSocket;
  ABytes: TBytes;
  i: integer;
  cc: TConnectCommand;
begin
  s:=SSocket.Socket;
  Dispose(SSocket);
  SetLength(ABytes,1024);
  try
    try
      i:=recv(s,ABytes[0],1024,0);
    except on e: Exception do
      begin
        SendErrorMsg('cClient_Cl.SocketThread 234: '+e.ClassName+' - '+e.Message);
        closesocket(s);
        exit;
      end;
    end;
    if (i = SOCKET_ERROR) then
    begin
      SendErrorMsg('cClient_Cl.SocketThread 241: SOCKET_ERROR');
      closesocket(s);
      exit;
    end;
    if i=0 then
    begin
      SendErrorMsg('cClient_Cl.SocketThread 247: i=0');
      closesocket(s);
      exit;
    end;
    if i=SizeOf(TConnectCommand) then
    begin
      move(ABytes[0],cc,i);
      SendDebugMsg('cClient_Cl.SocketThread 254: Command='+IntToStr(cc.Command)+', Channel='+IntToStr(cc.Channel)+', Flag='+IntToStr(cc.Flag));
      if cc.Command=CC_CHANNELLIST then
      begin
        if AllCameras.Count>0 then
        begin
          SetLength(ABytes,2*AllCameras.Count);
          for i := 0 to AllCameras.Count - 1  do
          begin
            ABytes[i*2]:=TCamera(AllCameras[i]).ID_Camera;
            if TCamera(AllCameras[i]).SecondaryExist then
              ABytes[1+i*2]:=1
            else
              ABytes[1+i*2]:=0;
          end;
        end
        else
          SetLength(ABytes,1);
        send(s,ABytes[0],length(ABytes),0);
        closesocket(s);
      end
      else
        AddClient(s,cc.Channel,cc.Flag=0)
    end
    else
    begin
      SendErrorMsg('cClient_Cl.SocketThread 280: invalid packet size '+IntToStr(i));
      closesocket(s);
    end;
  except on e: Exception do
    begin
      SendErrorMsg('cClient_Cl.SocketThread 285: '+e.ClassName+' - '+e.Message);
      closesocket(s);
    end;
  end;
end;

procedure AddClient(ASocket: TSocket; AID_Camera: integer; APrimary: boolean);
begin
  if not assigned(ClientManager) then
    ClientManager:=TClientManager.Create;
  ClientManager.AddClient(ASocket,AID_Camera,APrimary);
end;

procedure SendClient(APacket: PTimedDataHeader; AID_Camera: integer; APrimary: boolean);
begin
  try
    if assigned(ClientManager) then
      ClientManager.AddPacket(APacket,AID_Camera,APrimary);
  except on e: Exception do
    SendErrorMsg('cClient_Cl.SendClient 308: '+e.ClassName+' - '+e.Message);
  end;
end;

{ TCommandReceiver }

constructor TCommandReceiver.Create(ASender: TClientSender; ASocket: TSocket);
begin
  inherited Create(false);
  FSocket:=ASocket;
  FSender:=ASender;
end;

procedure TCommandReceiver.Execute;
var
  ABytes: TBytes;
  i: integer;
  cc: TConnectCommand;
begin
  FreeOnTerminate:=true;
  try
    try
      SetLength(ABytes,512);
      while not Terminated do
      begin
        i:=recv(FSocket,ABytes[0],512,0);
        if (i = SOCKET_ERROR) then
        begin
          SendErrorMsg('TCommandReceiver.Execute 333: SOCKET_ERROR ('+IntToStr(FSocket)+') - '+SysErrorMessage(WSAGetLastError));
          exit;
        end
        else if i=0 then
        begin
          SendErrorMsg('TCommandReceiver.Execute 338: i=0');
          exit;
        end
        else
        begin
          if i=SizeOf(TConnectCommand) then
          begin
            move(ABytes[0],cc,SizeOf(TConnectCommand));
            FSender.ParseCommand(cc);
            if cc.Command=CC_DISCONNECT then
              exit;
          end;
        end;
      end;
    except on e: Exception do
      SendErrorMsg('TCommandReceiver.Execute 354: '+e.ClassName+' - '+e.Message);
    end;
  finally
    SendDebugMsg('TCommandReceiver.Execute 357: FSocket='+IntToStr(FSocket)+', close');
    closesocket(FSocket);
    Terminate;
  end;
end;

{ TClientSender }

procedure TClientSender.ClearInput;
var
  cph: PClientPacket;
begin
  while InputQueue.Count>0 do
  begin
    cph:=PClientPacket(InputQueue.Pop);
    FreeMem(cph.Data);
    Dispose(cph);
  end;
end;

constructor TClientSender.Create(ASocket: TSocket; AID_Camera: integer; APrimary: boolean; AManager: TClientManager);
var
  Addr: TSockAddrIn;
  Size: integer;
begin
  inherited Create(ThreadController.QueueByName('ClientSender_'+IntToStr(AID_Camera)+'_'+IntToStr(ASocket)),nil);
  Socket:=ASocket;
  FID_Camera:=AID_Camera;
  FOnyIDR:=false;
  FPrimary:=APrimary;
  Manager:=AManager;
  Size := sizeof(Addr);
  getpeername(Socket, Addr, Size);
  FSelfString:=string(AnsiString(inet_ntoa(Addr.sin_addr)))+':'+IntToStr(FID_Camera)+':'+BoolToStr(FPrimary,true);
  TCommandReceiver.Create(self,Socket);
  HSize:=SizeOf(TClientPacketHeader);
  Active:=true;
end;

destructor TClientSender.Destroy;
begin
  closesocket(Socket);
  inherited;
end;

procedure TClientSender.DoExecute(var AInputData, AResultData: Pointer);
var
  cph: PClientPacket;
  q: TBytes;
  FrameType: byte;
  SendedBytes: integer;
begin
  try
    cph:=PClientPacket(AInputData);
    try
      AInputData:=nil;
      if FOnyIDR then
      begin
        //пускать только ключевые пакеты
        FrameType:=PByte(NativeUInt(cph.Data)+3)^ AND $1F;
        if FrameType=1 then
          exit;
      end;
      SetLength(q,HSize+cph.Header.Length);
      Move(cph.Header,q[0],HSize);
      Move(cph.Data^,q[HSize],cph.Header.Length);
      if not FOnyIDR then
        while (InputQueue.Count>0)and(length(q)<65535) do
        begin
          FreeMem(cph.Data);
          Dispose(cph);
          cph:=PClientPacket(InputQueue.Pop);
          SetLength(q,length(q)+HSize+cph.Header.Length);
          Move(cph.Header,q[length(q)-cph.Header.Length-HSize],HSize);
          Move(cph.Data^,q[length(q)-cph.Header.Length],cph.Header.Length);
        end;
      try
        SendedBytes:=send(Socket,q[0],length(q),0);
        if SendedBytes=SOCKET_ERROR then
        begin
          SendErrorMsg('TClientSender.DoExecute 437 ['+FSelfString+']: '+SysErrorMessage(GetLastError));
          Stop;
        end;
      except on e: Exception do
        begin
          SendErrorMsg('TClientSender.DoExecute 444 ['+FSelfString+']: '+e.ClassName+' - '+e.Message);
          Stop;
        end;
      end;
    finally
      FreeMem(cph.Data);
      Dispose(cph);
    end;
  except on e: Exception do
    SendErrorMsg('TClientSender.DoExecute 453 ['+FSelfString+']: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TClientSender.ParseCommand(ConnectCommand: TConnectCommand);
begin
  Lock;
  try
    if ConnectCommand.Command=CC_CONNECT then
    begin
      FPrimary:=ConnectCommand.Flag in [0,2];
      FOnyIDR:=ConnectCommand.Flag in [2,3];
    end
    else if ConnectCommand.Command=CC_DISCONNECT then
      Stop;
  finally
    UnLock;
  end;
end;

procedure TClientSender.Stop;
begin
  Manager.Remove(Self);
  closesocket(Socket);
  inherited Stop;
  //очистить входящую очередь
  ClearInput;
end;

{ TConnectWaitThread }

procedure TConnectWaitThread.Execute;
var
  vWSAData: TWSAData;
  S1: TSocket;
  vSockAddr : TSockAddr;
  cPort: Word;
  trId: Cardinal;
  Addr: TSockAddr;
  hRes: Integer;
  SSocket: PSSocket;
  BlackList: TStringList;
  AddrIn: TSockAddrIn;
  IP: string;
  sSize: integer;
begin
  FreeOnTerminate:=true;
  try
    try
      hRes:=WSAStartup($101,vWSAData);
      if hRes<>0 then
      begin
        SendErrorMsg('TConnectWaitThread.Execute 500: ['+IntToStr(hRes)+'] '+SysErrorMessage(GetLastError));
        exit;
      end;
      //Создаем прослушивающий сокет.
      vListenSocket := socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
      if vListenSocket = INVALID_SOCKET then
      begin
        SendErrorMsg('TConnectWaitThread.Execute 507: '+SysErrorMessage(GetLastError));
        exit;
      end;
      BlackList:=TStringList.Create;
      try
        with TIniFile.Create(ChangeFileExt(ParamStr(0),'.ini')) do
          try
            cPort:=ReadInteger('MAIN','ClientPort',50200);
            ReadSectionValues('BLACKLIST',BlackList);
          finally
            Free;
          end;
        FillChar(vSockAddr,SizeOf(TSockAddr),0);
        vSockAddr.sin_family := AF_INET;
        vSockAddr.sin_port := htons(cPort);
        vSockAddr.sin_addr.S_addr := INADDR_ANY;
        //Привязываем адрес и порт к сокету.
        hRes:=bind(vListenSocket,vSockAddr,SizeOf(TSockAddr));
        if hRes<>0 then
        begin
          SendErrorMsg('TConnectWaitThread.Execute 527: ['+IntToStr(hRes)+'] '+SysErrorMessage(GetLastError));
          exit;
        end;
        //Начинаем прослушивать
        hRes:=listen(vListenSocket,SOMAXCONN);
        if hRes<>0 then
        begin
          SendErrorMsg('TConnectWaitThread.Execute 534: ['+IntToStr(hRes)+'] '+SysErrorMessage(GetLastError));
          exit;
        end;
        repeat
          //Ожидаем подключения
          S1:=accept(vListenSocket,@Addr,nil);
          if Terminated then
            exit;
          sSize := SizeOf(AddrIn);
          getpeername(S1, AddrIn, sSize);
          IP:=string(inet_ntoa(AddrIn.sin_addr));
          if BlackList.IndexOf(IP)=-1 then
          begin
            New(SSocket);
            SSocket.Socket:=S1;
            //Клиент подключился, запускаем новый процесс на соединение
            CreateThread(nil,0,@SocketThread,SSocket,0,trId);
          end
          else
          begin
            closesocket(S1);
            SendErrorMsg('TConnectWaitThread.Execute 555: blacklist='+IP);
          end;
        until false;
      finally
        FreeAndNil(BlackList)
      end;
      closesocket(vListenSocket);
      WSACleanup;
    except on e: Exception do
      SendErrorMsg('TConnectWaitThread.Execute 568: '+e.ClassName+' - '+e.Message);
    end;
  finally
    ConnectWaitThread:=nil;
    Terminate;
  end;
end;

procedure TConnectWaitThread.Terminate;
begin
  inherited;
  closesocket(vListenSocket);
end;

{ TClientManager }

procedure TClientManager.AddClient(ASocket: TSocket; AID_Camera: integer; APrimary: boolean);
var
  Client: TClientSender;
  I: integer;
  Addr: TSockAddrIn;
  Size: integer;
  tmpPrimary: boolean;
  tmpCamera: TCamera;
begin
  Lock;
  try
    try
      Size := sizeof(Addr);
      getpeername(ASocket, Addr, Size);
      for I := 0 to AClients.Count - 1 do
        if AClients[I].Socket=ASocket then
        begin
          SendErrorMsg('TClientManager.AddClient 599: client socket exist '+IntToStr(ASocket));
          exit;
        end;
      tmpPrimary:=APrimary;
      if not tmpPrimary then
        for I := 0 to AllCameras.Count - 1  do
        begin
          tmpCamera:=TCamera(AllCameras[i]);
          if (tmpCamera.ID_Camera=AID_Camera) and (not tmpCamera.SecondaryExist) then  //если у камеры нет вторичного, то слать первичный
          begin
            tmpPrimary:=true;
            break;
          end;
        end;
        //if TCamera(AllCameras[i]).SecondaryExist then
      Client:=TClientSender.Create(ASocket,AID_Camera,tmpPrimary,self);
      AClients.Add(Client);
      CameraNeeded:=CameraNeeded+[AID_Camera];
    except on e: Exception do
      SendErrorMsg('TClientManager.AddClient 650: '+e.ClassName+' - '+e.Message);
    end;
  finally
    UnLock;
  end;
end;

procedure TClientManager.AddPacket(APacket: PTimedDataHeader; AID_Camera: integer; APrimary: boolean);
var
  PacketTask: PPacketTask;
  tmpIndex: integer;
  tmpData: Pointer;
begin
  FLock.Enter;
  try
    if TArray.BinarySearch<integer>(CameraNeeded,AID_Camera,tmpIndex) then
    begin
      New(PacketTask);
      GetMem(tmpData,APacket.DataHeader.Size);
      PacketTask.InputFrame:=tmpData;
      Move(APacket^,PacketTask.InputFrame^,APacket.DataHeader.Size);
      PacketTask.ID_Camera:=AID_Camera;
      PacketTask.Primary:=APrimary;
      InputQueue.Push(PacketTask);
    end;
  finally
    FLock.Leave;
  end;
end;

constructor TClientManager.Create;
begin
  inherited Create(ThreadController.QueueByName('ClientManager_Input'),nil);
  AClients:=TList<TClientSender>.Create;
  Active:=true;
end;

destructor TClientManager.Destroy;
var
  I: integer;
begin
  try
    if assigned(AClients) then
    begin
      for I:=0 to AClients.Count-1 do
        TClientSender(AClients[I]).Stop;
      FreeAndNil(AClients);
    end;
  except on e: Exception do
    SendErrorMsg('TClientManager.Destroy 692: '+e.ClassName+' - '+e.Message);
  end;
  inherited;
end;

procedure TClientManager.DoExecute(var AInputData, AResultData: Pointer);
var
  PacketTask: PPacketTask;
  ClientSender: TClientSender;
  cph: PClientPacket;
begin
  try
    PacketTask:=AInputData;
    try
      for ClientSender in AClients do
        if (ClientSender.FID_Camera=PacketTask.ID_Camera)and(ClientSender.FPrimary=PacketTask.Primary) then
        begin
          New(cph);
          cph.Header.Magic:=37;
          cph.Header.Reserved1:=0;
          cph.Header.Reserved2:=0;
          cph.Header.Reserved3:=0;
          cph.Header.Length:=PacketTask.InputFrame.DataHeader.Size;
          cph.Header.TimeStamp:=PacketTask.InputFrame.Time;
          GetMem(cph.Data,cph.Header.Length);
          Move(PacketTask.InputFrame.Data^,cph.Data^,cph.Header.Length);
          ClientSender.InputQueue.Push(cph);
        end;
    finally
      FreeMem(PacketTask.InputFrame);
      Dispose(PacketTask);
      AInputData:=nil;
    end;
  except on e: Exception do
    SendErrorMsg('TClientManager.DoExecute 722: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TClientManager.Remove(ClientSender: TClientSender);
var
  tmpClientSender: TClientSender;
begin
  FLock.Enter;
  try
    AClients.Remove(ClientSender);
    CameraNeeded:=[];
    for tmpClientSender in AClients do
      CameraNeeded:=CameraNeeded+[tmpClientSender.FID_Camera];
  finally
    FLock.Leave;
  end;
end;

end.
