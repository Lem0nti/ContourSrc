unit mdtTracker_TH;

interface

uses
  ABL.Core.TimerThread, Classes, ABL.Core.BaseQueue, SysUtils, mdtCommon, ABL.IO.IOTypes, ABL.IA.IATypes,
  mdtData_DM, SyncObjs;

type
  TTracker=class(TTimerThread)
  private
    Items: TList;
    wh: Extended;
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    destructor Destroy; override;
  end;

implementation

{ TTracker }

constructor TTracker.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  Items:=TList.Create;
  wh:=IcoSize/10;
end;

destructor TTracker.Destroy;
var
  TrackItem: PTrackItem;
  q: integer;
begin
  for q:=0 to Items.Count-1 do
  begin
    TrackItem:=Items[q];
    Dispose(TrackItem);
  end;
  Items.Free;
  inherited;
end;

procedure TTracker.DoExecute;
var
  CheckTime: TDateTime;
  TrackItem: PTrackItem;
  q: integer;
begin
  CheckTime:=now;
  FLock.Enter;
  try
    for q:=Items.Count-1 downto 0 do
    begin
      TrackItem:=Items[q];
      if TrackItem.LastUpdate+5000<CheckTime then
      begin
        Dispose(TrackItem);
        Items.Delete(q);
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TTracker.DoReceive(var AInputData: Pointer);
var
  TimedDataHeader: PTimedDataHeader;
  TrackItem,tmpItem: PTrackItem;
  q,AbsLeft,AbsTop,AbsRight,AbsBottom,CurSumm,MinSumm: integer;
  Area: TArea;
begin
  TimedDataHeader:=AInputData;
  Move(TimedDataHeader.Data^,Area,SizeOf(TArea));
  MinSumm:=100;
  tmpItem:=nil;
  FLock.Enter;
  try
    for q:=Items.Count-1 downto 0 do
    begin
      TrackItem:=Items[q];
      AbsLeft:=abs(TrackItem.CurRect.Left-Area.Rect.Left);
      AbsTop:=abs(TrackItem.CurRect.Top-Area.Rect.Top);
      AbsRight:=abs(TrackItem.CurRect.Right-Area.Rect.Right);
      AbsBottom:=abs(TrackItem.CurRect.Bottom-Area.Rect.Bottom);
      //ищем тот, с которым разница минимальна и меньше 10% для всех точек
      if (AbsLeft<wh)and(AbsTop<wh)and(AbsRight<wh)and(AbsBottom<wh) then
      begin
        CurSumm:=AbsLeft+AbsTop+AbsRight+AbsBottom;
        if CurSumm=0 then
        begin
          tmpItem:=TrackItem;
          break;
        end
        else if CurSumm<MinSumm then
        begin
          MinSumm:=CurSumm;
          tmpItem:=TrackItem;
        end;
      end;
    end;
    if assigned(tmpItem) then
    begin
      tmpItem.CurRect:=Area.Rect;
      if tmpItem.ID_Path=0 then
        tmpItem.ID_Path:=DataDM.AddPath;
      if tmpItem.ID_Path>0 then
        DataDM.ExecSQL('UPDATE Zone set ID_Path='+IntToStr(tmpItem.ID_Path)+' where ID_Zone='+IntToStr(Area.Cnt));
    end
    else
    begin
      New(tmpItem);
      tmpItem.CurRect:=Area.Rect;
      tmpItem.ID_Path:=0;
      Items.Add(tmpItem);
    end;
    tmpItem.LastUpdate:=now;
  finally
    FLock.Leave;
  end;
end;

end.
