function Generate-CMakeLists {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory=$true)]
        [ValidateSet("5.1", "5.2", "5.3", "5.4")]
        [string]$Version,

        [Parameter(Mandatory=$true)]
        [string]$SourcePath,

        [Parameter(Mandatory=$true)]
        [ValidateSet("static", "shared")]
        [string]$BuildType
    )

    $templatesDir = Join-Path $PSScriptRoot "..\..\templates\cmake"
    $versionSpecificFile = "CMakeLists.$Version.txt"
    $defaultTemplate = "CMakeLists.lua.default.txt"
    $engineTemplate = "CMakeLists.luajit.txt"

    # Get base template
    $templatePath = Join-Path $templatesDir $defaultTemplate
    $content = Get-Content $templatePath -Raw

    # Apply version-specific configurations
    $versionConfigPath = Join-Path $templatesDir $versionSpecificFile
    if (Test-Path $versionConfigPath) {
        $versionContent = Get-Content $versionConfigPath -Raw
        $content = $content -replace '@VERSION_SPECIFIC@', $versionContent
    }

    # Apply engine-specific configurations
    if ($Engine -eq "luajit") {
        $engineConfigPath = Join-Path $templatesDir $engineTemplate
        if (Test-Path $engineConfigPath) {
            $engineContent = Get-Content $engineConfigPath -Raw
            $content = $content -replace '@VERSION_SPECIFIC@', $engineContent
        }
    }

    # Set build parameters
    $libraryType = if ($BuildType -eq "shared") { "SHARED" } else { "STATIC" }
    $sharedFlag = if ($BuildType -eq "shared") { "ON" } else { "OFF" }

    $content = $content -replace '@LIBRARY_TYPE@', $libraryType
    $content = $content -replace '@SHARED_FLAG@', $sharedFlag
    $content = $content -replace '${LUA_VERSION}', $Version
    $content = $content -replace '${LUA_ENGINE}', $Engine

    # Handle LuaJIT version formatting
    if ($Engine -eq "luajit") {
        $versionParts = $Version -split '\.'
        $content = $content -replace '${LUA_VERSION_MAJOR}', $versionParts[0]
        $content = $content -replace '${LUA_VERSION_MINOR}', $versionParts[1]
    }

    # Save to source directory
    $outputPath = Join-Path $SourcePath "CMakeLists.txt"
    Set-Content -Path $outputPath -Value $content -Encoding UTF8

    Write-InfoLog "Generated CMakeLists.txt for $Engine $Version ($BuildType)"
}

Export-ModuleMember -Function Generate-CMakeLists
