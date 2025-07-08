# loader.psm1 - Enhanced module loader with dependency tracking
function Import-LuaDevModules {
    param (
        [Parameter(Mandatory)][string]$ModulesPath,
        [switch]$AllowFallback
    )

    if (-not (Test-Path $ModulesPath)) {
        throw "Modules path not found: $ModulesPath"
    }

    # 🔒 Strict module load order with dependency tracking
    $loadOrder = @(
        "globals.psm1",        # 🌐 Path helpers (must come first)
        "environment.psm1",    # 🧭 OS detection
        "versioning.psm1",     # 🔢 Version parsing
        "logging.psm1",        # 📢 Logging functions
        "downloader.psm1",     # ⬇️ Source fetching
        "cmake.psm1",          # 🛠️ CMake config
        "luaBuilder.psm1",     # 🔧 Lua build
        "luajitBuilder.psm1",  # 🔧 LuaJIT build
        "manifest.psm1",       # 🧾 Artifact tracking
        "export.psm1",         # 📝 Markdown export
        "logexporter.psm1"     # 📋 Docs export
    )

    $global:loadedModules = [System.Collections.Generic.List[string]]::new()
    $global:loadedModuleNames = [System.Collections.Generic.List[string]]::new()

    Write-Verbose "  [Loader] 🔍 Loading modules from: $ModulesPath"
    Write-Verbose "  [Loader] 📋 Load order: $($loadOrder -join ', ')"

    foreach ($module in $loadOrder) {
        $fullPath = Join-Path $ModulesPath $module
        if (Test-Path $fullPath) {
            try {
                # Get module name without extension
                $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)

                # Skip if already loaded
                if ($global:loadedModuleNames -contains $moduleName) {
                    Write-Verbose "  [Loader] ⏩ $moduleName already loaded"
                    continue
                }

                # Load the module
                Write-Verbose "  [Loader] 🔄 Loading $moduleName..."
                Import-Module -Name $fullPath -Force -DisableNameChecking -Scope Global -ErrorAction Stop

                $global:loadedModules.Add($module)
                $global:loadedModuleNames.Add($moduleName)
                Write-Verbose "  [Loader] ✅ Loaded $moduleName"
            }
            catch {
                Write-Warning "  [Loader] ❌ Failed to load $module - $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning "  [Loader] ⚠️ Module file not found: $fullPath"
        }
    }

    # 🔁 Fallback loading for any missing modules
    if ($AllowFallback) {
        Write-Verbose "  [Loader] 🔁 Starting fallback module loading..."
        Get-ChildItem -Path $ModulesPath -Filter *.psm1 | ForEach-Object {
            $moduleName = $_.BaseName
            if ($global:loadedModuleNames -notcontains $moduleName) {
                try {
                    Write-Verbose "  [Loader] 🔄 Loading fallback: $moduleName..."
                    Import-Module -Name $_.FullName -Force -DisableNameChecking -Scope Global
                    $global:loadedModules.Add($_.Name)
                    $global:loadedModuleNames.Add($moduleName)
                    Write-Verbose "  [Loader] ✅ Fallback loaded: $moduleName"
                }
                catch {
                    Write-Warning "  [Loader] ❌ Fallback failed: $($_.Name) - $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Verbose "  [Loader] 🎯 Successfully loaded $($global:loadedModuleNames.Count) modules"
    Write-Verbose "  [Loader] 📦 Modules loaded: $($global:loadedModuleNames -join ', ')"
}

Export-ModuleMember -Function Import-LuaDevModules
