unit ccPing;

interface

uses
  Windows, WinSock, SysUtils, ABL.Core.Debug;

type
  ip_option_information = packed record
    Ttl: byte;
    Tos: byte;
    Flags: byte;
    OptionsSize: byte;
    OptionsData: Pointer;
  end;

  icmp_echo_reply = packed record
    Address: u_long;
    Status: u_long;
    RTTime: u_long;
    DataSize: u_short;
    Reserved: u_short;
    Data: Pointer;
    Options: ip_option_information;
  end;

  PIPINFO = ^ip_option_information;
  PVOID = Pointer;

function IcmpCreateFile : THandle; stdcall; external 'ICMP.DLL' name 'IcmpCreateFile';
function IcmpCloseHandle(IcmpHandle : THandle) : BOOL; stdcall; external 'ICMP.DLL'  name 'IcmpCloseHandle';
function IcmpSendEcho(
                      IcmpHandle : THandle;    // handle, возвращенный IcmpCreateFile()
                      DestAddress : u_long;    // Адрес получателя (в сетевом порядке)
                      RequestData : PVOID;     // Указатель на посылаемые данные
                      RequestSize : Word;      // Размер посылаемых данных
                      RequestOptns : PIPINFO;  // Указатель на посылаемую структуру
                                         // ip_option_information (может быть nil)
                      ReplyBuffer : PVOID;     // Указатель на буфер, содержащий ответы.
                      ReplySize : DWORD;       // Размер буфера ответов
                      Timeout : DWORD          // Время ожидания ответа в миллисекундах
                     ) : DWORD; stdcall; external 'ICMP.DLL' name 'IcmpSendEcho';

function Ping(AHost: AnsiString; AttemptCount: byte; var AStatus: integer): boolean;

implementation

function Ping(AHost: AnsiString; AttemptCount: byte; var AStatus: integer): boolean;
var
  hIP: THandle;
  pingBuffer: array [0..31] of Char;
  pIpe: ^icmp_echo_reply;
  pHostEn: PHostEnt;
  wVersionRequested: WORD;
  lwsaData: WSAData;
  error: DWORD;
  destAddress: In_Addr;
  Attempt: byte;
begin
  result:=False;
  AStatus:=-1;
  try
    pIpe:=nil;
    hIP:=IcmpCreateFile;
    try
      GetMem(pIpe,sizeof(icmp_echo_reply)+sizeof(pingBuffer));
      pIpe.Data:= @pingBuffer;
      pIpe.DataSize:=sizeof(pingBuffer);
      wVersionRequested:=MakeWord(1,1);
      error:=WSAStartup(wVersionRequested,lwsaData);
      if (error <> 0) then
        Exit;
      pHostEn:=gethostbyname(PAnsiChar(AHost));
      error:=GetLastError;
      if (error<>0) then
        Exit;
      destAddress:=PInAddr(pHostEn^.h_addr_list^)^;
      Attempt:=1;
      error:=1;
      while (error<>0)and(Attempt<=AttemptCount) do
      begin
        error:=IcmpSendEcho(hIP,destAddress.S_addr,@pingBuffer,sizeof(pingBuffer),Nil,pIpe,sizeof(icmp_echo_reply)+sizeof(pingBuffer),1000);
        if error>0 then
        begin
          result:=(pIpe.Status=0)or(pIpe.Status=11050);
          AStatus:=pIpe.Status;
          break;
        end
        else
        begin
          error:=GetLastError;
          result:=(error=0)or(error=11050);
          if result then
            break
          else
            SendErrorMsg('ccPing.Ping 96: IcmpSendEcho='+IntToStr(error));
        end;
        inc(Attempt);
        if (error<>0)and(Attempt<=AttemptCount) then
          Sleep(400);
      end;
    finally
      IcmpCloseHandle(hIP);
      WSACleanup;
      if pIpe<>nil then
        FreeMem(pIpe);
    end;
  except on e: Exception do
    SendErrorMsg('ccPing.Ping 105: '+e.ClassName+' - '+e.Message);
  end;
end;

end.
