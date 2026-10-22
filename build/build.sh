#!/usr/bin/env bash
# Build di CoffeeBreak da WSL con i tool Windows.
#   build.sh test               compila ed esegue i test DUnitX
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/build/out"
DCC="/mnt/c/Program Files (x86)/Embarcadero/Studio/37.0/bin/dcc64.exe"
win() { wslpath -w "$1"; }

# dcc64 gira con cwd su un disco Windows: da una cartella di WSL cmd/dcc stampano avvisi sui path UNC
dcc() { (cd /mnt/c && "$DCC" -B -Q -NSSystem\;Winapi\;System.Win\;Vcl\;Vcl.Imaging \
  "-U$(win "$ROOT/src")" "-E$(win "$OUT")" "-NU$(win "$ROOT/build/dcu")" "$@") | tr -d '\r'; }

test() {
  mkdir -p "$OUT" "$ROOT/build/dcu"
  dcc "$(win "$ROOT/tests/CoffeeBreakTests.dpr")"
  chmod +x "$OUT/CoffeeBreakTests.exe"
  (cd "$OUT" && ./CoffeeBreakTests.exe) | tr -d '\r'
}

case "${1:-}" in
  test) test ;;
  *) echo "uso: build.sh test" >&2; exit 2 ;;
esac
