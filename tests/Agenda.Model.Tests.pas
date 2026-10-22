unit Agenda.Model.Tests;

interface

uses
  DUnitX.TestFramework, Agenda.Model;

type
  [TestFixture]
  TAgendaModelTests = class
  private
    FAgenda: TArray<TSession>;
    function CountTitle(const ATitle: string): Integer;
  public
    [Setup] procedure Setup;
    [Test] procedure ParseAgenda_Restituisce48Sessioni;
    [Test] procedure ParseAgenda_ConservaIQuattroRefusi;
    [Test] procedure ParseAgenda_TipoDalCampoKindNonDalTitolo;
    [Test] procedure ParseAgenda_KindSconosciutoSollevaEccezione;
    [Test] procedure SlotVuotiETBA_SonoLiberi;
    [Test] procedure CurrentSession_DuranteIlTalkDiAlessio;
    [Test] procedure CurrentSession_TraDueSlot;
    [Test] procedure CurrentSession_FuoriDallaConferenza;
    [Test] procedure CurrentSession_SlotLiberoNonEvidenziato;
    [Test] procedure NextBreak_MancanoVentiMinuti;
    [Test] procedure NextBreak_InCorsoAncoraQuindiciMinuti;
    [Test] procedure NextBreak_FineDellaPausaEsclusa;
    [Test] procedure NextBreak_DuranteLUltimoTalk;
    [Test] procedure NextBreak_PrimaDellaConferenza;
    [Test] procedure DefaultDay_GiornoDellaConferenza;
    [Test] procedure DefaultDay_FuoriDallaConferenza;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.DateUtils;

function DT(AYear, AMonth, ADay, AHour, AMinute: Word): TDateTime;
begin
  Result := EncodeDateTime(AYear, AMonth, ADay, AHour, AMinute, 0, 0);
end;

procedure TAgendaModelTests.Setup;
begin
  // il runner sta in build\out, l'agenda in data
  FAgenda := ParseAgenda(TFile.ReadAllText(
    TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\data\agenda-2026.json'), TEncoding.UTF8));
end;

function TAgendaModelTests.CountTitle(const ATitle: string): Integer;
begin
  Result := 0;
  for var S in FAgenda do
    if S.Title = ATitle then
      Inc(Result);
end;

procedure TAgendaModelTests.ParseAgenda_Restituisce48Sessioni;
var
  Day19: Integer;
begin
  Assert.AreEqual(48, Integer(Length(FAgenda)));
  Day19 := 0;
  for var S in FAgenda do
    if S.Day = EncodeDate(2026, 11, 19) then
      Inc(Day19);
  Assert.AreEqual(24, Day19);
end;

procedure TAgendaModelTests.ParseAgenda_ConservaIQuattroRefusi;
begin
  Assert.AreEqual(4, CountTitle('COFFE BREAK'));
end;

procedure TAgendaModelTests.ParseAgenda_TipoDalCampoKindNonDalTitolo;
var
  A: TArray<TSession>;
begin
  A := ParseAgenda('{"event":"x","sessions":[' +
    '{"day":"2026-11-19","room":"Kirk","start":"10:20","end":"10:45","kind":"break","title":"Pausa","speaker":""},' +
    '{"day":"2026-11-19","room":"Kirk","start":"10:50","end":"11:45","kind":"talk","title":"COFFEE BREAK","speaker":"X"}]}');
  Assert.AreEqual(2, Integer(Length(A)));
  Assert.IsTrue(A[0].Kind = skBreak, 'kind break');
  Assert.IsTrue(A[1].Kind = skTalk, 'kind talk');
  Assert.AreEqual(DT(2026, 11, 19, 10, 50), A[1].StartAt);
  Assert.AreEqual(DT(2026, 11, 19, 11, 45), A[1].EndAt);
end;

procedure TAgendaModelTests.ParseAgenda_KindSconosciutoSollevaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      ParseAgenda('{"event":"x","sessions":[' +
        '{"day":"2026-11-19","room":"Kirk","start":"10:20","end":"10:45","kind":"party","title":"x","speaker":""}]}');
    end, EConvertError);
end;

procedure TAgendaModelTests.SlotVuotiETBA_SonoLiberi;
var
  Free: Integer;
begin
  Free := 0;
  for var S in FAgenda do
    if (S.Title = '-') or (S.Title = 'TBA') then
    begin
      Assert.IsTrue(S.Kind = skFree, S.Title + ' alle ' + TimeToStr(S.StartAt));
      Inc(Free);
    end;
  Assert.AreEqual(13, Free);
end;

procedure TAgendaModelTests.CurrentSession_DuranteIlTalkDiAlessio;
var
  I: Integer;
begin
  I := CurrentSessionIndex(FAgenda, 'Kirk', DT(2026, 11, 20, 16, 50));
  Assert.IsTrue(I >= 0, 'nessuna sessione');
  Assert.AreEqual('Alessio Molinaro', FAgenda[I].Speaker);
end;

procedure TAgendaModelTests.CurrentSession_TraDueSlot;
begin
  Assert.AreEqual(-1, CurrentSessionIndex(FAgenda, 'Kirk', DT(2026, 11, 19, 10, 47)));
end;

procedure TAgendaModelTests.CurrentSession_FuoriDallaConferenza;
begin
  Assert.AreEqual(-1, CurrentSessionIndex(FAgenda, 'Kirk', DT(2026, 10, 22, 10, 0)));
end;

procedure TAgendaModelTests.CurrentSession_SlotLiberoNonEvidenziato;
begin
  Assert.AreEqual(-1, CurrentSessionIndex(FAgenda, 'Spock', DT(2026, 11, 20, 16, 50)));
end;

procedure TAgendaModelTests.NextBreak_MancanoVentiMinuti;
var
  M: Integer;
begin
  Assert.IsTrue(NextBreak(FAgenda, DT(2026, 11, 19, 10, 0), M) = bsUpcoming);
  Assert.AreEqual(20, M);
end;

procedure TAgendaModelTests.NextBreak_InCorsoAncoraQuindiciMinuti;
var
  M: Integer;
begin
  Assert.IsTrue(NextBreak(FAgenda, DT(2026, 11, 19, 10, 30), M) = bsInProgress);
  Assert.AreEqual(15, M);
end;

procedure TAgendaModelTests.NextBreak_FineDellaPausaEsclusa;
var
  M: Integer;
begin
  Assert.IsTrue(NextBreak(FAgenda, DT(2026, 11, 20, 16, 40), M) = bsNoMore);
end;

procedure TAgendaModelTests.NextBreak_DuranteLUltimoTalk;
var
  M: Integer;
begin
  Assert.IsTrue(NextBreak(FAgenda, DT(2026, 11, 20, 16, 50), M) = bsNoMore);
end;

procedure TAgendaModelTests.NextBreak_PrimaDellaConferenza;
var
  M: Integer;
begin
  Assert.IsTrue(NextBreak(FAgenda, DT(2026, 10, 22, 10, 0), M) = bsUpcoming);
  Assert.AreEqual(28 * 24 * 60 + 20, M); // fino al 19/11 alle 10:20, ora locale
end;

procedure TAgendaModelTests.DefaultDay_GiornoDellaConferenza;
begin
  Assert.AreEqual(EncodeDate(2026, 11, 20), DefaultDay(FAgenda, DT(2026, 11, 20, 16, 50)));
end;

procedure TAgendaModelTests.DefaultDay_FuoriDallaConferenza;
begin
  Assert.AreEqual(EncodeDate(2026, 11, 19), DefaultDay(FAgenda, DT(2026, 10, 22, 10, 0)));
end;

initialization
  TDUnitX.RegisterTestFixture(TAgendaModelTests);

end.
