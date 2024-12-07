unit cCommon;

interface

uses
  ABL.VS.VSTypes, Contnrs;

type
  PCameraTimePoint=^TCameraTimePoint;
  TCameraTimePoint=record
    ID_Camera: integer;
    Time: int64;
    Message: string;
  end;

  /// <summary>
  /// Содержимое команды клиента.
  /// </summary>
  /// <param name="Command: byte">
  /// Команда: 0 - подключение; 1 - отключение; 2 - запрос списка каналов.
  /// </param>
  /// <param name="Flag: byte">
  /// Параметр команды. Параметры команды для подключения: 0 - первичный; 1 - вторичный; 2 - первичный IDR; 3 - вторичный IDR.
  /// </param>
  /// <param name="Channel: Word">
  /// Номер камеры, в отношении которой должна быть применена команда.
  /// </param>
  TConnectCommand=record
    Command: byte;
    Flag: byte;
    Channel: Word;
  end;

  /// <summary>
  /// Заголовок клиентского пакета.
  /// </summary>
  /// <param name="Magic: byte">
  /// Подпись кадра, идентификатор по которому приёмник будет пониматиь что это именно кадр именно от сервера трансляции. Всегда должен быть равен 37 (х25)
  /// </param>
  /// <param name="Length: integer">
  /// Количество байт в кадре
  /// </param>
  /// <param name="TimeStamp: int64">
  /// Время кадра
  /// </param>
  TClientPacketHeader=record
    Magic: byte;
    Reserved1: byte;  //
    Reserved2: byte;  // это нужно для выравнивания без использования директив
    Reserved3: byte;  //
    Length: integer;
    TimeStamp: int64;
  end;

  TFrameHeader=record
    TimeStamp: Int64;
    Size: integer;
  end;

//  PInputFrame=^TInputFrame;
//  TInputFrame = record
//    TimeStamp: Int64;
//    Data: Pointer;
//    Size: integer;
//    FrameType: Byte;
//  end;

  PSaveCommand=^TSaveCommand;
  TSaveCommand = record
    Begin_Time,
    End_Time: int64;
    ID_Archive,
    ID_Camera: integer;
    Primary: boolean;
  end;

  PSlideFrame=^TSlideFrame;
  TSlideFrame=record
    ID_Camera: integer;
    DecodedFrame: PImageDataHeader;
  end;

  TVideoHeader=record
    Version: integer;
    FPS: word;
    FrameCount: word;
  end;

var
  AllCameras: TObjectList;

const
  CC_CONNECT      = 0;
  CC_DISCONNECT   = 1;
  CC_CHANNELLIST  = 2;

  VideoVersion    = 211226;

implementation

initialization
  AllCameras:=TObjectList.Create;
  AllCameras.OwnsObjects:=false;

finalization
  AllCameras.Free;

end.
