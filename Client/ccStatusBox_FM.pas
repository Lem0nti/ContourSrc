unit ccStatusBox_FM;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.SysUtils, System.Variants,
  Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls;

type
  TStatusBoxFM = class(TForm)
    bCancel: TButton;
    ProgressBar: TProgressBar;
    lbStatus: TLabel;
    procedure bCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    Canceled: boolean;
    procedure IncProgress;
    procedure SetMax(AMax: integer);
    procedure SetProgress(AProgress: integer);
    procedure SetStatus(ACaption: TCaption);
    procedure SetStatusAndProgress(ACaption: TCaption; AProgress: Integer);
  end;

var
  StatusBoxFM: TStatusBoxFM;

implementation

{$R *.dfm}

procedure TStatusBoxFM.bCancelClick(Sender: TObject);
begin
  bCancel.Enabled:=false;
  Canceled:=true;
end;

procedure TStatusBoxFM.FormCreate(Sender: TObject);
begin
  Canceled:= false;
end;

procedure TStatusBoxFM.IncProgress;
begin
  ProgressBar.Position:=ProgressBar.Position+1;
  Application.ProcessMessages;
end;

procedure TStatusBoxFM.SetMax(AMax: Integer);
begin
  ProgressBar.Max:=AMax;
end;

procedure TStatusBoxFM.SetProgress(AProgress: Integer);
begin
  ProgressBar.Position:=AProgress;
  ProgressBar.Update;
  Application.ProcessMessages;
end;

procedure TStatusBoxFM.SetStatus(ACaption: TCaption);
begin
  lbStatus.Caption:=ACaption;
  Application.ProcessMessages;
end;

procedure TStatusBoxFM.SetStatusAndProgress(ACaption: TCaption;
  AProgress: Integer);
begin
  ProgressBar.Position:=AProgress;
  lbStatus.Caption:=ACaption;
  Application.ProcessMessages;
end;

end.
