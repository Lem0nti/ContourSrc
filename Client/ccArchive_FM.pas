unit ccArchive_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, UITypes, DB,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ccArchiveDisk_FM, Generics.Collections, Vcl.ExtCtrls, ccData_DM, Vcl.StdCtrls;

type
  TArchiveFM = class(TForm)
    TimerArchive: TTimer;
    bSave: TButton;
    lblWarning: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerArchiveTimer(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
  private
    { Private declarations }
    FDiskList: TList<TArchiveDiskFM>;
    procedure DiskCallback(ASender: TObject);
  public
    { Public declarations }
    function ChekSave: boolean;
  end;

var
  ArchiveFM: TArchiveFM;

implementation

{$R *.dfm}

procedure TArchiveFM.bSaveClick(Sender: TObject);
var
  i: Integer;
  AName: string;
  IsActive: Boolean;
  Frame: TArchiveDiskFM;
begin
  for i:= ControlCount - 1 downto 0 do
    if Controls[i] is TArchiveDiskFM then
    begin
      Frame:=  TArchiveDiskFM(Controls[i]);
      IsActive:= Frame.cbActive.Checked;
      AName:= Frame.labDisk.Caption;
      if not Frame.IsSystem then
        DataDM.ArchiveUpdate(AName, IsActive);
    end;
  bSave.Font.Style:=[];
  lblWarning.Top:=bSave.Top+5;
  lblWarning.Show;
end;

function TArchiveFM.ChekSave: boolean;
begin
  result:=true;
  if bSave.Font.Style=[fsBold] then
    case MessageBoxEx(Handle,'Есть несохранённые данные. Сохранить?','Подтверждение перехода.',MB_YESNOCANCEL+MB_ICONQUESTION,RUSSIAN_CHARSET) of
      IDYES: bSave.Click;
      IDCANCEL: result:=false;
    end;
end;

procedure TArchiveFM.DiskCallback(ASender: TObject);
begin
  bSave.Font.Style:=[fsBold];
end;

procedure TArchiveFM.FormCreate(Sender: TObject);
var
  tmpEnable: boolean;
begin
  FDiskList:=TList<TArchiveDiskFM>.Create;
    tmpEnable:=DataDM.IsUserAdmin;
  Enabled:=tmpEnable;
  bSave.Enabled:=tmpEnable;
end;

procedure TArchiveFM.FormDestroy(Sender: TObject);
begin
  FDiskList.Free;
end;

procedure TArchiveFM.TimerArchiveTimer(Sender: TObject);
var
  lChar: Char;
  lDiskName: String;
  lFreeBytes, lFreeSize, lTotalSize: Int64;
  IsSystem, IsActive: Boolean;
  lIndex: Integer;
  i: Integer;
  lExists: Boolean;
  DiskFM: TArchiveDiskFM;
  Query: TDataSet;
begin
  TimerArchive.Enabled:= False;
  TimerARchive.Interval:=30000; // 30 секунд
{ Drive types:
  0 - DRIVE_UKNOWN
  1 - DRIVE_NO_ROOT_DIR
  2 - DRIVE_REMOVABLE (floppy disk, thumb drive, flash card reader)
  3 - DRIVE_FIXED (hard drive or flash drive)
  4 - DRIVE_REMOTE (network drive)
  5 - DRIVE_CDROM
  6 - DRIVE_RADISK

  Source: https://docs.microsoft.com/en-us/windows/desktop/api/fileapi/nf-fileapi-getdrivetypea
}
  for lChar:= 'C' to 'Z' do
  begin
    lExists:= False;
    if GetDriveType(PChar(lChar+':\'))=DRIVE_FIXED then // -> WinApi.Windows
    begin
      lDiskName:= lChar + ':';
      GetDiskFreeSpaceEx(PChar(lDiskName), lFreeBytes, lTotalSize, @lFreeSize);
      IsSystem:= (lDiskName = GetEnvironmentVariable('SYSTEMDRIVE'));
      if DataDM.Connected then
      begin
        if DataDM.DBType='PG' then
        begin
          DataDM.QueryPG.Close;
          DataDM.QueryPG.SQL.Text:= 'SELECT Active FROM Archive WHERE Path LIKE ''' + lDiskName + '%''';
          Query:=DataDM.QueryPG;
        end
        else
        begin
          DataDM.QueryMS.Close;
          DataDM.QueryMS.SQL.Text:= 'SELECT Active FROM Archive WHERE Path LIKE ''' + lDiskName + '%''';
          Query:=DataDM.QueryMS;
        end;
        Query.Open;
        IsActive:=Query.Fields[0].AsBoolean;
      end
      else
        IsActive:=false;
      for i := 0 to FDiskList.Count - 1 do
        if (FDiskList[i].labDisk.Caption = lDiskName) then
        begin
          lExists:= True;
          FDiskList[i].DiskTotalSize:= lTotalSize;
          FDiskList[i].DiskFreeSize:= lFreeBytes;
          FDiskList[i].SetDiskText;
          break;
        end;
      if not lExists then
      begin
        lIndex:= FDiskList.Count;
        DiskFM:= TArchiveDiskFM.Create(nil, DiskCallback);
        DiskFM.Parent:=Self;
        DiskFM.SetDisk(lDiskName, lTotalSize, lFreeBytes, IsActive, (IsSystem or (not DataDM.IsUserAdmin)));
        DiskFM.Show;
        DiskFM.Top:=lIndex*60;
        if not DataDM.Connected then
          DiskFM.cbActive.Enabled:=false;
        FDiskList.Add(DiskFM);
        bSave.Top:=DiskFM.Top+DiskFM.Height+16;
      end;
    end;
  end;
  bSave.Enabled:=DataDM.Connected;
  TimerArchive.Enabled:=DataDM.Connected;
end;

end.
