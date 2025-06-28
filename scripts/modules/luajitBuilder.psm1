function Build-LuaJIT {
    param(
        [Parameter(Mandatory)][string]$BuildType,
        [Parameter(Mandatory)][string]$Compiler
    )

    $sourcePath = Join-Path (Get-SourcesRoot) "LuaJIT"
    $buildMode = if ($BuildType -eq "shared") { "dynamic" } else { "static" }

    try {
        # Clone or update repository
        if (-not (Test-Path (Join-Path $sourcePath ".git"))) {
            Write-InfoLog "🌐 Cloning LuaJIT repository (v2.1 branch)"
            & git clone --branch v2.1 --single-branch --depth 1 https://github.com/LuaJIT/LuaJIT.git $sourcePath
        }
        else {
            Write-InfoLog "♻️ Updating LuaJIT repository"
            Push-Location $sourcePath
            & git checkout v2.1
            & git pull origin v2.1
            & git reset --hard
            & git clean -fdx
            Pop-Location
        }

        Push-Location $sourcePath

        # Get version information
        $commitHash = & git rev-parse --short HEAD
        $version = "2.1-$commitHash"
        Write-InfoLog "💡 Building LuaJIT version: $version"

        # Apply critical Windows patch
        $patchApplied = $false
        $makefilePath = Join-Path $sourcePath "src" "Makefile"
        if (Test-Path $makefilePath) {
            $makefileContent = Get-Content $makefilePath -Raw

            # Patch 1: Replace uname dependency
            $makefileContent = $makefileContent -replace 'HOST_SYS\s*:=\s*\$\(shell uname -s\)', 'HOST_SYS := Windows'

            # Patch 2: Fix version generation
            $makefileContent = $makefileContent -replace '\.\/ljarch\.h', 'ljarch.h'

            Set-Content $makefilePath $makefileContent
            $patchApplied = $true
            Write-VerboseLog "🔧 Applied critical Makefile patches"
        }

        # Build
        Write-InfoLog "🏗️ Building LuaJIT $version ($buildMode) with $Compiler"

        # Set compiler environment variables
        $env:CC = if ($Compiler -eq "clang") { "clang" } else { "gcc" }
        $env:HOST_CC = $env:CC

        # Determine best make command to use
        $makeCmd = if (Get-Command "mingw32-make" -ErrorAction SilentlyContinue) {
            "mingw32-make"
        } else {
            "make"
        }

        # Build flags
        $buildArgs = @(
            "BUILDMODE=$buildMode",
            "TARGET_SYS=Windows",
            "HOST_SYS=Windows",
            "Q="  # Quiet mode
        )

        # Add Clang-specific flags
        if ($Compiler -eq "clang") {
            $buildArgs += "CCFLAGS=-integrated-as"
            $buildArgs += "ASFLAGS=-integrated-as"
            $buildArgs += "XCFLAGS=-DLUAJIT_ENABLE_GC64"
        } else {
            $buildArgs += "XCFLAGS=-DLUAJIT_ENABLE_GC64"
        }

        # Build
        Write-VerboseLog "🔧 Running: $makeCmd $($buildArgs -join ' ')"
        & $makeCmd @buildArgs 2>&1 | Tee-Object -Variable buildOutput
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code $LASTEXITCODE"
        }

        # Install artifacts
        $artifactPath = Get-ArtifactPath -Engine "luajit" -Version $version -BuildType $BuildType -Compiler $Compiler -Create

        # Copy binaries
        $binaries = @("luajit.exe", "lua51.dll")
        $copiedFiles = 0

        $binaries | ForEach-Object {
            $sourceFile = Join-Path "src" $_
            if (Test-Path $sourceFile) {
                Copy-Item $sourceFile $artifactPath -Force
                $copiedFiles++
                Write-VerboseLog "📦 Copied: $sourceFile"
            }
        }

        # Copy static library if exists
        $libName = if ($BuildType -eq "static") { "luajit.lib" } else { "lua51.lib" }
        $libPath = Join-Path "src" $libName
        if (Test-Path $libPath) {
            Copy-Item $libPath $artifactPath -Force
            $copiedFiles++
            Write-VerboseLog "📦 Copied: $libPath"
        }

        if ($copiedFiles -eq 0) {
            throw "No binaries found in src directory"
        }

        Write-InfoLog "✅ Copied $copiedFiles files to $artifactPath"
        return $version
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-ErrorLog "❌ LuaJIT build failed: $errorMessage"
        return $null
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Build-LuaJIT
