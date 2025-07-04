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
