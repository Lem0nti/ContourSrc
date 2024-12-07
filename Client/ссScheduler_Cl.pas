unit ссScheduler_Cl;

interface

uses
  WinApi.Windows, cScheduleTypes, System.Classes, System.SysUtils, System.Contnrs,
  Vcl.Controls, Vcl.Graphics, ccData_DM;

type
  TChangedCallback = procedure of object;

  TScheduler = class(TCustomControl)
  private
    SurfaceBmp: Vcl.Graphics.TBitmap;
    FInUpdate: byte;
    FCells: TObjectList;
    FDragStartX, FDragStartY: Integer;
    FDragEndX, FDragEndY: Integer;
    FXOffset, FYOffset: Integer;
    FCreating: Boolean;
    FDeleting: Boolean;
    FChangedCallback: TChangedCallback;
    FActualWidth, FActualHeight: Integer;
    procedure ShMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ShMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ShMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RebuildBmp;
  protected
    procedure Paint; override;
  public
    procedure BeginUpdate;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EndUpdate;
    function GetSchedule: TWeekDay;
    procedure SetChangedCallback(ACallback: TChangedCallback);
    procedure SetSchedule(AType: Integer); overload;
    procedure SetSchedule(AType: Integer; ASchedule: TWeekDay); overload;
  published
    property Color;
  end;

  TSchedulerCell = class(TCustomControl)
  private
    FX, FY: Integer;
    FX1, FY1: Integer;
    FXOffset, FYOffset: Integer;
    FDay, FTime: Integer;
    FActive: Boolean;
  public
    procedure SetCell(AXOffset, AYOffset, ADay, ATime: integer);
    procedure SetSize(AWidth, AHeight: Integer);
    property Active: Boolean read FActive write FActive;
    property X: Integer read FX;
    property Y: Integer read FY;
    property X1: Integer read FX1;
    property Y1: Integer read FY1;
    property Day: Integer read FDay;
    property Time: Integer read FTime;
  end;

var
  Scheduler: TScheduler;

const
  DayTime: integer = 23;  // 0 - 23 (00:00 - 23:00)
  WeekDay : array[1..7] of string = ('пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс');

implementation

{ TSlider }

procedure TScheduler.BeginUpdate;
begin
  FInUpdate:=FInUpdate+1;
end;

constructor TScheduler.Create(AOwner: TComponent);
var
  i, j: integer;
  ACell: TSchedulerCell;
begin
  inherited Create(AOwner);
  DoubleBuffered:=true;
  Align:=alClient;
  SurfaceBmp:=Vcl.Graphics.TBitmap.Create;
  if DataDM.IsUserAdmin then
  begin
    OnMouseDown :=ShMouseDown;
    OnMouseMove :=ShMouseMove;
    OnMouseUp   :=ShMouseUp;
  end;
  FXOffset:= 26;
  FYOffset:= 35;
  FCells:= TObjectList.Create;
  for i := 1 to Length(WeekDay) do
    for j := 0 to DayTime do
    begin
      ACell:= TSchedulerCell.Create(Self);
      ACell.SetCell(FXOffset, FYOffset, i, j);
      ACell.Parent:= Self;
      FCells.Add(ACell);
    end;
end;

destructor TScheduler.Destroy;
begin
  //Удаляем ячейки
  while FCells.Count > 0 do
    FCells.Delete(0);
  FreeAndNil(FCells);
  FreeAndNil(SurfaceBmp);
  inherited;
end;

procedure TScheduler.EndUpdate;
begin
  if (FInUpdate > 0) then
    FInUpdate:= FInUpdate - 1;
  if (FInUpdate <= 0) then
  begin
    FInUpdate:=0;
    RebuildBmp;
  end;
end;

function TScheduler.GetSchedule: TWeekDay;
var
  i, j: Integer;
  ACell: TSchedulerCell;
  lStartDay: Boolean;
begin
  // Очищаем record
  for i := 1 to Length(Result) do
  begin
    Result[i].DayBegin:= 0;
    Result[i].DayEnd:= 0;
  end;
  for i := 1 to Length(Result) do
  begin
    lStartDay:= False;
    for j := (i - 1) * (DayTime + 1) to FCells.Count - 1 do
    begin
      ACell:= TSchedulerCell(FCells[j]);
      if ACell.Active then
      begin
        if (not lStartDay) then
        begin
          Result[ACell.Day].DayBegin := ACell.Time * 3600;
          lStartDay:= True;
        end;
        Result[ACell.Day].DayEnd:= (ACell.Time + 1) * 3600;
      end;
    end;
  end;
end;

procedure TScheduler.Paint;
var
  AWidth, AHeight: integer;
  i: Integer;
  ACell: TSchedulerCell;
begin
  if Assigned(SurfaceBmp) and (SurfaceBmp.Width > 0) then
  begin
    AWidth:= (Width - FXOffset) div (DayTime + 1);
    AHeight:= (Height - FYOffset) div Length(WeekDay);
    FActualWidth:= AWidth * (DayTime + 2);
    FActualHeight:= AHeight * (Length(WeekDay) + 1);
    Canvas.Draw(0, 0, SurfaceBmp);
    // Отрисовка дня недели
    Canvas.Font.Orientation:= 0;
    Canvas.Font.Style:= [fsBold];
    Canvas.Font.Size:= 8;
    Canvas.Brush.Style := bsClear;
    for i := 1 to Length(WeekDay) do
      Canvas.TextOut(FXOffset + (Canvas.Font.Height * 2), ((FYOffset + AHeight * i + Canvas.Font.Height * 2)),Format('%s', [WeekDay[i]]));
    // Отрисовка времени
    Canvas.Font.Orientation:= 500;
    for i := 0 to DayTime do
      Canvas.TextOut(FXOffset + (AWidth * i + Canvas.Font.Height), FYOffset + Canvas.Font.Height, Format('%.*d:00', [2, i]));
    // Отрисовка ячеек
    Canvas.Font.Orientation:= 0;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color:=clGray;
    for i := 0 to FCells.Count - 1 do
    begin
      ACell:= TSchedulerCell(FCells[i]);
      ACell.SetSize(AWidth, AHeight);
      if ACell.Active then
        Canvas.Brush.Color:=clMoneyGreen
      else
        Canvas.Brush.Color:=clSkyBlue;
      if i = 29 then
        AWidth := AWidth;
      Canvas.FillRect(Rect(ACell.X, ACell.Y, ACell.X1, ACell.Y1));
      // Границы отрисовки
      // Горизонтальная верхняя линия
      Canvas.MoveTo(ACell.X, ACell.Y);
      Canvas.LineTo(ACell.X1, ACell.Y);
      // Вертикальная верхняя линия
      Canvas.MoveTo(ACell.X, ACell.Y);
      Canvas.LineTo(ACell.X, ACell.Y1);
      // Горизонтальная нижняя линия
      if ACell.Day = Length(WeekDay) then
      begin
        Canvas.MoveTo(ACell.X, ACell.Y1);
        Canvas.LineTo(ACell.X1, ACell.Y1);
      end;
      // Вертикальная правая линия
      if ACell.Time = DayTime then
      begin
        Canvas.MoveTo(ACell.X1, ACell.Y);
        Canvas.LineTo(ACell.X1, ACell.Y1 + 1);
      end;
    end;
    // Отрисовка выделения
    if (FCreating) or (FDeleting) then
    begin
      if (FCreating) then
        Canvas.Pen.Color := clBlue;
      if (FDeleting) then
        Canvas.Pen.Color := clRed;
      Canvas.Brush.Style := bsClear;
      Canvas.Rectangle(FDragStartX, FDragStartY, FDragEndX, FDragEndY);
    end;
  end;
end;

procedure TScheduler.RebuildBmp;
begin
  if assigned(SurfaceBmp)and(FInUpdate=0) then
  begin
    SurfaceBmp.Width:=Width;
    SurfaceBmp.Height:=Height;
    SurfaceBmp.Canvas.Pen.Color:=clInactiveBorder;
    SurfaceBmp.Canvas.Brush.Color:=clInactiveBorder;
    SurfaceBmp.Canvas.FillRect(Rect(0,0,Width-1,Height-1));
    Invalidate;
  end;
end;

procedure TScheduler.SetSchedule(AType: Integer);
var
  lWeek: TWeekDay;
begin
  lWeek:= Self.GetSchedule;
  Self.SetSchedule(AType, lWeek);
end;

procedure TScheduler.SetChangedCallback(ACallback: TChangedCallback);
begin
  FChangedCallback:= ACallback;
end;

procedure TScheduler.SetSchedule(AType: Integer; ASchedule: TWeekDay);
var
  ACell: TSchedulerCell;
  i, j: integer;
  ABegin, AEnd: integer;
begin
  for i := 0 to FCells.Count - 1 do
    TSchedulerCell(FCells[i]).Active:= False;

  case AType of
    1: //рабочая неделя
      for i := 0 to FCells.Count - 1 do
      begin
        ACell:= TSchedulerCell(FCells[i]);
        if ACell.Day in [1..5] then
          if ACell.Time in [8..22] then
            ACell.Active:= True;
      end;
    2: //круглосуточно
      for i := 0 to FCells.Count - 1 do
        TSchedulerCell(FCells[i]).Active:= True;
    3:  //настроенное расписание
      for i := 1 to Length(ASchedule) do
      begin
        ABegin:= ASchedule[i].DayBegin div 60 div 60;
        AEnd:= ASchedule[i].DayEnd div 60 div 60;
        if (AEnd > 0) then // если расписание не пустое
          for j := 0 to FCells.Count - 1 do
          begin
            ACell:=TSchedulerCell(FCells[j]);
            if (ACell.Day=i) and (ABegin<=ACell.Time) and (ACell.Time<AEnd) then
              ACell.Active:=True;
          end;
      end;
    4: // По движению
    begin
      // Нельзя удалять
    end;
  else  //во всех остальных случаях - полная неделя
    for i := 0 to FCells.Count - 1 do
    begin
      ACell:= TSchedulerCell(FCells[i]);
      if ACell.Time in [8..22] then
        ACell.Active:= True;
    end;
  end;
  Invalidate;
end;

procedure TScheduler.ShMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ((ssLeft in Shift) or (ssRight in Shift)) and (X>FXOffset) and (Y>FYOffset) and (X<Width) and (Y<Height) then
  begin
    FDragStartX:= X;
    FDragStartY:= Y;
    FDragEndX:= X;
    FDragEndY:= Y;
  end;
end;

procedure TScheduler.ShMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if ((ssLeft in Shift) or (ssRight in Shift)) then
    if (X > FXOffset) and (Y > FYOffset) and (X < FActualWidth) and (Y < FActualHeight) then
    begin
      if (FDragStartX <> X) and (FDragStartY <> Y) then
      begin
        FDragEndX:= X;
        FDragEndY:= Y;
        FCreating:= (ssLeft in Shift);
        FDeleting:= (ssRight in Shift);
        Invalidate;
      end;
    end
    else
      ShMouseUp(Sender, mbLeft, Shift, X, Y);
end;

procedure TScheduler.ShMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  ACell: TSchedulerCell;
  AActive: Boolean;
  lYBack, lXBack: Integer;
  lYForw, lXForw: Integer;
  lYEnd: Integer;
  lOffset: Integer;

  procedure CheckBackward(ADay, ANumber: Integer);
  var
    i, j: Integer;
    lCell: TSchedulerCell;
  begin
    for i := ANumber - 1 downto 0 do
    begin
      lCell:= TSchedulerCell(FCells[i]);
      if (lCell.Active) then
        continue;
      for j := i downto 0 do
      begin
        lCell:= TSchedulerCell(FCells[j]);
        if lCell.Day = ACell.Day then
          lCell.Active:= False;
        if lCell.Time = 0 then
          break;
      end;
      if lCell.Time = 0 then
          break;
    end;
  end;

  procedure CheckForward(ADay, ANumber: Integer; ARemoved: Boolean = False);
  var
    i, j: Integer;
    lCell: TSchedulerCell;
  begin
    for i := ANumber + 1 to FCells.Count - 1 do
    begin
      lCell:= TSchedulerCell(FCells[i]);
      if (not ARemoved) and (lCell.Active) then
        continue;
      for j := i to FCells.Count - 1 do
      begin
        lCell:= TSchedulerCell(FCells[j]);
        if lCell.Day = ACell.Day then
          lCell.Active:= False;
        if lCell.Time = DayTime then
          break;
      end;
      if lCell.Time = 0 then
          break;
    end;
  end;

begin
  if (FCreating) or (FDeleting) then // Если было выделение
  begin
    for i := 0 to FCells.Count - 1 do
    begin
      ACell:= TSchedulerCell(FCells[i]);
      if (FDragStartX < FDragEndX) then   // Cлева направо ->
      begin
        if (FDragStartY > FDragEndY) then // Снизу вверх /\
          AActive:= (FDragStartX < ACell.X1) and (FDragEndY < ACell.Y1) and (FDragEndX > ACell.X) and (FDragStartY > ACell.Y)
        else                              // Сверху вниз \/
          AActive:= (FDragStartX < ACell.X1) and (FDragStartY < ACell.Y1) and (FDragEndX > ACell.X) and (FDragEndY > ACell.Y);
      end
      else                                // Справа налево  <-
      begin
        if (FDragStartY > FDragEndY) then // Снизу вверх /\
          AActive:= (FDragEndX < ACell.X1) and (FDragEndY < ACell.Y1) and (FDragStartX > ACell.X) and (FDragStartY > ACell.Y)
        else                              // Сверху вниз \/
          AActive:= (FDragEndX < ACell.X1) and (FDragStartY < ACell.Y1) and (FDragStartX > ACell.X) and (FDragEndY > ACell.Y);
      end;
      if AActive then
        ACell.Active:= FCreating;
    end;
    // Валидация по углам
    lYBack:= 0;
    lXBack:= 0;
    lYForw:= 0;
    lXForw:= 0;
    lYEnd:= 0;
    if ((FDragStartX < FDragEndX) and (FDragStartY < FDragEndY)) then  // > \/
    begin
      lYBack:= FDragStartY;
      lXBack:= FDragStartX;
      lYForw:= FDragStartY;
      lXForw:= FDragEndX;
      lYEnd:= FDragEndY;
    end;
    if ((FDragStartX < FDragEndX) and (FDragStartY > FDragEndY)) then  // > ^
    begin
      lYBack:= FDragEndY;
      lXBack:= FDragStartX;
      lYForw:= FDragEndY;
      lXForw:= FDragEndX;
      lYEnd:= FDragStartY;
    end;
    if ((FDragStartX > FDragEndX) and (FDragStartY > FDragEndY)) then  // < ^
    begin
      lYBack:= FDragEndY;
      lXBack:= FDragEndX;
      lYForw:= FDragEndY;
      lXForw:= FDragStartX;
      lYEnd:= FDragStartY;
    end;
    if ((FDragStartX > FDragEndX) and (FDragStartY < FDragEndY)) then // < \/
    begin
      lYBack:= FDragStartY;
      lXBack:= FDragEndX;
      lYForw:= FDragStartY;
      lXForw:= FDragStartX;
      lYEnd:= FDragEndY;
    end;
    if FCreating then
      for i := 0 to FCells.Count - 1 do
      begin
        ACell:= TSchedulerCell(FCells[i]);
        lOffset:= ((ACell.FY1 - ACell.FY) div 2);
        if lYBack <= lYEnd + lOffset then
          if (lXBack > ACell.X) and (lYBack > ACell.Y) and (lXBack < ACell.X1) and (lYBack < ACell.Y1) then
            if ACell.Time <> 0 then
            begin
              CheckBackward(ACell.Day, i);
              lYBack:=  ACell.FY1 + lOffset;
            end;
        // Направо
        if lYForw <= lYEnd + lOffset then
          if (lXForw > ACell.X) and (lYForw > ACell.Y) and (lXForw < ACell.X1) and (lYForw < ACell.Y1) then
            if ACell.Time <> DayTime then
            begin
              CheckForward(ACell.Day, i);
              lYForw:= ACell.FY1 + lOffset;
            end;
      end;
    if (FDeleting) then
      for i := 0 to FCells.Count - 1 do
      begin
        ACell:= TSchedulerCell(FCells[i]);
        lOffset:= ((ACell.FY1 - ACell.FY) div 2);
        if (lYBack<=lYEnd+lOffset)and (lXBack > ACell.X) and (lYBack > ACell.Y) and (lXBack < ACell.X1) and (lYBack < ACell.Y1) then
          if (ACell.Time<>DayTime) and (i>0) and TSchedulerCell(FCells[i-1]).Active then
          begin
            CheckForward(ACell.Day, i, True);
            lYBack:= ACell.FY1 + lOffset;
          end;
      end;
    FCreating:= False;
    FDeleting:= False;
  end
    // Просто клик
  else if (X > FXOffset) and (Y > FYOffset) and (X < Width) and (Y < Height) then
    for i := 0 to FCells.Count - 1 do
    begin
      ACell:= TSchedulerCell(FCells[i]);
      if (FDragEndX > ACell.X) and (FDragEndY > ACell.Y) and (FDragStartX < ACell.X1) and (FDragStartY < ACell.Y1) then
      begin
        ACell.Active:= not ACell.Active;
        // Проверка разрывов
        if ACell.Active then
        begin
          // Идём назад. Если ячейка первая в строке, то валидация не требуется
          if ACell.Time > 0 then
            CheckBackward(ACell.Day, i);

          // Идём вперёд. Если ячейка последняя в строке, то валидация не стребуется
          if (ACell.Time < DayTime) then
            CheckForward(ACell.Day, i);
        end
        else // Если ячейка неактивна, то идёт направо и удаляем всё лишнее
          if (ACell.Time<DayTime) and (i > 0) then
            if (TSchedulerCell(FCells[i - 1]).Active) then
              CheckForward(ACell.Day, i, True);
        break;
      end;
    end;
  FDragStartX:= 0;
  FDragStartY:= 0;
  FDragEndX:= 0;
  FDragEndY:= 0;
  FChangedCallback;
  Invalidate;
end;

{ TSheduleCell }

procedure TSchedulerCell.SetCell(AXOffset, AYOffset, ADay, ATime: integer);
begin
  FDay:= ADay;
  FTime:= ATime;
  Active:= False;
  FXOffset:= AXOffset;
  FYOffset:= AYOffset;
end;

procedure TSchedulerCell.SetSize(AWidth, AHeight: Integer);
begin
  FX  := AWidth * FTime + FXOffset;
  FY  := AHeight * (FDay - 1) + FYOffset;
  FX1 := AWidth * (FTime + 1) + FXOffset;
  FY1 := AHeight * FDay  + FYOffset;
end;

end.

