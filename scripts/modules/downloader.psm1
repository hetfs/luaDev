# downloader.psm1 - Updated for dynamic CMake generation

function Get-SourceArchive {
    <#
    .SYNOPSIS
        Downloads and extracts Lua/LuaJIT source with mirror fallback.
    .PARAMETER Engine
        'lua' or 'luajit'
    .PARAMETER Version
        Semantic version (e.g. 5.4.8 or 2.1.0-beta3)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory)][string]
        $Version
    )

    $sourcesRoot = Get-SourcesRoot
    Write-VerboseLog "📁 Sources root: $sourcesRoot"

    $name        = "$Engine-$Version"
    $tarball     = "$name.tar.gz"
    $archivePath = Join-Path $sourcesRoot $tarball
    $extractPath = Join-Path $sourcesRoot $name

    $checkFile = if ($Engine -eq "lua") {
        Join-Path $extractPath "src/lua.c"
    } else {
        Join-Path $extractPath "src/luajit.c"
    }

    # ♻️ Return existing extracted source if valid
    if (Test-Path $checkFile) {
        Write-InfoLog "♻️ Using cached $Engine $Version source"
        return $extractPath
    }

    # 🌍 Define source URLs
    $mirrors = @()
    if ($Engine -eq "lua") {
        $mirrors += "https://www.lua.org/ftp/lua-$Version.tar.gz"
    } else {
        $mirrors += "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v$Version.tar.gz"
    }

    # 📥 Attempt downloads
    $maxRetries = 3
    $downloaded = $false
    $lastError = $null

    foreach ($url in $mirrors) {
        for ($i = 1; $i -le $maxRetries; $i++) {
            try {
                Write-InfoLog "⬇️ Downloading $Engine $Version from [$url] (attempt $i/$maxRetries)"

                [Net.ServicePointManager]::SecurityProtocol =
                    [Net.SecurityProtocolType]::Tls12 -bor
                    [Net.SecurityProtocolType]::Tls11 -bor
                    [Net.SecurityProtocolType]::Tls

                Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing -TimeoutSec 30
                Write-InfoLog "✅ Download completed from: $url"
                $downloaded = $true
                break
            }
            catch {
                $lastError = $_.Exception.Message
                Write-WarningLog "⚠️ Attempt $i failed: $lastError"
                Start-Sleep -Seconds ([Math]::Pow(2, $i))  # backoff: 2, 4, 8
            }
        }

        if ($downloaded) { break }
    }

    if (-not $downloaded) {
        Write-ErrorLog "❌ All download attempts failed. Last error: $lastError"
        return $null
    }

    # 📦 Extraction
    $extracted = $false
    for ($j = 1; $j -le 2; $j++) {
        try {
            Write-InfoLog "📦 Extracting $tarball (attempt $j/2)"
            if (Get-Command tar -ErrorAction SilentlyContinue) {
                tar xzf $archivePath -C $sourcesRoot
            }
            elseif (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
                & "$env:ProgramFiles\7-Zip\7z.exe" x $archivePath -o$sourcesRoot
            }
            else {
                throw "No tar or 7-Zip found for extraction"
            }

            if (-not (Test-Path $checkFile)) {
                throw "Critical file missing after extract: $($checkFile | Split-Path -Leaf)"
            }

            $extracted = $true
            break
        }
        catch {
            Write-WarningLog "⚠️ Extract attempt $j failed: $($_.Exception.Message)"
            Start-Sleep -Seconds (3 * $j)
        }
    }

    if (-not $extracted) {
        Write-ErrorLog "❌ Extraction failed after 2 attempts"
        return $null
    }

    Write-InfoLog "✅ Extraction complete: $extractPath"
    return $extractPath
}

Export-ModuleMember -Function Get-SourceArchive
