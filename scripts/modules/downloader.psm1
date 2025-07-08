# downloader.psm1 - Robust downloader with mirror support and enhanced diagnostics
function Get-SourceArchive {
    <#
    .SYNOPSIS
        Downloads and extracts Lua/LuaJIT source with mirror fallback and better diagnostics
    .PARAMETER Engine
        'lua' or 'luajit'
    .PARAMETER Version
        Semantic version (e.g. 5.4.8 or 2.1.0-beta3)
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

    # 🌍 Define mirrors with fallback options
    $mirrors = @()
    if ($Engine -eq "lua") {
        $mirrors = @(
            "https://www.lua.org/ftp/lua-$Version.tar.gz"
        )
    } else {
        $mirrors = @(
            "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v$Version.tar.gz"
        )
    }

    # 📥 Download from mirrors with retry logic
    $maxRetries = 3
    $downloaded = $false
    $lastError = $null

    foreach ($url in $mirrors) {
        for ($i = 1; $i -le $maxRetries; $i++) {
            try {
                Write-InfoLog "⬇️ Downloading $Engine $Version from [$url] (attempt $i/$maxRetries)"

                # Use TLS 1.2+ for secure connections
                [Net.ServicePointManager]::SecurityProtocol =
                    [Net.SecurityProtocolType]::Tls12 -bor
                    [Net.SecurityProtocolType]::Tls11 -bor
                    [Net.SecurityProtocolType]::Tls

                # Modern download method
                Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing -TimeoutSec 30
                $downloaded = $true
                Write-InfoLog "✅ Download completed successfully from $url"
                break
            }
            catch {
                $lastError = $_.Exception.Message
                Write-WarningLog "⚠️ Download attempt $i failed: $lastError"

                # DNS-specific error handling
                if ($lastError -match "No such host is known") {
                    Write-VerboseLog "🔍 DNS resolution failed for $($url.Split('/')[2])"
                }

                # Sleep with exponential backoff
                $sleepSeconds = [Math]::Pow(2, $i)  # 2, 4, 8 seconds
                Write-VerboseLog "⏳ Retrying in $sleepSeconds seconds..."
                Start-Sleep -Seconds $sleepSeconds
            }
        }

        if ($downloaded) { break }
    }

    if (-not $downloaded) {
        Write-ErrorLog "❌ All download attempts failed. Last error: $lastError"
        return $null
    }

    # 📦 Extract archive with robust validation
    $maxExtractAttempts = 2
    $extracted = $false

    for ($j = 1; $j -le $maxExtractAttempts; $j++) {
        try {
            Write-InfoLog "📦 Extracting $tarball (attempt $j/$maxExtractAttempts)"

            # Use native tar command if available
            if (Get-Command tar -ErrorAction SilentlyContinue) {
                tar xzf $archivePath -C $sourcesRoot
            }
            else {
                # Fallback to 7-Zip if available
                $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
                if (Test-Path $7zPath) {
                    & $7zPath x $archivePath -o$sourcesRoot
                }
                else {
                    throw "No extraction method available (tar or 7-Zip not found)"
                }
            }

            # Verify extraction
            if (-not (Test-Path $checkFile)) {
                throw "Extraction failed - critical file missing: $($checkFile | Split-Path -Leaf)"
            }

            $extracted = $true
            break
        }
        catch {
            Write-WarningLog "⚠️ Extraction attempt $j failed: $($_.Exception.Message)"
            Start-Sleep -Seconds (3 * $j)
        }
    }

    if (-not $extracted) {
        Write-ErrorLog "❌ All extraction attempts failed"
        return $null
    }

    # 🧩 Inject fallback CMakeLists.txt if missing
    if (-not (Test-Path $cmakePath)) {
        $templateName = if ($Engine -eq "lua") { "CMakeLists.lua.txt" } else { "CMakeLists.luajit.txt" }
        $template     = Join-Path (Get-TemplatesRoot) "cmake\$templateName"

        if (Test-Path $template) {
            Copy-Item -Path $template -Destination $cmakePath -Force
            Write-InfoLog "🧩 Injected fallback template: $templateName"
        }
        else {
            Write-WarningLog "⚠️ No fallback template found for $Engine"
        }
    }

    return $extractPath
}

Export-ModuleMember -Function Get-SourceArchive
