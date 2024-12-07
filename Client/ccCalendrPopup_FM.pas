unit ccCalendrPopup_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, DateUtils, Types;

type
  TCalendarPopupFM = class(TForm)
    MonthCalendar: TMonthCalendar;
    procedure FormDeactivate(Sender: TObject);
    procedure MonthCalendarMouseLeave(Sender: TObject);
    procedure MonthCalendarGetMonthBoldInfo(Sender: TObject; Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
  private
    { Private declarations }
  public
    { Public declarations }
    Days: TIntegerDynArray;
  end;

var
  CalendarPopupFM: TCalendarPopupFM;

implementation

{$R *.dfm}

procedure TCalendarPopupFM.FormDeactivate(Sender: TObject);
begin
  Hide;
end;

procedure TCalendarPopupFM.MonthCalendarGetMonthBoldInfo(Sender: TObject; Month, Year: Cardinal;
  var MonthBoldInfo: Cardinal);
var
  sFirst,sLast,sDay: integer;
  ADays: array of LongWord;
  I: LongWord;
begin
  sFirst:=trunc(EncodeDate(Year,Month,1));
  sLast:=trunc(EndOfTheMonth(sFirst));
  ADays:=[0];
  for sDay in Days do
    if (sDay>=sFirst)and(sDay<=sLast) then
      ADays:=ADays+[DayOf(sDay)];
  MonthBoldInfo := 0;
  for I := Low(ADays) to High(ADays) do
    if (ADays[I] > 0) and (ADays[I] < 32) then
      MonthBoldInfo := MonthBoldInfo or ($00000001 shl (ADays[I] - 1));
end;

procedure TCalendarPopupFM.MonthCalendarMouseLeave(Sender: TObject);
begin
  Hide;
end;

end.
