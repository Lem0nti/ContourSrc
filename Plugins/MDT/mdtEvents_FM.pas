unit mdtEvents_FM;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, mdtData_DM,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.ComCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, mdtCommon;

type
  TEventsFM = class(TForm)
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    DateTimePicker: TDateTimePicker;
    dsEvents: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure DateTimePickerCloseUp(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure WMScroll(var Message: TMessage); message WM_SCROLLPLUGINEVENTS;
  public
    { Public declarations }
  end;

var
  EventsFM: TEventsFM;

implementation

{$R *.dfm}

procedure TEventsFM.DateTimePickerCloseUp(Sender: TObject);
begin
  DataDM.SelectEvents(DateTimePicker.Date);
end;

procedure TEventsFM.FormCreate(Sender: TObject);
begin
  dsEvents.DataSet:=DataDM.spEvents;
  DateTimePicker.Date:=Now-1;
  DateTimePickerCloseUp(nil);
end;

procedure TEventsFM.WMScroll(var Message: TMessage);
var
  DataSet: TDataSet;
  AfterScroll: TDataSetNotifyEvent;
begin
  DataSet:=DataDM.spEvents;
  if DataSet.FieldByName('ID_Event').Value<>Message.WParam then
  begin
    AfterScroll:=DataSet.AfterScroll;
    DataSet.AfterScroll:=nil;
    DataSet.Locate('ID_Event',Message.WParam,[]);
    DataSet.AfterScroll:=AfterScroll;
  end;
end;

end.
