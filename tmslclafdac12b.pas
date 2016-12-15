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

// COMPONENT TO ACCESS 12bit DAC

unit tmslclafdac12b;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  { TTMSLCLAdaDAC12B }

  TTMSLCLAdaDAC12B = class(TTMSLCLRaspiI2C)
  private
    buf: array[0..2] of byte;
  public
    constructor Create(AOwner: TCOmponent); override;
    procedure SetDac(Value: integer);
    procedure ProgDac(Value: integer);
  end;


implementation

uses
  baseunix;

const
  ADS4725_ADDRESS    = $62;

  MCP4726_CMD_WRITEDAC = $40;
  MCP4726_CMD_WRITEDACEEPROM = $60;


{ TTMSLCLAdaDAC12B }

constructor TTMSLCLAdaDAC12B.Create(AOwner: TCOmponent);
begin
  inherited Create(AOwner);
  I2CAddress := ADS4725_ADDRESS;
end;

procedure TTMSLCLAdaDAC12B.SetDac(Value: integer);
begin
  buf[0] := MCP4726_CMD_WRITEDAC;
  buf[1] := Value shr 4;
  buf[2] := (Value and $0F) shl 4;
  fpwrite(Handle, buf[0], 3);
end;

procedure TTMSLCLAdaDAC12B.ProgDac(Value: integer);
begin
  buf[0] := MCP4726_CMD_WRITEDACEEPROM;
  buf[1] := Value shr 4;
  buf[2] := (Value and $0F) shl 4;
  fpwrite(Handle, buf[0], 3);
end;

end.

