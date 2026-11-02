# win-anancore — Windows Portable Installer voor AnanCore

Bouwt [AnanCore](https://github.com/ChasingCoffee/AnanCore) (Zeus Standalone voor ANAN G2/HPSDR radio's) als een portable Windows distributie.

Het script cloned de broncode, bouwt de .NET 10 backend en de Vite/React frontend, en zet alles klaar in een `dist\` map naast het script. Die map is portable: zippen en doorsturen.

---

## Vereisten

| Software | Versie | Download |
|---|---|---|
| **Git** | 2.x | https://git-scm.com/download/win |
| **.NET SDK** | 10.0 | https://dotnet.microsoft.com/download/dotnet/10.0 |
| **Node.js** | 20 LTS+ | https://nodejs.org/ |

---

## Gebruik

```powershell
git clone https://github.com/pe5jw/win-anancore.git
cd win-anancore
.\Install-AnanCore.ps1
```

Na afloop staat de distributie in `dist\`:

```
dist\
├── OpenhpsdrZeus.exe     ← de server
├── *.dll                 ← .NET runtime
├── wwwroot\              ← React/Vite frontend
├── Start-AnanCore.bat    ← dubbelklik om te starten
└── version.json          ← build info
```

Start via `dist\Start-AnanCore.bat`, open browser op `http://localhost:6060`.

---

## Opties

```powershell
# Andere branch
.\Install-AnanCore.ps1 -Branch main

# Alleen clonen, niet bouwen
.\Install-AnanCore.ps1 -SkipBuild

# Updaten: script opnieuw draaien, dist\ wordt overschreven
.\Install-AnanCore.ps1
```

---

## PowerShell Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

---

## Licentie

[AnanCore](https://github.com/ChasingCoffee/AnanCore) — GPL-2.0-or-later.  
Dit installer script — MIT.
