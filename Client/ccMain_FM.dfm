object MainFM: TMainFM
  Left = 0
  Top = 0
  Caption = #1050#1086#1085#1090#1091#1088
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  WindowState = wsMaximized
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 635
    Height = 280
    ActivePage = tsPlayer
    Align = alClient
    Style = tsFlatButtons
    TabOrder = 0
    OnChange = PageControlChange
    OnChanging = PageControlChanging
    object tsPlayer: TTabSheet
      Caption = #1055#1088#1086#1089#1084#1086#1090#1088
    end
    object tsCameras: TTabSheet
      Caption = #1050#1072#1084#1077#1088#1099
      ImageIndex = 1
    end
    object tsPlugins: TTabSheet
      Caption = #1055#1083#1091#1075#1080#1085#1099
      ImageIndex = 3
    end
    object tsArchive: TTabSheet
      Caption = #1040#1088#1093#1080#1074
      ImageIndex = 2
    end
  end
  object sbStatus: TStatusBar
    Left = 0
    Top = 280
    Width = 635
    Height = 19
    Panels = <
      item
        Width = 96
      end
      item
        Bevel = pbRaised
        Style = psOwnerDraw
        Width = 19
      end
      item
        Width = 96
      end
      item
        Bevel = pbRaised
        Style = psOwnerDraw
        Width = 19
      end
      item
        Width = 96
      end
      item
        Bevel = pbRaised
        Style = psOwnerDraw
        Width = 19
      end
      item
        Width = 112
      end
      item
        Width = 50
      end>
    ParentShowHint = False
    ShowHint = False
    OnMouseDown = sbStatusMouseDown
    OnMouseMove = sbStatusMouseMove
    OnMouseUp = sbStatusMouseUp
    OnDrawPanel = sbStatusDrawPanel
  end
  object ppmServiceStarted: TPopupMenu
    OwnerDraw = True
    Left = 308
    Top = 143
    object miStopService: TMenuItem
      Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1089#1083#1091#1078#1073#1091
      OnClick = miStopServiceClick
      OnAdvancedDrawItem = miCurrentServerAdvancedDrawItem
      OnMeasureItem = miCurrentServerMeasureItem
    end
    object miRestartService: TMenuItem
      Caption = #1055#1077#1088#1077#1079#1072#1087#1091#1089#1090#1080#1090#1100' '#1089#1083#1091#1078#1073#1091
      OnClick = miRestartServiceClick
      OnAdvancedDrawItem = miCurrentServerAdvancedDrawItem
      OnMeasureItem = miCurrentServerMeasureItem
    end
  end
  object ppmSwitchServer: TPopupMenu
    AutoHotkeys = maManual
    OwnerDraw = True
    OnPopup = ppmSwitchServerPopup
    Left = 176
    Top = 88
    object miCurrentServer: TMenuItem
      Caption = #1058#1077#1082#1091#1097#1077#1077' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077': '
      Enabled = False
      OnAdvancedDrawItem = miCurrentServerAdvancedDrawItem
      OnMeasureItem = miCurrentServerMeasureItem
    end
    object miSwitchServer: TMenuItem
      Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100#1089#1103' '#1082' '#1076#1088#1091#1075#1086#1084#1091' ...'
      OnClick = miSwitchServerClick
      OnAdvancedDrawItem = miCurrentServerAdvancedDrawItem
      OnMeasureItem = miCurrentServerMeasureItem
    end
    object miInstall: TMenuItem
      Caption = #1059#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1079#1076#1077#1089#1100
      OnClick = miInstallClick
      OnAdvancedDrawItem = miCurrentServerAdvancedDrawItem
      OnMeasureItem = miCurrentServerMeasureItem
    end
  end
end
