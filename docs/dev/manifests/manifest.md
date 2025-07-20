---
id: manifest
title: 📦 Build Manifest
sidebar_label: Manifest
sidebar_position: 5
---
# Build Report - 20250715-151223

**Generated on:** 2025-07-15 15:12:34 UTC

---
### 🧹 Global
#### 📄 Other Logs
`log
[2025-07-15 15:12:23Z] === 🚀 LuaDev Build System v2.2.0 ===
[2025-07-15 15:12:23Z] Initializing module system...
[2025-07-15 15:12:23Z] 🔍 Loading modules from D:\HETFS-LTD\GitHub-Projects\luaDev\scripts\modules
[2025-07-15 15:12:23Z] ✅ Module loader imported
[2025-07-15 15:12:23Z] ✅ 12 modules loaded: globals, environment, versioning, logging, downloader, cmake, luaBuilder, luajitBuilder, manifest, logExporter, manifestsExporter, loader
2025-07-15 15:12:23 [INFO] Logging subsystem initialized (Level: Info)
2025-07-15 15:12:23 [INFO] 🚀 Initiating build process
2025-07-15 15:12:23 [INFO] ⚙️ Configuration:
2025-07-15 15:12:23 [INFO]   - Build Type: static
2025-07-15 15:12:23 [INFO]   - Compiler: msvc
2025-07-15 15:12:23 [INFO]   - Dry Run: False
2025-07-15 15:12:23 [INFO] 🌐 Platform: windows (x64)
2025-07-15 15:12:23 [VERBOSE] 🎯 Target registered: lua/5.4.8
2025-07-15 15:12:23 [VERBOSE] 🎯 Target registered: lua/5.3.6
2025-07-15 15:12:23 [VERBOSE] 🎯 Target registered: lua/5.2.4
2025-07-15 15:12:23 [VERBOSE] 🎯 Target registered: lua/5.1.5
2025-07-15 15:12:23 [VERBOSE] 🎯 Target registered: luajit/2.1.0-beta3
2025-07-15 15:12:23 [VERBOSE] 🎯 Target registered: luajit/2.0.5
2025-07-15 15:12:23 [INFO] 🎯 Build targets: 6
2025-07-15 15:12:23 [VERBOSE]     - lua 5.4.8
2025-07-15 15:12:23 [VERBOSE]     - lua 5.3.6
2025-07-15 15:12:23 [VERBOSE]     - lua 5.2.4
2025-07-15 15:12:23 [VERBOSE]     - lua 5.1.5
2025-07-15 15:12:23 [VERBOSE]     - luajit 2.1.0-beta3
2025-07-15 15:12:23 [VERBOSE]     - luajit 2.0.5
2025-07-15 15:12:23 [INFO] 🔨 Starting build sequence
2025-07-15 15:12:23 [INFO] ✅ Generated CMakeLists.txt for lua 5.4.8 (static/msvc)
2025-07-15 15:12:23 [INFO] 🛠️ Configuring CMake for Lua 5.4.8 (msvc)
2025-07-15 15:12:24 [ERROR] ❌ Lua build failed: CMake configuration failed (exit 1)
2025-07-15 15:12:24 [INFO] 📦 Source not found - fetching: lua 5.3.6
2025-07-15 15:12:24 [VERBOSE] 📁 Sources root: D:\HETFS-LTD\GitHub-Projects\luaDev\sources
2025-07-15 15:12:24 [INFO] ⬇️ Downloading lua 5.3.6 from [https://www.lua.org/ftp/lua-5.3.6.tar.gz] (attempt 1/3)
2025-07-15 15:12:25 [INFO] ✅ Download completed from: https://www.lua.org/ftp/lua-5.3.6.tar.gz
2025-07-15 15:12:25 [INFO] 📦 Extracting lua-5.3.6.tar.gz (attempt 1/2)
2025-07-15 15:12:25 [INFO] ✅ Extraction complete: D:\HETFS-LTD\GitHub-Projects\luaDev\sources\lua-5.3.6
2025-07-15 15:12:25 [INFO] ✅ Generated CMakeLists.txt for lua 5.3.6 (static/msvc)
2025-07-15 15:12:25 [INFO] 🛠️ Configuring CMake for Lua 5.3.6 (msvc)
2025-07-15 15:12:25 [ERROR] ❌ Lua build failed: CMake configuration failed (exit 1)
2025-07-15 15:12:25 [INFO] 📦 Source not found - fetching: lua 5.2.4
2025-07-15 15:12:25 [VERBOSE] 📁 Sources root: D:\HETFS-LTD\GitHub-Projects\luaDev\sources
2025-07-15 15:12:25 [INFO] ⬇️ Downloading lua 5.2.4 from [https://www.lua.org/ftp/lua-5.2.4.tar.gz] (attempt 1/3)
2025-07-15 15:12:27 [INFO] ✅ Download completed from: https://www.lua.org/ftp/lua-5.2.4.tar.gz
2025-07-15 15:12:27 [INFO] 📦 Extracting lua-5.2.4.tar.gz (attempt 1/2)
2025-07-15 15:12:27 [INFO] ✅ Extraction complete: D:\HETFS-LTD\GitHub-Projects\luaDev\sources\lua-5.2.4
2025-07-15 15:12:27 [INFO] ✅ Generated CMakeLists.txt for lua 5.2.4 (static/msvc)
2025-07-15 15:12:27 [INFO] 🛠️ Configuring CMake for Lua 5.2.4 (msvc)
2025-07-15 15:12:27 [ERROR] ❌ Lua build failed: CMake configuration failed (exit 1)
2025-07-15 15:12:27 [INFO] 📦 Source not found - fetching: lua 5.1.5
2025-07-15 15:12:27 [VERBOSE] 📁 Sources root: D:\HETFS-LTD\GitHub-Projects\luaDev\sources
2025-07-15 15:12:27 [INFO] ⬇️ Downloading lua 5.1.5 from [https://www.lua.org/ftp/lua-5.1.5.tar.gz] (attempt 1/3)
2025-07-15 15:12:28 [INFO] ✅ Download completed from: https://www.lua.org/ftp/lua-5.1.5.tar.gz
2025-07-15 15:12:28 [INFO] 📦 Extracting lua-5.1.5.tar.gz (attempt 1/2)
2025-07-15 15:12:29 [INFO] ✅ Extraction complete: D:\HETFS-LTD\GitHub-Projects\luaDev\sources\lua-5.1.5
2025-07-15 15:12:29 [INFO] ✅ Generated CMakeLists.txt for lua 5.1.5 (static/msvc)
2025-07-15 15:12:29 [INFO] 🛠️ Configuring CMake for Lua 5.1.5 (msvc)
2025-07-15 15:12:29 [ERROR] ❌ Lua build failed: CMake configuration failed (exit 1)
2025-07-15 15:12:29 [INFO] 📦 Source not found - fetching: luajit 2.1.0-beta3
2025-07-15 15:12:29 [VERBOSE] 📁 Sources root: D:\HETFS-LTD\GitHub-Projects\luaDev\sources
2025-07-15 15:12:29 [INFO] ⬇️ Downloading luajit 2.1.0-beta3 from [https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.0-beta3.tar.gz] (attempt 1/3)
2025-07-15 15:12:31 [INFO] ✅ Download completed from: https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.0-beta3.tar.gz
2025-07-15 15:12:31 [INFO] 📦 Extracting luajit-2.1.0-beta3.tar.gz (attempt 1/2)
2025-07-15 15:12:31 [INFO] ✅ Extraction complete: D:\HETFS-LTD\GitHub-Projects\luaDev\sources\luajit-2.1.0-beta3
2025-07-15 15:12:31 [INFO] ✅ Generated CMakeLists.txt for luajit 2.1.0-beta3 (static/msvc)
2025-07-15 15:12:31 [INFO] 🛠️ Configuring CMake for LuaJIT 2.1.0-beta3 (msvc)
2025-07-15 15:12:31 [ERROR] ❌ LuaJIT build failed: CMake configuration failed (exit 1)
2025-07-15 15:12:31 [INFO] 📦 Source not found - fetching: luajit 2.0.5
2025-07-15 15:12:31 [VERBOSE] 📁 Sources root: D:\HETFS-LTD\GitHub-Projects\luaDev\sources
2025-07-15 15:12:31 [INFO] ⬇️ Downloading luajit 2.0.5 from [https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.0.5.tar.gz] (attempt 1/3)
2025-07-15 15:12:34 [INFO] ✅ Download completed from: https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.0.5.tar.gz
2025-07-15 15:12:34 [INFO] 📦 Extracting luajit-2.0.5.tar.gz (attempt 1/2)
2025-07-15 15:12:34 [INFO] ✅ Extraction complete: D:\HETFS-LTD\GitHub-Projects\luaDev\sources\luajit-2.0.5
2025-07-15 15:12:34 [WARN] ⚠️ Creating version config: D:\HETFS-LTD\GitHub-Projects\luaDev\templates\cmake\luajit-2.0.5.cmake
2025-07-15 15:12:34 [INFO] ✅ Generated CMakeLists.txt for luajit 2.0.5 (static/msvc)
2025-07-15 15:12:34 [INFO] 🛠️ Configuring CMake for LuaJIT 2.0.5 (msvc)
2025-07-15 15:12:34 [ERROR] ❌ LuaJIT build failed: CMake configuration failed (exit 1)
2025-07-15 15:12:34 [INFO] 📊 Generating build reports
2025-07-15 15:12:34 [INFO] 📄 JSON manifest exported: D:\HETFS-LTD\GitHub-Projects\luaDev\manifests\manifest.json
2025-07-15 15:12:34 [INFO] 📝 Markdown manifest exported: D:\HETFS-LTD\GitHub-Projects\luaDev\manifests\manifest.md
`$newline

