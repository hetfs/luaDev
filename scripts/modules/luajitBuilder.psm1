# luajitBuilder.psm1
# ⚡ LuaJIT build module with optional DryRun simulation

function Build-LuaJIT {
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang",
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-InfoLog "🧪 [DryRun] Would build LuaJIT $Version ($BuildType/$Compiler) at $SourcePath"
        return $true
    }

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
        $cmakeArgs = @("-DCMAKE_BUILD_TYPE=Release", "-DTARGET_SYS=Windows")
        switch ($Compiler) {
            "clang" {
                $cmakeArgs += "-DCMAKE_C_COMPILER=clang"
                $cmakeArgs += "-DCMAKE_ASM_FLAGS=-integrated-as"
            }
            "mingw" { $cmakeArgs += "-G", "MinGW Makefiles" }
            "msvc"  { $cmakeArgs += "-A", "x64" }
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
            & cmake --build . --config Release --parallel
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed (exit $LASTEXITCODE)"
            }

            # 5. Artifact collection
            $artifactDir = Get-ArtifactPath -Engine "luajit" -Version $Version -BuildType $BuildType -Compiler $Compiler -Create
            $binDir = if (Test-Path "$buildDir/bin") { "$buildDir/bin" } else { $buildDir }

            $patterns = @(
                "luajit.exe", "luajit", "luajit-*",
                "lua51.dll", "liblua51.*",
                "luajit.lib", "libluajit.*"
            )

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
