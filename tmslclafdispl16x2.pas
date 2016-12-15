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

// COMPONENT TO ACCESS 16x2 LCD screen + 5 keys

unit TMSLCLAFDISPL16x2;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW, ExtCtrls;

type

  { TTMSLCLAdaDispl16x2 }

  TTMSLCLAdaDisplayBacklight = (blOff, blRed, blYellow, blGreen, blTeal, blBlue, blViolet, blWhite);

  TTMSLCLAdaDisplayLines = (d1Line, d2Lines);

  TTMSLCLAdaDisplayCursor = (cNone, cOn, cBlink);

  TTMSLCLAdaDisplayKey = (kUp, kDown, kLeft, kRight, kSelect);

  TTMSLCLAdaDisplayKeyEvent = procedure(Sender: TObject; Key: TTMSLCLAdaDisplayKey) of object;

  TTMSLCLAdaDispl16x2 = class(TTMSLCLRaspiI2C)
  private
    backlightbits: integer;
    displayfunction: integer;
    displaycontrol: integer;
    displaymode: integer;
    FBacklight: TTMSLCLAdaDisplayBacklight;
    FOnKeyDown: TTMSLCLAdaDisplayKeyEvent;
    FOnKeyUp: TTMSLCLAdaDisplayKeyEvent;
    numlines: integer;
    FOldButtonStates: integer;
    FPollkeys: boolean;
    FDisplayCursor: TTMSLCLAdaDisplayCursor;
    FDisplayLines: TTMSLCLAdaDisplayLines;
    FTimer: TTimer;
    procedure SetBacklight(AValue: TTMSLCLAdaDisplayBacklight);
    procedure SetPollkeys(AValue: boolean);
  protected
    procedure Send(value,mode: byte);
    procedure Command(value: byte);
    procedure Write(value: byte);
    procedure Display;
    procedure burstBits8a(value: byte);
    procedure burstBits8b(value: byte);
    procedure CheckKeys(Sender: TObject);
    procedure DoClickButton(Button: integer; Down: boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Init;
    procedure Clear;
    procedure Home;
    procedure DrawText(s: string);
    procedure SetCursor(Col,Row: integer);
    procedure SetColor(R,G,B: boolean);
    procedure SetDisplayOnOff(OnOff: boolean);
    function ButtonStates: integer;
  published
    property Backlight: TTMSLCLAdaDisplayBacklight read FBacklight write SetBacklight default blWhite;
    property DisplayLines: TTMSLCLAdaDisplayLines read FDisplayLines write FDisplayLines default d2Lines;
    property DisplayCursor: TTMSLCLAdaDisplayCursor read FDisplayCursor write FDisplayCursor default cNone;
    property PollKeys: boolean read FPollkeys write SetPollkeys default false;
    property OnKeyDown: TTMSLCLAdaDisplayKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyUp: TTMSLCLAdaDisplayKeyEvent read FOnKeyUp write FOnKeyUp;

  end;

implementation

uses
  baseunix;

const
  // bit pattern for the burstBits function is
  //
  //  B7 B6 B5 B4 B3 B2 B1 B0 A7 A6 A5 A4 A3 A2 A1 A0 - MCP23017
  //  RS RW EN D4 D5 D6 D7 LB LG LR BZ B4 B3 B2 B1 B0
  //  15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
   M17_BIT_RS = $8000;
   M17_BIT_RW = $4000;
   M17_BIT_EN = $2000;
   M17_BIT_D4 = $1000;
   M17_BIT_D5 = $0800;
   M17_BIT_D6 = $0400;
   M17_BIT_D7 = $0200;
   M17_BIT_LB = $0100;
   M17_BIT_LG = $0080;
   M17_BIT_LR = $0040;
   M17_BIT_BZ = $0020;
   M17_BIT_B4 = $0010;
   M17_BIT_B3 = $0008;
   M17_BIT_B2 = $0004;
   M17_BIT_B1 = $0002;
   M17_BIT_B0 = $0001;

   // for setBacklight() with MCP23017
    OFF    = $0;
    RED    = $1;
    YELLOW = $3;
    GREEN  = $2;
    TEAL   = $6;
    BLUE   = $4;
    VIOLET = $5;
    WHITE  = $7;

   // Standard directional button bits
    BUTTON_UP     = $08;
    BUTTON_DOWN   = $04;
    BUTTON_LEFT   = $10;
    BUTTON_RIGHT  = $02;
    BUTTON_SELECT = $01;

   // readButtons() will only return these bit values
    ALL_BUTTON_BITS = (BUTTON_UP or BUTTON_DOWN or BUTTON_LEFT or BUTTON_RIGHT or BUTTON_SELECT);

    MCP23008_ADDRESS  = $20;

   // registers
    MCP23017_IODIRA   = $00;
    MCP23017_IPOLA    = $02;
    MCP23017_GPINTENA = $04;
    MCP23017_DEFVALA  = $06;
    MCP23017_INTCONA  = $08;
    MCP23017_IOCONA   = $0A;
    MCP23017_GPPUA    = $0C;
    MCP23017_INTFA    = $0E;
    MCP23017_INTCAPA  = $10;
    MCP23017_GPIOA    = $12;
    MCP23017_OLATA    = $14;

    MCP23017_IODIRB   = $01;
    MCP23017_IPOLB    = $03;
    MCP23017_GPINTENB = $05;
    MCP23017_DEFVALB  = $07;
    MCP23017_INTCONB  = $09;
    MCP23017_IOCONB   = $0B;
    MCP23017_GPPUB    = $0D;
    MCP23017_INTFB    = $0F;
    MCP23017_INTCAPB  = $11;
    MCP23017_GPIOB    = $13;
    MCP23017_OLATB    = $15;

   // commands
    LCD_CLEARDISPLAY    = $01;
    LCD_RETURNHOME      = $02;
    LCD_ENTRYMODESET    = $04;
    LCD_DISPLAYCONTROL  = $08;
    LCD_CURSORSHIFT     = $10;
    LCD_FUNCTIONSET     = $20;
    LCD_SETCGRAMADDR    = $40;
    LCD_SETDDRAMADDR    = $80;

   // flags for display entry mode
    LCD_ENTRYRIGHT           = $00;
    LCD_ENTRYLEFT            = $02;
    LCD_ENTRYSHIFTINCREMENT  = $01;
    LCD_ENTRYSHIFTDECREMENT  = $00;

   // flags for display on/off control
    LCD_BLINKON     = $01;
    LCD_BLINKOFF    = $00;
    LCD_CURSORON    = $02;
    LCD_CURSOROFF   = $00;
    LCD_DISPLAYON   = $04;
    LCD_DISPLAYOFF  = $00;
    LCD_BACKLIGHT   = $08;

   // flags for display/cursor shift
    LCD_DISPLAYMOVE  = $08;
    LCD_CURSORMOVE   = $00;
    LCD_MOVERIGHT    = $04;
    LCD_MOVELEFT     = $00;

   // flags for function set
   //we only support 4-bit mode  LCD_8BITMODE  = $10
    LCD_4BITMODE  = $00;
    LCD_2LINE     = $08;
    LCD_1LINE     = $00;
    LCD_5x10DOTS  = $04;
    LCD_5x8DOTS   = $00;

{ TTMSLCLAdaDispl16x2 }

procedure TTMSLCLAdaDispl16x2.SetPollkeys(AValue: boolean);
begin
  if (FPollkeys <> AValue) then
  begin
    FPollkeys := AValue;
    FTimer.Interval := 100;
    FTimer.Enabled := FPollKeys;
    FTimer.OnTimer := CheckKeys;
  end;
end;

procedure TTMSLCLAdaDispl16x2.SetBacklight(AValue: TTMSLCLAdaDisplayBacklight);
begin
  if (FBacklight <> AValue) then
  begin
    FBacklight := AValue;

    case FBacklight of
    blOff: SetColor(false,false,false);
    blRed: SetColor(true, false, false);
    blYellow: SetColor(true, true, false);
    blGreen: SetColor(false, true, false);
    blTeal: SetColor(false, true, true);
    blBlue: SetColor(false,false, true);
    blViolet: SetColor(true, false, true);
    blWhite: SetColor(true, true, true);
    end;
  end;
end;

procedure TTMSLCLAdaDispl16x2.Send(value, mode: byte);
var
  bbuf: byte;
begin
  // BURST SPEED, OH MY GOD
  // the (now High Speed!) I/O expander pinout
  //  B7 B6 B5 B4 B3 B2 B1 B0 A7 A6 A5 A4 A3 A2 A1 A0 - MCP23017
  //  15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
  //  RS RW EN D4 D5 D6 D7 B  G  R     B4 B3 B2 B1 B0

  // n.b. RW bit stays LOW to write
  bbuf := backlightBits shr 8;

  // send high 4 bits
  if ((value AND $10) = $10) then bbuf := bbuf or (M17_BIT_D4 shr 8);
  if ((value AND $20) = $20) then bbuf := bbuf or (M17_BIT_D5 shr 8);
  if ((value AND $40) = $40) then bbuf := bbuf or (M17_BIT_D6 shr 8);
  if ((value AND $80) = $80) then bbuf := bbuf or (M17_BIT_D7 shr 8);

  if (mode = 1) then
    bbuf := bbuf or ((M17_BIT_RS or M17_BIT_EN) shr 8) // RS+EN
  else
    bbuf := bbuf or (M17_BIT_EN shr 8); // EN

  burstBits8b(bbuf);

  // resend w/ EN turned off
  bbuf := bbuf AND NOT (M17_BIT_EN shr 8);

  burstBits8b(bbuf);

  // send low 4 bits
  bbuf := backlightBits shr 8;
  // send high 4 bits
  if ((value AND $1) = $1) then bbuf := bbuf or (M17_BIT_D4 shr 8);
  if ((value AND $2) = $2) then bbuf := bbuf or (M17_BIT_D5 shr 8);
  if ((value AND $4) = $4) then bbuf := bbuf or (M17_BIT_D6 shr 8);
  if ((value AND $8) = $8) then bbuf := bbuf or (M17_BIT_D7 shr 8);

  if (mode = 1) then
    bbuf := bbuf or ((M17_BIT_RS or M17_BIT_EN) shr 8) // RS+EN
  else
    bbuf := bbuf or (M17_BIT_EN shr 8); // EN

  burstBits8b(bbuf);

  // resend w/ EN turned off
  bbuf := bbuf AND NOT (M17_BIT_EN shr 8);
  burstBits8b(bbuf);
end;

procedure TTMSLCLAdaDispl16x2.Command(value: byte);
begin
  Send(value,0);
end;

procedure TTMSLCLAdaDispl16x2.Write(value: byte);
begin
  Send(value,1);
end;

procedure TTMSLCLAdaDispl16x2.Display;
begin
  Command(LCD_DISPLAYCONTROL or displaycontrol);
end;

procedure TTMSLCLAdaDispl16x2.Clear;
begin
  command(LCD_CLEARDISPLAY);  // clear display, set cursor position to zero
  sleep(2);
end;

procedure TTMSLCLAdaDispl16x2.Home;
begin
  Command(LCD_RETURNHOME);  // set cursor position to zero
  sleep(2);
end;

constructor TTMSLCLAdaDispl16x2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  I2CAddress := $20;
  FDisplayLines := d2Lines;
  FDisplayCursor := cNone;
  FOldButtonStates := $1F; // buttons not pressed
  FTimer := TTimer.Create(Self);
  FBacklight := blWhite;
end;

destructor TTMSLCLAdaDispl16x2.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TTMSLCLAdaDispl16x2.burstBits8a(value: byte);
begin
  // we use this to burst bits to the GPIO chip whenever we need to. avoids repetitive code.
  SetByteRegister(MCP23017_GPIOA, value);
end;

procedure TTMSLCLAdaDispl16x2.burstBits8b(value: byte);
begin
  // we use this to burst bits to the GPIO chip whenever we need to. avoids repetitive code.
  SetByteRegister(MCP23017_GPIOB, value);
end;

procedure TTMSLCLAdaDispl16x2.CheckKeys(Sender: TObject);
var
  newstates: integer;
begin
  newstates := ButtonStates;

  if (newstates <> FOldButtonStates) then
  begin
    if (newstates and BUTTON_UP <> FOldButtonStates and BUTTON_UP) then
      DoClickButton(BUTTON_UP, newstates and BUTTON_UP = 0);

    if (newstates and BUTTON_DOWN <> FOldButtonStates and BUTTON_DOWN) then
      DoClickButton(BUTTON_DOWN, newstates and BUTTON_DOWN = 0);

    if (newstates and BUTTON_LEFT <> FOldButtonStates and BUTTON_LEFT) then
      DoClickButton(BUTTON_LEFT, newstates and BUTTON_LEFT = 0);

    if (newstates and BUTTON_RIGHT <> FOldButtonStates and BUTTON_RIGHT) then
      DoClickButton(BUTTON_RIGHT, newstates and BUTTON_RIGHT = 0);

    if (newstates and BUTTON_SELECT <> FOldButtonStates and BUTTON_SELECT) then
      DoClickButton(BUTTON_SELECT, newstates and BUTTON_SELECT = 0);

    FOldButtonStates := newstates;
  end;

end;

procedure TTMSLCLAdaDispl16x2.DoClickButton(Button: integer; Down: boolean);
var
  btn: TTMSLCLAdaDisplayKey;
begin
  if Button = BUTTON_UP then
    btn := kUp;
  if Button = BUTTON_DOWN then
    btn := kDown;
  if Button = BUTTON_LEFT then
    btn := kLeft;
  if Button = BUTTON_RIGHT then
    btn := kRight;
  if Button = BUTTON_SELECT then
    btn := kSelect;

  if Down then
  begin
    if Assigned(OnKeyDown) then
      OnKeyDown(Self, btn);
  end
  else
  begin
    if Assigned(OnKeyUp) then
      OnKeyUp(Self, btn);
  end;
end;


procedure TTMSLCLAdaDispl16x2.Init;
var
  i: integer;
begin
  backlightbits := 0;

//  backlightbits := M17_BIT_LB or M17_BIT_LR or M17_BIT_LG or M17_BIT_BZ;

  displayfunction := LCD_4BITMODE or LCD_2LINE or LCD_5x8DOTS;

  if DisplayLines = d2Lines then
  begin
    displayfunction := displayfunction or LCD_2LINE;
    numlines := 2;
  end
  else
  begin
    displayfunction := displayfunction or LCD_1LINE;
    numlines := 1;
  end;

  // all inputs on port A
  SetByteRegister(MCP23017_IODIRA, $FF);

  // all inputs on port B
  SetByteRegister(MCP23017_IODIRB, $FF);

  // buttons input, all others output
  SetByteRegister(MCP23017_IODIRA, $1F);

  // set the button pullups
  SetByteRegister(MCP23017_GPPUA, $1F);

  // all pins output
  SetByteRegister(MCP23017_IODIRB, $0);

  // put the LCD into 4 bit mode
  // start with a non-standard command to make it realize we're speaking 4-bit here
  // per LCD datasheet, first command is a single 4-bit burst, 0011.

  // bit pattern for the burstBits function is
  //
  //  B7 B6 B5 B4 B3 B2 B1 B0 A7 A6 A5 A4 A3 A2 A1 A0 - MCP23017
  //  15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
  //  RS RW EN D4 D5 D6 D7 B  G  R     B4 B3 B2 B1 B0

  for i := 0 to 3 do
  begin
    burstBits8b((M17_BIT_EN or M17_BIT_D5 or M17_BIT_D4) shr 8);
    burstBits8b((M17_BIT_D5 or M17_BIT_D4) shr 8);
  end;

  burstBits8b((M17_BIT_EN or M17_BIT_D5) shr 8);
  burstBits8b(M17_BIT_D5 shr 8);

  sleep(5);

  Command(LCD_FUNCTIONSET or displayfunction);
  sleep(5);

  Command(LCD_FUNCTIONSET or displayfunction);
  sleep(5);

  // turn on the LCD with our defaults
  displaycontrol := (LCD_DISPLAYON or LCD_BACKLIGHT);

  if DisplayCursor = cOn then
    displaycontrol := displaycontrol or LCD_CURSORON;

  if DisplayCursor = cBlink then
    displaycontrol := displaycontrol or LCD_CURSORON or LCD_BLINKON;

  Display;

  // clear it off
  Clear;

  Displaymode := LCD_ENTRYLEFT or LCD_ENTRYSHIFTDECREMENT;
  // set the entry mode
  Command(LCD_ENTRYMODESET or displaymode);

end;

procedure TTMSLCLAdaDispl16x2.SetCursor(Col, Row: integer);
var
  row_offsets: array[0..3] of byte = ( $0, $40, $14, $54);
begin
  if ( row > numlines ) then
    row := numlines - 1;    // we count rows starting w/0

  command(LCD_SETDDRAMADDR or (col + row_offsets[row]));
end;

procedure TTMSLCLAdaDispl16x2.SetColor(R, G, B: boolean);
var
  clrA: byte;
  clrB: byte;
begin
  clrA := 0;
  clrB := 0;

  if not R then
    clrA := clrA or M17_BIT_LR;

  if not G then
    clrA := clrA or M17_BIT_LG;

  if not B then
    clrB := clrB or (M17_BIT_LB shr 8);

  SetByteRegister(MCP23017_GPIOA, clrA);

  SetByteRegister(MCP23017_GPIOB, clrB);
end;

procedure TTMSLCLAdaDispl16x2.SetDisplayOnOff(OnOff: boolean);
begin
  if OnOff then
    displaycontrol := displaycontrol OR LCD_DISPLAYON
  else
    displaycontrol := displaycontrol AND NOT LCD_DISPLAYON;

  Display;
end;

function TTMSLCLAdaDispl16x2.ButtonStates: integer;
var
  buf: array[0..2] of byte;
begin
  buf[0] := MCP23017_GPIOA;

  fpwrite(Handle, buf, 1);

  buf[0] := 0;

  fpread(Handle, buf, 1);

  Result := buf[0] AND ALL_BUTTON_BITS;

end;

procedure TTMSLCLAdaDispl16x2.DrawText(s: string);
var
  i: integer;
begin
  for i := 1 to length(s) do
  begin
    write(ord(s[i]));
  end;

end;

end.

