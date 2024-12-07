unit cScheduleTypes;

interface

type
  TDaySchedule=record
    DayBegin: integer;
    DayEnd: integer;
  end;

  TWeekDay = array [1..7] of TDaySchedule;

implementation

end.
