# luajitBuilder.psm1

function Build-LuaJIT {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang",
        [switch]$PreviewOnly
    )

    $Engine = "luajit"

    try {
        # 1. Generate CMakeLists.txt
        $result = Generate-CMakeLists -Engine $Engine -Version $Version `
            -SourcePath $SourcePath -BuildType $BuildType -Compiler $Compiler `
            -PreviewOnly:$PreviewOnly

        if (-not $result) {
            throw "CMakeLists generation failed for LuaJIT $Version"
        }

        if ($PreviewOnly) {
            return $true
        }

        # 2. Prepare build directory
        $buildDir = Join-Path $SourcePath "build-$Compiler"
        if (Test-Path $buildDir) {
            Remove-Item -Path $buildDir -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

        # 3. Configure CMake arguments
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

        # 4. Configure and build
        Push-Location $buildDir
        try {
            Write-InfoLog "🛠️ Configuring CMake for LuaJIT $Version ($Compiler)"
            & cmake $SourcePath @cmakeArgs
            if ($LASTEXITCODE -ne 0) {
                throw "CMake configuration failed (exit $LASTEXITCODE)"
            }

            Write-InfoLog "🏗️ Building LuaJIT $Version with $Compiler ($BuildType)..."
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

            # 6. Copy artifacts
            $binDir = if (Test-Path "$buildDir/bin") { "$buildDir/bin" } else { $buildDir }
            $libDir = if (Test-Path "$buildDir/lib") { "$buildDir/lib" } else { $buildDir }

            $patterns = @("luajit*", "*.a", "*.lib", "*.dll", "*.so", "*.dylib")
            $copied = 0
            foreach ($pattern in $patterns) {
                $files = Get-ChildItem -Path $binDir, $libDir -Recurse -Include $pattern -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    if ($file.PSIsContainer -or $file.Extension -eq ".h") { continue }
                    $dest = Join-Path $artifactDir $file.Name
                    Copy-Item -Path $file.FullName -Destination $dest -Force
                    Write-VerboseLog "📦 Copied: $($file.Name)"
                    $copied++
                }
            }

            if ($copied -eq 0) {
                throw "No binaries copied from build output"
            }

            # 7. Copy headers
            $headers = Get-ChildItem -Path $SourcePath -Recurse -Include "*.h"
            foreach ($h in $headers) {
                $dest = Join-Path $artifactDir $h.Name
                Copy-Item -Path $h.FullName -Destination $dest -Force
                Write-VerboseLog "📄 Copied header: $($h.Name)"
            }

            Write-InfoLog "✅ LuaJIT $Version build successful - $copied artifacts saved to: $artifactDir"
            return $true
        }
        catch {
            Write-ErrorLog "❌ LuaJIT build failed: $($_.Exception.Message)"
            return $false
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-ErrorLog "❌ LuaJIT build failed: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Build-LuaJIT
