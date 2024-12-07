object StatusBoxFM: TStatusBoxFM
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'StatusBox'
  ClientHeight = 100
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = [fsBold]
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbStatus: TLabel
    Left = 15
    Top = 15
    Width = 3
    Height = 13
  end
  object bCancel: TButton
    Left = 295
    Top = 67
    Width = 90
    Height = 25
    Caption = #1054#1058#1052#1045#1053#1040
    TabOrder = 0
    OnClick = bCancelClick
  end
  object ProgressBar: TProgressBar
    Left = 15
    Top = 41
    Width = 370
    Height = 20
    TabOrder = 1
  end
end
