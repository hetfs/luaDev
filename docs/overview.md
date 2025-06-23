---
id: overview
title: Overview 
sidebar_label: Overview
sidebar_position: 2
---




## 🧱 Core Toolchain

| Tool | Purpose |
| --- | --- |
| LLVM/Clang | Compile Lua and native code |
| Lua/LuaJIT | Core scripting engine |
| LuaRocks | Package manager (from source) |
| Busted | Unit testing framework |
| Luacheck | Linter & static analysis |
| Stylua | Code formatting |
| Luadoc | Documentation generation |
| CMake/Make | Native module builds |
| clangd | C/C++ language server |
| Cargo | Rust FFI support |
| Git | Version control |
| Perl | Auxiliary build tooling |

---

## 🧠 Editor Integration

## VSCode

Install extensions:

- `Lua Language Server` (sumneko or LuaLS)
- `Lua Debug Adapter`
- `Clangd` (for native code support)

```jsonc
// settings.json example
{
  "Lua.workspace.library": ["${workspaceFolder}"],
  "Lua.diagnostics.enable": true,
  "Lua.format.enable": true
}
```

## Neovim

Recommended plugins (via `lazy.nvim`, `packer`, or `folke/lazy`):

- `lua-language-server`
  
- `null-ls` with `stylua`, `luacheck`
  
- Test runners with `telescope`, `dispatch`, or `neotest`
  

---

## ✅ Setup Checklist (Cross-Platform)

This project supports Windows, Linux, and macOS environments. Use the list below to verify your development environment is ready:

| Component | Status / Notes |
| --- | --- |
| **LLVM + Clang** | ✅ Installed via `winget` (Windows), `brew` (macOS), or `apt` (Linux) |
| **Lua (built from source)** | ✅ Compiled and added to system `PATH` |
| **LuaRocks** | ✅ Installed and configured |
| **Busted + Luacheck** | ✅ Installed using `luarocks install` |
| **Neovim** | ✅ Configured with Lua development settings |
| **VS Code Extensions** | ✅ Recommended plugins installed (e.g., Lua, Luacheck, etc.) |
| **Automation Scripts** | ⚙️ Customizable per OS: `.ps1`, `.sh`, `.envrc` |

> 💡 **Tip**: You can automate environment setup using shell profiles (`.bashrc`, `.zshrc`, PowerShell `$PROFILE`) or `direnv` via `.envrc`.

For detailed instructions, see the [`docs/setup.md`](./docs/setup.md) or the [dev-setup guide](./scripts/README.md).

---

## 🚀 Core Capabilities

| Category | Features |
| --- | --- |
| **Build Engine** | Incremental builds, dependency tracking, LuaJIT support |
| **Cross-Platform** | Linux, macOS, Windows, BSD, Android, Wasm, ARM |
| **Performance** | Parallel builds, distcc, LTO, artifact caching |
| **Security** | SBOMs, GPG signing, Trivy & Grype scans |

---

## ⚙️ Configuration & Workflow

**Create a** `luaDev-config.lua`:

```lua
return {
  profiles = {
    debug = { flags = "-g -O0" },
    release = { flags = "-O3 -flto" }
  },
  options = {
    LUA_IMPL = "luajit",    -- or "lua"
    BUILD_SHARED_LIBS = true,
    WITH_TESTS = true
  }
}

```

**Override with**:

- `.buildrc.lua` user config
  
- `.envrc` environment-specific config
  

---

**Use the CLI**:

```bash
./build.lua help       # List available commands
./build.lua build      # Run build
./build.lua test       # Run tests

```

---

## 📦 Packaging & Distribution

| Format | Output |
| --- | --- |
| Static/Dynamic Libs | `.a`, `.so`, `.dll`, `.dylib` |
| Archives | `.zip`, `.tar.gz`, `.7z` |
| System Packages | `.deb`, `.rpm`, Homebrew, Chocolatey |
| Lua Packages | `.rock`, `.rockspec`, `luarocks.lock` |

## 🧪 Testing & Quality Assurance

| Tool | Purpose |
| --- | --- |
| Busted | Unit tests |
| LuaUnit | Alt test runner |
| GCOV/LCOV | Code coverage reports |
| Luacheck | Static analysis & pre-hooks |
| Sanitizers | ASAN/UBSAN/TSAN for native code |

---

## 🔌 Plugins & Extensions

| Plugin | Feature |
| --- | --- |
| `watch` | Auto rebuild on file change |
| `graphviz` | Visualize build dependencies |
| `docs` | Docusaurus docs generator |
| `publish` | Publish to LuaRocks or GitHub |

---

## 🚀 Advanced Features

- **Multi-language builds**: Lua, C, Rust, Zig
  
- **Hot reloading**: Live dev loop for Lua modules
  
- **Build graphs**: HTML/DOT interactive dependency trees
  
- **CI/CD Hooks**: Pre/post build automation support
  

---

## 🧰 Project Templates

| Template | Stack |
| --- | --- |
| `lua-basic` | Pure Lua CLI app |
| `lua-c` | Lua with native C module |
| `lua-rust` | LuaJIT FFI + Rust `cdylib` |
| `lua-server` | Lapis/OpenResty web app |

---

## 📈 Maturity Roadmap

| Stage | Capabilities |
| --- | --- |
| **Basic** | Lua builds with manual config |
| **Professional** | Cross-platform, LuaRocks, testing |
| **Enterprise** | Security, SBOMs, CI/CD, multi-language |
| **Cutting-Edge** | Live diagnostics, hot reload, Wasm builds |

---

## 🏆 Key Advantages

✅ Unified workflow for Lua, LuaJIT, and native extensions  
✅ Bootstrap with `.envrc`, `.bashrc`, or PowerShell scripts  
✅ Cross-compilation and hybrid build workflows  
✅ Native Docusaurus support for docs  
✅ Preconfigured templates for rapid project starts

---

> Build everything from CLI tools to embedded systems and LuaJIT-accelerated native modules — all with a single powerful toolkit.
