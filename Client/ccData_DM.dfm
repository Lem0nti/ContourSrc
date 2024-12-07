inherited DataDM: TDataDM
  OldCreateOrder = True
  OnCreate = DataModuleCreate
  Height = 354
  Width = 786
  inherited FDConnection: TFDConnection
    Left = 264
    Top = 8
  end
  inherited FDPhysPgDriverLink: TFDPhysPgDriverLink
    Left = 680
    Top = 8
  end
  inherited ADOConnection: TADOConnection
    CommandTimeout = 60
    ConnectOptions = coAsyncConnect
    Left = 664
    Top = 256
  end
  inherited QueryPG: TFDQuery
    Left = 432
    Top = 56
  end
  inherited QueryMS: TADOQuery
    Left = 592
    Top = 120
  end
  object tCameraMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    Filter = 'Deleted=0'
    Filtered = True
    TableName = 'Camera'
    Left = 40
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
    Left = 40
    Top = 200
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
  object tArchiveMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Archive'
    Left = 40
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
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Archive'
    TableName = 'Archive'
    Left = 336
    Top = 8
  end
  object tCameraPG: TFDTable
    AfterPost = tCameraPGAfterPost
    AfterDelete = tCameraPGAfterDelete
    CachedUpdates = True
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Camera'
    TableName = 'Camera'
    Left = 336
    Top = 56
  end
  object tSchedulePG: TFDTable
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Schedule'
    TableName = 'Schedule'
    Left = 336
    Top = 200
  end
  object tPluginMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Plugin'
    Left = 40
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
    UpdateOptions.UpdateTableName = 'Plugin'
    TableName = 'Plugin'
    Left = 336
    Top = 152
  end
  object tPlugin_CameraPG: TFDTable
    Connection = FDConnection
    UpdateOptions.UpdateTableName = 'Plugin_Camera'
    TableName = 'Plugin_Camera'
    Left = 336
    Top = 104
  end
  object tPlugin_CameraMS: TADOTable
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    TableName = 'Plugin_Camera'
    Left = 40
    Top = 104
    object tPlugin_CameraMSID_Plugin_Camera: TAutoIncField
      FieldName = 'ID_Plugin_Camera'
      ReadOnly = True
    end
    object tPlugin_CameraMSID_Plugin: TIntegerField
      FieldName = 'ID_Plugin'
    end
    object tPlugin_CameraMSID_Camera: TIntegerField
      FieldName = 'ID_Camera'
    end
    object tPlugin_CameraMSAPrimary: TBooleanField
      FieldName = 'APrimary'
    end
  end
  object spPluginCameraMS: TADOStoredProc
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    ProcedureName = 'spPluginCamera'
    Parameters = <
      item
        Name = 'AID_Plugin'
        DataType = ftInteger
        Value = Null
      end>
    Left = 152
    Top = 56
    object spPluginCameraMSID_Camera: TIntegerField
      FieldName = 'ID_Camera'
    end
    object spPluginCameraMSName: TStringField
      FieldName = 'Name'
      Size = 128
    end
    object spPluginCameraMSConnectionString: TStringField
      FieldName = 'ConnectionString'
      Size = 512
    end
    object spPluginCameraMSSecondary: TStringField
      FieldName = 'Secondary'
      Size = 512
    end
    object spPluginCameraMSChecked: TBooleanField
      FieldName = 'Checked'
    end
    object spPluginCameraMSAPrimary: TBooleanField
      FieldName = 'APrimary'
    end
  end
  object spPluginParam: TADOStoredProc
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    ProcedureName = 'spPluginParam'
    Parameters = <
      item
        Name = 'AID_Plugin_Camera'
        DataType = ftInteger
        Value = Null
      end>
    Left = 152
    Top = 104
    object spPluginParamID_Plugin_Param: TAutoIncField
      FieldName = 'ID_Plugin_Param'
      ReadOnly = True
    end
    object spPluginParamParam: TStringField
      FieldName = 'Param'
      Size = 64
    end
    object spPluginParamValue: TStringField
      FieldName = 'Value'
      Size = 64
    end
  end
  object spUpdatePluginCameraMS: TADOStoredProc
    ProcedureName = 'spUpdatePluginCamera'
    Parameters = <
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'AID_Plugin'
        DataType = ftInteger
        Value = Null
      end
      item
        Name = 'AConnect'
        DataType = ftBoolean
        Value = Null
      end>
    Left = 152
    Top = 152
  end
  object spPluginCameraPG: TFDQuery
    Connection = FDConnection
    Left = 432
    Top = 104
  end
  object spCameraPluginMS: TADOStoredProc
    ConnectionString = 
      'Provider=SQLNCLI10.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=Contour;Data Source=.;Initi' +
      'al File Name="";Server SPN=""'
    CursorType = ctStatic
    ProcedureName = 'spCameraPlugin'
    Parameters = <
      item
        Name = 'AID_Camera'
        DataType = ftInteger
        Value = Null
      end>
    Left = 152
    Top = 8
    object spCameraPluginMSID_Plugin: TIntegerField
      FieldName = 'ID_Plugin'
      Visible = False
    end
    object spCameraPluginMSName: TStringField
      FieldName = 'Name'
      Size = 128
    end
  end
  object spCameraPluginPG: TFDQuery
    Connection = FDConnection
    Left = 432
    Top = 8
  end
end
