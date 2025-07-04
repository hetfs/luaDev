# luaBuilder.psm1

function Build-LuaEngine {
    param (
        [Parameter(Mandatory)][string]$Engine,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang",
        [switch]$DryRun
    )

    # ✅ Simulate build in DryRun mode
    if ($DryRun) {
        Write-InfoLog "🧪 [DryRun] Would build Lua $Version ($BuildType / $Compiler) at $SourcePath"
        Write-InfoLog "✅ [DryRun] Simulated build completed: $Engine $Version ($BuildType / $Compiler)"
        return $true
    }

    if (-not (Test-Path $SourcePath)) {
        Write-ErrorLog "❌ Source directory not found: $SourcePath"
        return $false
    }

    try {
        # 1. Generate CMakeLists.txt
        $generateResult = Generate-CMakeLists -Engine $Engine -Version $Version `
            -SourcePath $SourcePath -BuildType $BuildType
        if (-not $generateResult) {
            throw "CMakeLists generation failed"
        }

        # 2. Prepare build directory
        $buildDir = Join-Path $SourcePath "build-$Compiler"
        if (Test-Path $buildDir) {
            Remove-Item $buildDir -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

        # 3. Configure CMake arguments
        $cmakeArgs = @("-DCMAKE_BUILD_TYPE=Release")
        switch ($Compiler) {
            "clang"  { $cmakeArgs += "-DCMAKE_C_COMPILER=clang" }
            "mingw"  { $cmakeArgs += "-G", "MinGW Makefiles" }
            "msvc"   { $cmakeArgs += "-A", "x64" }
            default  { Write-WarningLog "⚠️ Using default CMake generator for $Compiler" }
        }

        # 4. Execute build process
        Push-Location $buildDir
        try {
            Write-InfoLog "🛠️ Configuring CMake for $($Engine.ToUpper()) $Version"
            & cmake $SourcePath @cmakeArgs
            if ($LASTEXITCODE -ne 0) {
                throw "CMake configuration failed (exit $LASTEXITCODE)"
            }

            Write-InfoLog "🏗️ Building $($Engine.ToUpper()) $Version with $Compiler..."
            $buildCommand = if ($IsWindows -and $Compiler -eq "msvc") {
                "cmake --build . --config Release --parallel"
            } else {
                "cmake --build . --config Release --parallel"
            }
            Invoke-Expression $buildCommand
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed (exit $LASTEXITCODE)"
            }

            # 5. Collect artifacts
            $artifactDir = Get-ArtifactPath -Engine $Engine -Version $Version `
                -BuildType $BuildType -Compiler $Compiler -Create
            $binDir = if (Test-Path "$buildDir/bin") { "$buildDir/bin" } else { $buildDir }

            $patterns = if ($Engine -eq "luajit") {
                @("*.exe", "*.dll", "*.lib", "*.a", "*.so", "*.dylib", "luajit*")
            } else {
                @("*.exe", "*.dll", "*.lib", "*.a", "*.so", "*.dylib", "lua*")
            }

            $copiedCount = 0
            foreach ($pattern in $patterns) {
                $binaries = Get-ChildItem -Path $binDir -Recurse -Include $pattern -ErrorAction SilentlyContinue
                foreach ($file in $binaries) {
                    $destPath = Join-Path $artifactDir $file.Name
                    Copy-Item -Path $file.FullName -Destination $destPath -Force
                    $copiedCount++
                    Write-VerboseLog "📦 Copied: $($file.Name)"
                }
            }

            if ($copiedCount -eq 0) {
                throw "No binaries copied from build directory"
            }

            Write-InfoLog "✅ Build successful - $copiedCount artifacts saved to: $artifactDir"
            return $true
        }
        catch {
            Write-ErrorLog "❌ $($Engine.ToUpper()) build failed: $($_.Exception.Message)"
            return $false
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-ErrorLog "❌ Build failed: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Build-LuaEngine
