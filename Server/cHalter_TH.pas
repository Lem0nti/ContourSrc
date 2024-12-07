unit cHalter_TH;

interface

uses
  ABL.Core.TimerThread, PsAPI, Windows, ABL.Core.Debug, SysUtils;

type
  THalter=class(TTimerThread)
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    constructor Create(ATimeOut: Cardinal = 30000); reintroduce;
  end;

var
  Halter: THalter;

implementation

{ THalter }

constructor THalter.Create(ATimeOut: Cardinal = 30000);
begin
  inherited Create(nil,nil,'THalter');
  FInterval:=ATimeOut;
  Enabled:=true;
  Active:=true;
end;

procedure THalter.DoExecute;
var
  cb: integer;
  pmc: PPROCESS_MEMORY_COUNTERS;
  CurMem: integer;
begin
  cb:=SizeOf(_PROCESS_MEMORY_COUNTERS);
  GetMem(pmc,cb);
  try
    pmc^.cb:=cb;
    if GetProcessMemoryInfo(GetCurrentProcess,pmc,cb) then
    begin
      CurMem:=pmc^.WorkingSetSize div (1024*1024);
      if CurMem>1024 then
      begin
        SendErrorMsg('THalter.DoExecute 47, использование ОЗУ: '+IntToStr(CurMem)+' Mb, перезапуск');
        Halt;
      end;
    end;
  finally
    FreeMem(pmc);
  end;
end;

procedure THalter.DoReceive(var AInputData: Pointer);
begin
end;

end.
