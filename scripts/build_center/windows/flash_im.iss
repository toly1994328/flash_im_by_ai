#ifndef Version
  #define Version "0.0.0"
#endif
#define MyAppName "闪讯"
#define MyAppExeName "flash_im.exe"
#define ReleaseDir "..\..\..\client\build\windows\x64\runner\Release"
#define IconFile "..\..\..\client\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{F1A5H-1M00-0027-SCAN-L0G1N000000}}
AppName={#MyAppName}
AppVersion={#Version}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dest\windows
OutputBaseFilename=flash_im
SetupIconFile={#IconFile}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "{#ReleaseDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动闪讯"; Flags: nowait postinstall skipifsilent
