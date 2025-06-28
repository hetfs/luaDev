function Build-LuaVersion {
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$BuildType,
        [Parameter(Mandatory)][string]$Compiler
    )

    $artifactPath = Get-ArtifactPath -Engine "lua" -Version $Version -BuildType $BuildType -Compiler $Compiler -Create
    Push-Location $SourcePath

    try {
        # Create build directory
        $buildDir = Join-Path $SourcePath "build"
        New-Item $buildDir -ItemType Directory -Force | Out-Null

        # Configure build parameters
        $cmakeParams = @(
            "-S", $SourcePath,
            "-B", $buildDir,
            "-DCMAKE_BUILD_TYPE=Release"
        )

        # Build type configuration
        if ($BuildType -eq "shared") {
            $cmakeParams += "-DBUILD_SHARED_LIBS=ON"
        }
        else {
            $cmakeParams += "-DBUILD_SHARED_LIBS=OFF"
        }

        # Compiler-specific configuration
        switch ($Compiler) {
            "mingw" {
                $cmakeParams += "-G", "MinGW Makefiles"
            }
            "clang" {
                $cmakeParams += "-G", "Ninja"
                $cmakeParams += "-DCMAKE_C_COMPILER=clang"
                $cmakeParams += "-DCMAKE_CXX_COMPILER=clang++"
            }
            "msvc" {
                $cmakeParams += "-A", "x64"
            }
        }

        # Run CMake configuration
        Write-InfoLog "🛠️ Configuring build (Type: $BuildType, Compiler: $Compiler)"
        & cmake @cmakeParams
        if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed" }

        # Build with CMake
        $buildParams = @("--build", $buildDir, "--config", "Release")
        if ((Get-OSPlatform).Cores -gt 1) {
            $buildParams += "--", "/maxcpucount"
        }

        Write-InfoLog "🏗️ Building binaries..."
        & cmake @buildParams
        if ($LASTEXITCODE -ne 0) { throw "Build failed" }

        # Copy artifacts
        $binDir = if ($Compiler -eq "msvc") {
            Join-Path $buildDir "Release"
        } else {
            $buildDir
        }

        $binaries = Get-ChildItem $binDir -Include *.exe, *.dll, *.lib
        $binaries | Copy-Item -Destination $artifactPath -Force

        Write-InfoLog "📦 Artifacts copied to: $artifactPath"
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

Export-ModuleMember -Function Build-LuaVersion
