# win-anancore — Windows Portable Installer for AnanCore

This repository contains a PowerShell script that builds [AnanCore](https://github.com/ChasingCoffee/AnanCore) (Zeus Standalone for ANAN G2 / HPSDR radios) as a portable Windows 11 zip distribution.

> **⚠️ Experimental — not officially supported**
> This Windows build is not supported by the AnanCore project, ANAN, or any other party. It is a personal experiment. If you run into installation or build issues, please [open a GitHub issue](https://github.com/pe5jw/win-anancore/issues) in this repository — do not report them upstream to AnanCore.

> **🛠️ Hobby project**
> This project is maintained in spare time and only as long as there is interest and time for it. There are no guarantees on response times, update frequency, or long-term support.

---

## How it works

The script clones the AnanCore source, builds the .NET 10 backend and the Vite/React frontend, and packages everything into a `distro\` folder next to the script. That folder is self-contained and portable: zip it up and copy it anywhere.

Automated releases are published to [Releases](https://github.com/pe5jw/win-anancore/releases) whenever a new AnanCore upstream release is detected.

---

## Requirements (build machine)

| Software | Version | Download |
|---|---|---|
| **Git** | 2.x | https://git-scm.com/download/win |
| **.NET SDK** | 10.0 | https://dotnet.microsoft.com/download/dotnet/10.0 |
| **Node.js** | 20 LTS+ | https://nodejs.org/ |

The built `distro\` is self-contained — no .NET or Node.js needed on the machine that runs it.

---

## Usage

```powershell
git clone https://github.com/pe5jw/win-anancore.git
cd win-anancore
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Install-AnanCore.ps1
```

After the build, the distribution is in `distro\`:

```
distro\
├── OpenhpsdrZeus.exe     ← the server
├── *.dll                 ← .NET runtime (self-contained)
├── wwwroot\              ← React/Vite frontend
├── Start-AnanCore.bat    ← double-click to start
└── version.json          ← build info
```

Start via `distro\Start-AnanCore.bat`, then open your browser at `http://localhost:6060`.

---

## Options

```powershell
# Use a different branch
.\Install-AnanCore.ps1 -Branch main

# Clone only, skip build
.\Install-AnanCore.ps1 -SkipBuild

# Update: re-run the script, distro\ will be rebuilt
.\Install-AnanCore.ps1
```

---

## License

[AnanCore](https://github.com/ChasingCoffee/AnanCore) — GPL-2.0-or-later.
This installer script — MIT.
