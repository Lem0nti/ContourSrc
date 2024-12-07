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
  /// ���������� ������� �������.
  /// </summary>
  /// <param name="Command: byte">
  /// �������: 0 - �����������; 1 - ����������; 2 - ������ ������ �������.
  /// </param>
  /// <param name="Flag: byte">
  /// �������� �������. ��������� ������� ��� �����������: 0 - ���������; 1 - ���������; 2 - ��������� IDR; 3 - ��������� IDR.
  /// </param>
  /// <param name="Channel: Word">
  /// ����� ������, � ��������� ������� ������ ���� ��������� �������.
  /// </param>
  TConnectCommand=record
    Command: byte;
    Flag: byte;
    Channel: Word;
  end;

  /// <summary>
  /// ��������� ����������� ������.
  /// </summary>
  /// <param name="Magic: byte">
  /// ������� �����, ������������� �� �������� ������� ����� ��������� ��� ��� ������ ���� ������ �� ������� ����������. ������ ������ ���� ����� 37 (�25)
  /// </param>
  /// <param name="Length: integer">
  /// ���������� ���� � �����
  /// </param>
  /// <param name="TimeStamp: int64">
  /// ����� �����
  /// </param>
  TClientPacketHeader=record
    Magic: byte;
    Reserved1: byte;  //
    Reserved2: byte;  // ��� ����� ��� ������������ ��� ������������� ��������
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
