---
id: windows-prereqs
title: Windows Prerequisites
sidebar_position: 2
---

# 🪟 Windows Setup — luaDev Prerequisites

This guide helps you prepare a Windows environment to build and develop with **luaDev**. Use the PowerShell script `luaDev-prereqs.ps1` to install all necessary tools.

---

## ⚡ Quick Start

```powershell
powershell -ExecutionPolicy Bypass -File luaDev/scripts/luaDev-prereqs.ps1 [--All] [--Minimal] [--DryRun]
````

| Flag        | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| `--All`     | Installs all core + extra tools (LSPs, Cppcheck, Make, etc.) |
| `--Minimal` | Installs only essential tools: Git, CMake, Python, Rust      |
| `--DryRun`  | Preview what would be installed, without making changes      |

> ✅ Windows 10/11 supported. PowerShell 7+ recommended.

---

## 🧰 Tools Installed

### ✅ Core Tools

* **Git** — Version control
* **CMake** — Build system
* **LLVM/Clang** — C/C++ compiler
* **Clangd** — C/C++ Language Server
* **Ninja** — Parallel build system
* **Python** — Python 3.13 or later
* **Rust** — via `rustup`
* **Perl** — via StrawberryPerl
* **direnv** — environment manager
* **git-cliff** — changelog generator

### 🧩 Extra Tools (via `--All`)

* **Cppcheck** — Static analysis
* **7-Zip** — Archiver tool
* **Make** — GNU Make
* **LuaLS** — Lua Language Server *(manual install fallback)*

---

## 📦 Installer Logic

The script uses [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) to install all required packages.

If you're missing WinGet, install it from the [official Microsoft Store link](https://aka.ms/winget-install).

> The script will skip tools that are already installed.

---

## 📁 Logs

Installation logs are saved to:

```
scripts/logs/luaDev-prereqs-YYYYMMDD-HHMMSS.log
```

Only the latest session log is kept.

---

## 🔄 Examples

Minimal toolchain:

```powershell
powershell -File luaDev/scripts/luaDev-prereqs.ps1 --Minimal
```

Install everything:

```powershell
powershell -File luaDev/scripts/luaDev-prereqs.ps1 --All
```

Dry run:

```powershell
powershell -File luaDev/scripts/luaDev-prereqs.ps1 --DryRun
```

---

## 🧪 Troubleshooting

* ❌ *"Command not found"* — Some tools failed to install. Check the log file.
* 🔐 *"Policy restriction"* — Bypass PowerShell policy with `-ExecutionPolicy Bypass`
* ⚠️ *Missing WinGet* — Download WinGet from the [Microsoft Store](https://aka.ms/winget-install)

---

## 📄 File Structure

```text
luaDev/
└── scripts/
    ├── logs/                    # Logs from setup
    └── luaDev-prereqs.ps1       # Windows installer script
```

---

Need a Linux/macOS setup instead? See [`linux-prereqs.md`](./linux-prereqs.md).




## 🛠️ Install `luaDev`

### 1. Clone the Repository

```bash
git clone https://github.com/hetfs/luaDev.git
cd luaDev/scripts
```

### 2. Install Toolchain Prerequisites

### 🪟 Windows (PowerShell 7+)

```powershell
./prereqs.ps1
```

### 🐧 Linux/macOS

```bash
./prereqs.sh
```

This installs compilers, Lua toolchains, language servers, and formatters.

---

### 3. Build Lua or LuaJIT

#### 🧱 Build Lua 5.4 with Clang

```powershell
./buildLua.ps1 `
  -Engines lua `
  -EngineVersions 5.4.8 `
  -Compiler clang `
  -BuildMode Release `
  -ExportReport markdown
```

#### ⚡ Build LuaJIT 2.1.0-beta3

```powershell
./buildLua.ps1 `
  -Engines luajit `
  -EngineVersions 2.1.0-beta3 `
  -Compiler clang `
  -ExportReport markdown
```

> 📁 Build logs are saved to `scripts/logs/*.md`

---

## 🔍 Verify the Installation

### 🧪 Check Installed Versions

```bash
lua -v      # e.g., Lua 5.4.8
luajit -v   # e.g., LuaJIT 2.1.0-beta3
```

---

### 🧪 Launch the Lua Prompt (REPL)

After installing Lua, you can use the REPL (Read-Eval-Print Loop) to interactively run Lua code.

### 🪟 Windows

1. Press `Win + R`, type `cmd`, and hit Enter
2. In the command prompt, type:

```powershell
lua
```

You’ll see:

```bash
Lua 5.4.8  Copyright (C) 1994–2025 Lua.org
>
```

### 🐧 macOS/Linux

1. Open your terminal
2. Type:

```bash
lua
```

---

### ✅ Try a Basic Test

Once inside the Lua prompt:

```lua
print("Lua works!")
print(_VERSION)
```

Expected output:

```
Lua works!
Lua 5.4
```

🔚 Exiting Lua

```lua
os.exit()
```

This is correct, but only works if the os library is available (which it is in the standard Lua interpreter). In some restricted environments (like embedded Lua), it might be disabled.
> 💡 The REPL is a great place to test small ideas and learn Lua incrementally.

---

## 🔒 Production-Grade Security

`luaDev` applies compiler hardening automatically:

```bash
-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2
```

✅ Logs are exported
✅ C module builds are supported
✅ LuaJIT FFI works out of the box

---

## 📦 Installing Lua Modules with LuaRocks

Use LuaRocks to install libraries like this:

```bash
luarocks install penlight
luarocks list
```

LuaRocks is auto-installed and integrated with every `luaDev` build.

---

 [🌐 luaDev GitHub](https://github.com/hetfs/luaDev)

