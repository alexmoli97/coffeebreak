# Fonti

Le fonti citate nel talk "Basta con AggiornamentiU.pas! Usa WinGet e UniGetUI per distribuire le tue applicazioni Delphi" (ITDevCon 2026), nell'ordine delle slide. Link controllati il 16 novembre 2026.

## WinGet

- [Windows Package Manager Preview](https://devblogs.microsoft.com/commandline/windows-package-manager-preview/), blog Microsoft, maggio 2020: la prima anteprima pubblica.
- [Windows Package Manager 1.0](https://devblogs.microsoft.com/commandline/windows-package-manager-1-0/), blog Microsoft, maggio 2021: la versione 1.0, distribuita con App Installer.
- [Use WinGet to install and manage applications](https://learn.microsoft.com/en-us/windows/package-manager/winget/), Microsoft Learn: requisiti (Windows 10 1809 e successivi, Windows 11, Windows Server 2025) e comandi.
- [winget-cli v1.29.380](https://github.com/microsoft/winget-cli/releases/tag/v1.29.380): la versione usata nelle demo.
- [Release di winget-cli](https://github.com/microsoft/winget-cli/releases) e il modulo PowerShell [Microsoft.WinGet.Client](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client): per i PC senza Microsoft Store.
- [winget upgrade](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade), Microsoft Learn.

## Installer

- [Documentazione di Inno Setup](https://jrsoftware.org/ishelp/).
- [CloseApplications](https://jrsoftware.org/ishelp/topic_setup_closeapplications.htm) e [PrivilegesRequiredOverridesAllowed](https://jrsoftware.org/ishelp/topic_setup_privilegesrequiredoverridesallowed.htm), Inno Setup.
- [Sezioni [Run] e [UninstallRun]](https://jrsoftware.org/ishelp/topic_runsection.htm), Inno Setup.
- [Restart Manager](https://learn.microsoft.com/en-us/windows/win32/rstmgr/restart-manager-portal) e [RegisterApplicationRestart](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-registerapplicationrestart), Microsoft Learn.

## Firma del codice

- [SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool), Microsoft Learn.
- [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161): il protocollo di timestamp.
- [Certificati di firma del codice validi al massimo 460 giorni](https://www.digicert.com/blog/understanding-the-new-code-signing-certificate-validity-change), DigiCert.
- [Azure Artifact Signing](https://azure.microsoft.com/pricing/details/artifact-signing/): la firma cloud di Microsoft.
- [Azure Artifact Signing generalmente disponibile: prezzi e chi può usarlo](https://www.devclass.com/security/2026/01/14/code-signing-windows-apps-may-be-easier-and-more-secure-with-new-azure-artifact-service/4079554), DevClass, gennaio 2026.
- [Prezzi dei certificati OV di DigiCert e Sectigo nel 2026](https://sslinsights.com/digicert-vs-sectigo-code-signing/), SSL Insights (prezzi dei rivenditori, indicativi).
- [Chiave su hardware per i certificati di firma dal 1° giugno 2023](https://cpl.thalesgroup.com/blog/encryption/ca-b-forum-code-signing-requirements-private-keys), Thales.

## Manifest e pubblicazione

- [Create your package manifest](https://learn.microsoft.com/en-us/windows/package-manager/package/manifest), Microsoft Learn: i tre file del manifest.
- [winget validate](https://learn.microsoft.com/en-us/windows/package-manager/winget/validate), Microsoft Learn.
- [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs): il catalogo pubblico.
- [microsoft/winget-create](https://github.com/microsoft/winget-create): `wingetcreate new` e `wingetcreate submit`.

## Sorgenti private

- [winget source](https://learn.microsoft.com/en-us/windows/package-manager/winget/source), Microsoft Learn: `source add` e `--trust-level`.
- [microsoft/winget-cli-restsource](https://github.com/microsoft/winget-cli-restsource): la sorgente REST di Microsoft, su Azure.
- [jantari/rewinged](https://github.com/jantari/rewinged): la sorgente REST usata nelle demo.

## UniGetUI

- [Devolutions/UniGetUI](https://github.com/Devolutions/UniGetUI): codice, licenza MIT, stelle.
- [UniGetUI enters its next chapter with Devolutions](https://devolutions.net/blog/2026/03/unigetui-enters-its-next-chapter-with-devolutions/), blog Devolutions, marzo 2026.
- [CLI di UniGetUI](https://github.com/Devolutions/UniGetUI/blob/main/docs/CLI.md): i comandi `uniget`.
