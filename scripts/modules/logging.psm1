# logging.psm1
# 🪵 Centralized logging for luaDev — supports color, verbosity, and easy integration.

# Define log level table
$script:LogLevels = @{
    Silent  = 0
    Error   = 1
    Warn    = 2
    Info    = 3
    Verbose = 4
    Debug   = 5
}

# Default to Info unless overridden later
$script:CurrentLogLevel = $script:LogLevels["Info"]

function Set-LogLevel {
    <#
    .SYNOPSIS
        Sets the current logging verbosity level.
    .PARAMETER Level
        One of: Silent, Error, Warn, Info, Verbose, Debug
    #>
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Silent", "Error", "Warn", "Info", "Verbose", "Debug")]
        [string]$Level
    )
    $script:CurrentLogLevel = $script:LogLevels[$Level]
}

function Get-LogLevel {
    <#
    .SYNOPSIS
        Returns the current logging level name (e.g., Info)
    #>
    return ($script:LogLevels.Keys | Where-Object { $script:LogLevels[$_] -eq $script:CurrentLogLevel })
}

function Write-InfoLog {
    param ([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Info"]) {
        Write-Host "[INFO] $Message" -ForegroundColor Cyan
    }
}

function Write-WarningLog {
    param ([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Warn"]) {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    }
}

function Write-ErrorLog {
    param ([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Error"]) {
        Write-Host "[ERROR] $Message" -ForegroundColor Red
    }
}

function Write-VerboseLog {
    param ([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Verbose"]) {
        Write-Host "[VERBOSE] $Message" -ForegroundColor Gray
    }
}

function Write-DebugLog {
    param ([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Debug"]) {
        Write-Host "[DEBUG] $Message" -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function `
    Set-LogLevel, `
    Get-LogLevel, `
    Write-InfoLog, `
    Write-WarningLog, `
    Write-ErrorLog, `
    Write-VerboseLog, `
    Write-DebugLog
