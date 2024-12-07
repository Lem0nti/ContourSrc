object HTTPReceiverDM: THTTPReceiverDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 215
  object IdHTTPServer: TIdHTTPServer
    Bindings = <>
    OnCommandGet = IdHTTPServerCommandGet
    Left = 64
    Top = 80
  end
end
