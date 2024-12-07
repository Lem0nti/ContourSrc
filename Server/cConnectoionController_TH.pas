unit cConnectoionController_TH;

interface

uses
  Classes, Windows, SyncObjs, SysUtils, DateUtils, Contnrs, cCamera_Cl, cCommon, ABL.Core.Debug,
  cAlarmer_TH, ABL.IO.IOTypes, ABL.Core.TimerThread;

type
  /// <summary>
  /// Поток для восстановления подключений к камерам.
  /// Каждые 15 секунд проверяет наличие свежих данных по камере.
  /// Если последние данные старше минуты, то вызывается подключение к камере.
  /// Совершается не более 256 попыток подключения в сутки.
  /// </summary>
  TConnectionController=class(TTimerThread)
  protected
    procedure DoExecute; override;
    procedure DoReceive(var AInputData: Pointer); override;
  public
    constructor Create; reintroduce;
  end;

var
  ConnectionController: TConnectionController;

implementation

{ TConnectionController }

constructor TConnectionController.Create;
begin
  inherited Create(nil,nil,'TConnectionController');
  FInterval:=30000;
  Enabled:=true;
  Active:=true;
end;

procedure TConnectionController.DoExecute;
var
  Camera: TCamera;
  i,FID_Camera: integer;
  FLastInput: TDateTime;
  q: string;
  AlarmPoint: PCameraTimePoint;
  tmpLTimeStamp: TTimeStamp;
  StrNum: string;
begin
  try
    StrNum:='50';
    for i := 0 to AllCameras.Count-1 do
    begin
      StrNum:='53';
      Camera:=TCamera(AllCameras[i]);
      if assigned(Camera) then
      begin
        StrNum:='57';
        FLastInput:=Camera.LastInput;
        FID_Camera:=Camera.ID_Camera;
        if (Camera.ConnectTryCount<256) then
        begin
          StrNum:='62';
          if SecondsBetween(FLastInput,now)>=45 then
          begin
            StrNum:='65';
            q:='TConnectionController.DoExecute 66: долго отсутствует сигнал по камере '+IntToStr(FID_Camera)+' - '+DateTimeToStr(FLastInput);
            SendDebugMsg(q);
            if Assigned(Alarmer) then
            begin
              StrNum:='70';
              tmpLTimeStamp := DateTimeToTimeStamp(now);
              new(AlarmPoint);
              AlarmPoint.Time:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
              AlarmPoint.ID_Camera:=FID_Camera;
              AlarmPoint.Message:=q;
              Alarmer.FInputQueue.Push(AlarmPoint);
            end;
            StrNum:='78';
            Camera.TryConnect;
          end
          else
          begin
            StrNum:='83';
            FLastInput:=Camera.LastSecondaryInput;
            if SecondsBetween(FLastInput,now)>=30 then
            begin
              StrNum:='87';
              q:='TConnectionController.DoExecute 88: долго отсутствует вторичный сигнал по камере '+IntToStr(FID_Camera)+' - '+DateTimeToStr(FLastInput);
              SendDebugMsg(q);
              if Assigned(Alarmer) then
              begin
                StrNum:='92';
                tmpLTimeStamp := DateTimeToTimeStamp(now);
                new(AlarmPoint);
                AlarmPoint.Time:=tmpLTimeStamp.Date*Int64(MSecsPerDay)+tmpLTimeStamp.Time-UnixTimeStart;
                AlarmPoint.ID_Camera:=FID_Camera;
                AlarmPoint.Message:=q;
                Alarmer.FInputQueue.Push(AlarmPoint);
              end;
              StrNum:='100';
              Camera.ReconnectSecondary;
            end
          end;
        end
        else if trunc(FLastInput)<trunc(now) then  //сутки сменились
        begin
          StrNum:='107';
          Camera.TryConnect;
        end;
      end;
    end;
  except on e: Exception do
    SendErrorMsg('TConnectionController.DoExecute 113, StrNum='+StrNum+': '+e.ClassName+' - '+e.Message);
  end;
end;

procedure TConnectionController.DoReceive(var AInputData: Pointer);
begin

end;

end.
