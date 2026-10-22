unit App.Options;

interface

function ResolveNow(const AArgs: TArray<string>; const ASystemNow: TDateTime): TDateTime;
function ScreenshotPath(const AArgs: TArray<string>): string;

implementation

uses
  System.SysUtils, System.DateUtils;

function ArgValue(const AArgs: TArray<string>; const AName: string): string;
begin
  for var A in AArgs do
    if A.StartsWith(AName + '=') then
      Exit(A.Substring(Length(AName) + 1));
  Result := '';
end;

// --now=2026-11-20T16:50 (ISO 8601 senza secondi, ora locale); qualsiasi altro valore viene ignorato
function ResolveNow(const AArgs: TArray<string>; const ASystemNow: TDateTime): TDateTime;
var
  V: string;
  Y, Mo, D, H, Mi: Integer;
begin
  Result := ASystemNow;
  V := ArgValue(AArgs, '--now');
  if (Length(V) <> 16) or (V[5] <> '-') or (V[8] <> '-') or (V[11] <> 'T') or (V[14] <> ':') then
    Exit;
  if TryStrToInt(V.Substring(0, 4), Y) and TryStrToInt(V.Substring(5, 2), Mo) and TryStrToInt(V.Substring(8, 2), D)
    and TryStrToInt(V.Substring(11, 2), H) and TryStrToInt(V.Substring(14, 2), Mi)
    and not TryEncodeDateTime(Y, Mo, D, H, Mi, 0, 0, Result) then
    Result := ASystemNow;
end;

function ScreenshotPath(const AArgs: TArray<string>): string;
begin
  Result := ArgValue(AArgs, '--screenshot');
end;

end.
