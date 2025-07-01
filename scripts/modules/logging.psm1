# logging.psm1
# 🪵 Unified logging module for luaDev
# Provides color-coded and level-aware logging functions for all CLI scripts.

$script:LogLevels = @{
    Silent  = 0
    Error   = 1
    Warn    = 2
    Info    = 3
    Verbose = 4
    Debug   = 5
}

$script:CurrentLogLevel = $script:LogLevels["Info"]

function Set-LogLevel {
    <#
    .SYNOPSIS
        Sets the current logging verbosity level.
    .PARAMETER Level
        One of: Silent, Error, Warn, Info, Verbose, Debug
    #>
    param(
        [ValidateSet("Silent", "Error", "Warn", "Info", "Verbose", "Debug")]
        [string]$Level
    )
    $script:CurrentLogLevel = $script:LogLevels[$Level]
}

function Get-LogLevel {
    <#
    .SYNOPSIS
        Returns the current logging level as string.
    #>
    return ($script:LogLevels.Keys | Where-Object { $script:LogLevels[$_] -eq $script:CurrentLogLevel })
}

function Write-InfoLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Info"]) {
        Write-Host "[INFO] $Message" -ForegroundColor Cyan
    }
}

function Write-ErrorLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Error"]) {
        Write-Host "[ERROR] $Message" -ForegroundColor Red
    }
}

function Write-WarningLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Warn"]) {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    }
}

function Write-VerboseLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Verbose"]) {
        Write-Host "[VERBOSE] $Message" -ForegroundColor Gray
    }
}

function Write-DebugLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Debug"]) {
        Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function `
    Set-LogLevel, `
    Get-LogLevel, `
    Write-InfoLog, `
    Write-ErrorLog, `
    Write-WarningLog, `
    Write-VerboseLog, `
    Write-DebugLog
