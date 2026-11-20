unit App.Options.Tests;

interface

uses
  DUnitX.TestFramework,
  App.Options;

type
  [TestFixture]
  TAppOptionsTests = class
  public
    [Test] procedure ResolveNow_FormatoValido;
    [Test] procedure ResolveNow_TestoNonValido;
    [Test] procedure ResolveNow_DataImpossibile;
    [Test] procedure ResolveNow_SoloCifre;
    [Test] procedure ResolveNow_SenzaArgomento;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

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

procedure TAppOptionsTests.ResolveNow_SoloCifre;
begin
  // StrToInt accetta segni ed esadecimale: '+026' diventerebbe l'anno 26
  Assert.AreEqual(SystemNow, ResolveNow(['--now=+026-11-20T16:50'], SystemNow));
  Assert.AreEqual(SystemNow, ResolveNow(['--now=2026-$B-20T16:50'], SystemNow));
end;

procedure TAppOptionsTests.ResolveNow_SenzaArgomento;
begin
  Assert.AreEqual(SystemNow, ResolveNow(['--altro=valore'], SystemNow));
end;

initialization
  TDUnitX.RegisterTestFixture(TAppOptionsTests);

end.
