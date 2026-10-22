#!/usr/bin/env bash
# Scrive i manifest WinGet (schema 1.12.0, formato multi-file) di una versione già pubblicata con publish.sh.
#   manifest.sh <versione>
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
v=${1:?versione mancante, es. 1.0.0}
id=AlessioMolinaro.CoffeeBreak
setup="$ROOT/build/out/CoffeeBreak-$v-x64-setup.exe"
url="https://github.com/alexmoli97/coffeebreak/releases/download/v$v/CoffeeBreak-$v-x64-setup.exe"
dir="$ROOT/manifests/a/AlessioMolinaro/CoffeeBreak/$v"
product_code="'{5B8DF55B-80F0-4CF5-ABCC-A745529C4B65}_is1'" # AppId del .iss + "_is1"

# lo SHA256 va calcolato sul file pubblicato: scaricarlo evita di firmare un manifest per un file diverso
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL -o "$tmp" "$url"
sha=$(sha256sum "$tmp" | awk '{print toupper($1)}')
[ ! -f "$setup" ] || [ "$sha" = "$(sha256sum "$setup" | awk '{print toupper($1)}')" ] \
  || { echo "l'installer pubblicato è diverso da quello in build/out" >&2; exit 1; }

mkdir -p "$dir"
cat > "$dir/$id.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.version.1.12.0.schema.json

PackageIdentifier: $id
PackageVersion: $v
DefaultLocale: it-IT
ManifestType: version
ManifestVersion: 1.12.0
YAML

cat > "$dir/$id.installer.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.installer.1.12.0.schema.json

PackageIdentifier: $id
PackageVersion: $v
InstallerType: inno
Scope: user
InstallModes:
- interactive
- silent
- silentWithProgress
InstallerSwitches:
  Custom: /CURRENTUSER
UpgradeBehavior: install
ProductCode: $product_code
ReleaseDate: $(git -C "$ROOT" log -1 --format=%cs "v$v")
AppsAndFeaturesEntries:
- DisplayName: CoffeeBreak
  Publisher: Alessio Molinaro
  ProductCode: $product_code
Installers:
- Architecture: x64
  InstallerUrl: $url
  InstallerSha256: $sha
ManifestType: installer
ManifestVersion: 1.12.0
YAML

cat > "$dir/$id.locale.it-IT.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.defaultLocale.1.12.0.schema.json

PackageIdentifier: $id
PackageVersion: $v
PackageLocale: it-IT
Publisher: Alessio Molinaro
PublisherUrl: https://github.com/alexmoli97
PublisherSupportUrl: https://github.com/alexmoli97/coffeebreak/issues
Author: Alessio Molinaro
PackageName: CoffeeBreak
PackageUrl: https://github.com/alexmoli97/coffeebreak
License: MIT
LicenseUrl: https://github.com/alexmoli97/coffeebreak/blob/HEAD/LICENSE
Copyright: Copyright (c) 2026 Alessio Molinaro
ShortDescription: L'agenda di ITDevCon 2026, con il conto alla rovescia per il coffee break.
Description: App demo del talk "Basta con AggiornamentiU.pas! Usa WinGet e UniGetUI per distribuire le tue applicazioni Delphi" (ITDevCon 2026, Roma). App VCL senza codice di aggiornamento, distribuita con WinGet.
Moniker: coffeebreak
Tags:
- delphi
- itdevcon
- vcl
ReleaseNotesUrl: https://github.com/alexmoli97/coffeebreak/releases/tag/v$v
ManifestType: defaultLocale
ManifestVersion: 1.12.0
YAML

echo "$dir"
(cd /mnt/c && winget.exe validate --manifest "$(wslpath -w "$dir")") | tr -d '\r'
