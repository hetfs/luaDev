<#
.SYNOPSIS
    Automated Lua/LuaJIT build system
.DESCRIPTION
    Builds Lua (5.1-5.4) and LuaJIT binaries
.PARAMETER Versions
    Target versions (shorthand or full) e.g., "514" or "5.1.4"
    Aliases: V
.PARAMETER Engines
    Build targets: "lua", "luajit", or both
    Aliases: E
.PARAMETER LogLevel
    Output verbosity: Silent, Error, Warn, Info, Verbose, Debug
    Aliases: LL
.EXAMPLE
    # Build all Lua versions
    .\buildLua.ps1
.EXAMPLE
    # Build specific version (shorthand)
    .\buildLua.ps1 -V 514
#>

[CmdletBinding()]
param (
    [Alias("V")]
    [string[]]$Versions = @(),
    [Alias("E")]
    [ValidateSet("lua", "luajit")]
    [string[]]$Engines = @("lua"),
    [Alias("LL")]
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
Write-InfoLog "🚀 Starting Lua/LuaJIT build automation"

# Create logs directory
$logsRoot = Get-ScriptsLogsRoot
$logPath = Join-Path $logsRoot "buildLua.ps1.log"
Start-Transcript -Path $logPath -Append | Out-Null
#endregion

#region Environment Setup
# Verify required tools
$requiredTools = @("make", "tar")
if ($IsWindows) { $requiredTools += "gcc" }
if ($Engines -contains "luajit") { $requiredTools += "git" }

$toolStatus = Confirm-ToolAvailability -Tools $requiredTools
if (-not $toolStatus.Available) {
    Write-ErrorLog "❌ Missing build tools: $($toolStatus.Missing -join ', ')"
    Write-InfoLog "💡 Installation instructions:"
    $toolStatus.Suggestions | ForEach-Object { Write-InfoLog "  $_" }
    exit 1
}

# Initialize directories
Get-SourcesRoot | Out-Null
Get-ManifestsRoot | Out-Null
#endregion

#region Version Processing
$Engines = $Engines | ForEach-Object { $_.Trim().ToLower() } | Select-Object -Unique
Write-InfoLog "🔧 Build targets: $($Engines -join ', ')"

if (-not $Versions) {
    $Versions = Get-LatestLuaVersions
    Write-InfoLog "🔍 Auto-detected versions: $($Versions -join ', ')"
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
            Platform = $osInfo.Platform
            Architecture = $osInfo.Architecture
            BuildTime = [DateTime]::UtcNow
            Success = $false
        }

        try {
            Write-InfoLog "📦 Building Lua $version"
            $srcDir = Get-LuaSource -Version $version
            if (-not $srcDir) {
                throw "Source download failed"
            }
            $buildResult = Build-LuaVersion -Version $version -SourcePath $srcDir

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
        Platform = $osInfo.Platform
        Architecture = $osInfo.Architecture
        BuildTime = [DateTime]::UtcNow
        Success = $false
    }

    try {
        Write-InfoLog "⚡ Building LuaJIT"
        $jitVersion = Build-LuaJIT

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
        Write-Host "  $status [$($_.Engine)] $($_.Version)" -ForegroundColor $(if($_.Success){"Green"}else{"Red"})
    }
    exit 0
}
else {
    Write-ErrorLog "💥 Build failed - no artifacts produced (Duration: ${duration}m)"
    exit 1
}
#endregion
