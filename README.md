# win-anancore — Windows Portable Installer voor AnanCore

Automatische Windows installer voor [AnanCore](https://github.com/ChasingCoffee/AnanCore) (Zeus Standalone voor ANAN G2/HPSDR radio's).

Het script cloned de broncode, bouwt de .NET 10 backend en de Vite/React frontend, en maakt een portable installatie die je gewoon kunt dubbelklikken.

---

## Vereisten

| Software | Minimale versie | Download |
|---|---|---|
| **Git** | 2.x | https://git-scm.com/download/win |
| **.NET SDK** | 10.0 | https://dotnet.microsoft.com/download/dotnet/10.0 |
| **Node.js** | 20 LTS | https://nodejs.org/ |

---

## Snel starten

```powershell
# 1. Download dit script
git clone https://github.com/joeri-noppus/win-anancore.git
cd win-anancore

# 2. Voer het installer script uit
# (Als PowerShell scripts geblokkeerd zijn: zie "Execution Policy" hieronder)
.\Install-AnanCore.ps1
```

Na afloop:

- Dubbelklik `AnanCore\AnanCore.bat` om te starten
- Of `AnanCore\AnanCore-OpenBrowser.bat` om te starten én de browser te openen op `http://localhost:6060`

---

## Opties

```powershell
# Andere installatiemap
.\Install-AnanCore.ps1 -InstallDir "C:\Radio\AnanCore"

# Andere branch
.\Install-AnanCore.ps1 -Branch main

# Alleen clonen, niet bouwen
.\Install-AnanCore.ps1 -SkipBuild

# Updaten naar de laatste versie
.\AnanCore\Update-AnanCore.ps1
```

---

## PowerShell Execution Policy

Als je de foutmelding `running scripts is disabled` krijgt:

```powershell
# Tijdelijk toestaan voor deze sessie
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Of: rechtermuisklik op het .ps1 bestand → "Uitvoeren met PowerShell"
```

---

## Wat het script doet

1. Controleert of Git, .NET 10 SDK en Node.js aanwezig zijn
2. Cloned `ChasingCoffee/AnanCore` (branch `freedv-in-core`) met submodules
3. Bouwt de .NET backend als self-contained Windows x64 executable
4. Installeert npm dependencies en bouwt de Vite frontend
5. Kopieert de frontend (`dist/`) naar `wwwroot/` naast de backend
6. Maakt launcher `.bat` bestanden aan
7. Slaat versie-info op in `version.json`

De installatie is volledig portable: verplaats de map naar een andere computer en het werkt.

---

## Mapstructuur na installatie

```
AnanCore\
├── AnanCore.bat                  ← dubbelklik om te starten
├── AnanCore-OpenBrowser.bat      ← start + opent browser
├── Update-AnanCore.ps1           ← update naar nieuwste versie
├── version.json                  ← geïnstalleerde versie info
├── src\                          ← geclonede broncode
│   └── (AnanCore git repo)
└── release\
    └── backend\
        ├── OpenhpsdrZeus.exe     ← de server executable
        ├── *.dll                 ← .NET runtime bestanden
        └── wwwroot\              ← gebouwde frontend (React/Vite)
```

---

## Handmatig starten (zonder .bat)

```powershell
cd AnanCore\release\backend
.\OpenhpsdrZeus.exe
# Open browser: http://localhost:6060
```

---

## Licentie

Zie [AnanCore LICENSE](https://github.com/ChasingCoffee/AnanCore/blob/freedv-in-core/LICENSE) — GPL-2.0-or-later.

Dit installer script zelf is MIT gelicenseerd.
