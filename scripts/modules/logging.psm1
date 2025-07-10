# logging.psm1 - Enhanced structured logging with color-coded levels

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
    param(
        [string]$Level,
        [string]$Message
    )

    $prefix = "[$Level]"
    $fg = "White"

    switch ($Level.ToUpper()) {
        "DEBUG"   { $prefix = "[DEBUG]";   $fg = "DarkGray" }
        "VERBOSE" { $prefix = "[VERBOSE]"; $fg = "Gray"     }
        "INFO"    { $prefix = "[INFO]";    $fg = "Cyan"     }
        "WARN"    { $prefix = "[WARN]";    $fg = "Yellow"   }
        "ERROR"   { $prefix = "[ERROR]";   $fg = "Red"      }
    }

    $fullMessage = "$prefix $Message"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Always write to log file if available
    if ($script:LogFile) {
        "$timestamp $fullMessage" | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
    }

    # Check level threshold before writing to console
    if ($script:LogLevels.ContainsKey($Level) -and ($script:LogLevels[$Level] -le $script:CurrentLogLevel)) {
        Write-Host $fullMessage -ForegroundColor $fg
    }
}

function Write-InfoLog    { param($msg) Write-LogInternal "Info"    $msg }
function Write-WarningLog { param($msg) Write-LogInternal "Warn"    $msg }
function Write-ErrorLog   { param($msg) Write-LogInternal "Error"   $msg }
function Write-VerboseLog { param($msg) Write-LogInternal "Verbose" $msg }
function Write-DebugLog   { param($msg) Write-LogInternal "Debug"   $msg }

Export-ModuleMember -Function Initialize-Logging, Set-LogLevel, `
    Write-InfoLog, Write-WarningLog, Write-ErrorLog, `
    Write-VerboseLog, Write-DebugLog
