object PluginsFM: TPluginsFM
  Left = 0
  Top = 0
  Align = alClient
  BorderStyle = bsNone
  Caption = 'PluginsFM'
  ClientHeight = 388
  ClientWidth = 664
  Color = clBtnFace
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
  object pMain: TPanel
    Left = 0
    Top = 0
    Width = 664
    Height = 388
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlPluginParams: TPanel
      Left = 185
      Top = 0
      Width = 216
      Height = 388
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object gbPluginSettings: TGroupBox
        Left = 15
        Top = 120
        Width = 194
        Height = 255
        Align = alCustom
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1087#1083#1091#1075#1080#1085#1072' '
        TabOrder = 0
      end
      object cbSecondPath: TCheckBox
        Left = 19
        Top = 44
        Width = 191
        Height = 20
        Caption = #1048#1089#1087#1086#1083#1100#1079#1086#1074#1072#1090#1100' '#1074#1090#1086#1088#1080#1095#1085#1099#1081' '#1087#1086#1090#1086#1082
        TabOrder = 1
      end
      object Button1: TButton
        Left = 17
        Top = 74
        Width = 190
        Height = 25
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1085#1072#1089#1090#1088#1086#1081#1082#1080
        TabOrder = 2
      end
      object cbCameraName: TCheckBox
        Left = 19
        Top = 16
        Width = 191
        Height = 17
        Caption = 'cbCameraName'
        TabOrder = 3
        OnClick = cbCameraNameClick
      end
    end
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 185
      Height = 388
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'Panel1'
      TabOrder = 1
      object gCameras: TDBGrid
        Left = 0
        Top = 185
        Width = 185
        Height = 203
        Align = alClient
        DataSource = dsPluginCamera
        Options = [dgColumnResize, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'ID_Camera'
            Width = 32
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'Name'
            Width = 128
            Visible = True
          end>
      end
      object gPlugins: TDBGrid
        Left = 0
        Top = 0
        Width = 185
        Height = 185
        Align = alTop
        DataSource = dsPlugin
        Options = [dgColumnResize, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ReadOnly = True
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'ID_Camera'
            Width = 32
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'Name'
            Width = 128
            Visible = True
          end>
      end
    end
    object pnlPluginOptions: TPanel
      Left = 401
      Top = 0
      Width = 263
      Height = 388
      Align = alClient
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 2
    end
  end
  object dsPlugin: TDataSource
    Left = 24
    Top = 16
  end
  object dsPluginCamera: TDataSource
    Left = 24
    Top = 72
  end
  object dsPluginParam: TDataSource
    Left = 24
    Top = 120
  end
end
