object ThumbFM: TThumbFM
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 1
  Caption = 'ThumbFM'
  ClientHeight = 206
  ClientWidth = 288
  Color = 4145477
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 7697919
  Font.Height = -16
  Font.Name = 'Tahoma'
  Font.Style = [fsBold]
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 19
  object Image: TImage
    Left = 0
    Top = 0
    Width = 286
    Height = 196
    Align = alCustom
    Anchors = [akLeft, akTop, akRight, akBottom]
    Stretch = True
    ExplicitWidth = 298
    ExplicitHeight = 198
  end
  object lblAlarm: TLabel
    Left = 0
    Top = 0
    Width = 288
    Height = 206
    Align = alClient
    Alignment = taCenter
    AutoSize = False
    Caption = 'lblAlarm'
    Color = clCream
    ParentColor = False
    Layout = tlCenter
    WordWrap = True
    ExplicitHeight = 200
  end
  object Timer: TTimer
    Enabled = False
    Interval = 200
    OnTimer = TimerTimer
    Left = 128
    Top = 88
  end
end
