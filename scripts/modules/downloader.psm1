function Get-LuaSource {
    param(
        [Parameter(Mandatory)][string]$Version
    )

    $sourcesRoot   = Get-SourcesRoot
    $tarball       = "lua-$Version.tar.gz"
    $archivePath   = Join-Path $sourcesRoot $tarball
    $extractPath   = Join-Path $sourcesRoot "lua-$Version"
    $sourceLuaPath = Join-Path $extractPath "src/lua.c"
    $cmakePath     = Join-Path $extractPath "CMakeLists.txt"

    # ♻️ Reuse already-extracted source
    if (Test-Path $sourceLuaPath) {
        Write-InfoLog "♻️ Using cached Lua $Version source"
        return $extractPath
    }

    # 🌍 Download from Lua.org
    $url = "https://www.lua.org/ftp/$tarball"
    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-InfoLog "⬇️ Downloading Lua $Version (attempt $i/$maxRetries)"
            Invoke-WebRequest $url -OutFile $archivePath -UseBasicParsing -ErrorAction Stop
            break
        } catch {
            if ($i -eq $maxRetries) {
                Write-ErrorLog "❌ Download failed: $($_.Exception.Message)"
                return $null
            }
            Start-Sleep -Seconds (5 * $i)
        }
    }

    # 📦 Extract
    try {
        & tar xzf $archivePath -C $sourcesRoot
        if (-not (Test-Path $sourceLuaPath)) {
            throw "Extraction incomplete — lua.c not found"
        }
    } catch {
        Write-ErrorLog "❌ Extraction failed: $($_.Exception.Message)"
        return $null
    }

    # 🧩 Inject fallback CMakeLists.txt if missing
    if (-not (Test-Path $cmakePath)) {
        $template = Join-Path $PSScriptRoot "..\templates\CMakeLists.lua.txt"
        if (Test-Path $template) {
            Copy-Item -Path $template -Destination $cmakePath -Force
            Write-InfoLog "🧩 Injected fallback CMakeLists.txt"
        } else {
            Write-WarningLog "⚠️ No template found: CMakeLists.lua.txt"
        }
    }

    return $extractPath
}

Export-ModuleMember -Function Get-LuaSource
