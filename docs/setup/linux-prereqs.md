---
id: linux-prereqs
title: Linux Prerequisites
sidebar_position: 2
---

## 🐧 Linux Setup — luaDev Prerequisites

This guide walks you through setting up your Linux development environment for the **luaDev** build system. It covers required tools, package managers, and OS-specific tips. The script `luaDev-prereqs.sh` automates most of this process.

---

### 📦 Quick Start

```bash
bash luaDev/scripts/luaDev-prereqs.sh [--all] [--minimal] [--dry-run]
```

| Flag        | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| `--all`     | Installs all core + extra tools (LSPs, Cppcheck, Make, etc.) |
| `--minimal` | Installs only essential tools: Git, CMake, Python, Rust      |
| `--dry-run` | Preview what would be installed, without making changes      |

---

### 🧰 Tools Installed

#### ✅ Core Tools (default)

* `git` — Version control
* `cmake` — Build automation
* `clang` / `clangd` — C compiler + LSP
* `ninja` — Build system
* `python` — Scripting and virtualenv
* `rustup` + `rustc` — Rust compiler & toolchain
* `perl` — Required by some Lua utilities
* `direnv` — Directory-based environment management
* `git-cliff` — Changelog generator *(AUR-only on Arch)*

#### 🧩 Extra Tools (`--all`)

* `cppcheck` — Static analysis
* `make` — GNU Make
* `p7zip` — 7-Zip CLI tool
* `lua-language-server` — Lua LSP *(AUR-only on Arch)*

---

### 🖥️ Supported Platforms

| OS / Distro   | Package Manager         | Notes                               |
| ------------- | ----------------------- | ----------------------------------- |
| Arch Linux    | `pacman` + `yay`/`paru` | AUR helper required for extra tools |
| Ubuntu/Debian | `apt`                   | Fully supported                     |
| Fedora        | `dnf`                   | Fully supported                     |
| macOS         | `brew`                  | Fully supported                     |
| WSL (Linux)   | any supported manager   | Works if base distro is supported   |

---

### 🗂️ Logs

Each run logs to:

```bash
scripts/logs/luaDev-prereqs-YYYYMMDD-HHMMSS.log
```

Only the current session log is preserved.

---

### 🔁 Example Workflows

Minimal dev setup:

```bash
bash luaDev-prereqs.sh --minimal
```

Full toolchain install:

```bash
bash luaDev-prereqs.sh --all
```

Dry run (CI-safe):

```bash
bash luaDev-prereqs.sh --dry-run
```

---

### 🙋 Troubleshooting

* ❌ *"Command not found"*
  → A required package or AUR helper may be missing. Try installing `yay` or `paru`.

* 🐢 *Slow installs?*
  → On Arch, update mirrors: `sudo pacman-mirrors --fasttrack`

* 💥 *Permission denied?*
  → Run the script with `sudo` if system-level install fails.

---

### 📁 Location

```
luaDev/
└── scripts/
    ├── logs/                   # Logs from setup
    └── luaDev-prereqs.sh       # Linux/macOS installer script
```

---
