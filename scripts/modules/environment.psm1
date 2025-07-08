# environment.psm1 - Enhanced platform detection
function Get-OSPlatform {
    <#
    .SYNOPSIS
        Detects the current platform (Windows/macOS/Linux) and architecture (x64/arm64).
    .OUTPUTS
        A hashtable with keys: Platform, Architecture, Cores
    #>
    $platform = if ($IsWindows) {
        "windows"
    } elseif ($IsLinux) {
        "linux"
    } elseif ($IsMacOS) {
        "macos"
    } else {
        "unknown"
    }

    # Unified architecture naming
    $arch = if ($IsWindows) {
        switch -Regex ($env:PROCESSOR_ARCHITECTURE) {
            "ARM64"  { "arm64" }
            "AMD64"  { "x64" }
            default  { "x86" }
        }
    }
    else {
        $uname = (uname -m) 2>$null
        switch -Regex ($uname) {
            "x86_64"  { "x64" }
            "aarch64|arm64" { "arm64" }
            default { $uname }
        }
    }

    $cores = if ($IsWindows) {
        (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    } else {
        [Environment]::ProcessorCount
    }

    return @{
        Platform     = $platform
        Architecture = $arch
        Cores        = $cores
    }
}

function Confirm-ToolAvailability {
    <#
    .SYNOPSIS
        Checks if required command-line tools are available in the system PATH.
    .PARAMETER Tools
        Array of tool names (e.g. 'git', 'cmake')
    .OUTPUTS
        Object with .Available (bool) and .Missing (list of tool names)
    #>
    param (
        [Parameter(Mandatory)]
        [string[]]$Tools
    )

    $result = [PSCustomObject]@{
        Available = $true
        Missing   = [System.Collections.Generic.List[string]]::new()
    }

    foreach ($tool in $Tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $result.Missing.Add($tool)
            $result.Available = $false
        }
    }

    return $result
}

Export-ModuleMember -Function Get-OSPlatform, Confirm-ToolAvailability
