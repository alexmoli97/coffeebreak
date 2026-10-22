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

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON, System.DateUtils, System.Types;

const
  KindNames: array [TSessionKind] of string = ('talk', 'break', 'lunch', 'plenary', 'free');

function ParseKind(const AName: string): TSessionKind;
begin
  for var K := Low(TSessionKind) to High(TSessionKind) do
    if KindNames[K] = AName then
      Exit(K);
  raise EConvertError.CreateFmt('Tipo di sessione sconosciuto: "%s"', [AName]);
end;

// "2026-11-19" + "10:20"
function ParseDateTime(const ADay, ATime: string): TDateTime;
begin
  Result := EncodeDateTime(ADay.Substring(0, 4).ToInteger, ADay.Substring(5, 2).ToInteger, ADay.Substring(8, 2).ToInteger,
    ATime.Substring(0, 2).ToInteger, ATime.Substring(3, 2).ToInteger, 0, 0);
end;

function ParseAgenda(const AJson: string): TArray<TSession>;
var
  Root: TJSONValue;
  Items: TJSONArray;
begin
  Root := TJSONObject.ParseJSONValue(AJson, False, True);
  try
    Items := Root.GetValue<TJSONArray>('sessions');
    SetLength(Result, Items.Count);
    for var I := 0 to Items.Count - 1 do
    begin
      var Item := Items[I];
      var Day := Item.GetValue<string>('day');
      Result[I].StartAt := ParseDateTime(Day, Item.GetValue<string>('start'));
      Result[I].EndAt := ParseDateTime(Day, Item.GetValue<string>('end'));
      Result[I].Day := DateOf(Result[I].StartAt);
      Result[I].Room := Item.GetValue<string>('room');
      Result[I].Kind := ParseKind(Item.GetValue<string>('kind'));
      Result[I].Title := Item.GetValue<string>('title');
      Result[I].Speaker := Item.GetValue<string>('speaker');
    end;
  finally
    Root.Free;
  end;
end;

function LoadEmbeddedAgenda: TArray<TSession>;
var
  Stream: TResourceStream;
  Bytes: TBytes;
begin
  Stream := TResourceStream.Create(HInstance, 'AGENDA', RT_RCDATA);
  try
    SetLength(Bytes, Stream.Size);
    Stream.ReadBuffer(Bytes, Stream.Size);
  finally
    Stream.Free;
  end;
  Result := ParseAgenda(TEncoding.UTF8.GetString(Bytes));
end;

function CurrentSessionIndex(const AAgenda: TArray<TSession>; const ARoom: string; const ANow: TDateTime): Integer;
begin
  for var I := 0 to High(AAgenda) do
    if (AAgenda[I].Room = ARoom) and (AAgenda[I].Kind <> skFree)
      and (AAgenda[I].StartAt <= ANow) and (ANow < AAgenda[I].EndAt) then
      Exit(I);
  Result := -1;
end;

// minuti arrotondati per eccesso: "mancano 0 minuti" solo quando è davvero l'ora
function MinutesUntil(const AFrom, ATo: TDateTime): Integer;
begin
  Result := (MilliSecondsBetween(ATo, AFrom) + 59999) div 60000;
end;

function NextBreak(const AAgenda: TArray<TSession>; const ANow: TDateTime; out AMinutes: Integer): TBreakState;
var
  Next: TDateTime;
begin
  AMinutes := 0;
  Next := 0;
  for var S in AAgenda do
  begin
    if S.Kind <> skBreak then
      Continue;
    if (S.StartAt <= ANow) and (ANow < S.EndAt) then
    begin
      AMinutes := MinutesUntil(ANow, S.EndAt);
      Exit(bsInProgress);
    end;
    if (S.StartAt > ANow) and ((Next = 0) or (S.StartAt < Next)) then
      Next := S.StartAt;
  end;
  if Next = 0 then
    Exit(bsNoMore);
  AMinutes := MinutesUntil(ANow, Next);
  Result := bsUpcoming;
end;

function DefaultDay(const AAgenda: TArray<TSession>; const ANow: TDateTime): TDate;
begin
  Result := 0;
  for var S in AAgenda do
  begin
    if S.Day = DateOf(ANow) then
      Exit(S.Day);
    if (Result = 0) or (S.Day < Result) then
      Result := S.Day;
  end;
end;

end.
