unit cpCacheClear_TH;

interface

uses
  Classes, SysUtils, IOUtils, Types, DateUtils;

type
  TCacheClear=class(TThread)
  protected
    procedure Execute; override;
  end;

implementation

{ TCacheClear }

procedure TCacheClear.Execute;
var
  fn: TFileName;
  ServerList,DaysList: TStringDynArray;
  tmpServer,TodayString,tmpDayFolder: string;
  MinDay: integer;
  DT: TDateTime;
begin
  fn:=ExtractFilePath(ParamStr(0))+'tmp\';
  //идЄм по серверам
  ServerList:=TDirectory.GetDirectories(fn);
  DT:=now;
  TodayString:=IntToStr((YearOf(DT)-2000)*10000+MonthOf(DT)*100+DayOf(DT));
  DT:=now-7;
  MinDay:=(YearOf(DT)-2000)*10000+MonthOf(DT)*100+DayOf(DT);
  //не больше недели кэша
  for tmpServer in ServerList do
  begin
    //удалить сегодн€шний день
    DaysList:=TDirectory.GetDirectories(tmpServer);
    //удалить всех, кто старше недели
    for tmpDayFolder in DaysList do
      if StrToIntDef(ExtractFileName(tmpDayFolder),0)<MinDay then
        TDirectory.Delete(tmpDayFolder,true);
  end;
end;

end.
