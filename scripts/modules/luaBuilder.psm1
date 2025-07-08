# luaBuilder.psm1 - Enhanced Lua build process with version-specific templates

function Build-LuaEngine {
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang"
    )

    $Engine = "lua"
    $baseVersion = $Version.Substring(0, 3)

    try {
        # 1. Generate CMakeLists.txt using version-specific template
        $generateResult = Generate-CMakeLists -Engine $Engine -Version $Version `
            -SourcePath $SourcePath -BuildType $BuildType -Compiler $Compiler
        if (-not $generateResult) {
            throw "CMakeLists generation failed"
        }

        # 2. Prepare build directory
        $buildDir = Join-Path $SourcePath "build-$Compiler"
        if (Test-Path $buildDir) {
            Remove-Item $buildDir -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

        # 3. Configure CMake arguments based on compiler
        $cmakeArgs = @("-DCMAKE_BUILD_TYPE=Release")

        switch ($Compiler) {
            "clang" {
                $cmakeArgs += "-DCMAKE_C_COMPILER=clang"
            }
            "mingw" {
                $cmakeArgs += "-G", "MinGW Makefiles"
                $cmakeArgs += "-DCMAKE_C_COMPILER=gcc"
            }
            "msvc" {
                $cmakeArgs += "-A", "x64"
                $cmakeArgs += "-T", "host=x64"
            }
        }

        # 4. Execute build process
        Push-Location $buildDir
        try {
            Write-InfoLog "🛠️ Configuring CMake for Lua $Version ($Compiler)"
            & cmake $SourcePath @cmakeArgs
            if ($LASTEXITCODE -ne 0) {
                throw "CMake configuration failed (exit $LASTEXITCODE)"
            }

            Write-InfoLog "🏗️ Building Lua $Version with $Compiler ($BuildType)..."
            & cmake --build . --config Release --parallel
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed (exit $LASTEXITCODE)"
            }

            # 5. Prepare artifact directory
            $artifactDir = Get-ArtifactPath -Engine $Engine -Version $Version `
                -BuildType $BuildType -Compiler $Compiler

            if (-not (Test-Path $artifactDir)) {
                New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
            }

            # Determine bin/lib dirs
            $binDir = if (Test-Path "$buildDir/bin") { "$buildDir/bin" } else { $buildDir }
            $libDir = if (Test-Path "$buildDir/lib") { "$buildDir/lib" } else { $buildDir }

            # 6. Copy artifacts
            $patterns = @("lua*", "liblua.*", "*.a", "*.lib", "*.dll", "*.so", "*.dylib")
            $copiedCount = 0

            foreach ($pattern in $patterns) {
                $files = Get-ChildItem -Path $binDir, $libDir -Recurse -Include $pattern -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    if ($file.PSIsContainer -or $file.Extension -eq ".h") { continue }
                    $destPath = Join-Path $artifactDir $file.Name
                    Copy-Item -Path $file.FullName -Destination $destPath -Force
                    $copiedCount++
                    Write-VerboseLog "📦 Copied: $($file.Name)"
                }
            }

            if ($copiedCount -eq 0) {
                throw "No binaries copied from build directory"
            }

            # 7. Copy headers
            $headers = Get-ChildItem -Path $SourcePath -Recurse -Include "*.h"
            foreach ($header in $headers) {
                $destPath = Join-Path $artifactDir $header.Name
                Copy-Item -Path $header.FullName -Destination $destPath -Force
                Write-VerboseLog "📄 Copied header: $($header.Name)"
            }

            Write-InfoLog "✅ Lua $Version build successful - $copiedCount artifacts saved to: $artifactDir"
            return $true
        }
        catch {
            Write-ErrorLog "❌ Lua build failed: $($_.Exception.Message)"
            return $false
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-ErrorLog "❌ Lua build failed: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Build-LuaEngine
