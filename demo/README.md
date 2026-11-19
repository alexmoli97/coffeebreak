# Rifare le demo

Le quattro demo del talk "Basta con AggiornamentiU.pas! Usa WinGet e UniGetUI per distribuire le tue applicazioni Delphi" (ITDevCon 2026), da rifare sul tuo PC. Servono Windows 10 o 11 con WinGet; per D3 anche WSL o un altro modo di generare un certificato con `openssl`.

Per rivedere CoffeeBreak a un'ora qualsiasi della conferenza c'è l'opzione `--now`, per esempio `CoffeeBreak.exe --now=2026-11-20T17:20`.

## D1: WinGet da utente

```
winget search PuTTY -s winget
winget show --id PuTTY.PuTTY -e -s winget
winget install --id PuTTY.PuTTY -e -s winget --version 0.84.0.0 --accept-package-agreements
winget list --id PuTTY.PuTTY -e
winget upgrade --id PuTTY.PuTTY -e -s winget --accept-package-agreements
```

La 0.84.0.0 si installa apposta: così `winget list` mostra la versione nuova nella colonna `Available` e `winget upgrade` ha un aggiornamento vero da fare. PuTTY si installa per tutto il PC, quindi installazione e aggiornamento chiedono la conferma UAC.

Con più sorgenti conviene indicare quella giusta. Con la sorgente rewinged della D3 attiva, `winget install` e `winget upgrade` di un pacchetto che rewinged non ha falliscono con `0x8a150044`: rewinged risponde 404 alla richiesta del manifest e WinGet lo legge come endpoint mancante.

## D2: il primo manifest

```
winget settings --enable LocalManifestFiles          # da amministratore
wingetcreate new https://github.com/alexmoli97/coffeebreak/releases/download/v1.0.0/CoffeeBreak-1.0.0-x64-setup.exe
winget validate --manifest <cartella del manifest>
winget install --manifest <cartella del manifest>
```

Alla domanda finale di `wingetcreate new`, se inviare il manifest a `winget-pkgs`, rispondi No. L'installer arriva da Internet ed è firmato con un certificato che Windows non conosce: SmartScreen può fermarlo con "PC protetto da Windows".

## D3: una sorgente privata

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

4. Copia in `packages` i tre file di [`manifests/a/AlessioMolinaro/CoffeeBreak/1.0.0`](../manifests/a/AlessioMolinaro/CoffeeBreak/1.0.0): rewinged li serve subito. `winget install --id AlessioMolinaro.CoffeeBreak -s itdevcon`, poi copia la 1.1.0 e `winget upgrade --id AlessioMolinaro.CoffeeBreak`.

## D4: UniGetUI

Avvia UniGetUI dopo aver aggiunto la sorgente: legge le sorgenti di WinGet all'avvio. Nella pagina Aggiornamenti CoffeeBreak compare con la sorgente "WinGet: itdevcon".

- Tasto destro, "Salta questa versione": ignora la 1.2.0 ma non le successive.
- Tasto destro, "Opzioni di aggiornamento", "Aggiorna automaticamente questo pacchetto". Funziona solo con la manutenzione pianificata "Installa gli aggiornamenti disponibili" attiva e limitata ai pacchetti contrassegnati. Attivarla senza quel limite aggiorna tutti i pacchetti del PC.
- Pagina Raccolte pacchetti: apri `itdevcon.ubundle` (in questa cartella) e installa i due pacchetti (CoffeeBreak e WinMerge) in un colpo.

Le stesse operazioni da script, con la CLI `uniget` che parla con UniGetUI aperto:

```
uniget package updates --manager winget
uniget package ignored add --id AlessioMolinaro.CoffeeBreak --manager winget --version 1.2.0
uniget bundle import --path itdevcon.ubundle
uniget bundle install
```
