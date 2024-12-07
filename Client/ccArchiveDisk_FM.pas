unit ccArchiveDisk_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, System.ImageList, Vcl.ImgList, cxProgressBar, Vcl.StdCtrls, Vcl.ExtCtrls, ShellAPI;

type
  TArchiveDiskFM = class(TForm)
    imgDIsk: TImage;
    labDisk: TLabel;
    cbActive: TCheckBox;
    cxProgressBar: TcxProgressBar;
    listIcons: TImageList;
    procedure imgDIskDblClick(Sender: TObject);
    procedure cbActiveMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    PSystem: boolean;
    FDiskFreeSize: Int64;
    FCallback: TNotifyEvent;
    function GetSystemDisk: boolean;
    procedure SetDiskFreeSize(const Value: Int64);
    { Private declarations }
  public
    { Public declarations }
    DiskTotalSize: Int64;
    constructor Create(AOwner: TComponent; ACallback: TNotifyEvent) ; reintroduce;
    procedure SetDisk(AName: string; ASize, AFreeSize: int64; IsActive, IsSystem: boolean);
    procedure SetDiskText;
    property DiskFreeSize: Int64 read FDiskFreeSize write SetDiskFreeSize;
    property IsSystem: boolean read GetSystemDisk;
  end;

implementation

{$R *.dfm}

{ TArchiveDiskFM }

procedure TArchiveDiskFM.cbActiveMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FCallback) then
    FCallback(Self);
end;

constructor TArchiveDiskFM.Create(AOwner: TComponent; ACallback: TNotifyEvent);
begin
  inherited Create(AOwner);
  FCallback:= ACallback;
end;

function TArchiveDiskFM.GetSystemDisk: boolean;
begin
  result:=PSystem;
end;

procedure TArchiveDiskFM.imgDIskDblClick(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', PChar(labDisk.Caption), nil, nil, SW_NORMAL);
end;

procedure TArchiveDiskFM.SetDisk(AName: string; ASize, AFreeSize: int64; IsActive, IsSystem: boolean);
begin
  if AName <> '' then
    labDisk.Caption:= AName;
  if (ASize > 0) then
  begin
    DiskTotalSize:= ASize;
    DiskFreeSize:= AFreeSize;
    SetDiskText;
  end;
  cbActive.Checked:= IsActive;
  cbActive.Enabled:= not IsSystem; // Если диск не системный мы можем ставить его как архив
  PSystem:= IsSystem;
  listIcons.GetBitmap(Integer(PSystem), imgDisk.Picture.Bitmap);
end;

procedure TArchiveDiskFM.SetDiskFreeSize(const Value: Int64);
var
  tmpPosition: Double;
  tmpColor: TColor;
begin
  if (FDiskFreeSize <> Value) then
  begin
    FDiskFreeSize:=Value;
    tmpPosition:=cxProgressBar.Properties.Max-Round((FDiskFreeSize /DiskTotalSize)*100);
    cxProgressBar.Position:=tmpPosition;
    if tmpPosition<90 then
      tmpColor:=$0006B025
    else if tmpPosition<95 then
      tmpColor:=clYellow
    else
      tmpColor:=clRed;
    cxProgressBar.Properties.BeginColor:=tmpColor;
  end;
end;

procedure TArchiveDiskFM.SetDiskText;
var
  lDiskSize, lDiskFreeSize: int64;
begin
  lDiskSize     := Round(DiskTotalSize div (1024*1024) / 102.4);
  lDiskFreeSize := Round(FDiskFreeSize div (1024*1024) / 102.4);
  cxProgressBar.Properties.Text:= Format('Свободно %d.%d/%d.%d Гб', [(lDiskFreeSize div 10), (lDiskFreeSize mod 10), (lDiskSize div 10), (lDiskSize mod 10)]);
end;

end.
