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
    Left = 328
    Top = 104
  end
  inherited QueryMS: TADOQuery
    Left = 192
    Top = 272
  end
  object spInsertLogMS: TADOStoredProc
    ProcedureName = 'spInsertLog'
    Parameters = <
      item
        Name = 'AType'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASource_Type'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'AID_Source'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASTime'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AMessage'
        DataType = ftString
        Size = 512
        Value = Null
      end>
    Left = 632
    Top = 424
  end
  object tConfigPG: TFDTable
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Config'
    TableName = 'Config'
    Left = 448
    Top = 104
    object tConfigPGID_Config: TIntegerField
      FieldName = 'ID_Config'
    end
    object tConfigPGCategory: TStringField
      FieldName = 'Category'
      Size = 50
    end
    object tConfigPGName: TStringField
      FieldName = 'Name'
      Size = 50
    end
    object tConfigPGData: TStringField
      FieldName = 'Data'
      Size = 8000
    end
  end
  object tConfigMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Config'
    Left = 136
    Top = 104
    object tConfigMSID_Config: TAutoIncField
      FieldName = 'ID_Config'
      ReadOnly = True
    end
    object tConfigMSCategory: TStringField
      FieldName = 'Category'
      Size = 50
    end
    object tConfigMSName: TStringField
      FieldName = 'Name'
      Size = 50
    end
    object tConfigMSData: TMemoField
      FieldName = 'Data'
      BlobType = ftMemo
    end
  end
  object tPluginMS: TADOTable
    CursorType = ctStatic
    TableName = 'Plugin'
    Left = 136
    Top = 152
    object tPluginMSID_Plugin: TAutoIncField
      FieldName = 'ID_Plugin'
      ReadOnly = True
    end
    object tPluginMSName: TStringField
      FieldName = 'Name'
      Size = 128
    end
    object tPluginMSFileName: TStringField
      FieldName = 'FileName'
      Size = 128
    end
    object tPluginMSPictureType: TIntegerField
      FieldName = 'PictureType'
    end
  end
  object tPluginPG: TFDTable
    Connection = FDConnection
    Left = 448
    Top = 168
    object tPluginPGID_Plugin: TIntegerField
      FieldName = 'ID_Plugin'
    end
    object tPluginPGName: TStringField
      FieldName = 'Name'
      Size = 128
    end
    object tPluginPGFileName: TStringField
      FieldName = 'FileName'
      Size = 128
    end
    object tPluginPGPictureType: TIntegerField
      FieldName = 'PictureType'
    end
  end
  object qPluginPG: TFDQuery
    Connection = FDConnection
    SQL.Strings = (
      
        'select p.FileName,pc.ID_Camera,pc.APrimary from Plugin p left jo' +
        'in Plugin_Camera pc on pc.ID_Plugin=p.ID_Plugin order by FileNam' +
        'e,ID_Camera')
    Left = 552
    Top = 216
    object qPluginPGFileName: TStringField
      FieldName = 'FileName'
      Origin = 'FileName'
      Required = True
      Size = 128
    end
    object qPluginPGID_Camera: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'ID_Camera'
      Origin = 'ID_Camera'
      ProviderFlags = []
      ReadOnly = True
    end
    object qPluginPGAPrimary: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'APrimary'
      Origin = 'APrimary'
      ProviderFlags = []
      ReadOnly = True
    end
  end
  object qPluginMS: TADOQuery
    Parameters = <>
    SQL.Strings = (
      
        'select p.FileName,pc.ID_Camera,pc.APrimary from Plugin p left jo' +
        'in Plugin_Camera pc on pc.ID_Plugin=p.ID_Plugin order by FileNam' +
        'e,ID_Camera')
    Left = 192
    Top = 224
  end
end
