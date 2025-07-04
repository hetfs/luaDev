# environment.psm1
# 🧭 OS, architecture, and toolchain environment detection for luaDev

function Get-OSPlatform {
    <#
    .SYNOPSIS
        Detects the current platform (Windows/macOS/Linux) and architecture (x64/arm64).
    .OUTPUTS
        A hashtable with keys: Platform, Architecture, Cores
    #>

    $arch = switch -Regex ($env:PROCESSOR_ARCHITECTURE) {
        "ARM64"  { "arm64"; break }
        "AMD64"  { "x64"; break }
        default  { "x64" }
    }

    $platform = if ($IsWindows) {
        "windows"
    } elseif ($IsLinux) {
        "linux"
    } elseif ($IsMacOS) {
        "macos"
    } else {
        "unknown"
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
