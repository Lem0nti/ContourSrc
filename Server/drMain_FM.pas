unit drMain_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cStart_TH, Vcl.StdCtrls, cData_DM;

type
  TMainFM = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFM: TMainFM;

implementation

{$R *.dfm}

procedure TMainFM.Button1Click(Sender: TObject);
begin
  TStartTH.Create;
end;

procedure TMainFM.Button2Click(Sender: TObject);
begin
  StopAllStarted;
end;

procedure TMainFM.FormDestroy(Sender: TObject);
begin
  if assigned(DataDM) then
    StopAllStarted;
end;

end.
