unit cFrameCollector_TH;

interface

uses
  SysUtils, ABL.Core.Debug, DateUtils, cCommon, ABL.Core.DirectThread, cFrameList_Cl, ABL.Core.BaseQueue,
  Classes, cScheduleTypes, ABL.IO.IOTypes;

type
  TFrameCollector = class(TDirectThread)
  private
    FrameList,SecondaryFrameList: TFrameList;
    FSchedule: TWeekDay;
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    DebugEnabled: boolean;
    constructor Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string = ''); override;
    Destructor Destroy; override;
    procedure ApplySchedule(AScheduleType: byte; ASchedule: TWeekDay);
    procedure IncSave;
  end;

implementation

{ TCollector }

procedure TFrameCollector.ApplySchedule(AScheduleType: byte; ASchedule: TWeekDay);
begin
  Lock;
  try
    case AScheduleType of
      1:  //рабочая неделя
      begin
        FSchedule[1].DayBegin:=28800;
        FSchedule[1].DayEnd:=82800;
        FSchedule[2].DayBegin:=28800;
        FSchedule[2].DayEnd:=82800;
        FSchedule[3].DayBegin:=28800;
        FSchedule[3].DayEnd:=82800;
        FSchedule[4].DayBegin:=28800;
        FSchedule[4].DayEnd:=82800;
        FSchedule[5].DayBegin:=28800;
        FSchedule[5].DayEnd:=82800;
        FSchedule[6].DayBegin:=0;
        FSchedule[6].DayEnd:=0;
        FSchedule[7].DayBegin:=0;
        FSchedule[7].DayEnd:=0;
      end;
      2:  //круглосуточно
      begin
        FSchedule[1].DayBegin:=-1;
        FSchedule[1].DayEnd:=87000;
        FSchedule[2].DayBegin:=-1;
        FSchedule[2].DayEnd:=87000;
        FSchedule[3].DayBegin:=-1;
        FSchedule[3].DayEnd:=87000;
        FSchedule[4].DayBegin:=-1;
        FSchedule[4].DayEnd:=87000;
        FSchedule[5].DayBegin:=-1;
        FSchedule[5].DayEnd:=87000;
        FSchedule[6].DayBegin:=-1;
        FSchedule[6].DayEnd:=87000;
        FSchedule[7].DayBegin:=-1;
        FSchedule[7].DayEnd:=87000;
      end;
      3:  //настроенное расписание
        move(ASchedule,FSchedule,SizeOf(TWeekDay));
      4:  //по движению
      begin
        FSchedule[1].DayBegin:=-2;
        FSchedule[1].DayEnd:=-1;
        FSchedule[2].DayBegin:=-2;
        FSchedule[2].DayEnd:=-1;
        FSchedule[3].DayBegin:=-2;
        FSchedule[3].DayEnd:=-1;
        FSchedule[4].DayBegin:=-2;
        FSchedule[4].DayEnd:=-1;
        FSchedule[5].DayBegin:=-2;
        FSchedule[5].DayEnd:=-1;
        FSchedule[6].DayBegin:=-2;
        FSchedule[6].DayEnd:=-1;
        FSchedule[7].DayBegin:=-2;
        FSchedule[7].DayEnd:=-1;
      end;
      else  //во всех остальных случаях - полная неделя
      begin
        FSchedule[1].DayBegin:=28800;
        FSchedule[1].DayEnd:=82800;
        FSchedule[2].DayBegin:=28800;
        FSchedule[2].DayEnd:=82800;
        FSchedule[3].DayBegin:=28800;
        FSchedule[3].DayEnd:=82800;
        FSchedule[4].DayBegin:=28800;
        FSchedule[4].DayEnd:=82800;
        FSchedule[5].DayBegin:=28800;
        FSchedule[5].DayEnd:=82800;
        FSchedule[6].DayBegin:=28800;
        FSchedule[6].DayEnd:=82800;
        FSchedule[7].DayBegin:=28800;
        FSchedule[7].DayEnd:=82800;
      end;
    end;
  finally
    UnLock;
  end;
end;

constructor TFrameCollector.Create(AInputQueue, AOutputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,AOutputQueue,AName);
  ApplySchedule(2,FSchedule);
  Active:=true;
  DebugEnabled:=false;
end;

destructor TFrameCollector.Destroy;
begin
  if assigned(FrameList) then
    FreeAndNil(FrameList);
  inherited;
end;

procedure TFrameCollector.DoExecute(var AInputData, AResultData: Pointer);
var
  NewList,CurList: TFrameList;
  Drop: boolean;
  CurSecondsBegin,CurSecondsEnd,FFrTimeIndex: integer;
  WeekDay: byte;
  FFrBeginTime,FFrEndTime: int64;
  SaveCount: integer;

  procedure DropTutuPart(AList: TFrameList);
  var
    AFrame: PTimedDataHeader;
  begin
    if AList.Count>1 then
    begin
      //первый всегда ключевой, его сбрасываем безусловно
      AFrame:=AList.First;
      repeat
        AList.Delete(0);
        FreeMem(AFrame);
        if AList.Count=0 then
          break;
        AFrame:=AList.First;
      until AFrame.Reserved=7;  //далее сбрасываем до следующего ключевого
    end;
  end;

begin
  try
    NewList:=TFrameList(AInputData);
    if assigned(NewList) then
    begin
      AInputData:=nil;
      if Terminated then
        exit;
      Drop:=false;
      if NewList.Primary then
        CurList:=FrameList
      else
        CurList:=SecondaryFrameList;
      if assigned(CurList) then
      begin
        //добавить фреймы себе
        while NewList.Count>0 do
        begin
          CurList.Add(NewList.Items[0]);
          NewList.Delete(0);
        end;
        if CurList.Primary then
          SaveCount:=128
        else
          SaveCount:=256;
        //если кол-во больше, или это команда на сброс, или накопилось 16 метров, то отправить на сохранение
        if (CurList.Count>SaveCount)or(NewList.ID_Camera=-1)or((CurList.Count>64)and(CurList.Size>16*1024*1024)) then
        begin
          if CurList.Count>0 then  //проверить расписание
          begin
            //ищем последний фрейм с временем
            FFrEndTime:=0;
            FFrTimeIndex:=CurList.Count;
            while FFrEndTime=0 do
            begin
              dec(FFrTimeIndex);
              if FFrTimeIndex>=0 then
                FFrEndTime:=PTimedDataHeader(CurList[FFrTimeIndex]).Time
              else
                break;
            end;
            FFrBeginTime:=0;
            FFrTimeIndex:=-1;
            while FFrBeginTime=0 do
            begin
              inc(FFrTimeIndex);
              if FFrTimeIndex=CurList.Count then  //защита от кадров без времени
                Break
              else
                FFrBeginTime:=PTimedDataHeader(CurList[FFrTimeIndex]).Time;
            end;
            Drop:=FFrBeginTime>0;
            if Drop then
            begin
              WeekDay:=DayOfWeek(IncMilliSecond(UnixDateDelta,FFrEndTime))-1;
              if WeekDay=0 then
                WeekDay:=7;
              CurSecondsEnd:=(FFrEndTime mod MSecsPerDay) div 1000;
              CurSecondsBegin:=(FFrBeginTime mod MSecsPerDay) div 1000;
              if FFrBeginTime div MSecsPerDay<>FFrEndTime div MSecsPerDay then
                CurSecondsBegin:=CurSecondsBegin-SecsPerDay;
              Drop:=(CurSecondsEnd>FSchedule[WeekDay].DayBegin)and(CurSecondsBegin<FSchedule[WeekDay].DayEnd);
            end
            else
            begin
              SendErrorMsg('TFrameCollector.DoExecute 232: отсутствует время в кадрах по камере '+IntToStr(CurList.ID_Camera)+', Primary='+BoolToStr(CurList.Primary,true)+
                  ', CurList.Count='+IntToStr(CurList.Count));
              DropTutuPart(CurList);
            end;
          end;
          if Drop then
          begin
            AResultData:=CurList;
            if CurList.Primary then
              FrameList:=nil
            else
              SecondaryFrameList:=nil;
          end
          else if NewList.ID_Camera>0 then
            DropTutuPart(CurList);  //иначе удалить первые кадры до ближайшего ключевого
        end;
        //удалить старый список
        FreeAndNil(NewList);
      end
      else if NewList.ID_Camera>0 then
        if NewList.Primary then
          FrameList:=NewList
        else
          SecondaryFrameList:=NewList;
    end
    else
      SendErrorMsg('TFrameCollector.DoExecute 243: empty input data');
  except on e: Exception do
    SendErrorMsg('TFrameCollector.DoExecute 245: '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TFrameCollector.IncSave;
var
  q: word;
  w: integer;
begin
  Lock;
  try
    //выяснить день
    q:=DayOfWeek(Now);
    q:=q-1;
    if q=0 then
      q:=7;
    //выяснить секунду
    w:=(DateTimeToTimeStamp(now).Time div 1000)+30;
    //сдвинуть расписание
    FSchedule[q].DayEnd:=w;
    //если переход через сутки, то сдвинуть следующий день
    if w>86400 then
    begin
      w:=w-86400;
      inc(q);
      if q>7 then
        q:=1;
      FSchedule[q].DayEnd:=w;
    end
    else
    begin
      dec(q);
      //сбросить предыдущий день
      if q=0 then
        q:=7;
      FSchedule[q].DayEnd:=-1;
    end;
  finally
    UnLock;
  end;
end;

end.
