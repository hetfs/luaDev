# luajitBuilder.psm1
# ⚡ Build LuaJIT 2.1 with CMake-based system and compiler selection

function Build-LuaJIT {
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang"
    )

    Write-VerboseLog "🔧 Starting LuaJIT $Version build with $Compiler ($BuildType)"

    try {
        # === 1. Generate CMakeLists.txt from templates ===
        $cmakeFile = Join-Path $SourcePath "CMakeLists.txt"
        $templateDir = Join-Path $PSScriptRoot "..\..\templates\cmake"

        # Get base and engine-specific templates
        $defaultTemplate = Join-Path $templateDir "CMakeLists.lua.default.txt"
        $engineTemplate = Join-Path $templateDir "CMakeLists.luajit.txt"

        $content = Get-Content $defaultTemplate -Raw
        $engineContent = Get-Content $engineTemplate -Raw

        # Combine templates
        $content = $content -replace '@VERSION_SPECIFIC@', $engineContent

        # Set build parameters
        $libraryType = if ($BuildType -eq "shared") { "SHARED" } else { "STATIC" }
        $sharedFlag = if ($BuildType -eq "shared") { "ON" } else { "OFF" }

        $content = $content -replace '@LIBRARY_TYPE@', $libraryType
        $content = $content -replace '@SHARED_FLAG@', $sharedFlag
        $content = $content -replace '\$\{LUA_VERSION\}', $Version

        # Handle LuaJIT version parts
        $versionParts = $Version -split '\.'
        $content = $content -replace '\$\{LUA_VERSION_MAJOR\}', $versionParts[0]
        $content = $content -replace '\$\{LUA_VERSION_MINOR\}', $versionParts[1]

        # Apply GC64 flag (LuaJIT specific)
        $content = $content -replace '@GC64_FLAG@', "-DLUAJIT_ENABLE_GC64"

        # Save to source directory
        Set-Content -Path $cmakeFile -Value $content -Encoding UTF8
        Write-InfoLog "📝 Generated CMakeLists.txt for LuaJIT $Version"

        # === 2. Prepare clean build directory ===
        $buildDir = Join-Path $SourcePath "build-$Compiler"
        if (Test-Path $buildDir) {
            Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

        # === 3. Construct CMake arguments ===
        $cmakeArgs = @(
            "-DCMAKE_BUILD_TYPE=Release",
            "-DTARGET_SYS=Windows"
        )

        switch ($Compiler) {
            "clang" {
                $cmakeArgs += "-DCMAKE_C_COMPILER=clang"
                # Apply integrated AS flag for Clang
                $cmakeArgs += "-DCMAKE_ASM_FLAGS=-integrated-as"
            }
            "mingw" { $cmakeArgs += @("-G", "MinGW Makefiles") }
            "msvc"  { $cmakeArgs += "-A", "x64" }
        }

        # === 4. Build with CMake ===
        Push-Location $buildDir
        try {
            Write-InfoLog "🛠️ Configuring CMake for LuaJIT $Version"
            & cmake $SourcePath @cmakeArgs
            if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed" }

            Write-InfoLog "🏗️ Building LuaJIT $Version..."
            & cmake --build . --config Release --parallel
            if ($LASTEXITCODE -ne 0) { throw "CMake build failed" }

            # === 5. Copy compiled artifacts ===
            $outDir = Get-ArtifactPath -Engine "luajit" -Version $Version -BuildType $BuildType -Compiler $Compiler -Create
            $binDir = if (Test-Path "$buildDir/bin") { "$buildDir/bin" } else { $buildDir }

            $copied = 0
            $expectedFiles = @("luajit.exe", "lua51.dll", "luajit.lib", "lua51.lib")

            foreach ($file in $expectedFiles) {
                $sourceFile = Join-Path $binDir $file
                if (Test-Path $sourceFile) {
                    Copy-Item -Path $sourceFile -Destination $outDir -Force
                    Write-VerboseLog "📦 Copied: $file"
                    $copied++
                }
            }

            if ($copied -eq 0) {
                throw "No compiled binaries found in: $binDir"
            }

            Write-InfoLog "✅ Build successful — $copied artifacts saved to: $outDir"
            return $true
        }
        catch {
            Write-ErrorLog "❌ Build-LuaJIT failed: $($_.Exception.Message)"
            return $false
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-ErrorLog "❌ LuaJIT build preparation failed: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Build-LuaJIT
