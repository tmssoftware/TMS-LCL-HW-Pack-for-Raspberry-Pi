{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit TMSLCLRaspiHWPkg;

interface

uses
  TMSLCLAFADC12b, tmslclafdac12b, TMSLCLAFDISPL128x32, TMSLCLAFQ7L, 
  TMSLCLRaspiFonts, TMSLCLRaspiHW, TMSLCLRaspiHWReg, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('TMSLCLRaspiHWReg', @TMSLCLRaspiHWReg.Register);
end;

initialization
  RegisterPackage('TMSLCLRaspiHWPkg', @Register);
end.
