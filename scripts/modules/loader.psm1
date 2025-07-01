# loader.psm1
# 📦 Loads all luaDev modules in a defined order

function Import-LuaDevModules {
    param (
        [string]$ModulesPath
    )

    if (-not (Test-Path $ModulesPath)) {
        Write-Host "❌ Modules path not found: $ModulesPath" -ForegroundColor Red
        return
    }

    $loadOrder = @(
        "logging.psm1",        # 🪵 Logging must come first
        "environment.psm1",    # 🔧 Tool detection
        "versioning.psm1",     # 🔢 Version resolution
        "downloader.psm1",     # ⬇️  Source fetching
        "build-lua.psm1",      # 🛠️ Lua builder
        "build-luajit.psm1",   # 🛠️ LuaJIT builder
        "manifest.psm1",       # 📋 Manifest generation
        "export.psm1"          # 📤 Markdown log export
    )

    foreach ($module in $loadOrder) {
        $fullPath = Join-Path $ModulesPath $module
        try {
            Import-Module -Name $fullPath -Force -DisableNameChecking -ErrorAction Stop
            Write-Verbose "[loader] ✅ Loaded: $module"
        }
        catch {
            Write-Host "[loader] ⚠️ Failed to load $module — $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Export-ModuleMember -Function Import-LuaDevModules


