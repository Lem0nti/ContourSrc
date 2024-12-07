object EventsFM: TEventsFM
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'EventsFM'
  ClientHeight = 457
  ClientWidth = 515
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 515
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object DateTimePicker: TDateTimePicker
      Left = 8
      Top = 14
      Width = 97
      Height = 21
      Date = 45341.900704861110000000
      Time = 45341.900704861110000000
      TabOrder = 0
      OnCloseUp = DateTimePickerCloseUp
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 49
    Width = 515
    Height = 408
    Align = alClient
    DataSource = dsEvents
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object dsEvents: TDataSource
    Left = 232
    Top = 168
  end
end
