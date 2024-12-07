unit mdtScroll_TH;

interface

uses
  Classes, ABL.Core.ThreadItem, mdtData_DM, ABL.IO.IOTypes, DB, SysUtils, ABL.Core.Debug, Windows, mdtCommon;

type
  TScroll=class(TThread) //унаследовать от обычного потока
  private
    FInputItem: TThreadItem;
    Handle: THandle;
  protected
    procedure Execute; override;
  public
    constructor Create(AInputItem: TThreadItem; SyncHandle: THandle); overload;
    procedure Push(AItem: Pointer);
  end;

var
  Scroll: TScroll;

implementation

{ TScroll }

constructor TScroll.Create(AInputItem: TThreadItem; SyncHandle: THandle);
begin
  inherited Create(false);
  FInputItem:=AInputItem;
  Handle:=SyncHandle;
end;

procedure TScroll.Execute;
var
  TimedDataHeader: PTimedDataHeader;
  tmpInt: PInteger;
  ID_Event: integer;
begin
  while not Terminated do
    try
      FInputItem.WaitForItems(100);
      if not Terminated then
      begin
        while (FInputItem.Count>0)and(not Terminated) do
        begin
          TimedDataHeader:=FInputItem.Pop;
          try
            tmpInt:=TimedDataHeader.Data;
            ID_Event:=DataDM.EventByTime(TimedDataHeader.Time,tmpInt^);
            if ID_Event>0 then
              SendMessage(Handle,WM_SCROLLPLUGINEVENTS,ID_Event,0);
          finally
            FreeMem(TimedDataHeader);
          end;
        end;
      end;
    except on e: Exception do
      SendErrorMsg('TScroll.Execute 76: '+e.ClassName+' - '+e.Message);
    end;
end;

procedure TScroll.Push(AItem: Pointer);
begin
  FInputItem.Push(AItem);
end;

end.
