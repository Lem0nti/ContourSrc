unit cFrameList_Cl;

interface

uses
  Classes, ABL.IO.IOTypes;

type
  TFrameList = class(TList)
  private
    function GetSize: Cardinal;
  public
    ID_Camera: integer;
    Primary: boolean;
    Constructor Create(AID_Camera: integer; APrimary: boolean); reintroduce;
    property Size: Cardinal read GetSize;
  end;

implementation

{ TFrameList }

constructor TFrameList.Create(AID_Camera: integer; APrimary: boolean);
begin
  inherited Create;
  ID_Camera:=AID_Camera;
  Primary:=APrimary;
end;

function TFrameList.GetSize: Cardinal;
var
  q: integer;
begin
  result:=0;
  for q := 0 to Count-1 do
    result:=result+PTimedDataHeader(Items[q]).DataHeader.Size;
end;

end.
