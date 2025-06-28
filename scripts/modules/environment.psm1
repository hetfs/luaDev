function Get-OSPlatform {
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    return @{
        Platform = "windows"
        Architecture = $arch
        Cores = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    }
}

function Confirm-ToolAvailability {
    param([Parameter(Mandatory)][string[]]$Tools)

    $result = [PSCustomObject]@{
        Available = $true
        Missing = [System.Collections.Generic.List[string]]::new()
    }

    foreach ($tool in $Tools) {
        $exists = $false

        # Special check for MSBuild
        if ($tool -eq "msbuild") {
            $exists = Get-Command "msbuild" -ErrorAction SilentlyContinue
        }
        # General command check
        else {
            $exists = Get-Command $tool -ErrorAction SilentlyContinue
        }

        if (-not $exists) {
            $result.Available = $false
            $result.Missing.Add($tool)
        }
    }

    return $result
}

Export-ModuleMember -Function Get-OSPlatform, Confirm-ToolAvailability
