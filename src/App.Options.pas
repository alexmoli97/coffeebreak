unit App.Options;

interface

function ResolveNow(const AArgs: TArray<string>; const ASystemNow: TDateTime): TDateTime;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.RegularExpressions;

function ArgValue(const AArgs: TArray<string>; const AName: string): string;
begin
  for var LArg in AArgs do
    if LArg.StartsWith(AName + '=') then
      Exit(LArg.Substring(AName.Length + 1));
  Result := '';
end;

// --now=2026-11-20T16:50 (ISO 8601 senza secondi, ora locale); qualsiasi altro valore viene ignorato
function ResolveNow(const AArgs: TArray<string>; const ASystemNow: TDateTime): TDateTime;
var
  LValue: string;
begin
  Result := ASystemNow;
  LValue := ArgValue(AArgs, '--now');
  // solo cifre ASCII: ToInteger accetterebbe anche segni ed esadecimale ('+026', '$B')
  if not TRegEx.IsMatch(LValue, '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}$') then
    Exit;
  // al massimo quattro cifre: la conversione in Word non perde nulla
  if not TryEncodeDateTime(Word(LValue.Substring(0, 4).ToInteger), Word(LValue.Substring(5, 2).ToInteger),
    Word(LValue.Substring(8, 2).ToInteger), Word(LValue.Substring(11, 2).ToInteger),
    Word(LValue.Substring(14, 2).ToInteger), 0, 0, Result) then
    Result := ASystemNow;
end;

end.
