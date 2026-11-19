# ITDevCon 2026 · WinGet e UniGetUI per le applicazioni Delphi

Il materiale del talk **"Basta con "AggiornamentiU.pas"! Usa WinGet e UniGetUI per distribuire le tue applicazioni Delphi"** di Alessio Molinaro, a [ITDevCon 2026](https://itdevcon.it/home/itdevcon-2026): Roma, 20 novembre 2026, Sala Kirk.

- **Slide**: [`docs/itdevcon-2026-slide.pdf`](docs/itdevcon-2026-slide.pdf), online dal 20 novembre
- **Fonti** citate nel talk: [`FONTI.md`](FONTI.md)
- **Rifare le demo** sul tuo PC: [`demo/README.md`](demo/README.md)
- **Installer** firmati di CoffeeBreak: [Releases](https://github.com/alexmoli97/coffeebreak/releases)

## CoffeeBreak, l'app delle demo

L'agenda di ITDevCon 2026, sala per sala, con il conto alla rovescia per il coffee break. È un'applicazione VCL scritta con Delphi 13 e non contiene una riga di codice di aggiornamento: installazione e aggiornamenti passano da WinGet.

Ogni versione cambia qualcosa che si vede da metà sala, così durante le demo si capisce subito che l'aggiornamento è arrivato:

| Versione | Cosa cambia |
|---|---|
| 1.0.0 | Stile chiaro, con i refusi dell'agenda del sito ("COFFE BREAK") |
| 1.1.0 | Stile scuro, refusi corretti, conto alla rovescia per il coffee break |
| 1.2.0 | Durante l'ultimo talk l'intestazione ringrazia chi è rimasto |
| 1.2.1 | Correzioni: vedi [`CHANGELOG.md`](CHANGELOG.md) |

## Cosa c'è nel repository

| Cartella | Contenuto |
|---|---|
| `src/`, `tests/` | L'app VCL e i test DUnitX del modello dell'agenda |
| `installer/` | Lo script Inno Setup, pronto per WinGet |
| `manifests/` | I manifest WinGet delle quattro versioni, nella struttura di `microsoft/winget-pkgs` |
| `build/` | Build, firma, release su GitHub e manifest, da WSL |
| `demo/` | Le istruzioni per rifare le demo e il bundle di UniGetUI |
| `.github/workflows/` | La PR su `microsoft/winget-pkgs` con `wingetcreate submit`; parte solo a mano |

## Le regole dell'installer

Le cinque regole del talk, applicate in `installer/CoffeeBreak.iss` e in `build/manifest.sh`:

1. **AppId fisso**: `{5B8DF55B-80F0-4CF5-ABCC-A745529C4B65}`. Windows registra l'app come `{5B8DF55B-80F0-4CF5-ABCC-A745529C4B65}_is1`, ed è il `ProductCode` con cui WinGet la riconosce.
2. **DisplayVersion uguale a PackageVersion**, altrimenti WinGet ripropone l'aggiornamento all'infinito.
3. **Un URL per versione, mai sovrascritto**: il manifest contiene lo SHA256 dell'installer.
4. **Installazione silenziosa**, senza messaggi che la blocchino.
5. **Per utente, senza UAC**, con la possibilità per l'IT di installare per tutta la macchina.

## Compilare

Da WSL, con Delphi 13, Inno Setup 6 e il Windows SDK installati su Windows. I loro path sono in cima a `build/build.sh`: adattali al tuo PC.

```
build/build.sh test          # test DUnitX
build/build.sh all 1.2.1     # test, app, firma, installer firmato
```

La firma usa il certificato dell'archivio `CurrentUser\My` indicato da `CODESIGN_THUMBPRINT`. Un certificato self-signed vale solo sul PC dove lo rendi attendibile: per distribuire davvero serve un certificato emesso da una CA o la firma cloud.

## Licenza

MIT, vedi [`LICENSE`](LICENSE).
