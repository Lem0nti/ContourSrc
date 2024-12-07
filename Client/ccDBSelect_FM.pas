unit ccDBSelect_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TDBSelectFM = class(TForm)
    Button4: TButton;
    Button1: TButton;
    Panel1: TPanel;
    rbMSSQL: TRadioButton;
    rbPostgre: TRadioButton;
    leServer: TLabeledEdit;
    leDatabase: TLabeledEdit;
    leUsername: TLabeledEdit;
    lePassword: TLabeledEdit;
    procedure rbMSSQLClick(Sender: TObject);
    procedure rbPostgreClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function Execute(var AType, AServer, ADatabase, AUser, APass: string): boolean;
  end;

var
  DBSelectFM: TDBSelectFM;

implementation

{$R *.dfm}

{ TDBSelectFM }

function TDBSelectFM.Execute(var AType, AServer, ADatabase, AUser, APass: string): boolean;
begin
  rbPostgre.Checked:=AType='PG';
  leServer.Text:=AServer;
  leDatabase.Text:=ADatabase;
  leUsername.Text:=AUser;
  lePassword.Text:=APass;
  result:=ShowModal=mrOk;
  if result then
  begin
    if rbPostgre.Checked then
      AType:='PG'
    else
      AType:='MS';
    AServer:=leServer.Text;
    ADatabase:=leDatabase.Text;
    AUser:=leUsername.Text;
    APass:=lePassword.Text;
  end;
end;

procedure TDBSelectFM.rbMSSQLClick(Sender: TObject);
begin
  leServer.Text:='.';
end;

procedure TDBSelectFM.rbPostgreClick(Sender: TObject);
begin
  leServer.Text:='localhost';
end;

end.
