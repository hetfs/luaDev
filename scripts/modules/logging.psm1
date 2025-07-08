# logging.psm1 - Fixed log level handling
$script:LogLevels = @{
    Silent  = 0
    Error   = 1
    Warn    = 2
    Info    = 3
    Verbose = 4
    Debug   = 5
}

$script:CurrentLogLevel = $script:LogLevels["Info"]
$script:LogFile = $null

function Initialize-Logging {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    $script:LogFile = $FilePath
}

function Set-LogLevel {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Silent", "Error", "Warn", "Info", "Verbose", "Debug")]
        [string]$Level
    )
    $script:CurrentLogLevel = $script:LogLevels[$Level]
}

function Write-LogInternal {
    param($Level, $Message)
    $prefix = switch($Level) {
        "DEBUG"   { "[DEBUG]"; $fg = "DarkGray" }
        "VERBOSE" { "[VERBOSE]"; $fg = "Gray" }
        "INFO"    { "[INFO]"; $fg = "Cyan" }
        "WARN"    { "[WARN]"; $fg = "Yellow" }
        "ERROR"   { "[ERROR]"; $fg = "Red" }
        default   { "[$Level]"; $fg = "White" }
    }

    $fullMessage = "$prefix $Message"
    $levelValue = $script:LogLevels[$Level]

    # Always write to file if initialized
    if ($script:LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp $fullMessage" | Out-File $script:LogFile -Append -Encoding UTF8
    }

    # Write to console based on log level
    if ($levelValue -le $script:CurrentLogLevel) {
        Write-Host $fullMessage -ForegroundColor $fg
    }
}

function Write-InfoLog($msg)    { Write-LogInternal "INFO" $msg }
function Write-WarningLog($msg) { Write-LogInternal "WARN" $msg }
function Write-ErrorLog($msg)   { Write-LogInternal "ERROR" $msg }
function Write-VerboseLog($msg) { Write-LogInternal "VERBOSE" $msg }
function Write-DebugLog($msg)   { Write-LogInternal "DEBUG" $msg }

Export-ModuleMember -Function Initialize-Logging, Set-LogLevel, `
    Write-InfoLog, Write-WarningLog, Write-ErrorLog, `
    Write-VerboseLog, Write-DebugLog
