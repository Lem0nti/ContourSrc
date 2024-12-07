object DBConnectorDM: TDBConnectorDM
  OldCreateOrder = False
  OnDestroy = DataModuleDestroy
  Height = 251
  Width = 595
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=PG'
      'CharacterSet=WIN1251')
    LoginPrompt = False
    Left = 152
    Top = 40
  end
  object FDPhysPgDriverLink: TFDPhysPgDriverLink
    Left = 240
    Top = 104
  end
  object ADOConnection: TADOConnection
    LoginPrompt = False
    Left = 40
    Top = 96
  end
  object QueryPG: TFDQuery
    Connection = FDConnection
    Left = 72
    Top = 24
  end
  object QueryMS: TADOQuery
    Parameters = <>
    Left = 232
    Top = 8
  end
end
