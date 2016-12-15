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

// COMPONENT TO ACCESS 4channel - 12bit ADC

unit TMSLCLAFADC12b;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  { TTMSLCLAdaADC12B }

  TTMSLCLAdaADC12B = class(TTMSLCLRaspiI2C)
  private
    buf: array[0..3] of byte;
  protected
    procedure Command(reg: byte; value: smallint);
    function ReadReg(reg: byte): smallint;
  public
    constructor Create(AOwner: TComponent); override;
    function ReadChannel(Ch: byte): integer;
  end;

implementation

uses
  baseunix;

const
  ADS1015_ADDRESS    = $48;

  ADS1015_CONVERSIONDELAY      = $1;
  ADS1115_CONVERSIONDELAY      = $8;

  // POINTER REGISTER

  ADS1015_REG_POINTER_MASK        = $03;
  ADS1015_REG_POINTER_CONVERT     = $00;
  ADS1015_REG_POINTER_CONFIG      = $01;
  ADS1015_REG_POINTER_LOWTHRESH   = $02;
  ADS1015_REG_POINTER_HITHRESH    = $03;

  // CONFIG REGISTER

  ADS1015_REG_CONFIG_OS_MASK      = $8000;
  ADS1015_REG_CONFIG_OS_SINGLE    = $8000;  // Write: Set to start a single-conversion
  ADS1015_REG_CONFIG_OS_BUSY      = $0000;  // Read: Bit = 0 when conversion is in progress
  ADS1015_REG_CONFIG_OS_NOTBUSY   = $8000;  // Read: Bit = 1 when device is not performing a conversion

  ADS1015_REG_CONFIG_MUX_MASK     = $7000;
  ADS1015_REG_CONFIG_MUX_DIFF_0_1 = $0000;  // Differential P = AIN0, N = AIN1 (default)
  ADS1015_REG_CONFIG_MUX_DIFF_0_3 = $1000;  // Differential P = AIN0, N = AIN3
  ADS1015_REG_CONFIG_MUX_DIFF_1_3 = $2000;  // Differential P = AIN1, N = AIN3
  ADS1015_REG_CONFIG_MUX_DIFF_2_3 = $3000;  // Differential P = AIN2, N = AIN3
  ADS1015_REG_CONFIG_MUX_SINGLE_0 = $4000;  // Single-ended AIN0
  ADS1015_REG_CONFIG_MUX_SINGLE_1 = $5000;  // Single-ended AIN1
  ADS1015_REG_CONFIG_MUX_SINGLE_2 = $6000;  // Single-ended AIN2
  ADS1015_REG_CONFIG_MUX_SINGLE_3 = $7000;  // Single-ended AIN3

  ADS1015_REG_CONFIG_PGA_MASK     = $0E00;
  ADS1015_REG_CONFIG_PGA_6_144V   = $0000;  // +/-6.144V range = Gain 2/3
  ADS1015_REG_CONFIG_PGA_4_096V   = $0200;  // +/-4.096V range = Gain 1
  ADS1015_REG_CONFIG_PGA_2_048V   = $0400;  // +/-2.048V range = Gain 2 (default)
  ADS1015_REG_CONFIG_PGA_1_024V   = $0600;  // +/-1.024V range = Gain 4
  ADS1015_REG_CONFIG_PGA_0_512V   = $0800;  // +/-0.512V range = Gain 8
  ADS1015_REG_CONFIG_PGA_0_256V   = $0A00;  // +/-0.256V range = Gain 16

  ADS1015_REG_CONFIG_MODE_MASK    = $0100;
  ADS1015_REG_CONFIG_MODE_CONTIN  = $0000;  // Continuous conversion mode
  ADS1015_REG_CONFIG_MODE_SINGLE  = $0100;  // Power-down single-shot mode (default)

  ADS1015_REG_CONFIG_DR_MASK      = $00E0;
  ADS1015_REG_CONFIG_DR_128SPS    = $0000;  // 128 samples per second
  ADS1015_REG_CONFIG_DR_250SPS    = $0020;  // 250 samples per second
  ADS1015_REG_CONFIG_DR_490SPS    = $0040;  // 490 samples per second
  ADS1015_REG_CONFIG_DR_920SPS    = $0060;  // 920 samples per second
  ADS1015_REG_CONFIG_DR_1600SPS   = $0080;  // 1600 samples per second (default)
  ADS1015_REG_CONFIG_DR_2400SPS   = $00A0;  // 2400 samples per second
  ADS1015_REG_CONFIG_DR_3300SPS   = $00C0;  // 3300 samples per second

  ADS1015_REG_CONFIG_CMODE_MASK   = $0010;
  ADS1015_REG_CONFIG_CMODE_TRAD   = $0000;  // Traditional comparator with hysteresis (default)
  ADS1015_REG_CONFIG_CMODE_WINDOW = $0010;  // Window comparator

  ADS1015_REG_CONFIG_CPOL_MASK    = $0008;
  ADS1015_REG_CONFIG_CPOL_ACTVLOW = $0000;  // ALERT/RDY pin is low when active (default)
  ADS1015_REG_CONFIG_CPOL_ACTVHI  = $0008;  // ALERT/RDY pin is high when active

  ADS1015_REG_CONFIG_CLAT_MASK    = $0004;  // Determines if ALERT/RDY pin latches once asserted
  ADS1015_REG_CONFIG_CLAT_NONLAT  = $0000;  // Non-latching comparator (default)
  ADS1015_REG_CONFIG_CLAT_LATCH   = $0004;  // Latching comparator

  ADS1015_REG_CONFIG_CQUE_MASK    = $0003;
  ADS1015_REG_CONFIG_CQUE_1CONV   = $0000;  // Assert ALERT/RDY after one conversions
  ADS1015_REG_CONFIG_CQUE_2CONV   = $0001;  // Assert ALERT/RDY after two conversions
  ADS1015_REG_CONFIG_CQUE_4CONV   = $0002;  // Assert ALERT/RDY after four conversions
  ADS1015_REG_CONFIG_CQUE_NONE    = $0003;  // Disable the comparator and put ALERT/RDY in high state (default)


{ TTMSLCLAdaADC12B }

constructor TTMSLCLAdaADC12B.Create(AOwner: TCOmponent);
begin
  inherited Create(AOwner);
  I2CAddress := ADS1015_ADDRESS;
end;


procedure TTMSLCLAdaADC12B.Command(reg: byte; value: smallint);
begin
  buf[0] := reg;
  buf[1] := value shr 8;
  buf[2] := value AND $FF;
  fpwrite(Handle, buf[0], 3);
end;

function TTMSLCLAdaADC12B.ReadReg(reg: byte): smallint;
begin
  Result := -1;
  buf[0] := reg;
  fpwrite(Handle, buf[0], 1);

  buf[0] := 0;
  buf[1] := 0;

  fpread(Handle,buf,2);

  Result := buf[0];
  Result := (Result shl 8) + buf[1];
end;

function TTMSLCLAdaADC12B.ReadChannel(Ch: byte): integer;
var
  cfg: integer;
begin
  cfg := ADS1015_REG_CONFIG_CQUE_NONE    or // Disable the comparator (default val)
         ADS1015_REG_CONFIG_CLAT_NONLAT  or // Non-latching (default val)
         ADS1015_REG_CONFIG_CPOL_ACTVLOW or // Alert/Rdy active low   (default val)
         ADS1015_REG_CONFIG_CMODE_TRAD   or // Traditional comparator (default val)
         ADS1015_REG_CONFIG_DR_1600SPS   or // 1600 samples per second (default)
         ADS1015_REG_CONFIG_MODE_SINGLE;    // Single-shot mode (default)

  cfg := cfg or ADS1015_REG_CONFIG_PGA_6_144V;

  case Ch of
  0: cfg := cfg or ADS1015_REG_CONFIG_MUX_SINGLE_0;
  1: cfg := cfg or ADS1015_REG_CONFIG_MUX_SINGLE_1;
  2: cfg := cfg or ADS1015_REG_CONFIG_MUX_SINGLE_2;
  3: cfg := cfg or ADS1015_REG_CONFIG_MUX_SINGLE_3;
  end;

  cfg := cfg or ADS1015_REG_CONFIG_OS_SINGLE;

  Command(ADS1015_REG_POINTER_CONFIG,cfg);
  sleep(10);

  Result := ReadReg(ADS1015_REG_POINTER_CONVERT) shr 4;
end;

end.

