# 🌙 **luaDev The Modern Lua Build System**

`luaDev` is a **cross-platform**, **modular**, and **extensible** build system designed for modern **Lua**, **LuaJIT**, and hybrid **C/Rust** projects. Whether you're building CLI tools, embedded apps, or portable libraries, `luaDev` delivers a professional-grade developer experience.

---

## 🎯 Mission

Provide an all-in-one Lua development environment with:

- 🔧 Automated, reproducible builds
  
- 📦 Smart package management (LuaRocks + system packages)
  
- ✅ Testing, linting & static analysis out-of-the-box
  
- 🧠 First-class editor integration (Neovim, VSCode)
  
- ⚙️ Hybrid C/Rust support + cross-compilation
  

---

## 🧰 Toolchain Overview

| Tool | Role |
| --- | --- |
| LLVM/Clang | Compiles Lua + native modules |
| Lua/LuaJIT | Core scripting runtimes |
| LuaRocks | Package manager (built from source) |
| Busted | Unit testing |
| Luacheck | Linter + static analysis |
| Stylua | Code formatting |
| Luadoc | Docs generation |
| CMake/Make | C/C++ build support |
| clangd | C/C++ language server |
| Cargo | Rust FFI and module builds |
| Git | Version control |
| Perl | Auxiliary tooling (for compatibility) |

---

## 🧠 Editor Integration

### VS Code

Recommended extensions:

- `Lua Language Server` (sumneko or LuaLS)
  
- `Lua Debug Adapter`
  
- `Clangd` for native FFI support
  

```jsonc
// VSCode settings.json
{
  "Lua.workspace.library": ["${workspaceFolder}"],
  "Lua.diagnostics.enable": true,
  "Lua.format.enable": true
}
```

---

### 🧠 Neovim

Recommended plugins (via `lazy.nvim`, `packer.nvim`, or `folke/lazy.nvim`):

- [lua-language-server](https://github.com/LuaLS/lua-language-server)  
  For full-featured Lua IntelliSense, diagnostics, and navigation.
  
- [nvimtools/none-ls.nvim](https://github.com/nvimtools/none-ls.nvim)  
  A modern replacement for `null-ls`. Use it to integrate:
  
  - `stylua` (formatter)
    
  - `luacheck` (linter)
    
  - Other external CLI tools (e.g. `shellcheck`, `markdownlint`)
    
- Test integration (choose your preferred runner):
  
  - [nvim-neotest/neotest](https://github.com/nvim-neotest/neotest)
    
  - [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
    
  - [tpope/vim-dispatch](https://github.com/tpope/vim-dispatch)
    

> 💡 Tip: Combine `none-ls.nvim` with `mason.nvim` for automatic tool installation and management.

---

## ✅ Setup Checklist

Fully cross-platform: supports **Windows**, **macOS**, and **Linux**.

| Component | Status / Notes |
| --- | --- |
| LLVM + Clang | ✅ Installed via `winget`, `brew`, or `apt` |
| Lua (from source) | ✅ Built and added to `PATH` |
| LuaRocks | ✅ Installed & configured |
| Busted / Luacheck | ✅ Installed via `luarocks` |
| Neovim | ✅ Lua dev-ready plugins configured |
| VS Code | ✅ Key extensions installed |
| Automation Scripts | ⚙️ OS-specific: `.ps1`, `.sh`, `.envrc` |

> 💡 Use `direnv`, `.bashrc`, or PowerShell profiles to auto-load toolchains.

See [docs/setup.md](https://chatgpt.com/c/docs/setup.md) or the [scripts README](https://chatgpt.com/c/scripts/README.md) for full setup instructions.

---

## 🚀 Key Capabilities

| Area | Features |
| --- | --- |
| Build Engine | Smart rebuilds, LuaJIT support, dependency tracking |
| Cross-Platform | Windows, Linux, macOS, BSD, ARM, Android, Wasm |
| Performance | Parallelism, LTO, caching, distcc support |
| Security | SBOMs, GPG signing, static analysis scanners |

---

## ⚙️ Configuration Workflow

Create a `luaDev-config.lua`:

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

### Config Layers:

- `.buildrc.lua` – user overrides
  
- `.envrc` – environment-specific settings
  

---

## 📟 CLI Usage

```bash
./build.lua help       # List available commands
./build.lua build      # Compile project
./build.lua test       # Run test suite
```

---

## 📦 Packaging & Distribution

| Type | Output Formats |
| --- | --- |
| Native Libraries | `.a`, `.so`, `.dll`, `.dylib` |
| Archives | `.zip`, `.tar.gz`, `.7z` |
| System Packages | `.deb`, `.rpm`, Homebrew, Chocolatey |
| Lua Packages | `.rock`, `.rockspec`, `luarocks.lock` |

---

## 🧪 Testing & QA

| Tool | Role |
| --- | --- |
| Busted | Unit tests |
| LuaUnit | Alternative test runner |
| Luacheck | Linter & pre-commit hooks |
| GCOV/LCOV | Coverage reports |
| Sanitizers | ASAN, TSAN, UBSAN for C/Rust code |

---

## 🔌 Plugins & Extensions

| Plugin | Functionality |
| --- | --- |
| `watch` | Auto-rebuild on file change |
| `graphviz` | Visualize build graph as DOT/HTML |
| `docs` | Auto-generate docs (e.g., Docusaurus) |
| `publish` | Publish to LuaRocks / GitHub |

---

## 🔍 Advanced Features

- 🧬 **Multi-language builds**: Lua, C, Rust, Zig
  
- 🔁 **Hot reloading**: Live Lua module updates
  
- 🌐 **Build graph explorer**: DOT or HTML visualizers
  
- 🛠️ **CI/CD Hooks**: Custom pre/post build scripts
  

---

## 🧪 Project Templates

| Template | Stack |
| --- | --- |
| `lua-basic` | Pure Lua CLI app |
| `lua-c` | Lua with native C module |
| `lua-rust` | LuaJIT FFI with Rust `cdylib` |
| `lua-server` | Lapis/OpenResty web backend |

---

## 📈 Roadmap to Maturity

| Stage | Features |
| --- | --- |
| **Basic** | Manual Lua builds |
| **Professional** | Cross-platform, testing, LuaRocks |
| **Enterprise** | CI/CD, SBOMs, static analysis, security |
| **Cutting-Edge** | Hot reloading, Wasm, live diagnostics |

---

## 🏅 Why Choose `luaDev`

✅ Unified workflows for Lua, LuaJIT, and native modules  
✅ Bootstrap-ready via `.envrc`, `.bashrc`, PowerShell  
✅ First-class support for hybrid and cross-compilation builds  
✅ Docusaurus-based doc generation  
✅ Prebuilt project templates to get started faster

---

> From CLI tools to embedded systems and native LuaJIT integrations — `luaDev` gives you everything you need in one cohesive toolkit.
