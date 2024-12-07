object ArchiveFM: TArchiveFM
  Left = 0
  Top = 0
  Align = alClient
  BorderStyle = bsNone
  Caption = 'ArchiveFM'
  ClientHeight = 338
  ClientWidth = 651
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblWarning: TLabel
    Left = 97
    Top = 230
    Width = 470
    Height = 13
    Caption = 
      #1048#1079#1084#1077#1085#1077#1085#1080#1077' '#1087#1072#1088#1072#1084#1077#1090#1088#1086#1074' '#1072#1088#1093#1080#1074#1086#1074' '#1090#1088#1077#1073#1091#1077#1090' '#1087#1077#1088#1077#1079#1072#1087#1091#1089#1082#1072' '#1089#1083#1091#1078#1073#1099' '#1076#1083#1103'  '#1087#1088#1080 +
      #1084#1077#1085#1077#1085#1080#1103
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object bSave: TButton
    Left = 8
    Top = 225
    Width = 75
    Height = 25
    Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
    TabOrder = 0
    OnClick = bSaveClick
  end
  object TimerArchive: TTimer
    Interval = 100
    OnTimer = TimerArchiveTimer
    Left = 208
    Top = 136
  end
end
