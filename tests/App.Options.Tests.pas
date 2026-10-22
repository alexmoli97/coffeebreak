unit App.Options.Tests;

interface

uses
  DUnitX.TestFramework, App.Options;

type
  [TestFixture]
  TAppOptionsTests = class
  public
    [Test] procedure ResolveNow_FormatoValido;
    [Test] procedure ResolveNow_TestoNonValido;
    [Test] procedure ResolveNow_DataImpossibile;
    [Test] procedure ResolveNow_SenzaArgomento;
    [Test] procedure ScreenshotPath_Presente;
    [Test] procedure ScreenshotPath_Assente;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

const
  SystemNow: TDateTime = 46000.5;

procedure TAppOptionsTests.ResolveNow_FormatoValido;
begin
  Assert.AreEqual(EncodeDateTime(2026, 11, 20, 16, 50, 0, 0), ResolveNow(['--now=2026-11-20T16:50'], SystemNow));
end;

procedure TAppOptionsTests.ResolveNow_TestoNonValido;
begin
  Assert.AreEqual(SystemNow, ResolveNow(['--now=boh'], SystemNow));
end;

procedure TAppOptionsTests.ResolveNow_DataImpossibile;
begin
  Assert.AreEqual(SystemNow, ResolveNow(['--now=2026-13-40T99:99'], SystemNow));
end;

procedure TAppOptionsTests.ResolveNow_SenzaArgomento;
begin
  Assert.AreEqual(SystemNow, ResolveNow(['--screenshot=C:\a.png'], SystemNow));
end;

procedure TAppOptionsTests.ScreenshotPath_Presente;
begin
  Assert.AreEqual('C:\a.png', ScreenshotPath(['--now=2026-11-20T16:50', '--screenshot=C:\a.png']));
end;

procedure TAppOptionsTests.ScreenshotPath_Assente;
begin
  Assert.AreEqual('', ScreenshotPath(['--now=2026-11-20T16:50']));
end;

initialization
  TDUnitX.RegisterTestFixture(TAppOptionsTests);

end.
