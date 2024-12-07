object CamerasFM: TCamerasFM
  Left = 0
  Top = 0
  Align = alClient
  BorderStyle = bsNone
  Caption = 'CamerasFM'
  ClientHeight = 505
  ClientWidth = 986
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
  object pnlControls: TPanel
    Left = 185
    Top = 0
    Width = 801
    Height = 505
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object iFrame: TImage
      Left = 480
      Top = 18
      Width = 278
      Height = 157
      Proportional = True
      Stretch = True
    end
    object lblWarning: TLabel
      Left = 104
      Top = 458
      Width = 458
      Height = 13
      Caption = 
        #1048#1079#1084#1077#1085#1077#1085#1080#1077' '#1087#1072#1088#1072#1084#1077#1090#1088#1086#1074' '#1082#1072#1084#1077#1088' '#1090#1088#1077#1073#1091#1077#1090' '#1087#1077#1088#1077#1079#1072#1087#1091#1089#1082#1072' '#1089#1083#1091#1078#1073#1099' '#1076#1083#1103'  '#1087#1088#1080#1084#1077 +
        #1085#1077#1085#1080#1103
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      Visible = False
    end
    object lblError: TLabel
      Left = 254
      Top = 159
      Width = 3
      Height = 13
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object leName: TLabeledEdit
      Left = 16
      Top = 34
      Width = 449
      Height = 21
      EditLabel.Width = 48
      EditLabel.Height = 13
      EditLabel.Caption = #1053#1072#1079#1074#1072#1085#1080#1077
      TabOrder = 0
      OnChange = leNameChange
      OnKeyPress = leNameKeyPress
    end
    object lePrimary: TLabeledEdit
      Left = 16
      Top = 79
      Width = 449
      Height = 21
      EditLabel.Width = 90
      EditLabel.Height = 13
      EditLabel.Caption = #1055#1077#1088#1074#1080#1095#1085#1099#1081' '#1087#1086#1090#1086#1082
      TabOrder = 1
      OnChange = lePrimaryChange
      OnDblClick = lePrimaryDblClick
    end
    object leSecondary: TLabeledEdit
      Left = 16
      Top = 123
      Width = 449
      Height = 21
      EditLabel.Width = 89
      EditLabel.Height = 13
      EditLabel.Caption = #1042#1090#1086#1088#1080#1095#1085#1099#1081' '#1087#1086#1090#1086#1082
      TabOrder = 2
      OnChange = leSecondaryChange
      OnDblClick = lePrimaryDblClick
    end
    object cbActive: TCheckBox
      Left = 16
      Top = 158
      Width = 89
      Height = 17
      Caption = #1042#1082#1083#1102#1095#1077#1085#1072
      TabOrder = 3
      OnClick = leNameChange
    end
    object pShedule: TPanel
      Left = 22
      Top = 193
      Width = 742
      Height = 242
      BevelOuter = bvNone
      ParentBackground = False
      ParentColor = True
      TabOrder = 4
      object pRadioShedule: TPanel
        Left = 560
        Top = 0
        Width = 182
        Height = 242
        Align = alRight
        Anchors = [akTop, akRight]
        BevelOuter = bvNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentBackground = False
        ParentColor = True
        ParentFont = False
        TabOrder = 0
        object rgSchedule: TRadioGroup
          Left = 0
          Top = 0
          Width = 182
          Height = 169
          Align = alTop
          Caption = ' '#1056#1072#1089#1087#1080#1089#1072#1085#1080#1077' '
          ItemIndex = 0
          Items.Strings = (
            #1055#1086#1083#1085#1072#1103' '#1085#1077#1076#1077#1083#1103
            #1056#1072#1073#1086#1095#1072#1103' '#1085#1077#1076#1077#1083#1103
            #1050#1088#1091#1075#1083#1086#1089#1091#1090#1086#1095#1085#1086
            #1053#1072#1089#1090#1088#1086#1077#1085#1085#1086#1077' '#1088#1072#1089#1087#1080#1089#1072#1085#1080#1077
            #1047#1072#1087#1080#1089#1100' '#1087#1086' '#1076#1074#1080#1078#1077#1085#1080#1102)
          TabOrder = 0
          OnClick = rgScheduleClick
        end
      end
    end
    object bSave: TButton
      Left = 16
      Top = 452
      Width = 75
      Height = 25
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      TabOrder = 5
      OnClick = bSaveClick
    end
    object bWeb: TButton
      Left = 94
      Top = 154
      Width = 72
      Height = 25
      Caption = 'Web'
      TabOrder = 6
      OnClick = bWebClick
    end
    object bPing: TButton
      Left = 174
      Top = 154
      Width = 72
      Height = 25
      Caption = 'Ping'
      TabOrder = 7
      OnClick = bPingClick
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 505
    Align = alLeft
    Caption = 'Panel1'
    TabOrder = 0
    object gCameras: TDBGrid
      Left = 1
      Top = 26
      Width = 185
      Height = 358
      Align = alLeft
      DataSource = dsCameras
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
    object pCameraButton: TPanel
      Left = 1
      Top = 1
      Width = 183
      Height = 25
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alTop
      BevelEdges = [beBottom]
      BevelKind = bkSoft
      BevelOuter = bvNone
      Color = clSilver
      ParentBackground = False
      TabOrder = 1
      object bAddCamera: TcxButton
        Left = 0
        Top = 0
        Width = 96
        Height = 23
        Align = alLeft
        Anchors = [akLeft, akTop, akRight]
        LookAndFeel.Kind = lfFlat
        LookAndFeel.NativeStyle = False
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001B744558745469746C65004164643B506C75733B426172733B526962
          626F6E3B9506332F0000036349444154785E35927D6C535518C69F73EE6DEB64
          63A3AEFB60A3A36E33B8C56581E0D8707E21CC1A43A2A22304FE3001512A86C4
          E900132451FF503367420043B244364C483031465C248B4441C0980C45B4D065
          CDBA4ECAE82AAC5DBBDE8FF3E1BD27F1397973DE9C3CBFF7233964226FC2D543
          A53E0280443E3FD752525AB14323FA06685A3381E492F329C6ADF39954E2F8C9
          C3DBA6018858DE940A9C2C5870C1D51BB6FAF61DBB327860F81A1BFE25297FB8
          3127C7EFE4E5D5745E9EBB9991239766E481937FE4DE1818DB0DC0EB322EABBA
          B63FD5EB7D6CCBBE6F1B83FE9E67BA82E084C0E4123697CAE0D109BC94805B0C
          E7AFCC606A66EEECF75FBCBB753AFAEB2201A0BD3E7861B02914D8DBF34408A9
          AC0D2181D3672E23319D81AB950D016CEBED824E809A722FC62E4CE17A343130
          D4DF73507FB9FFAB551E9F6FCF93EB82B879BB088D52504A14FCC9CE4E95F79D
          B80CD396284A8179C7D3DD1144F29FEC5BE1D73E1BA6BEB2C09BEDCD955A7CCE
          44D1744C1687C9045C05EBFC686F0DAADCB08413D2098E89B4E1BC5779965687
          5ED585D03ACBFDA548E7197EFA711C776EDFC5FF12200A7075F4E85975D7D4FA
          F1F4A635A82C5F02A2956CD46D2EEB1D160B455BC19FEE5E0F4A885A45828071
          81137D1B61DB0C1E5D43E4C8CF5858E4D0A1810BBA5CB76DEEBDB768C1E604AE
          EA6B1F40D9121F0A265385BC0E5457530109404A8010E27805EEE60598CDA15B
          8699C8E7CD4784EEC3F2BA00767C340A4AA9327E79300CE1505BDEFF0E9AA681
          5082150DD5604CA26858282E1693D428E42F6666B3909068EF68C5E6171FC7E6
          17BA611A260C93A9029C713CF7FC3A3C1BEE404B5B2398E0989FCBA190FD774C
          CFA46243B11B4B77ADADF67BB236478E10500AA5D2121D5C48354D3A674108A1
          56114C201E4BB1D9F86FA70880FB1EDD3E34B0A229B4E7E1350FC2E22E2011BF
          16C3FCBD050557562DC3CA964608B8B4C4E49F4924A27F1F193F1DD9AF03B0FE
          1AFDE03D113EDC6431B1A96575089212B4AD6D555F581280D902398343308EC9
          EB49DC9A981A75E043000CA46D09005A49457059DB4BC78E77EDFCDAEAFDF892
          DC3B1295EF7C13977D4E444E45E52BCE5BE7AE338555E10FDF0650EE32B30E4B
          D24C0212A8F210EAAED3D01969BB3FD0BCDDE32BEB06D56AD5D09CCDDA66EE62
          EED6EF43A9AB2331008603ABCEFF019D3AAD15CCD8D2E00000000049454E44AE
          426082}
        OptionsImage.Layout = blGlyphRight
        ParentShowHint = False
        ShowHint = True
        SpeedButtonOptions.Flat = True
        TabOrder = 0
        OnClick = bAddCameraClick
      end
      object bDeleteCamera: TcxButton
        Left = 96
        Top = 0
        Width = 87
        Height = 23
        Align = alRight
        LookAndFeel.Kind = lfFlat
        LookAndFeel.NativeStyle = False
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          6100000029744558745469746C650052656D6F76653B44656C6574653B426172
          733B526962626F6E3B5374616E646172643B635648300000026449444154785E
          A551494C5351146568194A2B583746627F458902118892AAB811369246043462
          8556D032A82D831664486D8C3FB40B8128E3C68998A289625720314469022591
          26566BC484681C22C6012B5A1556C7F73EBF507FDCF193F3DFBBE7DC7BDE7BF7
          86005811B820E80B2310F16B6880E4F7E10462AAF3F1B2014F889E961FBB307D
          AAE2EBC8FEDC137C72280FB1AB546BA0DAE4F11296C491940F36089F2CD5593F
          DFE8C682771453E71B31909D6D207C044D76166B8C339D1789E6C4A76B5D18D7
          15D9A869B04184A744E7FBED72C03FD08EF9B13BF09CADC1F50C55CDE08182DA
          B7ED562CB807E1BFDB06FF701F3C47753E52131D6C20B2EFCA343C31EAF1D3D1
          89B93E167F1EF5E37155255ED92C989F70E0C74D96E3C734F9B89498749A1E2A
          EC41644F4A6AF5B8F6107C7D2D98ED6D847FE80A7EDDBF8A6FBD4D98ED69C088
          3A0BD678A589E44A843D089844DB141B4D0FF3D5F8D251878FAC9EA08C5B87F6
          EC44B37C6D23C991F2530AF99F81E472BAAA7E42AFC307B612EFEA0E2FC1A52D
          446B5A4633C991090D968A5B93D24D4EAD06336DF5982E5363BA9C07D9BF674F
          62B4F020AC9B53976EF1CF145A36249B1EE4E5E28DA5022F8AB23045706B1383
          DB498974CFE1F599620CAB736061B63409A720ED5624CFBD341E81B760379EE5
          65A23F410183487ACE208EB1F42728E1CDCFE4F0BC641FBA9894395213176C10
          655EA3EC706CDF06778E0A76C57A5447C8E87B63298C91B166BB92817BEF0EDC
          4BDB8A0639D34DF8986083309A58278BEFB0C631BEAAC5E255940F6886A8D566
          A27DAF95ADEB22B15CD883808984208E209A8F859A9C6F6078F0145684BF98E8
          BFC080A205F60000000049454E44AE426082}
        OptionsImage.Layout = blGlyphTop
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = bDeleteCameraClick
      end
    end
    object gPlugins: TDBGrid
      Left = 1
      Top = 384
      Width = 183
      Height = 120
      Align = alBottom
      DataSource = dsPlugins
      Enabled = False
      Options = [dgColumnResize, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
      ReadOnly = True
      TabOrder = 2
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
  object dsCameras: TDataSource
    Left = 112
    Top = 8
  end
  object Timer: TTimer
    Enabled = False
    Interval = 300
    OnTimer = TimerTimer
    Left = 24
    Top = 56
  end
  object ErrorTimer: TTimer
    Interval = 300
    OnTimer = ErrorTimerTimer
    Left = 24
    Top = 8
  end
  object ActionList: TActionList
    Left = 479
    Top = 265
    object aSave: TAction
      Caption = 'aSave'
      ShortCut = 16467
      OnExecute = aSaveExecute
    end
  end
  object dsPlugins: TDataSource
    Left = 112
    Top = 56
  end
end
