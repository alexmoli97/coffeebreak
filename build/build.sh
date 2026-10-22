#!/usr/bin/env bash
# Build di CoffeeBreak da WSL con i tool Windows.
#   build.sh test               compila ed esegue i test DUnitX
#   build.sh app <versione>     compila le risorse (VERSIONINFO = <versione>.0) e CoffeeBreak.exe
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/build/out"
BDS="/mnt/c/Program Files (x86)/Embarcadero/Studio/37.0"
DCC="$BDS/bin/dcc64.exe"
SDK="/mnt/c/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64"
STYLES='C:/Users/Public/Documents/Embarcadero/Studio/37.0/Styles'
win() { wslpath -w "$1"; }

# dcc64 gira con cwd su un disco Windows: da una cartella di WSL cmd/dcc stampano avvisi sui path UNC
dcc() { (cd /mnt/c && "$DCC" -B -Q -NSSystem\;Winapi\;System.Win\;Vcl\;Vcl.Imaging \
  "-U$(win "$ROOT/src")" "-R$(win "$OUT")" "-E$(win "$OUT")" "-NU$(win "$ROOT/build/dcu")" "$@") | tr -d '\r'; }

test() {
  mkdir -p "$OUT" "$ROOT/build/dcu"
  dcc "$(win "$ROOT/tests/CoffeeBreakTests.dpr")"
  chmod +x "$OUT/CoffeeBreakTests.exe"
  (cd "$OUT" && ./CoffeeBreakTests.exe) | tr -d '\r'
}

app() {
  local v=${1:?versione mancante, es. 1.0.0}
  [[ $v =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "versione non valida: $v" >&2; exit 2; }
  mkdir -p "$OUT" "$ROOT/build/dcu"
  sed -e "s/@VERSION_COMMA@/${v//./,},0/g" -e "s/@VERSION@/$v/g" \
      -e "s|@ROOT@|$(wslpath -m "$ROOT")|g" -e "s|@STYLES@|$STYLES|g" "$ROOT/res/CoffeeBreak.rc" > "$OUT/CoffeeBreak.rc"
  # cgrc di Delphi cerca rc.exe nel PATH: si usa direttamente quello del Windows SDK
  (cd /mnt/c && "$SDK/rc.exe" /nologo /c65001 "/fo$(win "$OUT/CoffeeBreak.res")" "$(win "$OUT/CoffeeBreak.rc")") | tr -d '\r'
  dcc "$(win "$ROOT/src/CoffeeBreak.dpr")"
  chmod +x "$OUT/CoffeeBreak.exe"
}

case "${1:-}" in
  test) test ;;
  app) app "${2:-}" ;;
  *) echo "uso: build.sh test | app <versione>" >&2; exit 2 ;;
esac
