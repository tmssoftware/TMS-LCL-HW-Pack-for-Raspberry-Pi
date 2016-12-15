{***************************************************************************}
{ TMS LCL HW components for Raspberry Pi                                    }
{ for Lazarus                                                               }
{                                                                           }
{ written by TMS Software                                                   }
{            copyright © 2015                                               }
{            Email : info@tmssoftware.com                                   }
{            Web : http://www.tmssoftware.com                               }
{                                                                           }
{ The source code is given as is. The author is not responsible             }
{ for any possible damage done due to the use of this code.                 }
{ The component can be freely used in any application. The complete         }
{ source code remains property of the author and may not be distributed,    }
{ published, given or sold in any form as such. No parts of the source      }
{ code can be included in any other component or application without        }
{ written authorization of the author.                                      }
{***************************************************************************}

// CORE I2C ACCESS

unit TMSLCLRaspiHW;

{$mode delphi}

interface


uses
  Classes, SysUtils, baseunix;

type
  TArrowDirection = (aUp,aDown,aLeft,aRight);

type
  spi_ioc_transfer_t = record  (* sizeof(spi_ioc_transfer_t) = 32 *)
    tx_buf_ptr		: qword;
    rx_buf_ptr		: qword;
    len			: longword;
    speed_hz    	: longword;
    delay_usecs		: word;
    bits_per_word	: byte;
    cs_change		: byte;
    pad			: longword;
  end;

  { TTMSLCLRaspiI2C }

  TTMSLCLRaspiI2C = class(TComponent)
  private
    FHandle: integer;
    FI2CAddress: integer;
    FI2CPort: CInt;
  protected
    property Handle: Integer read FHandle;
  public
    constructor Create(AOwner: TComponent); override;
    function Open: boolean; virtual;
    function Close: boolean; virtual;
    function Connected: boolean;

    function SetByteRegister(RegNo: Integer; Val: Byte): Integer;
    function GetByteRegister(RegNo: Integer): byte;
  published
    property I2CAddress: integer read FI2CAddress write FI2CAddress;
    property I2CPort: CInt read FI2CPort write FI2CPort;
  end;

  TSPIPortNum = (spi0, spi1);

  { TTMSLCLRaspiSPI }

  TTMSLCLRaspiSPI = class(TComponent)
  private
    FHandle: integer;
    FMode: integer;
    FBits: byte;
    FSpeed: longword;
    FDelay: word;
    FPortNum: TSPIPortNum;
    SPI_IOC_RD_MODE, SPI_IOC_WR_MODE: longword;
    SPI_IOC_WR_BITS_PER_WORD, SPI_IOC_RD_BITS_PER_WORD: longword;
    SPI_IOC_WR_MAX_SPEED_HZ, SPI_IOC_RD_MAX_SPEED_HZ: longword;
  protected
    property Handle: Integer read FHandle;
    procedure InitTransfer(var spi_struct:spi_ioc_transfer_t; rx_bufptr,tx_bufptr:pointer; xferlen:longword);
  public
    constructor Create(AOwner: TComponent); override;
    function Open: boolean; virtual;
    function Close: boolean; virtual;
    function Connected: boolean;

    function Transfer(cmd: byte): boolean;
    function ReadTransfer(buf: pointer; wsize, rsize: integer): boolean;
    function WriteTransfer(buf: pointer; wsize: integer): boolean;

    function SetByteRegister(RegNo: Integer; Val: Byte): Integer;
    function GetByteRegister(RegNo: Integer): byte;
    function Command(cmd: byte): boolean;
  published
    property PortNum: TSPIPortNum read FPortNum write FPortNum;
  end;


implementation

const
  I2C_SLAVE = 1795;
  DeviceID = '/dev/i2c-'; // i2c port

  SPI_CPHA       = $01;
  SPI_CPOL       = $02;

  SPI_MODE_0     = 0;
  SPI_MODE_1     = SPI_CPHA;
  SPI_MODE_2     = SPI_CPOL;
  SPI_MODE_3     = SPI_CPOL or SPI_CPHA;

  SPI_IOC_MAGIC  = 'k';

  SPI_BUF_SIZE_c = 64;

  _IOC_NONE   	 = $00;
  _IOC_WRITE 	 = $01;
  _IOC_READ	 = $02;
  _IOC_NRBITS    = 8;
  _IOC_TYPEBITS  = 8;
  _IOC_SIZEBITS  = 14;
  _IOC_DIRBITS   =  2;
  _IOC_NRSHIFT   =  0;
  _IOC_TYPESHIFT = (_IOC_NRSHIFT +  _IOC_NRBITS);
  _IOC_SIZESHIFT = (_IOC_TYPESHIFT +_IOC_TYPEBITS);
  _IOC_DIRSHIFT  = (_IOC_SIZESHIFT +_IOC_SIZEBITS);

  spidevice = '/dev/spidev0.';  // spi port


function InitI2cDevice(devpath: String; iDevAddr: Cint; var hInst: Integer):Integer;
var
  iio : integer;
begin
  try
    hInst := fpopen(devpath,O_RDWR);                       //Open the I2C bus in Read/Write mode
    iio := FpIOCtl(hInst, I2C_SLAVE, pointer(iDevAddr));   //Set options
    if (iio = 0) and (hInst > 0) then
      InitI2cDevice := hInst
    else
      InitI2cDevice := -1;
  except
    InitI2cDevice := -1;
  end;
end;


procedure CloseI2cDevice(hInst: Integer);
begin
  fpclose(hInst);
end;


{ TTMSLCLRaspiI2C }

constructor TTMSLCLRaspiI2C.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHandle := -1;
  FI2CPort := 1;
  FI2CAddress := 0;
end;

function TTMSLCLRaspiI2C.Open: boolean;
var
  DevName: string;
begin
  DevName := DeviceID + inttostr(I2CPort);
  Result := InitI2cDevice(DevName,I2CAddress,FHandle) <> -1;
end;

function TTMSLCLRaspiI2C.Close: boolean;
begin
  Result := false;
  if FHandle <> -1 then
  begin
    CloseI2CDevice(FHandle);
    Result := true;
    FHandle := -1;
  end;
end;

function TTMSLCLRaspiI2C.Connected: boolean;
begin
  Result := FHandle <> -1;
end;

function TTMSLCLRaspiI2C.SetByteRegister(RegNo: Integer; Val: Byte): Integer;
var
  buf: array[0..1] of byte;
begin
  try
    buf[0] := RegNo;
    buf[1] := val;
    fpwrite(FHandle, buf[0], 2);
  except
    Result := -1;
  end;
  Result := 1;
end;

function TTMSLCLRaspiI2C.GetByteRegister(RegNo: Integer): byte;
var
  buf: array[0..1] of byte;
  iRet : Byte;
begin
  try
    buf[0] := RegNo;
    iRet := 0;
    fpwrite(FHandle, buf[0], 1);
    fpread(FHandle, iRet, 1);
  except
    Result := 0;
  end;
  Result := iRet;
end;


//------------------------------------------------------------------------------
// SPI IOC commands

function  _IOC(dir:byte; typ:char; nr,size:word): longword;
begin
  _ioc := (dir      shl _IOC_DIRSHIFT)  or
          (ord(typ) shl _IOC_TYPESHIFT) or
          (nr       shl _IOC_NRSHIFT)   or
          (size     shl _IOC_SIZESHIFT);
end;

function _IO(typ:char; nr:word):longword;
begin
 _IO  := _IOC(_IOC_NONE,typ,nr,0);
end;

function _IOR(typ:char; nr,size:word):longword;
begin
 _IOR := _IOC(_IOC_Read,typ,nr,size);
end;

function _IOW(typ:char; nr,size:word):longword;
begin
  _IOW := _IOC(_IOC_Write, typ,nr,size);
end;

function _IOWR(typ:char; nr,size:word):longword;
begin
  _IOWR := _IOC((_IOC_Write or _IOC_Read),typ,nr,size);
end;

function SPI_MSGSIZE(n:byte):word;
var
  siz:word;
begin
  if n * SizeOf(spi_ioc_transfer_t) < (1 shl _IOC_SIZEBITS) then
    siz := n * SizeOf(spi_ioc_transfer_t)
  else
    siz := 0;

  SPI_MSGSIZE := siz;
end;

function  SPI_IOC_MESSAGE(n:byte):longword;
begin
  SPI_IOC_MESSAGE := _IOW(SPI_IOC_MAGIC, 0, SPI_MSGSIZE(n));
end;

//------------------------------------------------------------------------------

constructor TTMSLCLRaspiSPI.Create(AOwner: TComponent);
begin
  inherited;
  FHandle := -1;
  FPortNum := spi0;
end;

function TTMSLCLRaspiSPI.Open: boolean;
var
  ret: integer;
  spidevid: string;
begin
  SPI_IOC_RD_MODE := _IOR(SPI_IOC_MAGIC, 1, 1);
  SPI_IOC_WR_MODE := _IOW(SPI_IOC_MAGIC, 1, 1);
  SPI_IOC_WR_BITS_PER_WORD := _IOW(SPI_IOC_MAGIC, 3, 1);
  SPI_IOC_RD_BITS_PER_WORD := _IOR(SPI_IOC_MAGIC, 3, 1);
  SPI_IOC_WR_MAX_SPEED_HZ := _IOW(SPI_IOC_MAGIC, 4, 4);
  SPI_IOC_RD_MAX_SPEED_HZ := _IOR(SPI_IOC_MAGIC, 4, 4);

  case FPortNum of 
  spi0: spidevid := spidevice + '0';
  spi1: spidevid := spidevice + '1';
  end;

  fHandle := fpopen(spidevid, O_RDWR);

  if (fHandle > 0) then
  begin
    fmode := 0;
    fdelay := 5;

    ret := fpioctl(fHandle, SPI_IOC_WR_MODE, addr(fmode));

    if (ret = -1) then
      raise exception.Create('Can''t set SPI write mode');

    ret := fpioctl(fHandle, SPI_IOC_RD_MODE, addr(fmode));

    if (ret = -1) then
      raise exception.Create('Can''t get SPI read mode');

    fbits := 8;

    ret := fpioctl(fHandle, SPI_IOC_WR_BITS_PER_WORD, addr(fbits));

    if (ret = -1) then
      raise exception.Create('Can''t set SPI write bits per word');

    ret := fpioctl(fHandle, SPI_IOC_RD_BITS_PER_WORD, addr(fbits));

    if (ret = -1) then
      raise exception.Create('Can''t set SPI read bits per word');

    fspeed := 1000000;

    ret := fpioctl(fHandle, SPI_IOC_WR_MAX_SPEED_HZ, addr(fspeed));

    if (ret = -1) then
      raise exception.Create('Can''t set SPI write speed');

    ret := fpioctl(fHandle, SPI_IOC_RD_MAX_SPEED_HZ, addr(fspeed));

    if (ret = -1) then
      raise exception.Create('Can''t set SPI read speed');
  end;
end;

procedure TTMSLCLRaspiSPI.InitTransfer(var spi_struct:spi_ioc_transfer_t; rx_bufptr,tx_bufptr:pointer; xferlen:longword);
var
  xlen:longword;
begin
  xlen := xferlen;

  if xlen > SPI_BUF_SIZE_c+1 then
    xlen := SPI_BUF_SIZE_c+1;

  with spi_struct do
  begin
    {$warnings off}
    rx_buf_ptr	:= qword(rx_bufptr);
    tx_buf_ptr	:= qword(tx_bufptr);
    {$warnings on}
    len			:= xlen;
    delay_usecs		:= fdelay;
    speed_hz    	:= fspeed;
    bits_per_word	:= fbits;
    cs_change		:= 0;
    pad			:= 0;
  end;
end;


function TTMSLCLRaspiSPI.SetByteRegister(RegNo: Integer; Val: Byte): Integer;
var
  xfer: spi_ioc_transfer_t;
  buf: array[0..1] of byte;
begin
  buf[0] := (regNo and $FF) or $80;
  buf[1] := Val;

  InitTransfer(xfer, addr(buf), addr(buf), 2);

  Result := fpioctl(fHandle, SPI_IOC_MESSAGE(1), addr(xfer));
end;

function TTMSLCLRaspiSPI.GetByteRegister(RegNo: Integer): byte;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  Result := -1;

  buf[0] := (regNo and $FF);

  InitTransfer(xfer[0], addr(buf), addr(buf), 1);
  InitTransfer(xfer[1], addr(buf), addr(buf), 1);

  res := fpioctl(fHandle, SPI_IOC_MESSAGE(2), addr(xfer));

  if res >= 0 then
    Result := buf[0];
end;

function TTMSLCLRaspiSPI.Command(cmd: byte): boolean;
var
  xfer: spi_ioc_transfer_t;
  buf: array[0..1] of byte;
begin
  buf[0] := (cmd and $FF) or $80;
  buf[1] := 0;

  InitTransfer(xfer, addr(buf), addr(buf), 1);
  Result := fpioctl(fHandle, SPI_IOC_MESSAGE(0), addr(xfer)) >= 0;
end;

function TTMSLCLRaspiSPI.Close: boolean;
begin
  fpclose(fHandle);
end;

function TTMSLCLRaspiSPI.Connected: boolean;
begin
  Result := fHandle <> -1;
end;

(*
function TTMSLCLRaspiSPI.GetDeviceID(var manufid, prodid:word): boolean;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
  buf: array[0..4] of byte;
  res: integer;
begin
  Result := false;

  buf[0] := $9F; //

  InitTransfer(xfer[0], addr(buf), addr(buf), 1);
  InitTransfer(xfer[1], addr(buf), addr(buf), 4);

  res := fpioctl(fHandle, SPI_IOC_MESSAGE(2), addr(xfer));

  Result := (res >= 0);

  if Result then
  begin
    manufid := buf[0];
    prodid := buf[2];
    prodid := (prodid shl 8) + buf[3];
  end;
end;

function TTMSLCLRaspiSPI.SetStatusReg(val: byte): boolean;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  Result := false;

  buf[0] := $01; //
  buf[1] := val; //

  InitTransfer(xfer[0], addr(buf), addr(buf), 2);

  res := fpioctl(fHandle, SPI_IOC_MESSAGE(1), addr(xfer));

  Result := (res >= 0);

  if Result then
  begin
    val := buf[0];
  end;
end;

function TTMSLCLRaspiSPI.GetStatusReg(var val: byte): boolean;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  Result := false;

  buf[0] := $05; //

  InitTransfer(xfer[0], addr(buf), addr(buf), 1);
  InitTransfer(xfer[1], addr(buf), addr(buf), 1);

  res := fpioctl(fHandle, SPI_IOC_MESSAGE(2), addr(xfer));

  Result := (res >= 0);

  if Result then
  begin
    val := buf[0];
  end;
end;
*)

function TTMSLCLRaspiSPI.Transfer(cmd: byte): boolean;
var
  xfer: spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  buf[0] := cmd;
  InitTransfer(xfer, addr(buf), addr(buf), 1);
  res := fpioctl(fHandle, SPI_IOC_MESSAGE(1), addr(xfer));
  Result := res >= 0;
end;

function TTMSLCLRaspiSPI.ReadTransfer(buf: pointer; wsize, rsize: integer): boolean;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
begin
  InitTransfer(xfer[0], buf, buf, wsize);
  InitTransfer(xfer[1], buf, buf, rsize);

  Result := fpioctl(fHandle, SPI_IOC_MESSAGE(2), addr(xfer)) >= 0;
end;

function TTMSLCLRaspiSPI.WriteTransfer(buf: pointer; wsize: integer): boolean;
var
  xfer: spi_ioc_transfer_t;
begin
  InitTransfer(xfer, buf, buf, wsize);
  Result := fpioctl(fHandle, SPI_IOC_MESSAGE(1), addr(xfer)) >= 0;
end;

(*

function TTMSLCLRaspiSPI.Write(Adr: word; val: byte): boolean;
var
  xfer: spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  buf[0] := $2;
  buf[1] := adr shr 8;
  buf[2] := adr and $FF;
  buf[3] := val;
  InitTransfer(xfer, addr(buf), addr(buf), 4);
  res := fpioctl(fHandle, SPI_IOC_MESSAGE(1), addr(xfer));
  Result := res >= 0;
end;

function TTMSLCLRaspiSPI.Read(Adr: word; var val: byte): boolean;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  buf[0] := $3;
  buf[1] := adr shr 8;
  buf[2] := adr and $FF;

  InitTransfer(xfer[0], addr(buf), addr(buf), 3);
  InitTransfer(xfer[1], addr(buf), addr(buf), 3);

  res := fpioctl(fHandle, SPI_IOC_MESSAGE(2), addr(xfer));
  Result := res >= 0;

  if Result then
  begin
    val := buf[0];
  end;
end;

*)

end.

