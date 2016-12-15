{***************************************************************************}
{ TMS LCL HW components for Raspberry Pi                                    }
{ for Lazarus                                                               }
{                                                                           }
{ written by TMS Software                                                   }
{            copyright © 2015 - 2016                                        }
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

// COMPONENT TO ACCESS 8x8 LED matrix

unit TMSLCLAF8x8L;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  T8x8MatrixRotation = (mr0, mr90, mr180, mr270);

  { TTMSLCLAda8x8MatrixLed }

  TTMSLCLAda8x8MatrixLed = class(TTMSLCLRaspiI2C)
  private
    buf: array[0..20] of byte;
    displaybuf: array[0..7] of byte;
    FRotation: T8x8MatrixRotation;
  public
    constructor Create(AOwner: TCOmponent); override;
    function Open: boolean; override;
    procedure DrawPixel(x,y: integer);
    procedure ClearPixel(x,y: integer);
    procedure Clear;
    procedure Fill;
    procedure Display;
    procedure DisplayOn;
    procedure DisplayOff;
    procedure DrawChar(x, y: byte; c: char);
    procedure DrawArrow(x,y: byte; ADirection: TArrowDirection);
    procedure DrawVertLine(x,y1,y2: integer);
    procedure DrawHorzLine(x1,x2,y: integer);
  published
    property Rotation: T8x8MatrixRotation read FRotation write FRotation;
  end;

implementation

uses
  baseunix, TMSLCLRaspiFonts;

{ TTMSLCLAda8x8MatrixLed }

constructor TTMSLCLAda8x8MatrixLed.Create(AOwner: TCOmponent);
begin
  inherited Create(AOwner);
  I2CAddress := $70;
  FRotation := mr0;
end;

function TTMSLCLAda8x8MatrixLed.Open: boolean;
begin
  Result := inherited Open;
  if Result then
  begin
    buf[0] := $21;  // turn on oscillator
    fpwrite(Handle, buf[0], 1);
  end;
end;

procedure TTMSLCLAda8x8MatrixLed.DrawChar(x, y: byte; c: char);
var
  i,j: integer;
  line: byte;
begin
  for  i := 0 to 5 do
  begin
    if (i = 5) then
      line := 0
    else
      line := font_table[(ord(c)*5)+i];

    for j := 0 to 7 do
    begin
      if (line and $1 = $1) then
        DrawPixel(x+i, y+j);
      line := line shr 1;
    end;
  end;
end;

procedure TTMSLCLAda8x8MatrixLed.DrawArrow(x, y: byte;
  ADirection: TArrowDirection);
begin
  case ADirection of
  aUp:
    begin
      DrawVertLine(x+2,y,y+4);
      DrawPixel(x+1,y+1);
      DrawPixel(x+3,y+1);
      DrawPixel(x,y+2);
      DrawPixel(x+4,y+2);
    end;
  aDown:
    begin
      DrawVertLine(x+2,y,y+4);
      DrawPixel(x+1,y+4);
      DrawPixel(x+3,y+4);
      DrawPixel(x,y+3);
      DrawPixel(x+4,y+3);
    end;
  aLeft:
    begin
      DrawHorzLine(x,x+4,y+2);
      DrawPixel(x+1,y+1);
      DrawPixel(x+1,y+3);
      DrawPixel(x+2,y);
      DrawPixel(x+2,y+4);
    end;
  aRight:
    begin
      DrawHorzLine(x,x+4,y+2);
      DrawPixel(x+3,y+1);
      DrawPixel(x+3,y+3);
      DrawPixel(x+2,y);
      DrawPixel(x+2,y+4);
    end;
  end;
end;

procedure TTMSLCLAda8x8MatrixLed.DrawVertLine(x, y1, y2: integer);
var
  i: integer;
begin
  for i := y1 to y2 do
    DrawPixel(x,i);
end;

procedure TTMSLCLAda8x8MatrixLed.DrawHorzLine(x1, x2, y: integer);
var
  i: integer;
begin
  for i := x1 to x2 do
    DrawPixel(i,y);
end;

procedure TTMSLCLAda8x8MatrixLed.Display;
var
  i: integer;
begin
  if Handle <> -1 then
  begin
    buf[0] := $00;   // set address pointer 0

    for i := 1 to 8 do
    begin
      buf[i * 2 - 1] := displaybuf[i - 1];
      buf[i * 2] := $00;
    end;

    fpwrite(Handle, buf[0], 16);
  end;
end;

procedure Swap(var x,y: integer);
var
  z: integer;
begin
  z := x;
  x := y;
  y := z;
end;

procedure TTMSLCLAda8x8MatrixLed.DrawPixel(x, y: integer);
begin
  if ((y < 0) or (y >= 8)) then
    Exit;
  if ((x < 0) or (x >= 8)) then
    Exit;

  case FRotation of
  mr90:
    begin
      Swap(x,y);
      x := 8 - x - 1;
    end;
  mr180:
    begin
      x := 8 - x - 1;
      y := 8 - y - 1;
    end;
  mr270:
    begin
      Swap(x,y);
      y := 8 - y - 1;
    end;
  end;

  x := x + 7;
  x := x mod 8;

  displaybuf[y] := displaybuf[y] or (1 shl x);

end;

procedure TTMSLCLAda8x8MatrixLed.ClearPixel(x, y: integer);
begin
  if ((y < 0) or (y >= 8)) then
    Exit;
  if ((x < 0) or (x >= 8)) then
    Exit;

  case FRotation of
  mr90:
    begin
      Swap(x,y);
      x := 8 - x - 1;
    end;
  mr180:
    begin
      x := 8 - x - 1;
      y := 8 - y - 1;
    end;
  mr270:
    begin
      Swap(x,y);
      y := 8 - y - 1;
    end;
  end;

  x := x + 7;
  x := x mod 8;

  displaybuf[y] := displaybuf[y] and not (1 shl x);
end;

procedure TTMSLCLAda8x8MatrixLed.Clear;
var
  i: integer;
begin
  for i := 0 to 7 do
    displaybuf[i] := 0;
end;

procedure TTMSLCLAda8x8MatrixLed.Fill;
var
  i: integer;
begin
  for i := 0 to 7 do
    displaybuf[i] := $FF;
end;

procedure TTMSLCLAda8x8MatrixLed.DisplayOn;
begin
  if Handle <> -1 then
  begin
    buf[0] := $81;  // turn on display
    fpwrite(Handle, buf[0], 1);
  end;
end;

procedure TTMSLCLAda8x8MatrixLed.DisplayOff;
begin
  if Handle <> -1 then
  begin
    buf[0] := $80;
    fpwrite(Handle, buf[0], 1);
  end;
end;


end.

