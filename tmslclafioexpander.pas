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

// i2c IO expander

unit TMSLCLAFIOExpander;

{$mode delphi}

interface

uses
  Classes, SysUtils, TMSLCLRaspiHW;

type

  { TTMSLCLAdaIOExpander }

  { TTMSLCLAdaI2CIOExpander }

  TTMSLCLAdaI2CIOExpander = class(TTMSLCLRaspiI2C)
  private
    function GetIODirA: byte;
    function GetIODirB: byte;
    function GetIOIntConA: byte;
    function GetIOIntConB: byte;
    function GetIOIntDefA: byte;
    function GetIOIntDefB: byte;
    function GetIOIntEnA: byte;
    function GetIOIntEnB: byte;
    function GetIOIntFlagA: byte;
    function GetIOIntFlagB: byte;
    function GetIOPolarityA: byte;
    function GetIOPolarityB: byte;
    function GetIOPullupA: byte;
    function GetIOPullupB: byte;
    function GetIOValA: byte;
    function GetIOValB: byte;
    procedure SetIODirA(AValue: byte);
    procedure SetIODirB(AValue: byte);
    procedure SetIOIntConA(AValue: byte);
    procedure SetIOIntConB(AValue: byte);
    procedure SetIOIntDefA(AValue: byte);
    procedure SetIOIntDefB(AValue: byte);
    procedure SetIOIntEnA(AValue: byte);
    procedure SetIOIntEnB(AValue: byte);
    procedure SetIOPolarityA(AValue: byte);
    procedure SetIOPolarityB(AValue: byte);
    procedure SetIOPullupA(AValue: byte);
    procedure SetIOPullupB(AValue: byte);
    procedure SetIOValA(AValue: byte);
    procedure SetIOValB(AValue: byte);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    property IODirA: byte read GetIODirA write SetIODirA;
    property IODirB: byte read GetIODirB write SetIODirB;
    property IOPolarityA: byte read GetIOPolarityA write SetIOPolarityA;
    property IOPolarityB: byte read GetIOPolarityB write SetIOPolarityB;
    property IOValA: byte read GetIOValA write SetIOValA;
    property IOValB: byte read GetIOValB write SetIOValB;
    property IOPullupA: byte read GetIOPullupA write SetIOPullupA;
    property IOPullupB: byte read GetIOPullupB write SetIOPullupB;
    property IOIntEnA: byte read GetIOIntEnA write SetIOIntEnA;
    property IOIntEnB: byte read GetIOIntEnB write SetIOIntEnB;
    property IOIntConA: byte read GetIOIntConA write SetIOIntConA;
    property IOIntDefA: byte read GetIOIntDefA write SetIOIntDefA;
    property IOIntDefB: byte read GetIOIntDefB write SetIOIntDefB;
    property IOIntConB: byte read GetIOIntConB write SetIOIntConB;
    property IOIntFlagA: byte read GetIOIntFlagA;
    property IOIntFlagB: byte read GetIOIntFlagB;
  end;


implementation

const
  MCP23017_ADDRESS    = $20;

  MCP23017_IODIRA   = $00;
  MCP23017_IODIRB   = $01;
  MCP23017_IPOLA    = $02;
  MCP23017_IPOLB    = $03;
  MCP23017_GPINTENA = $04;
  MCP23017_GPINTENB = $05;
  MCP23017_DEFVALA  = $06;
  MCP23017_DEFVALB  = $07;
  MCP23017_INTCONA  = $08;
  MCP23017_INTCONB  = $09;
  MCP23017_IOCONA   = $0A;
  MCP23017_IOCONB   = $0B;
  MCP23017_GPPUA    = $0C;
  MCP23017_GPPUB    = $0D;
  MCP23017_INTFA    = $0E;
  MCP23017_INTFB    = $0F;
  MCP23017_INTCAPA  = $10;
  MCP23017_INTCAPB  = $11;
  MCP23017_GPIOA    = $12;
  MCP23017_GPIOB    = $13;
  MCP23017_OLATA    = $14;
  MCP23017_OLATB    = $15;



{ TTMSLCLAdaIOExpander }

constructor TTMSLCLAdaI2CIOExpander.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  I2CAddress := MCP23017_ADDRESS;
end;

procedure TTMSLCLAdaI2CIOExpander.SetIODirA(AValue: byte);
begin
  SetByteRegister(MCP23017_IODIRA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIODirB(AValue: byte);
begin
  SetByteRegister(MCP23017_IODIRB, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOIntConA(AValue: byte);
begin
  SetByteRegister(MCP23017_INTCONA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOIntConB(AValue: byte);
begin
  SetByteRegister(MCP23017_INTCONB, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOIntDefA(AValue: byte);
begin
  SetByteRegister(MCP23017_DEFVALA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOIntDefB(AValue: byte);
begin
  SetByteRegister(MCP23017_DEFVALB, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOIntEnA(AValue: byte);
begin
  SetByteRegister(MCP23017_GPINTENA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOIntEnB(AValue: byte);
begin
  SetByteRegister(MCP23017_GPINTENB, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOPolarityA(AValue: byte);
begin
  SetByteRegister(MCP23017_IPOLA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOPolarityB(AValue: byte);
begin
  SetByteRegister(MCP23017_IPOLB, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOPullupA(AValue: byte);
begin
  SetByteRegister(MCP23017_GPPUA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOPullupB(AValue: byte);
begin
  SetByteRegister(MCP23017_GPPUB, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOValA(AValue: byte);
begin
  SetByteRegister(MCP23017_GPIOA, AValue);
end;

procedure TTMSLCLAdaI2CIOExpander.SetIOValB(AValue: byte);
begin
  SetByteRegister(MCP23017_GPIOB, AValue);
end;

function TTMSLCLAdaI2CIOExpander.GetIODirA: byte;
begin
  Result := GetByteRegister(MCP23017_IODIRA);
end;

function TTMSLCLAdaI2CIOExpander.GetIODirB: byte;
begin
  Result := GetByteRegister(MCP23017_IODIRB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntConA: byte;
begin
  Result := GetByteRegister(MCP23017_INTCONA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntConB: byte;
begin
  Result := GetByteRegister(MCP23017_INTCONB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntDefA: byte;
begin
  Result := GetByteRegister(MCP23017_DEFVALA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntDefB: byte;
begin
  Result := GetByteRegister(MCP23017_DEFVALB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntEnA: byte;
begin
  Result := GetByteRegister(MCP23017_GPINTENA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntEnB: byte;
begin
  Result := GetByteRegister(MCP23017_GPINTENB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntFlagA: byte;
begin
  Result := GetByteRegister(MCP23017_INTFA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOIntFlagB: byte;
begin
  Result := GetByteRegister(MCP23017_INTFB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOPolarityA: byte;
begin
  Result := GetByteRegister(MCP23017_IPOLA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOPolarityB: byte;
begin
  Result := GetByteRegister(MCP23017_IPOLB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOPullupA: byte;
begin
  Result := GetByteRegister(MCP23017_GPPUA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOPullupB: byte;
begin
  Result := GetByteRegister(MCP23017_GPPUB);
end;

function TTMSLCLAdaI2CIOExpander.GetIOValA: byte;
begin
  Result := GetByteRegister(MCP23017_GPIOA);
end;

function TTMSLCLAdaI2CIOExpander.GetIOValB: byte;
begin
  Result := GetByteRegister(MCP23017_GPIOB);
end;

end.

