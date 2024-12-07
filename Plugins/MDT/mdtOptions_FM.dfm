object OptionsFM: TOptionsFM
  Left = 0
  Top = 0
  Align = alClient
  BorderStyle = bsNone
  Caption = 'OptionsFM'
  ClientHeight = 334
  ClientWidth = 497
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlScreen: TPanel
    Left = 8
    Top = 8
    Width = 481
    Height = 270
    BevelOuter = bvNone
    TabOrder = 0
  end
  object Timer: TTimer
    Interval = 300
    OnTimer = TimerTimer
    Left = 192
    Top = 216
  end
end
