program CoffeeBreakTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  Agenda.Model.Tests in 'Agenda.Model.Tests.pas',
  App.Options.Tests in 'App.Options.Tests.pas';

var
  Runner: ITestRunner;
begin
  Runner := TDUnitX.CreateRunner;
  Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
  Runner.FailsOnNoAsserts := True;
  if not Runner.Execute.AllPassed then
    ExitCode := 1;
end.
