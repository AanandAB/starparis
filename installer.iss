; Star Paris Graphic — Windows installer (cloud-auth SaaS variant).
;
; The app authenticates against the Cloudflare Worker, so there is NO
; PC-lock, license key or activation screen here — subscription/access is
; enforced server-side. Per-user install (no UAC prompt) into
; %LOCALAPPDATA%\Programs\Star Paris Graphic.
;
; Build: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss

#define MyAppName "Star Paris Graphic"
#define MyAppVersion "0.1.1"
#define MyAppExeName "shop_app.exe"

[Setup]
AppId={{6B8A2F3C-9E1D-4A7B-8C5E-2F3D6B8A1C4E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Star Paris Graphic LLC
AppPublisherURL=https://starparis-api.theblacklightstudio.workers.dev
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=installer
OutputBaseFilename=StarParis_Setup_v{#MyAppVersion}
SetupIconFile=apps\shop_app\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "apps\shop_app\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Wildcard catches every plugin DLL + the bundled VC++ runtime DLLs.
Source: "apps\shop_app\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "apps\shop_app\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
