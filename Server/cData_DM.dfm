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
    Left = 312
    Top = 168
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
  object spDropArchMS: TADOStoredProc
    ProcedureName = 'spDropArch'
    Parameters = <
      item
        Name = 'TimeBefore'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AID_Archive'
        DataType = ftInteger
        Value = Null
      end>
    Left = 56
    Top = 8
  end
  object spInsertAlarmMS: TADOStoredProc
    ProcedureName = 'spInsertAlarm'
    Parameters = <
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASBegin'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ASEnd'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AStartMessage'
        DataType = ftString
        Size = 512
        Value = Null
      end>
    Left = 56
    Top = 56
  end
  object spInsertMotionMS: TADOStoredProc
    ProcedureName = 'spInsertMotion'
    Parameters = <
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASBegin'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ASEnd'
        DataType = ftLargeint
        Value = Null
      end>
    Left = 56
    Top = 152
  end
  object spInsertVideoMS: TADOStoredProc
    ProcedureName = 'spInsertVideo'
    Parameters = <
      item
        Name = 'AID_Archive'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASBegin'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ASEnd'
        DataType = ftLargeint
        Value = Null
      end>
    Left = 56
    Top = 248
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
    Left = 56
    Top = 104
  end
  object tArchiveMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Archive'
    Left = 136
    Top = 8
    object tArchiveMSID_Archive: TAutoIncField
      FieldName = 'ID_Archive'
      ReadOnly = True
    end
    object tArchiveMSPath: TStringField
      FieldName = 'Path'
      Size = 512
    end
    object tArchiveMSActive: TBooleanField
      FieldName = 'Active'
    end
  end
  object tCameraMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    Filter = 'Deleted=0 and Active=1'
    Filtered = True
    TableName = 'Camera'
    Left = 136
    Top = 56
    object tCameraMSID_Camera: TAutoIncField
      FieldName = 'ID_Camera'
      ReadOnly = True
    end
    object tCameraMSConnectionString: TStringField
      FieldName = 'ConnectionString'
      Size = 512
    end
    object tCameraMSSecondary: TStringField
      FieldName = 'Secondary'
      Size = 512
    end
    object tCameraMSName: TStringField
      FieldName = 'Name'
      Size = 128
    end
    object tCameraMSActive: TBooleanField
      FieldName = 'Active'
    end
    object tCameraMSSchedule_Type: TIntegerField
      FieldName = 'Schedule_Type'
    end
    object tCameraMSDeleted: TBooleanField
      FieldName = 'Deleted'
    end
  end
  object tScheduleMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Schedule'
    Left = 136
    Top = 152
    object tScheduleMSID_Schedule: TAutoIncField
      FieldName = 'ID_Schedule'
      ReadOnly = True
    end
    object tScheduleMSID_Camera: TIntegerField
      FieldName = 'ID_Camera'
    end
    object tScheduleMSDay: TIntegerField
      FieldName = 'Day'
    end
    object tScheduleMSSBegin: TIntegerField
      FieldName = 'SBegin'
    end
    object tScheduleMSSEnd: TIntegerField
      FieldName = 'SEnd'
    end
  end
  object spInsertSecondaryVideoMS: TADOStoredProc
    ProcedureName = 'spInsertSecondaryVideo'
    Parameters = <
      item
        Name = 'AID_Archive'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ASBegin'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ASEnd'
        DataType = ftLargeint
        Value = Null
      end>
    Left = 56
    Top = 200
  end
  object tArchivePG: TFDTable
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Archive'
    TableName = 'Archive'
    Left = 448
    Top = 8
    object tArchivePGID_Archive: TIntegerField
      FieldName = 'ID_Archive'
    end
    object tArchivePGPath: TStringField
      FieldName = 'Path'
      Size = 512
    end
    object tArchivePGActive: TBooleanField
      FieldName = 'Active'
    end
  end
  object tCameraPG: TFDTable
    Filtered = True
    Filter = 'Active=true and Deleted=false'
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Camera'
    TableName = 'Camera'
    Left = 448
    Top = 56
    object tCameraPGID_Camera: TIntegerField
      FieldName = 'ID_Camera'
    end
    object tCameraPGConnectionString: TStringField
      FieldName = 'ConnectionString'
      Size = 512
    end
    object tCameraPGSecondary: TStringField
      FieldName = 'Secondary'
      Size = 512
    end
    object tCameraPGName: TStringField
      FieldName = 'Name'
      Size = 128
    end
    object tCameraPGActive: TBooleanField
      FieldName = 'Active'
    end
    object tCameraPGSchedule_Type: TIntegerField
      FieldName = 'Schedule_Type'
    end
    object tCameraPGDeleted: TBooleanField
      FieldName = 'Deleted'
    end
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
  object tSchedulePG: TFDTable
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Schedule'
    TableName = 'Schedule'
    Left = 448
    Top = 152
  end
end
