# CoffeeBreak

L'agenda di ITDevCon 2026 (Roma, 19-20 novembre), con il conto alla rovescia per il coffee break.

App demo del talk "Basta con AggiornamentiU.pas! Usa WinGet e UniGetUI per distribuire le tue applicazioni Delphi" (20 novembre, Sala Kirk, 16:45). L'app non contiene codice di aggiornamento: installazione e aggiornamenti passano da WinGet.

## Build

Da WSL, con Delphi 13 installato su Windows:

```
build/build.sh test
```

Installer firmato (Inno Setup 6 e Windows SDK):

```
build/build.sh all 1.0.0
```

L'`AppId` dell'installer è `{5B8DF55B-80F0-4CF5-ABCC-A745529C4B65}` e non va mai cambiato: Windows registra l'app come `{5B8DF55B-80F0-4CF5-ABCC-A745529C4B65}_is1`, ed è il `ProductCode` con cui WinGet la riconosce.

## Opzioni da riga di comando

- `--now=2026-11-20T16:50`: usa quest'ora invece di quella di sistema (prove e video).

## Il talk

Slide: [`docs/itdevcon-2026-slide.pdf`](docs/itdevcon-2026-slide.pdf).

## Cosa c'è nel repository

- `src/`, `tests/`: l'app VCL e i test DUnitX del modello dell'agenda.
- `installer/CoffeeBreak.iss`: installer Inno Setup pronto per WinGet. `AppId` fisso, installazione per utente senza UAC, modalità silenziosa, chiusura e riapertura dell'app durante l'aggiornamento.
- `build/build.sh`: test, compilazione, firma dell'exe, installer, firma dell'installer.
- `build/publish.sh`: tag Git e GitHub Release con installer e changelog.
- `build/manifest.sh`: i tre manifest WinGet di una versione, con lo SHA256 calcolato sul file pubblicato e `winget validate`.
- `manifests/`: i manifest delle versioni 1.0.0, 1.1.0 e 1.2.0, nella stessa struttura di `microsoft/winget-pkgs`.
- `.github/workflows/winget-pr.yml`: apre la PR su `microsoft/winget-pkgs` con `wingetcreate submit`. Parte solo a mano (`workflow_dispatch`).
- `demo/itdevcon.ubundle`: il bundle di UniGetUI usato nella demo.

I path di Delphi, Inno Setup e Windows SDK sono in cima a `build/build.sh`: adattali al tuo PC. La firma usa il certificato dell'archivio `CurrentUser\My` indicato da `CODESIGN_THUMBPRINT`. Un certificato self-signed vale solo sul PC dove lo rendi attendibile: per distribuire davvero serve un certificato emesso da una CA o la firma cloud.

## Rifare le demo

### D1: WinGet da utente

```
winget search UniGetUI -s winget
winget show --id Devolutions.UniGetUI -s winget
winget install --id Devolutions.UniGetUI -e -s winget
winget list --id Devolutions.UniGetUI
winget upgrade --id Devolutions.UniGetUI -s winget
```

Con più sorgenti conviene indicare quella giusta. Con la sorgente rewinged della D3 attiva, `winget install` e `winget upgrade` di un pacchetto che rewinged non ha falliscono con `0x8a150044`: rewinged risponde 404 alla richiesta del manifest e WinGet lo legge come endpoint mancante.

### D2: il primo manifest

```
winget settings --enable LocalManifestFiles          # da amministratore
wingetcreate new https://github.com/alexmoli97/coffeebreak/releases/download/v1.0.0/CoffeeBreak-1.0.0-x64-setup.exe
winget validate --manifest <cartella del manifest>
winget install --manifest <cartella del manifest>
```

Alla domanda finale di `wingetcreate new`, se inviare il manifest a `winget-pkgs`, rispondi No. L'installer arriva da Internet ed è firmato con un certificato che Windows non conosce: SmartScreen può fermarlo con "PC protetto da Windows".

### D3: una sorgente privata

Una sorgente REST con [rewinged](https://github.com/jantari/rewinged) su `https://localhost:8443`. WinGet vuole HTTPS anche in locale.

1. Un certificato per `localhost`, reso attendibile per l'utente corrente:

   ```
   openssl req -x509 -newkey rsa:2048 -nodes -days 60 -subj "/CN=localhost" \
     -keyout localhost.key -out localhost.crt \
     -addext "basicConstraints=critical,CA:FALSE" \
     -addext "extendedKeyUsage=serverAuth" \
     -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
   ```

   ```
   Import-Certificate -FilePath localhost.crt -CertStoreLocation Cert:\CurrentUser\Root
   ```

2. rewinged, con una cartella `packages` per i manifest e una `installers` dove scarica e serve gli installer:

   ```
   winget install --id jantari.rewinged -e
   rewinged -https -listen localhost:8443 -manifestPath .\packages -autoInternalize -autoInternalizePath .\installers -httpsCertificateFile localhost.crt -httpsPrivateKeyFile localhost.key
   ```

3. La sorgente, da amministratore:

   ```
   winget source add -n itdevcon -a https://localhost:8443/api -t Microsoft.Rest --trust-level trusted
   ```

   Con `--trust-level trusted` WinGet marca gli installer scaricati come zona Attendibili invece che Internet, e SmartScreen non li ferma. Usalo solo con sorgenti che controlli tu.

4. Copia in `packages` i tre file di `manifests/a/AlessioMolinaro/CoffeeBreak/1.0.0`: rewinged li serve subito. `winget install --id AlessioMolinaro.CoffeeBreak -s itdevcon`, poi copia la 1.1.0 e `winget upgrade --id AlessioMolinaro.CoffeeBreak`.

### D4: UniGetUI

Avvia UniGetUI dopo aver aggiunto la sorgente: legge le sorgenti di WinGet all'avvio. Nella pagina Aggiornamenti CoffeeBreak compare con la sorgente "WinGet: itdevcon".

- Tasto destro, "Salta questa versione": ignora la 1.2.0 ma non le successive.
- Tasto destro, "Opzioni di aggiornamento", "Aggiorna automaticamente questo pacchetto". Funziona solo con la manutenzione pianificata "Installa gli aggiornamenti disponibili" attiva e limitata ai pacchetti contrassegnati. Attivarla senza quel limite aggiorna tutti i pacchetti del PC.
- Pagina Raccolte pacchetti: apri `demo/itdevcon.ubundle` e installa i tre pacchetti in un colpo.

Le stesse operazioni da script, con la CLI `uniget` che parla con UniGetUI aperto:

```
uniget package updates --manager winget
uniget package ignored add --id AlessioMolinaro.CoffeeBreak --manager winget --version 1.2.0
uniget bundle import --path demo\itdevcon.ubundle
uniget bundle install
```
