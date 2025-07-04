---
id: build-system
title: 🔧 luaDev Build System
sidebar_position: 2
---

# 🔧 luaDev Build System

The `luaDev` build system is a **modular PowerShell-based pipeline** for downloading, configuring, and compiling Lua and LuaJIT versions using CMake and injected templates. It features structured logging, parallel builds, manifest output, and export to Markdown.

### ✅ Supported Features:
- Structured logging and Markdown export  
- Dry run simulation (`-DryRun`)  
- Parallel builds (`-MaxParallelJobs`)  
- Strict deterministic module loading  
- CMakeLists injection by version/engine  

---

## 📁 Project Layout

```text
luaDev/
├── scripts/
│   ├── buildLua.ps1                  # 🚀 Main entry script
│   └── modules/                      # 🧩 Core build logic modules
│       ├── globals.psm1              # 🌐 Shared paths/constants
│       ├── logging.psm1              # 📢 Logging helpers
│       ├── loader.psm1               # 📦 Deterministic module loading
│       ├── environment.psm1          # 🧭 Toolchain/platform detection
│       ├── versioning.psm1           # 🔢 Version parsing/validation
│       ├── downloader.psm1           # ⬇️ Fetches Lua/LuaJIT sources
│       ├── cmake.psm1                # 🛠️ Injects version-specific CMakeLists
│       ├── luaBuilder.psm1           # 🔧 Lua build logic (via CMake)
│       ├── luajitBuilder.psm1        # 🔧 LuaJIT-specific builder
│       ├── manifest.psm1             # 🧾 Manifest generator (.json/.md)
│       ├── export.psm1               # 📝 Markdown log writer (basic)
│       └── logexporter.psm1          # 📋 Docusaurus-style Markdown export
├── templates/
│   └── cmake/
│       ├── CMakeLists.lua.default.txt
│       ├── CMakeLists.5.1.txt ... 5.4.txt
│       └── CMakeLists.luajit.txt     # 💡 LuaJIT override
├── logs/                             # 🧾 Build logs (raw and Markdown)
└── LuaBinaries/                      # 📦 Final output binaries
````

---

## ⚙️ Script Entry: `buildLua.ps1`

This is the entry point to the build system. It:

* Parses CLI arguments (`-Engines`, `-Versions`, `--Clean`, etc.)
* Loads modules in strict dependency order
* Invokes Lua or LuaJIT builds using generated `CMakeLists.txt`
* Outputs manifest and themed Markdown logs

### Example

```powershell
.\buildLua.ps1 `
  -Engines lua,luajit `
  -Versions 5.4.8,2.1.0 `
  -BuildType static `
  -Compiler clang `
  -Clean -DryRun
```

---

## 🧱 CMakeLists Injection Strategy

The `cmake.psm1` module handles intelligent CMakeLists generation by engine/version:

* Starts with a base: `CMakeLists.lua.default.txt`
* Optionally injects:

  * `CMakeLists.5.X.txt` (version-specific)
  * `CMakeLists.luajit.txt` (engine-specific)
* Performs keyword substitutions like:

  * `${LUA_VERSION}`, `${LUA_ENGINE}`
  * `@LIBRARY_TYPE@`, `@GC64_FLAG@`

---

## 🧩 Key Modules

### 🧠 `loader.psm1`

* Loads all other modules in strict sequence
* Ensures no circular dependency issues

### 🔧 `luaBuilder.psm1` / `luajitBuilder.psm1`

* Core logic for building Lua or LuaJIT
* Calls into `cmake.psm1` and invokes CMake
* Supports `DryRun` mode and post-build logging

### 📝 `logexporter.psm1`

* Groups logs by engine/version
* Outputs Docusaurus-compatible Markdown with:

  * ✅ Success
  * ⚠️ Warnings
  * ❌ Errors
  * 📄 Misc

---

## 📦 Output Paths

### 🔨 Binaries

```text
luaDev/LuaBinaries/
├── lua/
│   ├── 5.4.8/
│   └── 5.3.6/
└── luajit/
    └── 2.1.0/
```

### 📝 Logs

```text
logs/build/YYYY-MM-DDTHH-MM-SS/
├── Lua/
│   └── 5.4.8.md
└── LuaJIT/
    └── 2.1.0.md
```

### 🧾 Manifest

* `manifest.json` — for tooling
* `manifest.md` — for human-readable docs

---

## 🔁 Module Load Order

Strict loading ensures reproducibility:

| 🔢     | Module               | Purpose                      |
| ------ | -------------------- | ---------------------------- |
| 1️⃣    | `globals.psm1`       | Constants, root paths        |
| 2️⃣    | `logging.psm1`       | Log output support           |
| 3️⃣    | `loader.psm1`        | Deterministic module loading |
| 4️⃣    | `environment.psm1`   | Platform/compiler detection  |
| 5️⃣    | `versioning.psm1`    | Validate versions            |
| 6️⃣    | `downloader.psm1`    | Fetch and unpack source      |
| 7️⃣    | `cmake.psm1`         | CMakeLists injection         |
| 8️⃣    | `luaBuilder.psm1`    | Lua build logic              |
| 9️⃣    | `luajitBuilder.psm1` | LuaJIT builder               |
| 🔟     | `manifest.psm1`      | Save build result manifest   |
| 1️⃣1️⃣ | `export.psm1`        | Markdown log export          |
| 1️⃣2️⃣ | `logexporter.psm1`   | Grouped themed logs          |

---

## 🚀 Roadmap & Enhancements

* ✅ Parallel build support
* ✅ Dry-run simulation
* ✅ Per-version config overrides
* 🔜 Cross-compilation (ARM, MIPS, etc.)
* 🔜 GitHub Actions integration
* 🔜 GUI build dashboard

---

> 💡 This system is cleanly structured, easy to extend, and ideal for multi-version Lua and LuaJIT compilation in modern dev environments.
