---
id: what-new
title: What's New
sidebar_label: 📢 What's New
sidebar_position: 3
---

# What’s New in luaDev 🆕

## 🧱 Build System Modularized
- `buildLua.ps1` has been split into clean modules under `scripts/modules/`
- Logging, version parsing, downloading, and building are all modular!

## 🛠️ Dual CLI Support
- PowerShell & Bash support for `buildLua` and `luaDev-prereqs`

## 📦 Lua Binaries Manifest
- JSON manifest added at `scripts/logs/manifest.json`
- Example: `{ "versions": ["5.1.5", "5.4.8"] }`

## 📃 Changelog Tracking with git-cliff
- Full `CHANGELOG.md` generated from commits
- `cliff.toml` at project root controls formatting

## Stylua
- Stylua.toml a project root `luaDev` controls lua formatting
