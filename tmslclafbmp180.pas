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

unit TMSLCLAFBMP180;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  TSamplingMode = (smLowPower,smStandard,smHighRes,smUltraHighRes);

  { TTMSLCLAdaBarTemp }

  TTMSLCLAdaBarTemp = class(TTMSLCLRaspiI2C)
  private
    ac1,ac2,ac3: smallint;
    ac4,ac5,ac6: integer;
    b1,b2: smallint;
    FSamplingMode: TSamplingMode;
    mb,mc,md: smallint;
    buf: array[0..2] of byte;
  protected
    procedure Init;
    procedure Write8b(Addr,Value: byte);
    function Read8b(Addr: byte): byte;
    function Read16b(Addr: byte): integer;
    function GetRawTemperature: integer;
    function GetRawPressure: integer;
    function SampleCoef: integer;
  public
    constructor Create(AOwner: TCOmponent); override;
    function Open: boolean; override;
    function GetTemperature: single;
    function GetPressure: single;
  published
    property SamplingMode: TSamplingMode read FSamplingMode write FSamplingMode;
  end;


implementation

uses
  baseunix, math;

const
   BMP085_ULTRALOWPOWER = 0;
   BMP085_STANDARD      = 1;
   BMP085_HIGHRES       = 2;
   BMP085_ULTRAHIGHRES  = 3;
   BMP085_CAL_AC1       = $AA;  // R   Calibration data (16 bits)
   BMP085_CAL_AC2       = $AC;  // R   Calibration data (16 bits)
   BMP085_CAL_AC3       = $AE;  // R   Calibration data (16 bits)
   BMP085_CAL_AC4       = $B0;  // R   Calibration data (16 bits)
   BMP085_CAL_AC5       = $B2;  // R   Calibration data (16 bits)
   BMP085_CAL_AC6       = $B4;  // R   Calibration data (16 bits)
   BMP085_CAL_B1        = $B6;  // R   Calibration data (16 bits)
   BMP085_CAL_B2        = $B8;  // R   Calibration data (16 bits)
   BMP085_CAL_MB        = $BA;  // R   Calibration data (16 bits)
   BMP085_CAL_MC        = $BC;  // R   Calibration data (16 bits)
   BMP085_CAL_MD        = $BE;  // R   Calibration data (16 bits)

   BMP085_CONTROL         = $F4;
   BMP085_TEMPDATA        = $F6;
   BMP085_PRESSUREDATA    = $F6;
   BMP085_READTEMPCMD     = $2E;
   BMP085_READPRESSURECMD = $34;

   BMP085_ADDRESS         = $77;


{ TTMSLCLAdaBarTemp }

procedure TTMSLCLAdaBarTemp.Init;
begin
  Write8b($E0,$B6);

  sleep(5);

  if (Read8b($D0) <> $55) then
    raise Exception.Create('Communication error');

  // read calibration data
  ac1 := Read16b(BMP085_CAL_AC1);
  ac2 := Read16b(BMP085_CAL_AC2);
  ac3 := Read16b(BMP085_CAL_AC3);
  ac4 := Read16b(BMP085_CAL_AC4);
  ac5 := Read16b(BMP085_CAL_AC5);
  ac6 := Read16b(BMP085_CAL_AC6);

  b1 := Read16b(BMP085_CAL_B1);
  b2 := Read16b(BMP085_CAL_B2);

  mb := Read16b(BMP085_CAL_MB);
  mc := Read16b(BMP085_CAL_MC);
  md := Read16b(BMP085_CAL_MD);
end;

procedure TTMSLCLAdaBarTemp.Write8b(Addr, Value: byte);
begin
  buf[0] := Addr;
  buf[1] := Value;

  fpwrite(Handle, buf, 2);
end;

function TTMSLCLAdaBarTemp.Read8b(Addr: byte): byte;
begin
  buf[0] := Addr;
  fpwrite(Handle, buf, 1);

  buf[0] := 0;
  fpread(Handle, buf, 1);
  Result := buf[0];
end;

function TTMSLCLAdaBarTemp.Read16b(Addr: byte): integer;
begin
  buf[0] := Addr;
  fpwrite(Handle, buf, 1);

  buf[0] := 0;
  buf[1] := 0;
  fpread(Handle, buf, 2);
  Result := buf[0];
  Result := (Result shl 8) or buf[1];
end;

function TTMSLCLAdaBarTemp.GetRawTemperature: integer;
begin
  Write8b(BMP085_CONTROL, BMP085_READTEMPCMD);
  Sleep(5);
  Result := Read16b(BMP085_TEMPDATA);
end;

function TTMSLCLAdaBarTemp.GetRawPressure: integer;
var
  oss: integer;
begin
  oss := SampleCoef;

  Write8b(BMP085_CONTROL, BMP085_READPRESSURECMD + (oss shl 6));
  sleep(15);

  Result := Read16b(BMP085_PRESSUREDATA);

  Result:= Result shl 8;

  Result  := (Result AND $FFFF00) OR Read8b(BMP085_PRESSUREDATA + 2);

  // oversampling
  Result  := Result shr (8 - oss);
end;

function TTMSLCLAdaBarTemp.SampleCoef: integer;
begin
  Result := BMP085_STANDARD;
  case SamplingMode of
  smLowPower: Result := BMP085_ULTRALOWPOWER;
  smStandard: Result := BMP085_STANDARD;
  smHighRes: Result := BMP085_HIGHRES;
  smUltraHighRes: Result := BMP085_ULTRAHIGHRES;
  end;
end;

constructor TTMSLCLAdaBarTemp.Create(AOwner: TCOmponent);
begin
  inherited Create(AOwner);
  I2CAddress := BMP085_ADDRESS;
  SamplingMode := smHighRes;
end;

function TTMSLCLAdaBarTemp.Open: boolean;
begin
  Result := inherited Open;
  if Result then
  begin
    Init;
  end;
end;

function TTMSLCLAdaBarTemp.GetTemperature: single;
var
  ut: integer;
  x1,x2,b5: single;
begin
  ut := GetRawTemperature;
  x1 := (ut - ac6) * ac5 / power(2,15);
  x2 := (mc * power(2,11)) / (x1 + md);
  b5  := x1 + x2;

  Result := (b5 + 8) / power(2,4) / 10;
end;

function TTMSLCLAdaBarTemp.GetPressure: single;
var
  ut,up,b3: integer;
  x1,x2,x3,b4,b5,b6,p: single;
  b7: cardinal;
  tmp,oss: integer;

begin
  oss := SampleCoef;

  ut := GetRawTemperature;
  x1 := Round((ut - ac6) * ac5 / power(2,15));
  x2 := Round((mc * power(2,11)) / (x1 + md));
  b5  := x1 + x2;

  //  Result := (b5 + 8) / power(2,4) / 10;

  b6 := b5 - 4000;
  x1 := Round((b2 * (b6 * b6 / power(2,12))) / power(2,11));
  x2 := Round(ac2 * b6 / power(2,11));
  x3 := x1 + x2;

  tmp := (ac1 shl 2) + Round(x3);
  tmp := tmp shl oss;

  b3 := (tmp + 2) shr 2;
  x1 := Round(ac3 * b6 / power(2,13));
  x2 := Round((b1 * (b6 * b6 / power(2,12))) / power(2,16));
  x3 := Round(((x1 + x2) + 2) / power(2,2));

  b4 := ac4 * (x3 + 32768) / power(2,15);

  up := GetRawPressure;

  b7 := (up - b3) * (5000 shr oss);
  if (b7 < $80000000) then
    p := (b7 * 2) / b4
  else
    p := (b7 / b4) * 2;

  x1 := (p / power(2,8)) * (p / power(2,8));
  x1 := (x1 * 3038) / power(2,16);
  x2 := (-7357 * p) / power(2,16);
  p := p + (x1 + x2 + 3791) / power(2,4);

  Result := p /10; // pressure in mBar
end;

end.

