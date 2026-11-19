unit Agenda.Model;

interface

type
  TSessionKind = (skTalk, skBreak, skLunch, skPlenary, skFree);

  TSession = record
    Day: TDate;
    Room: string;
    StartAt, EndAt: TDateTime;
    Kind: TSessionKind;
    Title, Speaker: string;
  end;

  TBreakState = (bsUpcoming, bsInProgress, bsNoMore);

function ParseAgenda(const AJson: string): TArray<TSession>;
function LoadEmbeddedAgenda: TArray<TSession>;
function CurrentSessionIndex(const AAgenda: TArray<TSession>; const ARoom: string; const ANow: TDateTime): Integer;
function NextBreak(const AAgenda: TArray<TSession>; const ANow: TDateTime; out AMinutes: Integer): TBreakState;
function DefaultDay(const AAgenda: TArray<TSession>; const ANow: TDateTime): TDate;
function BreakBannerText(const AState: TBreakState; const AMinutes: Integer): string;
function IsLastTalk(const AAgenda: TArray<TSession>; const ANow: TDateTime): Boolean;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections, // senza, TJSONArray.GetValue non viene espanso inline (H2443)
  System.JSON,
  System.DateUtils,
  System.Types;

const
  KindNames: array [TSessionKind] of string = ('talk', 'break', 'lunch', 'plenary', 'free');

function ParseKind(const AName: string): TSessionKind;
begin
  for var LKind := Low(TSessionKind) to High(TSessionKind) do
    if KindNames[LKind] = AName then
      Exit(LKind);
  raise EConvertError.CreateFmt('Tipo di sessione sconosciuto: "%s"', [AName]);
end;

// "2026-11-19" + "10:20". Al massimo quattro cifre per campo, quindi la conversione in Word non perde nulla;
// una data o un'ora impossibile fa sollevare EConvertError a EncodeDateTime
function ParseDateTime(const ADay, ATime: string): TDateTime;
begin
  Result := EncodeDateTime(Word(ADay.Substring(0, 4).ToInteger), Word(ADay.Substring(5, 2).ToInteger),
    Word(ADay.Substring(8, 2).ToInteger), Word(ATime.Substring(0, 2).ToInteger),
    Word(ATime.Substring(3, 2).ToInteger), 0, 0);
end;

function ParseAgenda(const AJson: string): TArray<TSession>;
var
  LRoot: TJSONValue;
  LItems: TJSONArray;
begin
  // con RaiseExc = True un JSON non valido solleva un'eccezione invece di restituire nil
  LRoot := TJSONObject.ParseJSONValue(AJson, False, True);
  try
    LItems := LRoot.GetValue<TJSONArray>('sessions');
    SetLength(Result, LItems.Count);
    for var I: Integer := 0 to LItems.Count - 1 do
    begin
      var LItem := LItems[I];
      var LDay := LItem.GetValue<string>('day');
      Result[I].StartAt := ParseDateTime(LDay, LItem.GetValue<string>('start'));
      Result[I].EndAt := ParseDateTime(LDay, LItem.GetValue<string>('end'));
      Result[I].Day := DateOf(Result[I].StartAt);
      Result[I].Room := LItem.GetValue<string>('room');
      Result[I].Kind := ParseKind(LItem.GetValue<string>('kind'));
      Result[I].Title := LItem.GetValue<string>('title');
      Result[I].Speaker := LItem.GetValue<string>('speaker');
    end;
  finally
    LRoot.Free;
  end;
end;

function LoadEmbeddedAgenda: TArray<TSession>;
var
  LStream: TResourceStream;
  LBytes: TBytes;
begin
  LStream := TResourceStream.Create(HInstance, 'AGENDA', RT_RCDATA);
  try
    SetLength(LBytes, LStream.Size);
    LStream.ReadBuffer(LBytes, LStream.Size);
  finally
    LStream.Free;
  end;
  Result := ParseAgenda(TEncoding.UTF8.GetString(LBytes));
end;

function CurrentSessionIndex(const AAgenda: TArray<TSession>; const ARoom: string; const ANow: TDateTime): Integer;
begin
  // l'agenda ha 48 sessioni: Length (NativeInt su Win64) sta comodo in un Integer
  for var I: Integer := 0 to Integer(Length(AAgenda)) - 1 do
    if (AAgenda[I].Room = ARoom) and (AAgenda[I].Kind <> skFree)
      and (AAgenda[I].StartAt <= ANow) and (ANow < AAgenda[I].EndAt) then
      Exit(I);
  Result := -1;
end;

// minuti arrotondati per eccesso: "mancano 0 minuti" solo quando è davvero l'ora.
// MilliSecondsBetween restituisce il valore assoluto: chi chiama garantisce AFrom < ATo
function MinutesUntil(const AFrom, ATo: TDateTime): Integer;
begin
  Result := Integer((MilliSecondsBetween(ATo, AFrom) + 59999) div 60000);
end;

function NextBreak(const AAgenda: TArray<TSession>; const ANow: TDateTime; out AMinutes: Integer): TBreakState;
var
  LNext: TDateTime;
begin
  AMinutes := 0;
  LNext := 0;
  for var LSession in AAgenda do
  begin
    if LSession.Kind <> skBreak then
      Continue;
    if (LSession.StartAt <= ANow) and (ANow < LSession.EndAt) then
    begin
      AMinutes := MinutesUntil(ANow, LSession.EndAt);
      Exit(bsInProgress);
    end;
    if (LSession.StartAt > ANow) and ((LNext = 0) or (LSession.StartAt < LNext)) then
      LNext := LSession.StartAt;
  end;
  if LNext = 0 then
    Exit(bsNoMore);
  AMinutes := MinutesUntil(ANow, LNext);
  Result := bsUpcoming;
end;

function DefaultDay(const AAgenda: TArray<TSession>; const ANow: TDateTime): TDate;
begin
  Result := 0;
  for var LSession in AAgenda do
  begin
    if LSession.Day = DateOf(ANow) then
      Exit(LSession.Day);
    if (Result = 0) or (LSession.Day < Result) then
      Result := LSession.Day;
  end;
end;

function Quantity(const AValue: Integer; const ASingular, APlural: string): string;
begin
  if AValue = 1 then
    Result := '1 ' + ASingular
  else
    Result := AValue.ToString + ' ' + APlural;
end;

// "Manca 1 minuto", "Mancano 20 minuti"
function Remaining(const AValue: Integer; const AText: string): string;
begin
  if AValue = 1 then
    Result := 'Manca ' + AText
  else
    Result := 'Mancano ' + AText;
end;

function BreakBannerText(const AState: TBreakState; const AMinutes: Integer): string;
var
  LHours, LMinutes: Integer;
begin
  case AState of
    bsInProgress:
      Exit('Coffee break in corso (ancora ' + Quantity(AMinutes, 'minuto', 'minuti') + ')');
    bsNoMore:
      Exit('Coffee break finiti. Prossimo: ITDevCon 2027');
  end;
  // bsUpcoming
  if AMinutes >= MinsPerDay then
    Exit(Remaining(AMinutes div MinsPerDay, Quantity(AMinutes div MinsPerDay, 'giorno', 'giorni')) + ' al primo coffee break');
  if AMinutes < MinsPerHour then
    Exit(Remaining(AMinutes, Quantity(AMinutes, 'minuto', 'minuti')) + ' al coffee break');
  LHours := AMinutes div MinsPerHour;
  LMinutes := AMinutes mod MinsPerHour;
  if LMinutes = 0 then
    Result := Remaining(LHours, Quantity(LHours, 'ora', 'ore'))
  else
    Result := 'Mancano ' + Quantity(LHours, 'ora', 'ore') + ' e ' + Quantity(LMinutes, 'minuto', 'minuti');
  Result := Result + ' al coffee break';
end;

// vero mentre è in corso un talk dell'ultimo slot della conferenza
function IsLastTalk(const AAgenda: TArray<TSession>; const ANow: TDateTime): Boolean;
var
  LLastStart: TDateTime;
begin
  LLastStart := 0;
  for var LSession in AAgenda do
    if (LSession.Kind = skTalk) and (LSession.StartAt > LLastStart) then
      LLastStart := LSession.StartAt;
  for var LSession in AAgenda do
    if (LSession.Kind = skTalk) and (LSession.StartAt = LLastStart) and (LSession.StartAt <= ANow)
      and (ANow < LSession.EndAt) then
      Exit(True);
  Result := False;
end;

end.
