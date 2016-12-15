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

unit TMSLCLRaspiHWReg;

{$R tmslclraspihwreg.dcr}

{$mode delphi}

interface

uses
  Classes, SysUtils;

procedure Register;

implementation

uses
  TMSLCLAFQ7L, TMSLCLAFDAC12B, TMSLCLAFADC12B, TMSLCLAFDISPL128x32, 
  TMSLCLAFDISPL16x2, TMSLCLAFBMP180, TMSLCLAF8x8L, TMSLCLAFFRAM8kSPI;

procedure Register;
begin
  RegisterComponents('TMS LCL Raspi HW', [TTMSLCLAdaQuad7SegLed,TTMSLCLAdaADC12B,
    TTMSLCLAdaDAC12B,TTMSLCLAdaDispl128x32, TTMSLCLAdaDispl16x2, TTMSLCLAdaBarTemp,
    TTMSLCLAda8x8MatrixLed, TTMSLCLAdaFram8KSPI]);
end;

end.

