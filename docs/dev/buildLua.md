# 🛠️ `buildLua` Modular Build Roadmap

A modern, cross-platform, modular Lua build system part of the `luaDev` project. It compiles Lua versions from source with support for both **PowerShell** and **Bash**, ensuring clean automation and maintainability across operating systems.

---

## 📁 Folder Structure

```
luaDev/
├── LuaBinaries/                   # ✅ Output directory for built Lua versions
└── scripts/
    ├── buildLua.ps1               # ⚙️ Windows (PowerShell)
    ├── buildLua.sh                # 🐧 Linux/macOS (Bash)
    ├── luaDev-prereqs.ps1         # 📦 PowerShell prerequisites
    ├── luaDev-prereqs.sh          # 📦 Bash prerequisites
    ├── logs/                      # 📂 Logs + build manifest
    │   └── manifest.json
    └── modules/                   # 🔧 Modular script logic
        ├── build-lua.psm1
        ├── build-luajit.psm1
        ├── downloader.psm1
        ├── environment.psm1
        ├── logging.psm1
        ├── manifest.psm1
        ├── versioning.psm1
```

---

## 🚀 CLI Usage (`buildLua.ps1`)

```powershell
.\buildLua.ps1 -Versions "5.1.5,5.4.8" -Engines "lua,luajit"
.\buildLua.ps1 -V 54 -Engines "lua"           # shorthand for 5.4.0
.\buildLua.ps1 -V 51 -Engines "luajit"        # LuaJIT only
```

### ✅ Parameters:

| Flag | Example | Description |
| --- | --- | --- |
| `-Versions` | `"5.1.5,5.4.8"` | Exact versions to build (comma-separated) |
| `-V` | `51` or `54` | Shorthand for versions like `5.1.0`, `5.4.0` |
| `-Engines` | `"lua"`, `"luajit"` or `"lua,luajit"` | Which engine(s) to build |
| `-Force` |     | Force rebuilds and overwrite logs |

---

## 🧱 Modular Structure

All modules live in `scripts/modules/`:

| Module | Purpose |
| --- | --- |
| `build-lua.psm1` | Build standard Lua source |
| `build-luajit.psm1` | Build LuaJIT |
| `downloader.psm1` | Download Lua sources |
| `environment.psm1` | Check for tools (e.g., make, tar) |
| `logging.psm1` | Unified logging with color + timestamps |
| `manifest.psm1` | Write manifest.json with built versions |
| `versioning.psm1` | Parse version shorthands, detect latest |

---

## ⚙️ Sample Entry Point (`buildLua.ps1`)

```powershell
$ModulePath = Join-Path $PSScriptRoot "modules"
$LogPath    = Join-Path $PSScriptRoot "logs"

Import-Module "$ModulePath/logging.psm1"
Import-Module "$ModulePath/versioning.psm1"
Import-Module "$ModulePath/environment.psm1"
Import-Module "$ModulePath/downloader.psm1"
Import-Module "$ModulePath/build-lua.psm1"
Import-Module "$ModulePath/build-luajit.psm1"
Import-Module "$ModulePath/manifest.psm1"

# CLI parameter parsing and build orchestration
```

---

## 🧩 Example: `versioning.psm1`

```powershell
function Parse-VersionShorthand {
    param ([string]$short)
    switch ($short.Length) {
        3 { return "$($short[0]).$($short[1]).$($short[2])" }
        2 { return "$($short[0]).$($short[1]).0" }
        default { return $short }
    }
}

function Get-LatestLuaVersions {
    return @("5.1.5", "5.2.4", "5.3.6", "5.4.8")
}
Export-ModuleMember -Function Parse-VersionShorthand, Get-LatestLuaVersions
```

---

## 📝 Manifest Format

📄 `scripts/logs/manifest.json` (auto-generated):

```json
{
  "versions": [ "5.1.5", "5.4.8" ],
  "generated": "2025-06-23T21:10:00"
}
```

---

## 🔮 Roadmap & Future Work

| Feature | Status |
| --- | --- |
| Modularized `buildLua.ps1` | ✅ Done |
| `-Engines` param | ✅ Done |
| LuaJIT support | ✅ Done |
| Manifest export | ✅ Done |
| Bash parity (`buildLua.sh`) | 🚧 In progress |
| CI-friendly logs & diff | 🔜 Planned |
| Docusaurus docs | ✅ In place |

---

## 📘 Docs Tip (Docusaurus)

- Add this to `/docs/dev/buildLua-roadmap.md`
  
- Add to Docusaurus sidebar as: 
  `Build Lua Setup (PowerShell + Bash)`
