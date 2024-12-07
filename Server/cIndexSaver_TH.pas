unit cIndexSaver_TH;

interface

uses
  ABL.Core.Debug, ABL.Core.DirectThread, cCommon, cData_DM, SysUtils;

type
  TIndexSaver = class(TDirectThread)
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  end;

var
  IndexSaver: TIndexSaver;

implementation

{ TIndexSaver }

procedure TIndexSaver.DoExecute(var AInputData, AResultData: Pointer);
var
  sc: PSaveCommand;
begin
  try
    sc:=PSaveCommand(AInputData);
    DataDM.InsertVideo(sc.ID_Archive,sc.ID_Camera,sc.Begin_Time,sc.End_Time,sc.Primary);
  except on e: Exception do
    SendErrorMsg('TIndexSaver.DoExecute 29: '+e.ClassName+ ' - '+e.Message);
  end;
end;

end.
