<#
.SYNOPSIS
    Automated Lua/LuaJIT build system for Windows
.DESCRIPTION
    Builds Lua (5.1-5.4) and LuaJIT binaries for Windows
.PARAMETER Versions
    Target Lua versions (shorthand or full) e.g., "514" or "5.1.4"
.PARAMETER Engines
    Build targets: "lua", "luajit", or both
.PARAMETER BuildType
    Build configuration: "static" or "shared"
.PARAMETER Compiler
    Compiler toolchain: "msvc", "mingw", or "clang"
.PARAMETER LogLevel
    Output verbosity: Silent, Error, Warn, Info, Verbose, Debug
.EXAMPLE
    # Build Lua 5.4.8 and LuaJIT with Clang
    .\buildLua.ps1 -Versions 548 -Engines lua,luajit -Compiler clang
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
    [string]$LogLevel = "Info"
)

#region Initialization
$ScriptRoot = $PSScriptRoot
$ModulesPath = Join-Path $ScriptRoot "modules"

# Load core modules
Get-ChildItem $ModulesPath -Filter *.psm1 | ForEach-Object {
    Import-Module $_.FullName -Force -DisableNameChecking
}

# Configure diagnostics
Set-LogLevel -Level $LogLevel
Write-InfoLog "🚀 Starting Lua/LuaJIT build automation (Windows)"
Write-InfoLog "🔧 Configuration: BuildType=$BuildType, Compiler=$Compiler"

# Create logs directory
$logsRoot = Get-ScriptsLogsRoot
$logPath = Join-Path $logsRoot "buildLua.ps1.log"
Start-Transcript -Path $logPath -Append | Out-Null
#endregion

#region Environment Setup
# Verify required tools
$requiredTools = @("git", "cmake")
switch ($Compiler) {
    "mingw" { $requiredTools += "gcc" }
    "clang" { $requiredTools += "clang" }
    "msvc" { $requiredTools += "msbuild" }
}

$toolStatus = Confirm-ToolAvailability -Tools $requiredTools
if (-not $toolStatus.Available) {
    Write-ErrorLog "❌ Missing build tools: $($toolStatus.Missing -join ', ')"
    exit 1
}

# Initialize directories
Get-SourcesRoot | Out-Null
Get-ManifestsRoot | Out-Null
#endregion

#region Version Processing
$Engines = $Engines | ForEach-Object { $_.Trim().ToLower() } | Select-Object -Unique
Write-InfoLog "🔧 Build targets: $($Engines -join ', ')"

if ($Engines -contains "lua" -and -not $Versions) {
    $Versions = Get-LatestLuaVersions
    Write-InfoLog "🔍 Auto-detected Lua versions: $($Versions -join ', ')"
}

$BuildTargets = [System.Collections.Generic.List[string]]::new()
foreach ($v in $Versions) {
    $normalized = Convert-VersionShorthand $v
    if (Test-IsSupportedVersion $normalized) {
        $BuildTargets.Add($normalized)
        Write-VerboseLog "✓ Version resolved: $v → $normalized"
    }
    else {
        Write-WarningLog "⚠️ Skipping unsupported version: $v → $normalized"
    }
}

if ($BuildTargets.Count -eq 0 -and $Engines -contains "lua") {
    Write-ErrorLog "❌ No valid Lua versions specified"
    exit 1
}
#endregion

#region Build Execution
$Artifacts = [System.Collections.Generic.List[hashtable]]::new()
$startTime = [DateTime]::UtcNow
$osInfo = Get-OSPlatform

# Process Lua builds
if ($Engines -contains "lua") {
    foreach ($version in $BuildTargets) {
        $artifact = @{
            Engine = "lua"
            Version = $version
            BuildType = $BuildType
            Compiler = $Compiler
            Platform = $osInfo.Platform
            Architecture = $osInfo.Architecture
            BuildTime = [DateTime]::UtcNow
            Success = $false
        }

        try {
            Write-InfoLog "📦 Building Lua $version ($BuildType) with $Compiler"
            $srcDir = Get-LuaSource -Version $version
            if (-not $srcDir) {
                throw "Source download failed"
            }
            $buildResult = Build-LuaVersion -Version $version -SourcePath $srcDir -BuildType $BuildType -Compiler $Compiler

            if ($buildResult) {
                $artifact.Success = $true
                $Artifacts.Add($artifact)
                Write-InfoLog "✅ Built Lua $version successfully"
            }
        }
        catch {
            $Artifacts.Add($artifact)
            Write-ErrorLog "🚨 Lua $version failed: $($_.Exception.Message)"
        }
    }
}

# Process LuaJIT build
if ($Engines -contains "luajit") {
    $artifact = @{
        Engine = "luajit"
        Version = "unknown"
        BuildType = $BuildType
        Compiler = $Compiler
        Platform = $osInfo.Platform
        Architecture = $osInfo.Architecture
        BuildTime = [DateTime]::UtcNow
        Success = $false
    }

    try {
        Write-InfoLog "⚡ Building LuaJIT ($BuildType) with $Compiler"
        $jitVersion = Build-LuaJIT -BuildType $BuildType -Compiler $Compiler

        if ($jitVersion) {
            $artifact.Version = $jitVersion
            $artifact.Success = $true
            $Artifacts.Add($artifact)
            Write-InfoLog "✅ Built LuaJIT $jitVersion successfully"
        }
    }
    catch {
        $Artifacts.Add($artifact)
        Write-ErrorLog "🚨 LuaJIT failed: $($_.Exception.Message)"
    }
}
#endregion

#region Artifact Processing
$successCount = ($Artifacts | Where-Object { $_.Success }).Count
$duration = [Math]::Round(([DateTime]::UtcNow - $startTime).TotalMinutes, 2)

if ($successCount -gt 0) {
    # Generate reports
    Export-LuaBuildManifest -Artifacts $Artifacts
    Write-InfoLog "📝 Manifests saved to $(Get-ManifestsRoot)"

    # Final status
    Write-InfoLog "🏁 Completed in ${duration}m | Success: $successCount/$($Artifacts.Count)"
    $Artifacts | ForEach-Object {
        $status = if ($_.Success) { "✅" } else { "❌" }
        Write-Host "  $status [$($_.Engine)] $($_.Version) ($($_.BuildType)/$($_.Compiler))" -ForegroundColor $(if($_.Success){"Green"}else{"Red"})
    }
    exit 0
}
else {
    Write-ErrorLog "💥 Build failed - no artifacts produced (Duration: ${duration}m)"
    exit 1
}
#endregion
