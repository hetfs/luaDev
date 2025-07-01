# luaBuilder.psm1

function Build-LuaVersion {
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang"
    )

    Write-VerboseLog "🔧 Starting Lua $Version build with $Compiler ($BuildType)"

    # === 1. Generate CMakeLists.txt from templates ===
    $cmakeFile = Join-Path $SourcePath "CMakeLists.txt"
    $templateDir = Join-Path $PSScriptRoot "..\..\templates\cmake"

    # Extract major.minor version (5.1, 5.2, etc.)
    $versionKey = ($Version -split '\.')[0..1] -join '.'

    # Generate from templates
    try {
        # Get base template
        $defaultTemplate = Join-Path $templateDir "CMakeLists.lua.default.txt"
        $content = Get-Content $defaultTemplate -Raw

        # Apply version-specific configurations
        $versionTemplate = Join-Path $templateDir "CMakeLists.$versionKey.txt"
        if (Test-Path $versionTemplate) {
            $versionContent = Get-Content $versionTemplate -Raw
            $content = $content -replace '@VERSION_SPECIFIC@', $versionContent
        }

        # Set build parameters
        $libraryType = if ($BuildType -eq "shared") { "SHARED" } else { "STATIC" }
        $sharedFlag = if ($BuildType -eq "shared") { "ON" } else { "OFF" }

        $content = $content -replace '@LIBRARY_TYPE@', $libraryType
        $content = $content -replace '@SHARED_FLAG@', $sharedFlag
        $content = $content -replace '\$\{LUA_VERSION\}', $versionKey

        # Save to source directory
        Set-Content -Path $cmakeFile -Value $content -Encoding UTF8
        Write-InfoLog "📝 Generated CMakeLists.txt for Lua $versionKey"
    }
    catch {
        Write-ErrorLog "❌ CMake template generation failed: $($_.Exception.Message)"
        return $false
    }

    # === 2. Prepare clean build directory ===
    $buildDir = Join-Path $SourcePath "build-$Compiler"
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

    # === 3. Construct CMake arguments ===
    $cmakeArgs = @("-DCMAKE_BUILD_TYPE=Release")

    switch ($Compiler) {
        "clang" { $cmakeArgs += "-DCMAKE_C_COMPILER=clang" }
        "mingw" { $cmakeArgs += @("-G", "MinGW Makefiles") }
        "msvc"  { $cmakeArgs += "-A", "x64" }
    }

    # === 4. Build with CMake ===
    Push-Location $buildDir
    try {
        Write-InfoLog "🛠️ Configuring CMake for Lua $Version"
        & cmake $SourcePath @cmakeArgs
        if ($LASTEXITCODE -ne 0) { throw "CMake configuration failed" }

        Write-InfoLog "🏗️ Building Lua $Version..."
        & cmake --build . --config Release --parallel
        if ($LASTEXITCODE -ne 0) { throw "CMake build failed" }

        # === 5. Copy compiled artifacts ===
        $outDir = Get-ArtifactPath -Engine "lua" -Version $Version -BuildType $BuildType -Compiler $Compiler -Create
        $binDir = if (Test-Path "$buildDir/bin") { "$buildDir/bin" } else { $buildDir }

        $binaries = Get-ChildItem -Path $binDir -Recurse -Include *.exe, *.dll, *.lib, *.a, *.so, *.dylib -ErrorAction SilentlyContinue
        if (-not $binaries) {
            Write-WarningLog "⚠️ No compiled binaries found in: $binDir"
        }

        $binaries | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $outDir -Force
        }

        Write-InfoLog "✅ Build successful — artifacts saved to: $outDir"
        return $true
    }
    catch {
        Write-ErrorLog "❌ Build-LuaVersion failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Build-LuaJIT {
    param (
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$SourcePath,
        [ValidateSet("static", "shared")][string]$BuildType = "static",
        [ValidateSet("msvc", "mingw", "clang")][string]$Compiler = "clang"
    )

    Write-VerboseLog "🔧 Starting LuaJIT $Version build with $Compiler ($BuildType)"

    # === 1. Generate CMakeLists.txt from templates ===
    $cmakeFile = Join-Path $SourcePath "CMakeLists.txt"
    $templateDir = Join-Path $PSScriptRoot "..\..\templates\cmake"

    try {
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

        # Save to source directory
        Set-Content -Path $cmakeFile -Value $content -Encoding UTF8
        Write-InfoLog "📝 Generated CMakeLists.txt for LuaJIT $Version"
    }
    catch {
        Write-ErrorLog "❌ CMake template generation failed: $($_.Exception.Message)"
        return $false
    }

    # === 2. Prepare clean build directory ===
    $buildDir = Join-Path $SourcePath "build-$Compiler"
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

    # === 3. Construct CMake arguments ===
    $cmakeArgs = @("-DCMAKE_BUILD_TYPE=Release")

    switch ($Compiler) {
        "clang" { $cmakeArgs += "-DCMAKE_C_COMPILER=clang" }
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

        $binaries = Get-ChildItem -Path $binDir -Recurse -Include *.exe, *.dll, *.lib, *.a, *.so, *.dylib -ErrorAction SilentlyContinue
        if (-not $binaries) {
            Write-WarningLog "⚠️ No compiled binaries found in: $binDir"
        }

        $binaries | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $outDir -Force
        }

        Write-InfoLog "✅ Build successful — artifacts saved to: $outDir"
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

Export-ModuleMember -Function Build-LuaVersion, Build-LuaJIT
