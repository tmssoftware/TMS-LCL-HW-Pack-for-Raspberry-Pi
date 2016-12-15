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

// COMPONENT TO PROGRAM 128x32 OLED Display
// NOTE: REQUIRES ADMIN RIGHTS TO REPROGRAM GPIO RESET PIN

unit TMSLCLAFDISPL128x32;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  { TTMSLCLAdaDispl128x32 }

  TTMSLCLAdaDispl128x32 = class(TTMSLCLRaspiI2C)
  private
    cmdbuf: array[0..31] of byte;
    displbuf: array[0..511] of byte;
    FResetGPIO: integer;
    vccstate: integer;
  protected
    procedure Command(c: byte);
    function ResetPin(OnOff: boolean): longint;
  public
    constructor Create(AOwner: TComponent); override;
    function Open: boolean; override;
    function InitGPIO: longint; // needed to reset display
    procedure Display;
    procedure Clear;
    procedure Pattern;
    procedure DrawRect(x1,y1,x2,y2: integer);
    procedure FillRect(x1,y1,x2,y2: integer);
    procedure DrawPixel(x,y: byte);
    procedure ClearPixel(x,y: byte);
    procedure DrawChar(x,y:byte;c: char);
    procedure DrawCharLarge(x,y:byte;c: char);
    procedure DrawText(x,y:byte;s: string);
    procedure DrawTextLarge(x,y:byte;s: string);
    procedure DrawLine(x1,y1,x2,y2: integer);
    procedure DrawVertLine(x,y1,y2: integer);
    procedure DrawHorzLine(x1,x2,y: integer);
    procedure DrawArrow(x, y: byte;ADirection: TArrowDirection);
  published
    property ResetGPIO: integer read FResetGPIO write FResetGPIO;
  end;

implementation

uses
  baseunix, TMSLCLRaspiFonts;

const
  SSD1306_LCDWIDTH  = 128;
  SSD1306_LCDHEIGHT =  32;

  SSD1306_SETCONTRAST = $81;
  SSD1306_DISPLAYALLON_RESUME = $A4;
  SSD1306_DISPLAYALLON =$A5;
  SSD1306_NORMALDISPLAY =$A6;
  SSD1306_INVERTDISPLAY =$A7;
  SSD1306_DISPLAYOFF =$AE;
  SSD1306_DISPLAYON =$AF;

  SSD1306_SETDISPLAYOFFSET = $D3;
  SSD1306_SETCOMPINS =$DA;
  SSD1306_SETVCOMDETECT = $DB;

  SSD1306_SETDISPLAYCLOCKDIV = $D5;
  SSD1306_SETPRECHARGE = $D9;

  SSD1306_SETMULTIPLEX  = $A8;

  SSD1306_SETLOWCOLUMN  = $00;
  SSD1306_SETHIGHCOLUMN  = $10;

  SSD1306_SETSTARTLINE  = $40;

  SSD1306_MEMORYMODE  = $20;
  SSD1306_COLUMNADDR  = $21;
  SSD1306_PAGEADDR    = $22;

  SSD1306_COMSCANINC  = $C0;
  SSD1306_COMSCANDEC  = $C8;

  SSD1306_SEGREMAP  = $A0;
  SSD1306_CHARGEPUMP  = $8D;

  SSD1306_EXTERNALVCC  = $1;
  SSD1306_SWITCHCAPVCC  = $2;

  SSD1306_ACTIVATE_SCROLL  = $2F;
  SSD1306_DEACTIVATE_SCROLL  = $2E;
  SSD1306_SET_VERTICAL_SCROLL_AREA  = $A3;
  SSD1306_RIGHT_HORIZONTAL_SCROLL  = $26;
  SSD1306_LEFT_HORIZONTAL_SCROLL  = $27;
  SSD1306_VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL  = $29;
  SSD1306_VERTICAL_AND_LEFT_HORIZONTAL_SCROLL  = $2A;

  OLEDADDRESS = $3C;

  PIN_17: PChar = '17';
  PIN_ON: PChar = '1';
  PIN_OFF: PChar = '0';
  OUT_DIRECTION: PChar = 'out';

procedure Swap(var a,b: integer);
var
  c: integer;
begin
  c := b;
  b := a;
  a := c;
end;


{ TTMSLCLAdaDispl128x32 }

procedure TTMSLCLAdaDispl128x32.Command(c: byte);
begin
  cmdbuf[0] := $0;
  cmdbuf[1] := c;
  fpwrite(Handle, cmdbuf[0], 2);
end;

function TTMSLCLAdaDispl128x32.ResetPin(OnOff: boolean): longint;
var
  fileDesc: integer;
  Dev: shortstring;
begin

  Dev := '/sys/class/gpio/gpio'+inttostr(ResetGPIO)+'/value';

  if OnOff then
  begin
    // Swith SoC pin resetpin on:
    try
      fileDesc := fpopen(Dev, O_WrOnly);
      Result := fpwrite(fileDesc, PIN_ON[0], 1);
    finally
      Result := fpclose(fileDesc);
    end;
  end
  else
  begin
    // Switch SoC pin resetpin off:
    try
      fileDesc := fpopen(Dev, O_WrOnly);
      Result := fpwrite(fileDesc, PIN_OFF[0], 1);
    finally
      Result := fpclose(fileDesc);
    end;
  end;
end;

constructor TTMSLCLAdaDispl128x32.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  I2CAddress := OLEDADDRESS;
  FResetGPIO := 17;
  vccstate := 0;
end;

function TTMSLCLAdaDispl128x32.Open: boolean;
begin
  Result := inherited Open;

  if Result then
  begin
    ResetPin(true);
    // VDD (3.3V) goes high at start, lets just chill for a ms
    Sleep(10);
    // bring reset low
    ResetPin(false);
    // wait 10ms
    Sleep(10);
    // bring out of reset
    ResetPin(true);
    Sleep(10);

    Command(SSD1306_DISPLAYOFF);                   // 0xAE
    Command(SSD1306_SETDISPLAYCLOCKDIV);           // 0xD5
    Command($80);                                  // the suggested ratio 0x80

    Command(SSD1306_SETMULTIPLEX);                 // 0xA8
    Command($1F);
    Command(SSD1306_SETDISPLAYOFFSET);             // 0xD3
    Command($00);                                  // no offset
    Command(SSD1306_SETSTARTLINE or $00);          // line #0
    Command(SSD1306_CHARGEPUMP);                   // 0x8D

    if (vccstate = SSD1306_EXTERNALVCC) then
      Command($10)
    else
      Command($14);

    Command(SSD1306_MEMORYMODE);                   // 0x20
    Command($00);                                  // 0x0 act like ks0108
    Command(SSD1306_SEGREMAP or $01);
    Command(SSD1306_COMSCANDEC);
    Command(SSD1306_SETCOMPINS);                   // 0xDA
    Command($02);
    Command(SSD1306_SETCONTRAST);                  // 0x81
    Command($8F);
    Command(SSD1306_SETPRECHARGE);                 // 0xd9

    if (vccstate = SSD1306_EXTERNALVCC) then
      Command($22)
    else
      Command($F1);

    Command(SSD1306_SETVCOMDETECT);                 // 0xDB
    Command($40);
    Command(SSD1306_DISPLAYALLON_RESUME);           // 0xA4
    Command(SSD1306_NORMALDISPLAY);                 // 0xA6

    Command(SSD1306_DISPLAYON);
  end;
end;

function TTMSLCLAdaDispl128x32.InitGPIO: longint;
var
  fileDesc: integer;
begin
 // Prepare SoC pin 17 (pin 11 on GPIO port) for access:
 try
   fileDesc := fpopen('/sys/class/gpio/export', O_WrOnly);
   Result := fpwrite(fileDesc, PIN_17[0], 2);
 finally
   Result := fpclose(fileDesc);
 end;

 // Set SoC pin 17 as output:
 try
   fileDesc := fpopen('/sys/class/gpio/gpio17/direction', O_WrOnly);
   Result := fpwrite(fileDesc, OUT_DIRECTION[0], 3);
 finally
   Result := fpclose(fileDesc);
 end;
end;

procedure TTMSLCLAdaDispl128x32.Display;
var
  i,j,k: integer;

begin
  Command(SSD1306_COLUMNADDR);
  Command(0);   // Column start address (0 = reset)
  Command(SSD1306_LCDWIDTH-1); // Column end address (127 = reset)

  Command(SSD1306_PAGEADDR);
  Command(0); // Page start address (0 = reset)

  // #if SSD1306_LCDHEIGHT == 32
  Command(3); // Page end address

  k := 0;

  for i := 1 to 32 do
  begin
    cmdbuf[0] := $40;

    for j := 0 to 15 do
    begin
      cmdbuf[1 + j] := displbuf[k + j];
    end;

    fpwrite(Handle, cmdbuf[0], 17);

    k := k + 16;
  end;
end;

procedure TTMSLCLAdaDispl128x32.Clear;
var
   i: integer;
begin
  for i := 0 to 511 do
    displbuf[i] := 0;
end;

procedure TTMSLCLAdaDispl128x32.Pattern;
var
   i: integer;
begin
  for i := 0 to 511 do
  begin
    if odd(i) then
      displbuf[i] := $FF
    else
      displbuf[i] := $00;
  end;
end;

procedure TTMSLCLAdaDispl128x32.DrawRect(x1, y1, x2, y2: integer);
var
  i: integer;
begin
  for i := x1 to x2 do
  begin
    DrawPixel(i,y1);
    DrawPixel(i,y2);
  end;

  for i := y1 to y2 do
  begin
    DrawPixel(x1,i);
    DrawPixel(x2,i);
  end;
end;

procedure TTMSLCLAdaDispl128x32.FillRect(x1, y1, x2, y2: integer);
var
  i,j: integer;
begin
  for i := x1 to x2 do
    for j := y1 to y2 do
      DrawPixel(i,j);
end;

procedure TTMSLCLAdaDispl128x32.DrawPixel(x, y: byte);
var
  b: integer;
  p: byte;
begin
  b := x + (y div 8) * 128;
  p := 1 shl (y and $7);
  displbuf[b] := displbuf[b] or p;
end;

procedure TTMSLCLAdaDispl128x32.ClearPixel(x, y: byte);
var
  b: integer;
  p: byte;
begin
  b := x + (y div 8) * 128;
  p := 1 shl (y and $7);
  displbuf[b] := displbuf[b] and not p;
end;

procedure TTMSLCLAdaDispl128x32.DrawChar(x, y: byte; c: char);
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

procedure TTMSLCLAdaDispl128x32.DrawCharLarge(x, y: byte; c: char);
var
  i,j: integer;
  line: integer;
begin
  for  i := 0 to 23 do
  begin
    line := font_table_large[(ord(c)*48)+i*2];

    line := (line shl 8) + font_table_large[(ord(c)*48)+i*2+1];

    line := line shr 4;

    for j := 0 to 11 do
    begin
      if (line and $1 = $1) then
        DrawPixel(x+11-j, y+i);
      line := line shr 1;
    end;
  end;

end;

procedure TTMSLCLAdaDispl128x32.DrawText(x, y: byte; s: string);
var
  i: integer;
  c: char;
begin
  for i := 1 to Length(s) do
  begin
    c := s[i];
    DrawChar(x,y,c);
    x := x + 6;
  end;
end;

procedure TTMSLCLAdaDispl128x32.DrawTextLarge(x, y: byte; s: string);
var
  i: integer;
  c: char;
begin
  for i := 1 to Length(s) do
  begin
    c := s[i];
    DrawCharLarge(x,y,c);
    x := x + 12;
  end;
end;

procedure TTMSLCLAdaDispl128x32.DrawVertLine(x, y1, y2: integer);
var
  i: integer;
begin
  for i := y1 to y2 do
    DrawPixel(x,i);
end;

procedure TTMSLCLAdaDispl128x32.DrawHorzLine(x1, x2, y: integer);
var
  i: integer;
begin
  for i := x1 to x2 do
    DrawPixel(i,y);
end;

procedure TTMSLCLAdaDispl128x32.DrawLine(x1, y1, x2, y2: integer);
var
  steep: boolean;
  dx,dy,x: integer;
  err,ystep: integer;
begin
  steep := abs(y2 - y1) > abs(x2 - x1);

  if (steep) then
  begin
     Swap(x1, y1);
     Swap(x2, y2);
  end;

  if (x1 > x2) then
  begin
    Swap(x1, x2);
    Swap(y1, y2);
  end;

  dx := x2 - x1;
  dy := abs(y2 - y1);

  err := dx div 2;

  if (y1 < y2) then
    ystep := 1
  else
    ystep := -1;

  for x := x1 to x2 do
  begin
    if (steep) then
      DrawPixel(x, y1)
    else
      DrawPixel(x, y1);

    err  := err - dy;

    if (err < 0) then
    begin
      y1 := y1 + ystep;
      err := err + dx;
    end;
  end;
end;

procedure TTMSLCLAdaDispl128x32.DrawArrow(x, y: byte;
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

end.

