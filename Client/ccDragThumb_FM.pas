unit ccDragThumb_FM;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TDragThumbFM = class(TForm)
    lblCaption: TLabel;
    procedure FormHide(Sender: TObject);
  private
    { Private declarations } 
  public
    { Public declarations }
  end;

var
  DragThumbFM: TDragThumbFM;

implementation

{$R *.dfm}

procedure TDragThumbFM.FormHide(Sender: TObject);
begin
  Screen.Cursor:=crDefault;
end;

end.
