; Clipboard Push Win32 - Inno Setup Script
; Requires: Inno Setup 6.x (https://jrsoftware.org/isinfo.php)
;
; Build command (from project root):
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" scripts\installer.iss
;
; Output: build\ClipboardPushWin32-Setup.exe

#define AppName "Clipboard Push"
#define AppVersion "4.7.1"
#define AppPublisher "ClipboardPush"
#define AppURL "https://clipboardpush.com"
#define AppExeName "ClipboardPushWin32.exe"
#define AppExeSrc "..\build\ClipboardPushWin32.exe"

[Setup]
AppId={{B3A2F1C4-8E7D-4A5B-9C6E-1D2F3A4B5C6D}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
; Install to user's LocalAppData — no admin/UAC needed, config.json writes alongside EXE
DefaultDirName={localappdata}\{#AppName}
DefaultGroupName={#AppName}
; No admin required
PrivilegesRequired=lowest
; Output
OutputDir=..\build
OutputBaseFilename=ClipboardPushWin32-Setup
SetupIconFile=..\src\resources\app_icon.ico
; Compression
Compression=lzma2
SolidCompression=yes
; Uninstall
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
; Wizard appearance
WizardStyle=modern
; Minimum Windows version: Windows 10
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: {#AppExeSrc}; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu
Name: "{group}\{#AppName}";         Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
; Desktop (optional task)
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Launch after install
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Kill the process before uninstall so the EXE can be deleted
Filename: "taskkill.exe"; Parameters: "/f /im {#AppExeName}"; Flags: runhidden; RunOnceId: "KillApp"

[UninstallDelete]
; Remove the EXE (config.json is user data — intentionally left behind)
Type: files; Name: "{app}\{#AppExeName}"
