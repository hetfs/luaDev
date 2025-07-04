# loader.psm1
# 📦 Strict module loader for luaDev with optional fallback discovery

function Import-LuaDevModules {
    param (
        [Parameter(Mandatory)][string]$ModulesPath,
        [switch]$AllowFallback
    )

    if (-not (Test-Path $ModulesPath)) {
        Write-Host "❌ Modules path not found: $ModulesPath" -ForegroundColor Red
        return
    }

    Write-Verbose "[loader] 🔍 Loading modules from: $ModulesPath"

    # 🔒 Strict module load order: honor dependencies
    $loadOrder = @(
        "globals.psm1",        # 🌐 Path helpers, Get-ProjectRoot, etc.
        "logging.psm1",        # 📢 Write-InfoLog, Write-WarningLog
        "loader.psm1",         # 🔁 Allows re-import and noop
        "environment.psm1",    # 🧭 OS, compiler, toolchain checks
        "versioning.psm1",     # 🔢 Semantic version helpers
        "downloader.psm1",     # ⬇️ Download/extract sources
        "cmake.psm1",          # 🛠️ CMakeLists injection
        "luaBuilder.psm1",     # 🔧 Lua build logic (via CMake)
        "luajitBuilder.psm1",  # 🔧 LuaJIT-specific build
        "manifest.psm1",       # 🧾 Manifest generation (JSON/MD)
        "export.psm1",         # 📝 Basic Markdown log writer
        "logexporter.psm1"     # 📋 Docusaurus-style log formatter
    )

    $loadedModules = @()

    foreach ($module in $loadOrder) {
        $fullPath = Join-Path $ModulesPath $module
        if (Test-Path $fullPath) {
            try {
                Import-Module -Name $fullPath -Force -DisableNameChecking -ErrorAction Stop
                Write-Verbose "[loader] ✅ Loaded: $module"
                $loadedModules += $module
            } catch {
                Write-Warning "[loader] ⚠️ Failed to load $module — $($_.Exception.Message)"
            }
        } elseif ($AllowFallback) {
            Write-Warning "[loader] ⚠️ Missing in load order: $module — skipping"
        } else {
            Write-Error "[loader] ❌ Required module missing: $module"
        }
    }

    # 🔁 Fallback: Import any missing *.psm1 in modules dir
    if ($AllowFallback) {
        Get-ChildItem -Path $ModulesPath -Filter '*.psm1' | ForEach-Object {
            if ($_.Name -notin $loadedModules) {
                try {
                    Import-Module -Name $_.FullName -Force -DisableNameChecking -ErrorAction Stop
                    Write-Verbose "[loader] ➕ Fallback-loaded: $($_.Name)"
                } catch {
                    Write-Warning "[loader] ⚠️ Failed fallback-load: $($_.Name) — $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Verbose "[loader] 🎯 Module import finished"
}

Export-ModuleMember -Function Import-LuaDevModules
