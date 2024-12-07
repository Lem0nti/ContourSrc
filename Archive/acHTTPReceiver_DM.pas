unit acHTTPReceiver_DM;

interface

uses
  SysUtils, System.Classes, IdBaseComponent, IdComponent, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer,
  IdContext, acData_DM, Types, DateUtils, ABL.Core.Debug, Windows, acTypes, DB;

type
  THTTPReceiverDM = class(TDataModule)
    IdHTTPServer: TIdHTTPServer;
    procedure IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    iCounterPerMSec: int64;
  public
    { Public declarations }
  end;

var
  HTTPReceiverDM: THTTPReceiverDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure THTTPReceiverDM.DataModuleCreate(Sender: TObject);
begin
  IdHTTPServer.Active:=true;
  QueryPerformanceFrequency(iCounterPerMSec);
  iCounterPerMSec:=Round(iCounterPerMSec/1000);
end;

procedure THTTPReceiverDM.IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  sl: TStringList;
  s,curParam,curValue: string;
  q,tmpDay,w: integer;
  DayPoint: int64;
  fn: TFileName;
  T1,T2: int64;
  tmpByte: Byte;
  tmpDateTime: TDateTime;
  PerfCounter: Extended;
  tArchive: TDataSet;
begin
  QueryPerformanceCounter(T1);
  AResponseInfo.CloseConnection := true;
  try
    AResponseInfo.ContentType := 'text/html';
    AResponseInfo.CharSet := 'utf-8';
    sl:=TStringList.Create;
    try
      sl.LineBreak := '&';
      sl.Text:=LowerCase(ARequestInfo.QueryParams);
      sl.LineBreak := #13#10;
      AResponseInfo.ContentText:='OK';
      for s in sl do
        if s='cameraslist' then
        begin
          AResponseInfo.ContentText:=DataDM.GetCamerasList;
          break;
        end
        else if s='dayslist' then
        begin
          AResponseInfo.ContentText:=DataDM.GetDaysList;
          break;
        end
        else
        begin
          q:=pos('=',s);
          if q>0 then
          begin
            curParam:=copy(s,1,q-1);
            curValue:=copy(s,q+1,32);
            if curParam='content' then
            begin
              q:=StrToIntDef(curValue,0);
              if q>0 then
                AResponseInfo.ContentText:=DataDM.IndexByDayAndCamera(q,StrToIntDef(sl.Values['camera'],-1));
              break;
            end
            else if curParam='video' then
            begin
              DayPoint:=StrToInt64Def(curValue,0);
              if DayPoint>0 then
              begin
                tmpByte:=StrToIntDef(sl.Values['next'],0);
                if tmpByte>2 then
                  tmpByte:=0;
                fn:=DataDM.GetFragment(DayPoint,StrToIntDef(sl.Values['camera'],-1),TNextType(tmpByte),sl.Values['primary']<>'0');
                if FileExists(fn) then
                begin
                  AResponseInfo.ContentText := '';
                  AResponseInfo.ContentType := 'video/mpeg';
                  AResponseInfo.ContentDisposition:='attachment; filename="'+ExtractFileName(fn)+'";';
                  AResponseInfo.ContentStream := TFileStream.Create(fn,fmOpenRead or fmShareDenyNone);
                end
                else
                begin
                  SendErrorMsg('THTTPReceiverDM.IdHTTPServerCommandGet 105: no video file for '+IntToStr(DayPoint));
                  AResponseInfo.ContentText := '<>no video '+sl.Values['camera']+':'+IntToStr(DayPoint);
                end;
              end;
              break;
            end
            else if curParam='slide' then
            begin
              DayPoint:=StrToInt64Def(curValue,0);
              if DayPoint>0 then
              begin
                //день
                tmpDateTime:=IncMilliSecond(UnixDateDelta,DayPoint);
                tmpDay:=(YearOf(tmpDateTime)-2000)*10000+MonthOf(tmpDateTime)*100+DayOf(tmpDateTime);
                //секунда
                q:=(DayPoint mod 86400000) div 1000;
                w:=q mod 10;
                q:=q-w;
                if w>=5 then
                  q:=q+10;
                //ближайший файл
                if DataDM.DBType='PG' then
                  tArchive:=DataDM.tArchivePG
                else
                  tArchive:=DataDM.tArchiveMS;
                tArchive.Open;
                tArchive.First;
                fn:=tArchive.FieldByName('Path').AsString+'\'+IntToStr(tmpDay)+'\'+sl.Values['camera']+'_0\'+IntToStr(q)+'.jpg';
                if FileExists(fn) then
                begin
                  AResponseInfo.ContentText := '';
                  AResponseInfo.ContentType := 'image/jpeg';
                  AResponseInfo.ContentDisposition:='attachment; filename="'+ExtractFileName(fn)+'";';
                  AResponseInfo.ContentStream := TFileStream.Create(fn,fmOpenRead or fmShareDenyNone);
                end
                else
                begin
                  SendErrorMsg('THTTPReceiverDM.IdHTTPServerCommandGet 137: no slide file '+fn);
                  AResponseInfo.ContentText := '<>no slide '+sl.Values['slide'];
                end;
              end;
              break;
            end;
          end;
        end;
    finally
      FreeAndNil(sl);
    end;
  except on e: Exception do
    begin
      AResponseInfo.ContentText:='THTTPReceiverDM.IdHTTPServerCommandGet 140: '+e.ClassName+' - '+e.Message;
      SendErrorMsg(AResponseInfo.ContentText);
    end;
  end;
  QueryPerformanceCounter(T2);
  PerfCounter:=(T2-T1)/iCounterPerMSec;
  if PerfCounter>8 then
    SendPerformanceMsg('THTTPReceiverDM.IdHTTPServerCommandGet 158: '+ARequestInfo.Document+ARequestInfo.QueryParams+' = '+FormatFloat('0.0000',PerfCounter));
end;

end.
