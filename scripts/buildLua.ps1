<#
.SYNOPSIS
    Enterprise-grade Lua/LuaJIT build automation solution
.DESCRIPTION
    Cross-platform build system for Lua (5.1–5.4) and LuaJIT (2.0.5+) with
    support for Clang, MSVC, and MinGW compilers. Features dry-run simulation,
    automatic source fetching, and structured artifact generation.
.PARAMETER EngineVersions
    Specific versions to build (e.g., 5.4.8, 2.1.0)
.PARAMETER Engines
    Engines to build: lua and/or luajit (default: both)
.PARAMETER BuildType
    Build configuration: static or shared (default: static)
.PARAMETER Compiler
    Compiler toolchain: clang, msvc, mingw (default: clang)
.PARAMETER LogLevel
    Verbosity: Silent, Error, Warn, Info, Verbose, Debug (default: Info)
.PARAMETER Clean
    Purge logs and binaries before building
.PARAMETER DryRun
    Simulate build without execution
.EXAMPLE
    .\buildLua.ps1 -DryRun
.EXAMPLE
    .\buildLua.ps1 -V 5.4.8,2.1.0
.EXAMPLE
    .\buildLua.ps1 -Clean -Engines luajit
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs,

    [Alias("Versions", "V")]
    [string[]]$EngineVersions = @(),

    [ValidateSet("lua", "luajit")]
    [string[]]$Engines = @("lua", "luajit"),

    [ValidateSet("static", "shared")]
    [string]$BuildType = "static",

    [ValidateSet("msvc", "mingw", "clang")]
    [string]$Compiler = "clang",

    [ValidateSet("Silent", "Error", "Warn", "Info", "Verbose", "Debug")]
    [string]$LogLevel = "Info",

    [switch]$Clean,
    [switch]$DryRun
)

#region Logging Setup
$ErrorActionPreference = "Stop"

# --- Setup logs directory and fix visibility ---
$rawLogDir = Join-Path $PSScriptRoot "logs"
$logDir = (Resolve-Path -Path $rawLogDir -ErrorAction SilentlyContinue)?.Path

if (-not $logDir) {
    try {
        $logDir = (New-Item -ItemType Directory -Force -Path $rawLogDir).FullName
    } catch {
        Write-Host "❌ Failed to create logs directory: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Normalize path
$logDir = $logDir -replace '\\', '/'

# Force remove Hidden/System attributes
try {
    $item = Get-Item -LiteralPath $logDir -Force
    $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::Hidden)
    $item.Attributes = $item.Attributes -band (-bnot [System.IO.FileAttributes]::System)
} catch {
    Write-Host "⚠️ Could not reset logs/ attributes: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean previous log files
try {
    Get-ChildItem -Path "$logDir/*" -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
} catch {
    Write-Host "⚠️ Failed to clean logs/: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- Create timestamped log file ---
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = "$logDir/buildLua-$timestamp.log"

function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )
    $stamp = "[$(Get-Date -Format u)]"
    $line = "$stamp $Message"
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
    $line | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Wrapper functions for different log levels
function Write-InfoLog($msg) {
    if ($LogLevel -in "Info", "Verbose", "Debug") {
        Write-Log -Message "[INFO] $msg" -Color Cyan
    } else {
        # Log to file only
        $stamp = "[$(Get-Date -Format u)]"
        "$stamp [INFO] $msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

function Write-WarningLog($msg) {
    if ($LogLevel -in "Warn", "Info", "Verbose", "Debug") {
        Write-Log -Message "[WARN] $msg" -Color Yellow
    } else {
        $stamp = "[$(Get-Date -Format u)]"
        "$stamp [WARN] $msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

function Write-ErrorLog($msg) {
    if ($LogLevel -ne "Silent") {
        Write-Log -Message "[ERROR] $msg" -Color Red
    } else {
        $stamp = "[$(Get-Date -Format u)]"
        "$stamp [ERROR] $msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

function Write-VerboseLog($msg) {
    if ($LogLevel -in "Verbose", "Debug") {
        Write-Log -Message "[VERBOSE] $msg" -Color DarkGray
    } else {
        $stamp = "[$(Get-Date -Format u)]"
        "$stamp [VERBOSE] $msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

function Write-DebugLog($msg) {
    if ($LogLevel -eq "Debug") {
        Write-Log -Message "[DEBUG] $msg" -Color DarkMagenta
    } else {
        $stamp = "[$(Get-Date -Format u)]"
        "$stamp [DEBUG] $msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

Write-Log "=== 🚀 LuaDev Build System ===" -Color Cyan
Write-Log "Log file: $logFile"
Write-Log "Script version: 1.0.0" -Color DarkGray
#endregion

#region Initialization
$SCRIPT_VERSION = "1.0.0"
$startTime = Get-Date
$showHelp = $false
$showVersion = $false

# Parse legacy arguments
foreach ($arg in $RemainingArgs) {
    switch ($arg) {
        { $_ -in '-h', '-?', '--help', '/?' } { $showHelp = $true }
        { $_ -in '-v', '--version' } { $showVersion = $true }
    }
}

if ($showVersion) {
    Write-Log "luaDev Build System v$SCRIPT_VERSION" -Color Green
    exit 0
}

if ($showHelp) {
    Get-Help $MyInvocation.MyCommand.Definition -Detailed | Out-String | Write-Log
    exit 0
}

$ScriptRoot = $PSScriptRoot
#endregion

#region Clean Operation
if ($Clean) {
    Write-InfoLog "🚮 Initializing clean operation..."
    $pathsToClean = @(
        (Join-Path $ScriptRoot ".." "LuaBinaries")
    )

    foreach ($path in $pathsToClean) {
        if (Test-Path $path) {
            try {
                if ($PSCmdlet.ShouldProcess($path, "Remove directory")) {
                    Remove-Item -Recurse -Force $path -ErrorAction Stop
                    Write-InfoLog "🧹 Successfully cleaned: $path"
                }
            }
            catch {
                Write-ErrorLog "❌ Clean failed for $path : $($_.Exception.Message)"
            }
        }
        else {
            Write-VerboseLog "Skipping clean (path not found): $path"
        }
    }
}
#endregion

#region Module System
$ModulesPath = Join-Path $ScriptRoot "modules"

# Default implementations (overridden by modules)
function global:Get-BuildSystemVersion { $SCRIPT_VERSION }
function global:Set-LogLevel { param($Level) $script:LogLevel = $Level }
function global:Test-IsSupportedVersion { param($Engine, $Version) $true }
function global:Get-OSPlatform {
    return @{
        Platform = if ($IsWindows) { "Windows" } elseif ($IsLinux) { "Linux" } elseif ($IsMacOS) { "macOS" } else { "Unknown" }
        Architecture = if ($IsWindows) { $env:PROCESSOR_ARCHITECTURE } else { (uname -m) }
    }
}
function global:Export-LogAsMarkdown {
    param($MarkdownPath, $LogLines, $Title)
    $content =
"# $Title
````log
$($LogLines -join "`n")
````"
    $content | Set-Content -Path $MarkdownPath
}
function global:Export-LuaBuildManifest { param($Artifacts) }
function global:Export-BuildLogsToDocs { param([switch]$Force) }
function global:Get-LatestEngineVersions {
    param($Engine)
    return $Engine -eq 'lua' ?
        @('5.4.8', '5.3.6', '5.2.4', '5.1.5') :
        @('2.1.0-beta3', '2.0.5')
}
function global:Get-SourcePath {
    param($Engine, $Version)
    Join-Path $ScriptRoot ".." "sources" "$Engine-$Version"
}
function global:Build-LuaEngine {
    param($Engine, $Version, $SourcePath, $BuildType, $Compiler)
    return $true
}

# Dynamic module loading with verbose/debug passthrough
try {
    $loaderPath = Join-Path $ModulesPath "loader.psm1"
    if (Test-Path $loaderPath) {
        Import-Module $loaderPath -Force -DisableNameChecking
        if (Get-Command Import-LuaDevModules -ErrorAction SilentlyContinue) {
            # ✅ Forward -Verbose and -Debug from buildLua.ps1
            Import-LuaDevModules -ModulesPath $ModulesPath -Verbose:$VerbosePreference -Debug:$DebugPreference
        }
    }
    else {
        Write-VerboseLog "Module loader not found: $loaderPath"
    }
}
catch {
    Write-WarningLog "⚠️ Module loader exception: $($_.Exception.Message)"
}

# Optional: Debug visibility for module load results
if ($LogLevel -eq "Debug") {
    $loadedModulesVar = Get-Variable -Scope Global -Name "loadedModules" -ErrorAction SilentlyContinue
    if ($loadedModulesVar) {
        Write-DebugLog "Modules loaded: $($loadedModulesVar.Value -join ', ')"
    } else {
        Write-DebugLog "No loadedModules variable detected (maybe fallback mode skipped tracking)"
    }
}


# Apply log level if supported
if (Get-Command Set-LogLevel -ErrorAction SilentlyContinue) {
    Set-LogLevel -Level $LogLevel
}
#endregion

#region Build Planning
Write-InfoLog "🚀 Initiating build process"
Write-InfoLog "⚙️ Configuration:"
Write-InfoLog "  - Build Type: $BuildType"
Write-InfoLog "  - Compiler: $Compiler"
Write-InfoLog "  - Dry Run: $($DryRun.IsPresent)"

$osInfo = Get-OSPlatform
Write-InfoLog "🌐 Platform: $($osInfo.Platform) ($($osInfo.Architecture))"

$BuildTargets = [System.Collections.Generic.List[hashtable]]::new()
$Engines = $Engines | Select-Object -Unique

# Resolve target versions
foreach ($engine in $Engines) {
    $versions = if ($EngineVersions) {
        # Filter by engine-specific version patterns
        $pattern = if ($engine -eq 'lua') { '^5\.\d+\.\d+' } else { '^2\.\d+\.\d+' }
        $EngineVersions | Where-Object { $_ -match $pattern }
    }
    else {
        Get-LatestEngineVersions -Engine $engine
    }

    if (-not $versions) {
        Write-WarningLog "⚠️ No versions resolved for engine: $engine"
        continue
    }

    foreach ($version in $versions) {
        if (Test-IsSupportedVersion -Engine $engine -Version $version) {
            $BuildTargets.Add(@{
                Engine = $engine
                Version = $version
            })
            Write-VerboseLog "🎯 Target registered: $engine/$version"
        }
        else {
            Write-WarningLog "⚠️ Unsupported version: $engine/$version"
        }
    }
}

# Validate targets
if ($BuildTargets.Count -eq 0) {
    Write-ErrorLog "❌ Critical: No valid build targets found"
    exit 1
}

Write-InfoLog "🎯 Build targets: $($BuildTargets.Count)"
$BuildTargets | ForEach-Object {
    Write-VerboseLog "    - $($_.Engine) $($_.Version)"
}
#endregion

#region Build Execution
$Artifacts = @()

function InvokeBuildTarget {
    param($target, $osInfo, $DryRun)

    $meta = @{
        Engine = $target.Engine
        Version = $target.Version
        Compiler = $Compiler
        BuildType = $BuildType
        Platform = $osInfo.Platform
        Architecture = $osInfo.Architecture
        BuildStart = [DateTime]::UtcNow
        BuildEnd = $null
        Success = $false
        Duration = $null
    }

    try {
        if ($DryRun) {
            Write-InfoLog "[DRYRUN] Build simulation: $($meta.Engine)/$($meta.Version)"
            $meta.Success = $true
        }
        else {
$src = Get-SourcePath -Engine $meta.Engine -Version $meta.Version
if (-not (Test-Path $src)) {
    Write-WarningLog "📦 Missing source: $($meta.Engine) $($meta.Version) — attempting auto-fetch..."
    if (Get-Command Get-SourceArchive -ErrorAction SilentlyContinue) {
        $fetchedPath = Get-SourceArchive -Engine $meta.Engine -Version $meta.Version
        if ($fetchedPath -and (Test-Path $fetchedPath)) {
            $src = $fetchedPath
            Write-InfoLog "✅ Auto-fetch successful: $src"
        } else {
            throw "Auto-fetch failed for $($meta.Engine) $($meta.Version)"
        }
    } else {
        throw "Source directory missing and Get-SourceArchive not available: $src"
    }
}

            $buildStart = Get-Date
            $meta.Success = Build-LuaEngine @meta -SourcePath $src
            $meta.Duration = [Math]::Round(((Get-Date) - $buildStart).TotalSeconds, 2)
        }
    }
    catch {
        $meta.Error = $_.Exception.Message
        Write-ErrorLog "❌ Build failure: $($meta.Engine)/$($meta.Version) - $($meta.Error)"
    }
    finally {
        $meta.BuildEnd = [DateTime]::UtcNow
    }

    return $meta
}

try {
    Write-InfoLog "🔨 Sequential build mode activated"
    foreach ($target in $BuildTargets) {
        $Artifacts += InvokeBuildTarget -target $target -osInfo $osInfo -DryRun:$DryRun.IsPresent
    }
}
catch {
    Write-ErrorLog "🔥 Critical build error: $($_.Exception.Message)"
    exit 2
}
#endregion

#-------------region Post-Build Processing
$successCount = ($Artifacts | Where-Object { $_.Success }).Count
$failureCount = $Artifacts.Count - $successCount
$totalDuration = [Math]::Round(((Get-Date) - $startTime).TotalMinutes, 2)

# Generate artifacts
try {
    # Markdown report
    $lines = Get-Content $logFile -ErrorAction SilentlyContinue
    if ($lines) {
        $mdPath = $logFile.Replace('.log', '.md')
        Export-LogAsMarkdown -MarkdownPath $mdPath -LogLines $lines -Title "Build Report - $timestamp"
        Write-InfoLog "📝 Generated Markdown report: $mdPath"
    }

    # JSON log
    $jsonPath = $logFile.Replace('.log', '.json')
    $Artifacts | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-InfoLog "📄 Generated JSON log: $jsonPath"

    # Manifest and docs
    if ($successCount -gt 0) {
        Export-LuaBuildManifest -Artifacts $Artifacts
        Export-BuildLogsToDocs -Force
        Write-InfoLog "📦 Published artifacts to documentation system"
    }
}
catch {
    Write-ErrorLog "❌ Artifact generation failed: $($_.Exception.Message)"
}

# Build summary
Write-Log ""
Write-Log "=== BUILD SUMMARY ===" -Color Magenta
Write-Log "🕒 Total Duration: $totalDuration minutes" -Color Cyan
Write-Log "✅ Successes: $successCount" -Color Green
if ($failureCount -gt 0) {
    Write-Log "❌ Failures: $failureCount" -Color Red
} else {
    Write-Log "❌ Failures: $failureCount" -Color Gray
}
Write-Log ""

$Artifacts | ForEach-Object {
    $status = if ($_.Success) { "✅" } else { "❌" }
    $color = if ($_.Success) { "Green" } else { "Red" }
    $durationInfo = if ($_.Duration) { "in ${$_.Duration}s" } else { "" }
    Write-Log "$status [$($_.Engine)] $($_.Version) ($($_.BuildType)/$($_.Compiler)) $durationInfo" -Color $color
}

Write-Log ""
Write-Log "📝 Log policy: Only current session log preserved" -Color DarkGray
Write-Log "Logs available at: $logDir" -Color Cyan
#endregion

exit ($failureCount -eq 0 ? 0 : 1)
