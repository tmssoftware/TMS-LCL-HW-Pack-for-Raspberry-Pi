{***************************************************************************}
{ TMS LCL HW components for Raspberry Pi                                    }
{ for Lazarus                                                               }
{                                                                           }
{ written by TMS Software                                                   }
{            copyright © 2016                                               }
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

// COMPONENT TO ACCESS 8k FRAM

unit TMSLCLAFFRAM8kSPI;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  { TTMSLCLAdaFram8KSPI }

  TTMSLCLAdaFram8KSPI = class(TTMSLCLRaspiSPI)
  public
    function GetDeviceID(var manufid, prodid:word): boolean;
    function SetStatusReg(val: byte): boolean;
    function GetStatusReg(var val: byte): boolean;
    function WriteEnable(enable: boolean): boolean;
    function WriteByte(Adr: word; val: byte): boolean;
    function ReadByte(Adr: word; var val: byte): boolean;
  end;



implementation

{ TTMSLCLAdaFram8KSPI }

function TTMSLCLAdaFram8KSPI.GetDeviceID(var manufid, prodid: word): boolean;
var
  buf: array[0..4] of byte;
begin
  buf[0] := $9F; //

  Result := ReadTransfer(addr(buf), 1, 4);

  if Result then
  begin
    manufid := buf[0];
    prodid := buf[2];
    prodid := (prodid shl 8) + buf[3];
  end;
end;

function TTMSLCLAdaFram8KSPI.SetStatusReg(val: byte): boolean;
var
  buf: array[0..1] of byte;
begin
  buf[0] := $01; //
  buf[1] := val; //

  Result := WriteTransfer(addr(buf), 2);
end;

function TTMSLCLAdaFram8KSPI.GetStatusReg(var val: byte): boolean;
var
  buf: array[0..1] of byte;
begin
  buf[0] := $05; //

  Result := ReadTransfer(addr(buf), 1, 1);

  val := buf[0];
end;

function TTMSLCLAdaFram8KSPI.WriteEnable(enable: boolean): boolean;
begin
  if enable then
    Transfer($6)
  else
    Transfer($4);
end;

function TTMSLCLAdaFram8KSPI.WriteByte(Adr: word; val: byte): boolean;
var
  xfer: spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  buf[0] := $2;
  buf[1] := adr shr 8;
  buf[2] := adr and $FF;
  buf[3] := val;

  WriteEnable(true);
  Result := WriteTransfer(addr(buf), 4);
  WriteEnable(false);
end;

function TTMSLCLAdaFram8KSPI.ReadByte(Adr: word; var val: byte): boolean;
var
  xfer: array[0..1] of spi_ioc_transfer_t;
  buf: array[0..1] of byte;
  res: integer;
begin
  buf[0] := $3;
  buf[1] := adr shr 8;
  buf[2] := adr and $FF;

  Result := ReadTransfer(addr(buf), 3, 3);

  if Result then
  begin
    val := buf[0];
  end;
end;

end.

