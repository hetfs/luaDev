# loader.psm1 - Enhanced module loader with dependency tracking

# 🛡️ Fallback logging
if (-not (Get-Command Write-WarningLog -ErrorAction SilentlyContinue)) {
    function Write-WarningLog  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
}
if (-not (Get-Command Write-InfoLog -ErrorAction SilentlyContinue)) {
    function Write-InfoLog     { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
}
if (-not (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue)) {
    function Write-ErrorLog    { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
}

function Import-LuaDevModules {
    param (
        [Parameter(Mandatory)][string]$ModulesPath,
        [switch]$AllowFallback
    )

    if (-not (Test-Path $ModulesPath)) {
        throw "Modules path not found: $ModulesPath"
    }

    # 🔒 Strict load order for dependency resolution
    $loadOrder = @(
        "globals.psm1",            # 🌐 Path helpers
        "environment.psm1",        # 🧱 OS detection
        "versioning.psm1",         # 📂 Version parsing
        "logging.psm1",            # 📢 Logging functions
        "downloader.psm1",         # ⬇️ Source fetching
        "cmake.psm1",              # 🛠️ CMake config
        "luaBuilder.psm1",         # 🔧 Lua build
        "luajitBuilder.psm1",      # 🔧 LuaJIT build
        "manifest.psm1",           # 🧾 Artifact manifesting
        "logExporter.psm1",        # 📜 Markdown log
        "manifestsExporter.psm1"   # 📋 Export to docs/manifest markdown
    )

    $global:loadedModules = [System.Collections.Generic.List[string]]::new()
    $global:loadedModuleNames = [System.Collections.Generic.List[string]]::new()

    Write-Verbose "  [Loader] 🔍 Scanning modules from: $ModulesPath"
    Write-Verbose "  [Loader] 📋 Defined load order: $($loadOrder -join ', ')"

    foreach ($module in $loadOrder) {
        $fullPath = Join-Path $ModulesPath $module
        if (Test-Path $fullPath) {
            try {
                $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
                if ($global:loadedModuleNames -contains $moduleName) {
                    Write-Verbose "  [Loader] ⏭️  Skipping already-loaded module: $moduleName"
                    continue
                }

                Import-Module -Name $fullPath -Force -DisableNameChecking -Scope Global -ErrorAction Stop
                $global:loadedModules.Add($module)
                $global:loadedModuleNames.Add($moduleName)
                Write-Verbose "  [Loader] ✅ Loaded module: $moduleName"
            }
            catch {
                Write-WarningLog "  [Loader] ❌ Failed to load `${module}`: $($_.Exception.Message)"
            }
        }
        else {
            Write-WarningLog "  [Loader] ⚠️ Module not found: $fullPath"
        }
    }

    # 🔁 Load any missing modules in fallback mode
    if ($AllowFallback) {
        Write-Verbose "  [Loader] 🔁 Fallback loading enabled..."
        Get-ChildItem -Path $ModulesPath -Filter *.psm1 | ForEach-Object {
            $moduleName = $_.BaseName
            if ($global:loadedModuleNames -notcontains $moduleName) {
                try {
                    Import-Module -Name $_.FullName -Force -DisableNameChecking -Scope Global
                    $global:loadedModules.Add($_.Name)
                    $global:loadedModuleNames.Add($moduleName)
                    Write-Verbose "  [Loader] ✅ Fallback loaded: $moduleName"
                }
                catch {
                    Write-WarningLog "  [Loader] ❌ Fallback failed: $($_.Name) - $($_.Exception.Message)"
                }
            }
        }
    }

    # 🧩 Validate critical function availability
    $criticalFunctions = @{
        "environment" = "Get-OSPlatform"
        "cmake"       = "Generate-CMakeLists"
        "downloader"  = "Get-SourceArchive"
    }

    $missing = @()
    foreach ($module in $criticalFunctions.Keys) {
        $func = $criticalFunctions[$module]
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missing += "$module (missing $func)"
        }
    }

    if ($missing.Count -gt 0) {
        throw "❌ Critical module functions missing: $($missing -join ', ')"
    }

    Write-Verbose "  [Loader] 🌟 Loaded $($global:loadedModuleNames.Count) modules successfully"
    Write-Verbose "  [Loader] 📦 Modules loaded: $($global:loadedModuleNames -join ', ')"
}

Export-ModuleMember -Function Import-LuaDevModules
