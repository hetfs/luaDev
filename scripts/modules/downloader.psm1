# downloader.psm1
# ⬇️ Downloads and extracts Lua or LuaJIT sources for luaDev builds

function Get-SourceArchive {
    <#
    .SYNOPSIS
        Downloads and extracts the Lua or LuaJIT source code.
    .PARAMETER Engine
        Engine name: 'lua' or 'luajit'
    .PARAMETER Version
        Full semantic version (e.g. 5.4.8 or 2.1.0-beta3)
    #>
    param (
        [Parameter(Mandatory)][ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory)][string]$Version
    )

    $sourcesRoot = Get-SourcesRoot
    $name        = "$Engine-$Version"
    $tarball     = "$name.tar.gz"
    $archivePath = Join-Path $sourcesRoot $tarball
    $extractPath = Join-Path $sourcesRoot $name
    $checkFile   = if ($Engine -eq "lua") {
        Join-Path $extractPath "src/lua.c"
    } else {
        Join-Path $extractPath "src/luajit.c"
    }

    $cmakePath   = Join-Path $extractPath "CMakeLists.txt"

    # ♻️ Reuse already-extracted source
    if (Test-Path $checkFile) {
        Write-InfoLog "♻️ Using cached $Engine $Version source"
        return $extractPath
    }

    # 🌍 Download
    $url = switch ($Engine) {
        "lua"    { "https://www.lua.org/ftp/lua-$Version.tar.gz" }
        "luajit" { "https://luajit.org/download/LuaJIT-$Version.tar.gz" }
    }

    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-InfoLog "⬇️ Downloading $Engine $Version (attempt $i/$maxRetries)"
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

    # 📦 Extract archive
    try {
        & tar xzf $archivePath -C $sourcesRoot
        if (-not (Test-Path $checkFile)) {
            throw "Extraction failed — expected file not found: $checkFile"
        }
    } catch {
        Write-ErrorLog "❌ Extraction failed: $($_.Exception.Message)"
        return $null
    }

    # 🧩 Inject fallback CMakeLists.txt if not generated yet
    if (-not (Test-Path $cmakePath)) {
        $templateName = if ($Engine -eq "lua") { "CMakeLists.lua.txt" } else { "CMakeLists.luajit.txt" }
        $template     = Join-Path (Get-TemplatesRoot) "cmake\$templateName"

        if (Test-Path $template) {
            Copy-Item -Path $template -Destination $cmakePath -Force
            Write-InfoLog "🧩 Injected fallback template: $templateName"
        } else {
            Write-WarningLog "⚠️ No fallback template found for $Engine"
        }
    }

    return $extractPath
}

Export-ModuleMember -Function Get-SourceArchive
