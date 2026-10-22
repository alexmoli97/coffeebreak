#!/usr/bin/env bash
# Build di CoffeeBreak da WSL con i tool Windows.
#   build.sh test               compila ed esegue i test DUnitX
#   build.sh app <versione>     compila le risorse (VERSIONINFO = <versione>.0) e CoffeeBreak.exe
#   build.sh all <versione>     test, app, firma dell'exe, installer Inno Setup firmato
# La firma usa il certificato con thumbprint $CODESIGN_THUMBPRINT (archivio CurrentUser\My);
# se non è impostato lo legge da ../demo-env/certs.json, il certificato di demo.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/build/out"
BDS="/mnt/c/Program Files (x86)/Embarcadero/Studio/37.0"
DCC="$BDS/bin/dcc64.exe"
SDK="/mnt/c/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64"
STYLES='C:/Users/Public/Documents/Embarcadero/Studio/37.0/Styles'
ISCC="/mnt/c/Users/amoli/AppData/Local/Programs/Inno Setup 6/ISCC.exe"
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

sign() {
  local thumb=${CODESIGN_THUMBPRINT:-}
  [ -n "$thumb" ] || thumb=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["codeSigningThumbprint"])' "$ROOT/../demo-env/certs.json")
  (cd /mnt/c && "$SDK/signtool.exe" sign /sha1 "$thumb" /s My /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "$(win "$1")") | tr -d '\r'
  (cd /mnt/c && "$SDK/signtool.exe" verify /pa /q "$(win "$1")") | tr -d '\r'
}

all() {
  local v=${1:?versione mancante, es. 1.0.0}
  test
  app "$v"
  sign "$OUT/CoffeeBreak.exe"
  (cd /mnt/c && "$ISCC" /Q "/DAppVersion=$v" "$(win "$ROOT/installer/CoffeeBreak.iss")") | tr -d '\r'
  sign "$OUT/CoffeeBreak-$v-x64-setup.exe"
  echo "pronto: build/out/CoffeeBreak-$v-x64-setup.exe"
}

case "${1:-}" in
  test) test ;;
  app) app "${2:-}" ;;
  all) all "${2:-}" ;;
  *) echo "uso: build.sh test | app <versione> | all <versione>" >&2; exit 2 ;;
esac
