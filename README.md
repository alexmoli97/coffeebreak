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
