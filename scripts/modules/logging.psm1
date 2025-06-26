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
    param([string]$Level)
    $script:CurrentLogLevel = $script:LogLevels[$Level]
}

function Write-InfoLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Info"]) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

function Write-ErrorLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Error"]) {
        Write-Host $Message -ForegroundColor Red
    }
}

function Write-WarningLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Warn"]) {
        Write-Host $Message -ForegroundColor Yellow
    }
}

function Write-VerboseLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Verbose"]) {
        Write-Host $Message -ForegroundColor Gray
    }
}

function Write-DebugLog {
    param([string]$Message)
    if ($script:CurrentLogLevel -ge $script:LogLevels["Debug"]) {
        Write-Host $Message -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function Set-LogLevel, Write-InfoLog, Write-ErrorLog,
    Write-WarningLog, Write-VerboseLog, Write-DebugLog
