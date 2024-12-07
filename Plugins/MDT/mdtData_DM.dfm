inherited DataDM: TDataDM
  OldCreateOrder = True
  Height = 483
  Width = 784
  inherited FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=PG'
      'CharacterSet=WIN1251'
      'LoginTimeout=30')
    Left = 568
    Top = 8
  end
  inherited FDPhysPgDriverLink: TFDPhysPgDriverLink
    VendorLib = 'D:\Projects\ABItems\bin\Contour\libpq.dll'
    Left = 656
    Top = 144
  end
  inherited ADOConnection: TADOConnection
    CommandTimeout = 60
    ConnectOptions = coAsyncConnect
    Left = 256
    Top = 8
  end
  inherited QueryPG: TFDQuery
    Left = 432
    Top = 248
  end
  inherited QueryMS: TADOQuery
    Left = 208
    Top = 200
  end
  object spSaveEventMS: TADOStoredProc
    Connection = ADOConnection
    ProcedureName = 'spSaveEvent'
    Parameters = <
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'Event_Time'
        DataType = ftLargeint
        Value = Null
      end>
    Left = 40
    Top = 104
  end
  object spSaveZoneMS: TADOStoredProc
    Connection = ADOConnection
    ProcedureName = 'spSaveZone'
    Parameters = <
      item
        Name = 'AID_Event'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASquare_From'
        DataType = ftSmallint
        Value = Null
      end
      item
        Name = 'ASquare_To'
        DataType = ftSmallint
        Value = Null
      end>
    Left = 40
    Top = 152
  end
  object spEventsMS: TADOStoredProc
    Connection = ADOConnection
    AfterOpen = spEventsMSAfterOpen
    AfterScroll = spEventsMSAfterScroll
    ProcedureName = 'spEvents'
    Parameters = <
      item
        Name = 'BeginDate'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'EndDate'
        DataType = ftLargeint
        Value = Null
      end>
    Left = 40
    Top = 56
  end
  object qEventsPG: TFDQuery
    AfterOpen = spEventsMSAfterOpen
    AfterScroll = spEventsMSAfterScroll
    Connection = FDConnection
    SQL.Strings = (
      
        'select p.FileName,pc.ID_Camera,pc.APrimary from Plugin p left jo' +
        'in Plugin_Camera pc on pc.ID_Plugin=p.ID_Plugin order by FileNam' +
        'e,ID_Camera')
    Left = 432
    Top = 200
    object qEventsPGFileName: TStringField
      FieldName = 'FileName'
      Origin = 'FileName'
      Required = True
      Size = 128
    end
    object qEventsPGID_Camera: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'ID_Camera'
      Origin = 'ID_Camera'
      ProviderFlags = []
      ReadOnly = True
    end
    object qEventsPGAPrimary: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'APrimary'
      Origin = 'APrimary'
      ProviderFlags = []
      ReadOnly = True
    end
  end
  object tEventsScroll: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tEventsScrollTimer
    Left = 136
    Top = 296
  end
  object spEventByTimeMS: TADOStoredProc
    ProcedureName = 'spEventByTime'
    Parameters = <
      item
        Name = 'DateTime'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'Pause'
        DataType = ftInteger
        Value = 300
      end>
    Left = 40
    Top = 8
  end
  object spZoneByEventMS: TADOStoredProc
    ProcedureName = 'spZoneByEvent'
    Parameters = <>
    Left = 40
    Top = 200
  end
  object qZoneByEventPG: TFDQuery
    AfterOpen = spEventsMSAfterOpen
    AfterScroll = spEventsMSAfterScroll
    Connection = FDConnection
    SQL.Strings = (
      
        'select p.FileName,pc.ID_Camera,pc.APrimary from Plugin p left jo' +
        'in Plugin_Camera pc on pc.ID_Plugin=p.ID_Plugin order by FileNam' +
        'e,ID_Camera')
    Left = 432
    Top = 304
    object StringField1: TStringField
      FieldName = 'FileName'
      Origin = 'FileName'
      Required = True
      Size = 128
    end
    object IntegerField1: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'ID_Camera'
      Origin = 'ID_Camera'
      ProviderFlags = []
      ReadOnly = True
    end
    object IntegerField2: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'APrimary'
      Origin = 'APrimary'
      ProviderFlags = []
      ReadOnly = True
    end
  end
end
