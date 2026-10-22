; Installer di CoffeeBreak. Compilare con: ISCC /DAppVersion=1.2.3 CoffeeBreak.iss (lo fa build/build.sh)
#ifndef AppVersion
  #error Definire AppVersion, es. /DAppVersion=1.0.0
#endif

[Setup]
; AppId fisso per sempre: è la chiave con cui Windows, e quindi WinGet, riconosce l'app installata ({AppId}_is1)
AppId={{5B8DF55B-80F0-4CF5-ABCC-A745529C4B65}
AppName=CoffeeBreak
AppVersion={#AppVersion}
AppVerName=CoffeeBreak {#AppVersion}
AppPublisher=Alessio Molinaro
AppPublisherURL=https://github.com/alexmoli97/coffeebreak
AppSupportURL=https://github.com/alexmoli97/coffeebreak/issues
AppUpdatesURL=https://github.com/alexmoli97/coffeebreak/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\CoffeeBreak
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\build\out
OutputBaseFilename=CoffeeBreak-{#AppVersion}-x64-setup
SetupIconFile=..\res\CoffeeBreak.ico
UninstallDisplayName=CoffeeBreak
UninstallDisplayIcon={app}\CoffeeBreak.exe
CloseApplications=yes
RestartApplications=yes
WizardStyle=modern
Compression=lzma2
SolidCompression=yes

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Files]
Source: "..\build\out\CoffeeBreak.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\CoffeeBreak"; Filename: "{app}\CoffeeBreak.exe"

[Run]
Filename: "{app}\CoffeeBreak.exe"; Description: "{cm:LaunchProgram,CoffeeBreak}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; a differenza del setup, il disinstallatore non chiude l'app aperta e lascerebbe l'exe bloccato nella cartella
Filename: "{sys}\taskkill.exe"; Parameters: "/IM CoffeeBreak.exe /F"; Flags: runhidden; RunOnceId: "ChiudiCoffeeBreak"
