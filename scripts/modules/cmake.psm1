function Generate-CMakeLists {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory)]
        [string]$Version,  # Removed ValidateSet to support LuaJIT versions

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateSet("static", "shared")]
        [string]$BuildType
    )

    $templatesDir = Join-Path $PSScriptRoot "..\..\templates\cmake"
    $defaultTemplate = "CMakeLists.lua.default.txt"

    # 1. Load base template
    $templatePath = Join-Path $templatesDir $defaultTemplate
    if (-not (Test-Path $templatePath)) {
        throw "Base template not found: $templatePath"
    }
    $content = Get-Content $templatePath -Raw

    # 2. Apply version-specific configuration
    $versionKey = if ($Engine -eq "lua") {
        ($Version -split '\.')[0..1] -join '.'  # Extract major.minor (5.3, 5.4, etc.)
    } else {
        $Version  # For LuaJIT use full version (2.1, 2.1.0, etc.)
    }

    $versionTemplate = "CMakeLists.$versionKey.txt"
    $versionConfigPath = Join-Path $templatesDir $versionTemplate

    if (Test-Path $versionConfigPath) {
        $versionContent = Get-Content $versionConfigPath -Raw
        $content = $content -replace '@VERSION_SPECIFIC@', $versionContent
    } else {
        Write-WarningLog "⚠️ Version template not found: $versionTemplate"
    }

    # 3. Apply engine-specific configuration
    $engineTemplate = "CMakeLists.$Engine.txt"
    $engineConfigPath = Join-Path $templatesDir $engineTemplate

    if ($Engine -eq "luajit" -and (Test-Path $engineConfigPath)) {
        $engineContent = Get-Content $engineConfigPath -Raw
        $content = $content -replace '@ENGINE_SPECIFIC@', $engineContent

        # Handle LuaJIT version parts
        $versionParts = $Version -split '\.'
        $content = $content -replace '\$\{LUA_VERSION_MAJOR\}', $versionParts[0]
        if ($versionParts.Count -ge 2) {
            $content = $content -replace '\$\{LUA_VERSION_MINOR\}', $versionParts[1]
        }
        if ($versionParts.Count -ge 3) {
            $content = $content -replace '\$\{LUA_VERSION_PATCH\}', $versionParts[2]
        }
    }

    # 4. Set build parameters
    $replacements = @{
        '@LIBRARY_TYPE@'   = if ($BuildType -eq "shared") { "SHARED" } else { "STATIC" }
        '@SHARED_FLAG@'    = if ($BuildType -eq "shared") { "ON" } else { "OFF" }
        '${LUA_VERSION}'   = $versionKey
        '${LUA_ENGINE}'    = $Engine
        '@GC64_FLAG@'      = if ($Engine -eq "luajit") { "-DLUAJIT_ENABLE_GC64" } else { "" }
    }

    foreach ($key in $replacements.Keys) {
        $content = $content -replace [regex]::Escape($key), $replacements[$key]
    }

    # 5. Save generated file
    $outputPath = Join-Path $SourcePath "CMakeLists.txt"
    try {
        Set-Content -Path $outputPath -Value $content -Encoding UTF8 -Force
        Write-InfoLog "✅ Generated CMakeLists.txt for $Engine $Version ($BuildType)"
        return $true
    }
    catch {
        Write-ErrorLog "❌ Failed to write CMakeLists: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Generate-CMakeLists
