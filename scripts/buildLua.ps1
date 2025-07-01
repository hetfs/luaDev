<#
.SYNOPSIS
    Cross-platform Lua/LuaJIT build automation script for Windows
.DESCRIPTION
    Downloads and builds Lua 5.1–5.4 and LuaJIT using compilers like Clang, MSVC, or MinGW with CMake-based workflows.
.PARAMETER Versions
    Specific Lua versions to build (e.g., 5.1.4 or 514 shorthand)
.PARAMETER Engines
    List of engines: lua, luajit, or both
.PARAMETER BuildType
    Build configuration: static or shared
.PARAMETER Compiler
    Compiler toolchain to use: clang, msvc, mingw
.PARAMETER LogLevel
    Logging verbosity: Silent, Error, Warn, Info, Verbose, Debug
.PARAMETER Clean
    Optional. Removes logs and build artifacts before build
#>

[CmdletBinding()]
param (
    [string[]]$Versions = @(),
    [ValidateSet("lua", "luajit")]
    [string[]]$Engines = @("lua"),
    [ValidateSet("static", "shared")]
    [string]$BuildType = "static",
    [ValidateSet("msvc", "mingw", "clang")]
    [string]$Compiler = "clang",
    [ValidateSet("Silent", "Error", "Warn", "Info", "Verbose", "Debug")]
    [string]$LogLevel = "Info",
    [switch]$Clean
)

#region 🔁 Setup
$ScriptRoot = $PSScriptRoot
$ModulesPath = Join-Path $ScriptRoot "modules"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
$logFolder = Join-Path $ScriptRoot "..\logs\build\$timestamp"
$null = New-Item -Path $logFolder -ItemType Directory -Force
$logPath = Join-Path $logFolder "buildLua.ps1.log"
Start-Transcript -Path $logPath -Append | Out-Null

# Load modules first
$moduleFiles = Get-ChildItem -Path $ModulesPath -Filter *.psm1 -File -Recurse -ErrorAction SilentlyContinue
foreach ($file in $moduleFiles) {
    try {
        Import-Module -Name $file.FullName -Force -DisableNameChecking -ErrorAction Stop
    } catch {
        Write-Warning "⚠️ Failed to load module: $($file.FullName) — $($_.Exception.Message)"
    }
}

Set-LogLevel -Level $LogLevel
Write-InfoLog "🚀 Build automation started"
Write-InfoLog "🔧 Config: BuildType=$BuildType, Compiler=$Compiler, Clean=$($Clean.IsPresent)"
#endregion

#region 🧹 Clean Mode
if ($Clean) {
    $cleanTargets = @(
        Join-Path $ScriptRoot "..\logs\build",
        Join-Path $ScriptRoot "..\binaries"
    )
    foreach ($target in $cleanTargets) {
        if (Test-Path $target) {
            Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue
            Write-InfoLog "🧹 Cleaned: $target"
        }
    }
}
#endregion

#region 🛠️ Check Required Tools
$requiredTools = @("git", "cmake")
switch ($Compiler) {
    "mingw" { $requiredTools += "gcc" }
    "clang" { $requiredTools += "clang" }
    "msvc"  { $requiredTools += "msbuild" }
}
$toolStatus = Confirm-ToolAvailability -Tools $requiredTools
if (-not $toolStatus.Available) {
    Write-ErrorLog "❌ Missing required tools: $($toolStatus.Missing -join ', ')"
    Stop-Transcript | Out-Null
    exit 1
}
#endregion

#region 📦 Resolve Versions
$Engines = $Engines | ForEach-Object { $_.Trim().ToLower() } | Select-Object -Unique
Write-InfoLog "🧠 Engines selected: $($Engines -join ', ')"

if ($Engines -contains "lua" -and -not $Versions) {
    $Versions = Get-LatestLuaVersions
    Write-InfoLog "🔍 Auto-resolved Lua versions: $($Versions -join ', ')"
}

$BuildTargets = [System.Collections.Generic.List[string]]::new()
foreach ($v in $Versions) {
    $normalized = Convert-VersionShorthand $v
    if (Test-IsSupportedVersion $normalized) {
        $BuildTargets.Add($normalized)
    } else {
        Write-WarningLog "⚠️ Skipping unsupported version: $v → $normalized"
    }
}

if ($BuildTargets.Count -eq 0 -and $Engines -contains "lua") {
    Write-ErrorLog "💥 No valid Lua versions to build"
    Stop-Transcript | Out-Null
    exit 1
}
#endregion

#region 🏗️ Build Loop
$startTime = [DateTime]::UtcNow
$osInfo = Get-OSPlatform
$Artifacts = @()

foreach ($version in $BuildTargets) {
    $artifact = @{
        Engine       = "lua"
        Version      = $version
        BuildType    = $BuildType
        Compiler     = $Compiler
        Platform     = $osInfo.Platform
        Architecture = $osInfo.Architecture
        BuildTime    = [DateTime]::UtcNow
        Success      = $false
    }

    try {
        Write-InfoLog "📦 Building Lua $version..."
        $srcDir = Get-LuaSource -Version $version
        if (-not $srcDir) { throw "Failed to fetch Lua source" }

        # Per-version config
        $configPath = Join-Path $ScriptRoot "configs/lua-$version/build_config.json"
        $customConfig = if (Test-Path $configPath) { Get-Content $configPath | ConvertFrom-Json } else { $null }

        $buildOK = Build-LuaVersion -Version $version -SourcePath $srcDir `
            -BuildType $BuildType -Compiler $Compiler -Config $customConfig

        if ($buildOK) {
            $artifact.Success = $true
            Write-InfoLog "✅ Build successful: Lua $version"
        } else {
            Write-ErrorLog "❌ Build failed: Lua $version"
        }
    }
    catch {
        Write-ErrorLog ("🚨 Lua $version failed: {0}" -f $_.Exception.Message)
    }

    $Artifacts += $artifact
}
#endregion

#region 📜 Post-Build Logging
$successCount = ($Artifacts | Where-Object { $_.Success }).Count
$duration = [Math]::Round(([DateTime]::UtcNow - $startTime).TotalMinutes, 2)

Stop-Transcript | Out-Null
$logLines = Get-Content $logPath
$mdLogPath = Join-Path $logFolder "build.md"
$jsonPath  = Join-Path $logFolder "build.json"

Import-Module "$ModulesPath/logging/export.psm1" -ErrorAction SilentlyContinue
Export-LogAsMarkdown -MarkdownPath $mdLogPath -LogLines $logLines -Title "Build Log - $timestamp"
$Artifacts | ConvertTo-Json -Depth 6 | Set-Content $jsonPath -Encoding UTF8

if ($successCount -gt 0) {
    Export-LuaBuildManifest -Artifacts $Artifacts
    Write-InfoLog "📝 Manifest exported → $(Get-ManifestsRoot)"
    Write-InfoLog "🏁 Build finished in ${duration}m — $successCount successful builds"
    $Artifacts | ForEach-Object {
        $symbol = if ($_.Success) { "✅" } else { "❌" }
        $color  = if ($_.Success) { "Green" } else { "Red" }
        Write-Host "  $symbol [$($_.Engine)] $($_.Version) ($($_.BuildType)/$($_.Compiler))" -ForegroundColor $color
    }
    exit 0
} else {
    Write-ErrorLog "💥 All builds failed — Duration: ${duration}m"
    exit 1
}
#endregion
