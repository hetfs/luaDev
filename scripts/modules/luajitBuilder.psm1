function Build-LuaJIT {
    $sourcePath = Join-Path (Get-SourcesRoot) "LuaJIT"

    try {
        # Clone or update repository
        if (-not (Test-Path (Join-Path $sourcePath ".git"))) {
            Write-InfoLog "🌐 Cloning LuaJIT repository"
            & git clone --depth 1 https://github.com/LuaJIT/LuaJIT.git $sourcePath
        }
        else {
            Write-InfoLog "♻️ Using existing LuaJIT repository"
            Push-Location $sourcePath
            & git reset --hard
            & git clean -fdx
            Pop-Location
        }

        Push-Location $sourcePath

        # Get latest stable tag
        Write-InfoLog "🔖 Fetching tags"
        & git fetch --tags --quiet
        $latestTag = git tag -l "v*" |
            Where-Object { $_ -match '^v\d+\.\d+\.\d+$' } |
            Sort-Object { [System.Version]($_ -replace '^v', '') } -Descending |
            Select-Object -First 1

        if (-not $latestTag) {
            throw "No stable tags found in repository"
        }

        Write-InfoLog "💡 Checking out $latestTag"
        & git checkout $latestTag --quiet
        $version = $latestTag -replace '^v', ''

        # Build
        $osInfo = Get-OSPlatform
        Write-InfoLog "🏗️ Building LuaJIT $version for $($osInfo.Platform)"

        if ($osInfo.Platform -eq "windows") {
            Push-Location src
            & mingw32-make BUILDMODE=static
            Pop-Location
        }
        else {
            & make
        }

        # Install artifacts
        $artifactPath = Get-ArtifactPath -Engine "luajit" -Version $version -Create

        # Copy binaries with validation
        $binaries = if ($osInfo.Platform -eq "windows") {
            "luajit.exe", "lua51.dll"
        } else {
            "luajit"
        }

        $binaries | ForEach-Object {
            $sourceFile = Join-Path "src" $_
            if (-not (Test-Path $sourceFile)) {
                throw "Binary not found: $sourceFile"
            }
            Copy-Item $sourceFile $artifactPath -Force -ErrorAction Stop
        }

        return $version
    }
    catch {
        Write-ErrorLog "❌ LuaJIT build failed: $($_.Exception.Message)"
        return $null
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Build-LuaJIT
