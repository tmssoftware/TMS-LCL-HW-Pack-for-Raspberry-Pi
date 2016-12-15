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

// COMPONENT TO ACCESS QUAD 7seg LED

unit TMSLCLAFQ7L;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

const
  // numbers on 7seg LED
  n7seg_0 = $3F;
  n7seg_1 = $06;
  n7seg_2 = $5B;
  n7seg_3 = $4F;
  n7seg_4 = $66;
  n7seg_5 = $6D;
  n7seg_6 = $7D;
  n7seg_7 = $07;
  n7seg_8 = $7F;
  n7seg_9 = $6F;

  // extra letters possible with 7seg LED
  n7seg_space = $00;
  n7seg_t = $78;
  n7seg_f = $71;
  n7seg_b = $7c;
  n7seg_g = $3d;
  n7seg_o = $5c;
  n7seg_c = $39;
  n7seg_d = $5d;
  n7seg_e = $7b;
  n7seg_h = $74;
  n7seg_i = $04;
  n7seg_j = $0e;
  n7seg_l = $38;
  n7seg_n = $54;
  n7seg_p = $73;
  n7seg_r = $50;
  n7seg_u = $1c;


type

  { TTMSLCLAdaQuad7SegLed }

  TTMSLCLAdaQuad7SegLed = class(TTMSLCLRaspiI2C)
  private
    buf: array[0..10] of byte;
  protected
    procedure SetNumbers(a,b,c,d: byte);
  public
    constructor Create(AOwner: TCOmponent); override;
    function Open: boolean; override;
    procedure DisplayNumber(i: integer);
    procedure DisplayChars(a,b,c,d: byte);
    procedure DisplayOn;
    procedure DisplayOff;
  end;

implementation

uses
  baseunix;

{ TTMSLCLAdaQuad7SegLed }

constructor TTMSLCLAdaQuad7SegLed.Create(AOwner: TCOmponent);
begin
  inherited Create(AOwner);
  I2CAddress := $70;
end;

function TTMSLCLAdaQuad7SegLed.Open;
begin
  Result := inherited Open;
  if Result then
  begin
    buf[0] := $21;  // turn on oscillator
    fpwrite(Handle, buf[0], 1);
  end;
end;


function segval(a: byte): integer;
begin
  case a of
  0: result := n7seg_0;
  1: result := n7seg_1;
  2: result := n7seg_2;
  3: result := n7seg_3;
  4: result := n7seg_4;
  5: result := n7seg_5;
  6: result := n7seg_6;
  7: result := n7seg_7;
  8: result := n7seg_8;
  9: result := n7seg_9;
  end;
end;


procedure TTMSLCLAdaQuad7SegLed.SetNumbers(a,b,c,d: byte);
begin
  if Handle <> -1 then
  begin
    buf[0] := $0;   // set address pointer 0
    buf[1] := segval(a);
    buf[2] := $00;
    buf[3] := segval(b);
    buf[4] := $00;
    buf[5] := $00;
    buf[6] := $00;
    buf[7] := segval(c);
    buf[8] := $00;
    buf[9] := segval(d);
    buf[10] := $00;

    fpwrite(Handle, buf[0], 10);
  end;
end;

procedure TTMSLCLAdaQuad7SegLed.DisplayNumber(i: integer);
begin
  SetNumbers((i mod 10000) div 1000, (i mod 1000) div 100, (i mod 100) div 10, i mod 10);
end;

procedure TTMSLCLAdaQuad7SegLed.DisplayChars(a,b,c,d: byte);
begin
  if Handle <> -1 then
  begin
    buf[0] := $0;   // set address pointer 0
    buf[1] := a;
    buf[2] := $00;
    buf[3] := b;
    buf[4] := $00;
    buf[5] := $00;
    buf[6] := $00;
    buf[7] := c;
    buf[8] := $00;
    buf[9] := d;
    buf[10] := $00;
    fpwrite(Handle, buf[0], 10);
  end;
end;

procedure TTMSLCLAdaQuad7SegLed.DisplayOn;
begin
  if Handle <> -1 then
  begin
    buf[0] := $81;  // turn on display
    fpwrite(Handle, buf[0], 1);
  end;
end;

procedure TTMSLCLAdaQuad7SegLed.DisplayOff;
begin
  if Handle <> -1 then
  begin
    buf[0] := $80;
    fpwrite(Handle, buf[0], 1);
  end;
end;


end.

