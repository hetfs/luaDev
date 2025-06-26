function Build-LuaVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Version,
        [Parameter(Mandatory)]
        [string]$SourcePath
    )

    $osInfo = Get-OSPlatform
    $artifactPath = Get-ArtifactPath -Engine "lua" -Version $Version -Create
    Push-Location $SourcePath

    try {
        Write-InfoLog "🏗️ Building Lua $Version for $($osInfo.Platform)"

        # Clean Makefile to remove AIX/FreeBSD duplicates
        $makefilePath = Join-Path $SourcePath "Makefile"
        if (Test-Path $makefilePath) {
            $content = Get-Content $makefilePath -Raw
            $content = $content -replace '(?m)^AIX:.*\r?\n', ''
            $content = $content -replace '(?m)^FreeBSD:.*\r?\n', ''
            $content | Set-Content $makefilePath -Force
        }

        # Platform-specific build
        switch ($osInfo.Platform) {
            "windows" { Build-LuaWindows -Version $Version }
            default   { Build-LuaUnix -Cores $osInfo.Cores }
        }

        # Copy binaries
        if ($osInfo.Platform -eq "windows") {
            $binDir = if ($Version.StartsWith("5.1")) { "." } else { "src" }
            $binaries = "lua.exe", "luac.exe"
        }
        else {
            $binDir = "src"
            $binaries = "lua", "luac"
        }

        $binaries | ForEach-Object {
            $sourceFile = Join-Path $binDir $_
            if (-not (Test-Path $sourceFile)) {
                throw "Binary not found: $sourceFile"
            }
            Copy-Item $sourceFile $artifactPath -Force -ErrorAction Stop
        }

        return $true
    }
    catch {
        Write-ErrorLog "❌ Build failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Build-LuaWindows {
    param([string]$Version)

    if ($Version.StartsWith("5.1")) {
        & mingw32-make PLAT=mingw TO_BIN="lua51.exe luac51.exe" lua51.exe luac51.exe
        Rename-Item "lua51.exe" "lua.exe" -ErrorAction SilentlyContinue
        Rename-Item "luac51.exe" "luac.exe" -ErrorAction SilentlyContinue
    }
    else {
        & mingw32-make PLAT=mingw CC=gcc
    }
}

function Build-LuaUnix {
    param([int]$Cores = 4)

    $env:PLAT = if ($IsMacOS) { "macosx" } else { "linux" }

    $makeCmd = if (Get-Command gmake -ErrorAction SilentlyContinue) { "gmake" } else { "make" }

    if ($Cores -gt 1) {
        & $makeCmd -j $Cores $env:PLAT
    }
    else {
        & $makeCmd $env:PLAT
    }
}

Export-ModuleMember -Function Build-LuaVersion
