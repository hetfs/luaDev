# luajitBuilder.psm1 - Enhanced LuaJIT build module

function Build-LuaJIT {
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang"
    )

    try {
        # 1. Generate CMakeLists.txt
        if (-not (Generate-CMakeLists -Engine "luajit" -Version $Version -SourcePath $SourcePath -BuildType $BuildType)) {
            throw "CMakeLists generation failed"
        }

        # 2. Prepare build directory
        $buildDir = Join-Path $SourcePath "build-$Compiler"
        if (Test-Path $buildDir) {
            Remove-Item $buildDir -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

        # 3. Configure CMake arguments
        $cmakeArgs = @(
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLUAJIT_VERSION=$Version"
        )

        # Add platform-specific flags
        if ($IsWindows) {
            $cmakeArgs += "-DTARGET_SYS=Windows"
        } elseif ($IsMacOS) {
            $cmakeArgs += "-DTARGET_SYS=Darwin"
        } else {
            $cmakeArgs += "-DTARGET_SYS=Linux"
        }

        # Add compiler-specific flags
        switch ($Compiler) {
            "clang" {
                $cmakeArgs += "-DCMAKE_C_COMPILER=clang"
                $cmakeArgs += "-DCMAKE_ASM_COMPILER=clang"
            }
            "mingw" {
                $cmakeArgs += "-G", "MinGW Makefiles"
                $cmakeArgs += "-DCMAKE_C_COMPILER=gcc"
            }
            "msvc"  {
                $cmakeArgs += "-A", "x64"
                $cmakeArgs += "-T", "host=x64"
            }
        }

        # 4. Build process
        Push-Location $buildDir
        try {
            Write-InfoLog "🛠️ Configuring LuaJIT $Version with $Compiler"
            & cmake $SourcePath @cmakeArgs
            if ($LASTEXITCODE -ne 0) {
                throw "CMake configuration failed (exit $LASTEXITCODE)"
            }

            Write-InfoLog "🏗️ Building LuaJIT $Version ($BuildType)"
            $buildCommand = "cmake --build . --config Release --parallel"
            Invoke-Expression $buildCommand
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed (exit $LASTEXITCODE)"
            }

            # 5. Artifact collection
            $artifactDir = Get-ArtifactPath -Engine "luajit" -Version $Version -BuildType $BuildType -Compiler $Compiler -Create

            # Copy binaries from multiple locations
            $copyPaths = @("$buildDir/bin", "$buildDir/lib", $buildDir)
            $patterns = @("luajit*", "lua51*", "libluajit*")

            $copiedCount = 0
            foreach ($path in $copyPaths) {
                if (Test-Path $path) {
                    foreach ($pattern in $patterns) {
                        $binaries = Get-ChildItem -Path $path -Recurse -Include $pattern -ErrorAction SilentlyContinue
                        foreach ($file in $binaries) {
                            # Skip directories and headers
                            if ($file.PSIsContainer -or $file.Extension -eq ".h") { continue }

                            $destPath = Join-Path $artifactDir $file.Name
                            Copy-Item -Path $file.FullName -Destination $destPath -Force
                            $copiedCount++
                            Write-VerboseLog "📦 Copied: $($file.Name)"
                        }
                    }
                }
            }

            # Copy headers for development
            $headers = Get-ChildItem -Path $SourcePath -Recurse -Include "*.h"
            foreach ($header in $headers) {
                $destPath = Join-Path $artifactDir $header.Name
                Copy-Item -Path $header.FullName -Destination $destPath -Force
                Write-VerboseLog "📄 Copied header: $($header.Name)"
            }

            if ($copiedCount -eq 0) {
                throw "No binaries copied from build directory"
            }

            Write-InfoLog "✅ LuaJIT $Version build successful - $copiedCount artifacts saved to: $artifactDir"
            return $true
        }
        catch {
            Write-ErrorLog "❌ Build phase failed: $($_.Exception.Message)"
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
