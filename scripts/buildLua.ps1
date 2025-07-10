<#
.SYNOPSIS
    Enterprise-grade Lua/LuaJIT build automation solution
.DESCRIPTION
    Cross-platform build system for Lua (5.1–5.4) and LuaJIT (2.0.5+) with
    support for Clang, MSVC, and MinGW compilers. Features dry-run simulation,
    automatic source fetching, and structured artifact generation.
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

#region Initial Bootstrapping
$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$SCRIPT_VERSION = "2.2.0"
$startTime = Get-Date

$logDir = Join-Path $ScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = Join-Path $logDir "build-$timestamp.log"

function Write-Log {
    param($Message, $Color = "White")
    $stamp = "[$(Get-Date -Format u)]"
    "$stamp $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $Message -ForegroundColor $Color
}

Write-Log "=== 🚀 LuaDev Build System v$SCRIPT_VERSION ===" -Color Cyan
Write-Log "Initializing module system..." -Color DarkGray
#endregion

#region Module Loading
$ModulesPath = Join-Path $ScriptRoot "modules"
try {
    Write-Log "🔍 Loading modules from $ModulesPath" -Color DarkCyan

    $loaderPath = Join-Path $ModulesPath "loader.psm1"
    if (Test-Path $loaderPath) {
        Import-Module $loaderPath -Force -DisableNameChecking
        Write-Log "✅ Module loader imported" -Color Green

        Import-LuaDevModules -ModulesPath $ModulesPath -AllowFallback

        $criticalFunctions = @{
            "globals" = "Get-ProjectRoot"
            "logging" = "Initialize-Logging"
        }

        $missing = @()
        foreach ($module in $criticalFunctions.Keys) {
            if (-not (Get-Command $criticalFunctions[$module] -ErrorAction SilentlyContinue)) {
                $missing += $module
            }
        }

        if ($missing) {
            throw "Critical functions missing from modules: $($missing -join ', ') (from $($criticalFunctions[$missing] -join ', '))"
        }

        Write-Log "✅ $($global:loadedModuleNames.Count) modules loaded: $($global:loadedModuleNames -join ', ')" -Color Green
    }
    else {
        throw "Module loader not found at $loaderPath"
    }

    Initialize-Logging -FilePath $logFile
    Set-LogLevel -Level $LogLevel
    Write-InfoLog "Logging subsystem initialized (Level: $LogLevel)"
}
catch {
    $errMsg = "Module system failed: $($_.Exception.Message)"
    Write-Log $errMsg -Color Red

    if (Test-Path $ModulesPath) {
        $moduleFiles = Get-ChildItem $ModulesPath -Filter *.psm1 |
                       Select-Object -ExpandProperty Name
        Write-Log "Available modules: $($moduleFiles -join ', ')" -Color Yellow
    }

    if ($global:loadedModuleNames) {
        Write-Log "Loaded modules: $($global:loadedModuleNames -join ', ')" -Color Yellow
    }

    $errMsg | Out-File $logFile -Append
    exit 1
}
#endregion

#region Clean Operation
if ($Clean) {
    try {
        Write-InfoLog "🚽 Initializing clean operation..."
        $pathsToClean = @(
            (Join-Path (Get-ProjectRoot) "luaBinary"),
            (Join-Path (Get-ProjectRoot) "logs")
        )

        foreach ($path in $pathsToClean) {
            if (Test-Path $path) {
                if ($PSCmdlet.ShouldProcess($path, "Remove directory")) {
                    Remove-Item -Recurse -Force $path -ErrorAction Stop
                    Write-InfoLog "🧹 Successfully cleaned: $path"
                }
            }
        }
    }
    catch {
        Write-ErrorLog "❌ Clean operation failed: $($_.Exception.Message)"
        exit 1
    }
}
#endregion

#region Build Planning
try {
    Write-InfoLog "🚀 Initiating build process"
    Write-InfoLog "⚙️ Configuration:"
    Write-InfoLog "  - Build Type: $BuildType"
    Write-InfoLog "  - Compiler: $Compiler"
    Write-InfoLog "  - Dry Run: $($DryRun.IsPresent)"

    $osInfo = Get-OSPlatform
    Write-InfoLog "🌐 Platform: $($osInfo.Platform) ($($osInfo.Architecture))"

    $BuildTargets = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($engine in ($Engines | Select-Object -Unique)) {
        $versions = if ($EngineVersions) {
            $EngineVersions | Where-Object {
                Test-IsSupportedVersion -Engine $engine -Version $_
            }
        }
        else {
            Get-LatestEngineVersions -Engine $engine
        }

        if (-not $versions) {
            Write-WarningLog "⚠️ No valid versions resolved for engine: $engine"
            continue
        }

        foreach ($version in $versions) {
            $BuildTargets.Add(@{
                Engine = $engine
                Version = $version
            })
            Write-VerboseLog "🎯 Target registered: $engine/$version"
        }
    }

    if ($BuildTargets.Count -eq 0) {
        throw "No valid build targets found"
    }

    Write-InfoLog "🎯 Build targets: $($BuildTargets.Count)"
    $BuildTargets | ForEach-Object {
        Write-VerboseLog "    - $($_.Engine) $($_.Version)"
    }
}
catch {
    Write-ErrorLog "❌ Build planning failed: $($_.Exception.Message)"
    exit 1
}
#endregion

#region Build Execution
$Artifacts = @()

try {
    Write-InfoLog "🔨 Starting build sequence"
    foreach ($target in $BuildTargets) {
        $engine = $target.Engine
        $version = $target.Version

        $buildMeta = @{
            Engine = $engine
            Version = $version
            Compiler = $Compiler
            BuildType = $BuildType
            Platform = $osInfo.Platform
            Architecture = $osInfo.Architecture
            BuildStart = [DateTime]::UtcNow
            Success = $false
        }

        try {
            if ($DryRun) {
                Write-InfoLog "[DRYRUN] Build simulation: $engine/$version"
                $buildMeta.Success = $true
            }
            else {
                $sourcePath = Get-SourcePath -Engine $engine -Version $version
                if (-not (Test-Path $sourcePath)) {
                    Write-InfoLog "📦 Source not found - fetching: $engine $version"
                    $sourcePath = Get-SourceArchive -Engine $engine -Version $version
                    if (-not $sourcePath) {
                        throw "Source download failed"
                    }
                }

                if ($engine -eq "lua") {
                    $buildMeta.Success = Build-LuaEngine -Version $version -SourcePath $sourcePath -BuildType $BuildType -Compiler $Compiler
                }
                else {
                    $buildMeta.Success = Build-LuaJIT -Version $version -SourcePath $sourcePath -BuildType $BuildType -Compiler $Compiler
                }
            }
        }
        catch {
            $buildMeta.Error = $_.Exception.Message
            Write-ErrorLog "❌ Build failure: $engine/$version - $($buildMeta.Error)"
        }
        finally {
            $buildMeta.BuildEnd = [DateTime]::UtcNow
            $buildMeta.Duration = [Math]::Round(($buildMeta.BuildEnd - $buildMeta.BuildStart).TotalSeconds, 2)
            $Artifacts += $buildMeta
        }
    }
}
catch {
    Write-ErrorLog "🔥 Critical build error: $($_.Exception.Message)"
    exit 2
}
#endregion

#region Post-Build Processing
try {
    Write-InfoLog "📊 Generating build reports"
    $manifestPath = Export-LuaBuildManifest -Artifacts $Artifacts
    $logLines = Get-Content -Path $logFile -Encoding UTF8
    $markdownPath = Join-Path (Get-ProjectRoot) "manifests/manifest.md"

    Export-LogAsMarkdown -Path $markdownPath -LogLines $logLines -Title "Build Report - $timestamp" -DryRun:$DryRun
    Export-BuildManifestsToDocs -DryRun:$DryRun

    if (-not $DryRun) {
        Export-BuildLogsToDocs -Artifacts $Artifacts
    }

    $successCount = ($Artifacts | Where-Object { $_.Success }).Count
    $totalDuration = [Math]::Round(((Get-Date) - $startTime).TotalMinutes, 2)

    Write-InfoLog "=== BUILD SUMMARY ==="
    Write-InfoLog "🕒 Total Duration: ${totalDuration}m"
    Write-InfoLog "✅ Successes: $successCount/$($Artifacts.Count)"
    $Artifacts | ForEach-Object {
        $status = if ($_.Success) { "✅" } else { "❌" }
        $duration = if ($_.Duration) { "in $($_.Duration)s" } else { "" }
        $errorInfo = if ($_.Error) { "($($_.Error))" } else { "" }
        Write-InfoLog "$status [$($_.Engine)] $($_.Version) $($_.BuildType)/$($_.Compiler) $duration $errorInfo"
    }
}
catch {
    Write-WarningLog "⚠️ Post-build processing failed: $($_.Exception.Message)"
}
#endregion

Write-InfoLog "=== BUILD COMPLETE ==="

$failedCount = ($Artifacts | Where-Object { -not $_.Success }).Count
exit ($failedCount -eq 0) ? 0 : 1
