#!/usr/bin/env bash
# Pubblica una versione già compilata con build.sh all <versione>: tag git e GitHub Release con l'installer.
#   publish.sh <versione>
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
v=${1:?versione mancante, es. 1.0.0}
setup="build/out/CoffeeBreak-$v-x64-setup.exe"

[ "$(git branch --show-current)" = main ] || { echo "le release partono solo da main" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "working tree non pulito" >&2; exit 1; }
[ -f "$setup" ] || { echo "manca $setup: lanciare prima build/build.sh all $v" >&2; exit 1; }
notes=$(awk -v v="$v" '$0 ~ "^## "v" " {on=1; next} /^## / {on=0} on' CHANGELOG.md)
[ -n "$(echo "$notes" | tr -d '[:space:]')" ] || { echo "la versione $v non è in CHANGELOG.md" >&2; exit 1; }

git tag -a "v$v" -m "CoffeeBreak $v"
git push origin main "v$v"
gh release create "v$v" "$setup" --title "CoffeeBreak $v" --notes "$notes"
echo "InstallerUrl: https://github.com/alexmoli97/coffeebreak/releases/download/v$v/CoffeeBreak-$v-x64-setup.exe"
sha256sum "$setup" | awk '{print "InstallerSha256: " toupper($1)}'
