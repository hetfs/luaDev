<#
.SYNOPSIS
    Cross-platform Lua/LuaJIT build automation script.
.DESCRIPTION
    Downloads and builds Lua 5.1–5.4 and LuaJIT using Clang, MSVC, or MinGW via CMake.
.PARAMETER EngineVersions
    Specific versions to build (e.g., 5.4.6, 2.1.0).
.PARAMETER Engines
    Engines to build: lua or luajit.
.PARAMETER BuildType
    Build configuration: static or shared.
.PARAMETER Compiler
    Compiler toolchain: clang, msvc, mingw.
.PARAMETER LogLevel
    Verbosity level: Silent, Error, Warn, Info, Verbose, Debug.
.PARAMETER Clean
    Cleans logs and binaries before building.
.PARAMETER MaxParallelJobs
    Max parallel builds (defaults to CPU count).
.PARAMETER DryRun
    Simulate build steps without executing them.
.PARAMETER Parallel
    Enable parallel builds across targets.
#>

[CmdletBinding()]
param (
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs,

    [Alias("Versions", "V")]
    [string[]]$EngineVersions = @(),

    [ValidateSet("lua", "luajit")]
    [string[]]$Engines = @("lua"),

    [ValidateSet("static", "shared")]
    [string]$BuildType = "static",

    [ValidateSet("msvc", "mingw", "clang")]
    [string]$Compiler = "clang",

    [ValidateSet("Silent", "Error", "Warn", "Info", "Verbose", "Debug")]
    [string]$LogLevel = "Info",

    [int]$MaxParallelJobs = [Environment]::ProcessorCount,
    [switch]$Clean,
    [switch]$DryRun,
    [switch]$Parallel
)

# --- Region: CLI Helpers ---
$showHelp = $false
$showVersion = $false

foreach ($arg in $RemainingArgs) {
    switch ($arg) {
        { $_ -in '-h', '--help', '-?', '/?' } { $showHelp = $true; continue }
        { $_ -in '-v', '--version' } { $showVersion = $true; continue }
        { $_ -in '-V', '--V' } {
            if (-not $EngineVersions) {
                Write-Host "❗ -V requires one or more version numbers. Use -v for version info." -ForegroundColor Red
                exit 1
            }
        }
    }
}

if ($showVersion) {
    Write-Host "luaDev Build System v1.0.0" -ForegroundColor Green
    exit 0
}

if ($showHelp) {
    Write-Host @"
luaDev Build System v1.0.0
-----------------------------------------------
USAGE:
  .\buildLua.ps1
    [-EngineVersions <ver1,ver2,...>]
    [-Engines {lua,luajit}]
    [-BuildType {static,shared}]
    [-Compiler {clang,mingw,msvc}]
    [-LogLevel {Silent,Error,Warn,Info,Verbose,Debug}]
    [-MaxParallelJobs <int>]
    [-Clean] [-DryRun] [-Parallel]

ALIASES:
  -h, --help        Show this help message
  -v, --version     Show build system version
  -V, --Versions    Alias for -EngineVersions
"@
    exit 0
}

# --- Region: Init ---
$ScriptRoot = $PSScriptRoot
$ModulesPath = Join-Path $ScriptRoot "modules"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
$logFolder = Join-Path $ScriptRoot "..\logs\build\$timestamp"
$logPath = Join-Path $logFolder "build.log"

New-Item -ItemType Directory -Force -Path $logFolder | Out-Null
Start-Transcript -Path $logPath -Append | Out-Null

# --- Logging Helpers ---
function Write-InfoLog { param($msg) if ($LogLevel -in "Info","Verbose","Debug") { Write-Host "[INFO] $msg" -ForegroundColor Cyan } }
function Write-WarningLog { param($msg) if ($LogLevel -in "Warn","Info","Verbose","Debug") { Write-Host "[WARN] $msg" -ForegroundColor Yellow } }
function Write-ErrorLog { param($msg) if ($LogLevel -ne "Silent") { Write-Host "[ERROR] $msg" -ForegroundColor Red } }
function Write-VerboseLog { param($msg) if ($LogLevel -in "Verbose","Debug") { Write-Host "[VERBOSE] $msg" -ForegroundColor DarkGray } }

# --- Region: Clean ---
if ($Clean) {
    foreach ($folder in @("logs\build", "LuaBinaries")) {
        $path = Join-Path $ScriptRoot "..\$folder"
        if (Test-Path $path) {
            try {
                Remove-Item -Recurse -Force $path -ErrorAction Stop
                Write-InfoLog "🧹 Cleaned: $path"
            } catch {
                Write-ErrorLog "❌ Failed to clean $folder: $(${_.Exception.Message})"
            }
        }
    }
}

# --- Region: Stub Functions (Override via Modules) ---
function global:Get-BuildSystemVersion { "1.0.0" }
function global:Set-LogLevel { param($Level) }
function global:Test-IsSupportedVersion { $true }
function global:Get-OSPlatform {
    return @{
        Platform = if ($IsWindows) { "Windows" } elseif ($IsLinux) { "Linux" } elseif ($IsMacOS) { "macOS" } else { "Unknown" }
        Architecture = $env:PROCESSOR_ARCHITECTURE ?? [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    }
}
function global:Export-LogAsMarkdown { param($MarkdownPath, $LogLines, $Title) }
function global:Export-LuaBuildManifest { param($Artifacts) }
function global:Export-BuildLogsToDocs { param($Force) }
function global:Get-LatestEngineVersions {
    param($Engine)
    if ($Engine -eq 'lua') { @('5.4.8', '5.3.6', '5.2.4', '5.1.5') }
    else { @('2.1.0-beta3', '2.0.5') }
}
function global:Get-SourcePath {
    param($Engine, $Version)
    Join-Path $PSScriptRoot "..\sources\$Engine-$Version"
}
function global:Build-LuaEngine { $true }

# --- Region: Load Modules ---
try {
    Import-Module (Join-Path $ModulesPath "loader.psm1") -Force -DisableNameChecking -ErrorAction Stop
    Import-LuaDevModules -ModulesPath $ModulesPath -ErrorAction Stop
} catch {
    Write-WarningLog "⚠️ Module loading failed: $(${_.Exception.Message})"
}

if (Get-Command Set-LogLevel -ErrorAction SilentlyContinue) {
    Set-LogLevel -Level $LogLevel
}

# --- Region: Build Plan ---
Write-InfoLog "🚀 Starting Build @ $timestamp"
Write-InfoLog "⚙️ Config: Type=$BuildType, Compiler=$Compiler, DryRun=$DryRun, Parallel=$Parallel, Jobs=$MaxParallelJobs"

$defaultVersions = @{ lua = @("5.4.6", "5.3.6", "5.2.4", "5.1.5"); luajit = @("2.1.0-beta3", "2.0.5") }
$Engines = $Engines | ForEach-Object { $_.ToLower() } | Select-Object -Unique
$BuildTargets = [System.Collections.Generic.List[hashtable]]::new()

foreach ($engine in $Engines) {
    $versions = if ($EngineVersions) {
        $EngineVersions | Where-Object { $_ -match $(if ($engine -eq "lua") { "^5\." } else { "^2\." }) }
    } else {
        Get-LatestEngineVersions -Engine $engine
    }

    foreach ($version in $versions) {
        if (Test-IsSupportedVersion -Engine $engine -Version $version) {
            $BuildTargets.Add(@{ Engine = $engine; Version = $version })
            Write-VerboseLog "🎯 Target queued: $engine $version"
        } else {
            Write-WarningLog "⚠️ Unsupported: $engine $version"
        }
    }
}

if (-not $BuildTargets.Count) {
    Write-ErrorLog "❌ No valid targets found"
    exit 1
}

# --- Region: Build Execution ---
$osInfo = Get-OSPlatform
$startTime = Get-Date
$Artifacts = @()

function InvokeBuildTarget {
    param ($target, $osInfo, $DryRun)

    $meta = @{
        Engine      = $target.Engine
        Version     = $target.Version
        Compiler    = $Compiler
        BuildType   = $BuildType
        Platform    = $osInfo.Platform
        Architecture = $osInfo.Architecture
        BuildTime   = [DateTime]::UtcNow
        Success     = $false
    }

    try {
        $src = Get-SourcePath -Engine $meta.Engine -Version $meta.Version
        if (-not (Test-Path $src)) { throw "Source not found: $src" }

        if ($DryRun) {
            Write-InfoLog "[DRYRUN] Would build $($meta.Engine) $($meta.Version)"
            $meta.Success = $true
        } else {
            $meta.Success = Build-LuaEngine -Engine $meta.Engine -Version $meta.Version -SourcePath $src -BuildType $BuildType -Compiler $Compiler
        }
    } catch {
        $meta.Error = $_.Exception.Message
        Write-ErrorLog "❌ Build failed: $($meta.Engine) $($meta.Version) — $($meta.Error)"
    }

    return $meta
}

if ($Parallel) {
    $jobs = @()
    $sem = [System.Threading.SemaphoreSlim]::new($MaxParallelJobs)

    foreach ($target in $BuildTargets) {
        $sem.Wait()
        $jobs += Start-ThreadJob -Name "$($target.Engine)-$($target.Version)" -ScriptBlock {
            param($target, $ModulesPath, $BuildType, $Compiler, $DryRun, $osInfo)
            try {
                Import-Module "$using:ModulesPath\loader.psm1" -Force
                Import-LuaDevModules -ModulesPath "$using:ModulesPath"
            } catch {}
            InvokeBuildTarget -target $target -osInfo $osInfo -DryRun:$DryRun
        } -ArgumentList $target, $ModulesPath, $BuildType, $Compiler, $DryRun, $osInfo
    }

    $Artifacts += ($jobs | Wait-Job | ForEach-Object { Receive-Job $_; Remove-Job $_ })
} else {
    foreach ($target in $BuildTargets) {
        $Artifacts += InvokeBuildTarget -target $target -osInfo $osInfo -DryRun:$DryRun
    }
}

# --- Region: Export ---
$lines = Get-Content $logPath -ErrorAction SilentlyContinue
if ($lines) {
    Export-LogAsMarkdown -MarkdownPath (Join-Path $logFolder "build.md") -LogLines $lines -Title "Build Report - $timestamp"
}

$Artifacts | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $logFolder "build.json") -Encoding UTF8

$success = ($Artifacts | Where-Object { $_.Success }).Count
$fail = $Artifacts.Count - $success
$duration = [Math]::Round(((Get-Date) - $startTime).TotalMinutes, 2)

if ($success -gt 0) {
    Export-LuaBuildManifest -Artifacts $Artifacts
    Export-BuildLogsToDocs -Force
    Write-InfoLog "📦 Logs & Manifest pushed to docs/dev/logs"
}

Write-InfoLog "🏁 Build complete: ${duration}m | ✅ $success | ❌ $fail"
$Artifacts | ForEach-Object {
    $s = if ($_.Success) { "✅" } else { "❌" }
    Write-Host "$s [$($_.Engine)] $($_.Version) ($($_.BuildType)/$($_.Compiler))" -ForegroundColor Gray
}

exit ($fail -eq 0 ? 0 : 1)

} finally {
    Stop-Transcript | Out-Null
}
