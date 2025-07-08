# cmake.psm1 - Fixed replacement logic
function Generate-CMakeLists {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateSet("static", "shared")]
        [string]$BuildType,

        [Parameter(Mandatory)]
        [ValidateSet("msvc", "mingw", "clang")]
        [string]$Compiler
    )

    $templatesDir = Join-Path (Get-TemplatesRoot) "cmake"

    # Get base template
    $templatePath = if ($Engine -eq "lua") {
        Join-Path $templatesDir "CMakeLists.lua.default.txt"
    } else {
        Join-Path $templatesDir "CMakeLists.luajit.txt"
    }

    if (-not (Test-Path $templatePath)) {
        throw "Base template not found: $templatePath"
    }

    # Read base template content
    $content = Get-Content $templatePath -Raw

    # Apply base replacements
    $content = $content -replace '@LUA_VERSION@', $Version
    $content = $content -replace '@SHARED_FLAG@',
        $(if ($BuildType -eq "shared") { "ON" } else { "OFF" })

    # Apply engine-specific replacements
    if ($Engine -eq "lua") {
        # Get version-specific configuration
        $versionKey = $Version.Substring(0, 3)  # 5.4.8 -> 5.4
        $versionTemplate = "CMakeLists.$versionKey.txt"
        $versionPath = Join-Path $templatesDir $versionTemplate

        if (-not (Test-Path $versionPath)) {
            Write-WarningLog "⚠️ Version template not found: $versionPath"
            $versionContent = "# No version-specific configuration"
        } else {
            $versionContent = Get-Content $versionPath -Raw
            # Apply version replacements in version-specific content
            $versionContent = $versionContent -replace '@LUA_VERSION@', $Version
        }

        # Insert version-specific content
        $content = $content -replace '@VERSION_SPECIFIC@', $versionContent
    }
    else {
        # LuaJIT specific replacements
        $content = $content -replace '@GC64_FLAG@',
            $(if ($Version -match "2\.1") { "-DLUAJIT_ENABLE_GC64" } else { "" })
    }

    # Save generated file
    $outputPath = Join-Path $SourcePath "CMakeLists.txt"
    try {
        Set-Content -Path $outputPath -Value $content -Encoding UTF8 -Force
        Write-InfoLog "✅ Generated CMakeLists.txt for $Engine $Version ($BuildType/$Compiler)"
        return $true
    }
    catch {
        Write-ErrorLog "❌ Failed to write CMakeLists: $($_.Exception.Message)"
        return $false
    }
}
