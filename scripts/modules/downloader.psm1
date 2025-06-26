function Get-LuaSource {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    $tarball = "lua-$Version.tar.gz"
    $url = "https://www.lua.org/ftp/$tarball"
    $sourcesDir = Get-SourcesRoot
    $archivePath = Join-Path $sourcesDir $tarball
    $extractPath = Join-Path $sourcesDir "lua-$Version"

    # Check existing source
    if (Test-Path "$extractPath/src/lua.c") {
        Write-InfoLog "♻️ Using cached Lua $Version source"
        return $extractPath
    }

    # Download with retries
    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-InfoLog "⬇️ Downloading Lua $Version (attempt $i/$maxRetries)"
            Invoke-WebRequest $url -OutFile $archivePath -UseBasicParsing -ErrorAction Stop
            break
        }
        catch {
            if ($i -eq $maxRetries) {
                Write-ErrorLog "❌ Download failed: $($_.Exception.Message)"
                return $null
            }
            Start-Sleep -Seconds (5 * $i)
        }
    }

    # Extract archive
    try {
        if ($IsWindows) {
            & tar xzf $archivePath -C $sourcesDir
        }
        else {
            & tar xzf $archivePath -C $sourcesDir
        }

        if (-not (Test-Path "$extractPath/src/lua.c")) {
            throw "Source validation failed - lua.c missing"
        }

        return $extractPath
    }
    catch {
        Write-ErrorLog "❌ Extraction failed: $($_.Exception.Message)"
        return $null
    }
}

Export-ModuleMember -Function Get-LuaSource
