object CalendarPopupFM: TCalendarPopupFM
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'CalendarPopupFM'
  ClientHeight = 160
  ClientWidth = 162
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDeactivate = FormDeactivate
  PixelsPerInch = 96
  TextHeight = 13
  object MonthCalendar: TMonthCalendar
    Left = 0
    Top = 0
    Width = 162
    Height = 160
    Date = 44595.940704409720000000
    TabOrder = 0
    OnGetMonthBoldInfo = MonthCalendarGetMonthBoldInfo
    OnMouseLeave = MonthCalendarMouseLeave
  end
end
