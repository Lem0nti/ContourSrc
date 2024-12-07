inherited DataDM: TDataDM
  OldCreateOrder = True
  OnCreate = DataModuleCreate
  Height = 327
  Width = 967
  inherited FDConnection: TFDConnection
    Left = 384
    Top = 8
  end
  inherited FDPhysPgDriverLink: TFDPhysPgDriverLink
    Left = 752
    Top = 8
  end
  inherited ADOConnection: TADOConnection
    CommandTimeout = 60
    ConnectOptions = coAsyncConnect
    Left = 296
    Top = 8
  end
  inherited QueryPG: TFDQuery
    Left = 752
    Top = 112
  end
  object spCamerasListMS: TADOStoredProc
    ProcedureName = 'spCamerasList'
    Parameters = <>
    Left = 64
    Top = 56
  end
  object spDaysListMS: TADOStoredProc
    ProcedureName = 'spDaysList'
    Parameters = <>
    Left = 64
    Top = 104
  end
  object spIndexByDayAndCameraMS: TADOStoredProc
    ProcedureName = 'spIndexByDayAndCamera'
    Parameters = <
      item
        Name = 'FromDT'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ToDT'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end>
    Left = 64
    Top = 200
  end
  object spGetFragmentMS: TADOStoredProc
    ProcedureName = 'spGetFragment'
    Parameters = <
      item
        Name = 'DayPoint'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'ANext'
        DataType = ftBoolean
        Value = Null
      end
      item
        Name = 'APrimary'
        DataType = ftBoolean
        Value = Null
      end>
    Left = 64
    Top = 152
  end
  object spMotionByDayAndCameraMS: TADOStoredProc
    ProcedureName = 'spMotionByDayAndCamera'
    Parameters = <
      item
        Name = 'FromDT'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ToDT'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end>
    Left = 64
    Top = 248
  end
  object spAlarmByDayAndCameraMS: TADOStoredProc
    ProcedureName = 'spAlarmByDayAndCamera'
    Parameters = <
      item
        Name = 'FromDT'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'ToDT'
        DataType = ftLargeint
        Value = Null
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end>
    Left = 64
    Top = 8
  end
  object tArchiveMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    Filter = 'Active=1'
    Filtered = True
    TableName = 'Archive'
    Left = 168
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
  object tArchivePG: TFDTable
    Filter = 'Active=true'
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Archive'
    TableName = 'Archive'
    Left = 600
    Top = 8
  end
  object tCameraPG: TFDTable
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Camera'
    TableName = 'Camera'
    Left = 600
    Top = 56
  end
  object tCameraMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Camera'
    Left = 168
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
  object fnGetFragmentPG: TFDStoredProc
    Connection = FDConnection
    StoredProcName = 'fnGetFragment'
    Left = 496
    Top = 152
    ParamData = <
      item
        Name = 'DayPoint'
        DataType = ftLargeint
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
      end
      item
        Name = 'ANext'
        DataType = ftBoolean
      end
      item
        Name = 'APrimary'
        DataType = ftBoolean
      end>
  end
  object fnCamerasListPG: TFDStoredProc
    Connection = FDConnection
    StoredProcName = 'fnCamerasList'
    Left = 496
    Top = 56
  end
  object fnDaysListPG: TFDStoredProc
    Connection = FDConnection
    StoredProcName = 'fnDaysList'
    Left = 496
    Top = 104
  end
  object fnIndexByDayAndCameraPG: TFDStoredProc
    Connection = FDConnection
    StoredProcName = 'fnIndexByDayAndCamera'
    Left = 496
    Top = 200
    ParamData = <
      item
        Name = 'FromDT'
        DataType = ftLargeint
      end
      item
        Name = 'ToDT'
        DataType = ftLargeint
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
      end>
  end
  object fnMotionByDayAndCameraPG: TFDStoredProc
    Connection = FDConnection
    StoredProcName = 'fnMotionByDayAndCamera'
    Left = 496
    Top = 248
    ParamData = <
      item
        Name = 'FromDT'
        DataType = ftLargeint
      end
      item
        Name = 'ToDT'
        DataType = ftLargeint
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
      end>
  end
  object fnAlarmByDayAndCameraPG: TFDStoredProc
    Connection = FDConnection
    StoredProcName = 'fnAlarmByDayAndCamera'
    Left = 496
    Top = 8
    ParamData = <
      item
        Name = 'FromDT'
        DataType = ftLargeint
      end
      item
        Name = 'ToDT'
        DataType = ftLargeint
      end
      item
        Name = 'AID_Camera'
        DataType = ftInteger
      end>
  end
end
