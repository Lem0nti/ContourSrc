object DBSelectFM: TDBSelectFM
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1042#1099#1073#1077#1088#1080#1090#1077' '#1041#1044
  ClientHeight = 235
  ClientWidth = 308
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Button4: TButton
    Left = 120
    Top = 194
    Width = 75
    Height = 25
    Align = alCustom
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object Button1: TButton
    Left = 216
    Top = 194
    Width = 75
    Height = 25
    Align = alCustom
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 291
    Height = 172
    Align = alCustom
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelInner = bvLowered
    TabOrder = 2
    object rbMSSQL: TRadioButton
      Left = 16
      Top = 24
      Width = 113
      Height = 17
      Caption = 'MS SQL'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbMSSQLClick
    end
    object rbPostgre: TRadioButton
      Left = 152
      Top = 24
      Width = 113
      Height = 17
      Caption = 'PostgreSQL'
      TabOrder = 1
      OnClick = rbPostgreClick
    end
    object leServer: TLabeledEdit
      Left = 16
      Top = 72
      Width = 121
      Height = 21
      EditLabel.Width = 37
      EditLabel.Height = 13
      EditLabel.Caption = #1057#1077#1088#1074#1077#1088
      ReadOnly = True
      TabOrder = 2
    end
    object leDatabase: TLabeledEdit
      Left = 152
      Top = 72
      Width = 121
      Height = 21
      EditLabel.Width = 14
      EditLabel.Height = 13
      EditLabel.Caption = #1041#1044
      TabOrder = 3
    end
    object leUsername: TLabeledEdit
      Left = 16
      Top = 120
      Width = 121
      Height = 21
      EditLabel.Width = 72
      EditLabel.Height = 13
      EditLabel.Caption = #1055#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1100
      TabOrder = 4
    end
    object lePassword: TLabeledEdit
      Left = 152
      Top = 120
      Width = 121
      Height = 21
      EditLabel.Width = 37
      EditLabel.Height = 13
      EditLabel.Caption = #1055#1072#1088#1086#1083#1100
      PasswordChar = '*'
      TabOrder = 5
    end
  end
end
