function Get-OSPlatform {
    $platform = if ($IsWindows) { "windows" }
                elseif ($IsLinux) { "linux" }
                elseif ($IsMacOS) { "macos" }
                else { "unknown" }

    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' }
            else { 'x64' }

    # Get logical processor count
    $cores = try {
        if ($IsWindows) {
            (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
        }
        elseif ($IsLinux -or $IsMacOS) {
            (nproc).Trim()
        }
        else { 4 }
    }
    catch { 4 }

    return @{
        Platform = $platform
        Architecture = $arch
        Cores = $cores
    }
}

function Confirm-ToolAvailability {
    param([Parameter(Mandatory)][string[]]$Tools)

    $os = (Get-OSPlatform).Platform
    $result = [PSCustomObject]@{
        Available = $true
        Missing = [System.Collections.Generic.List[string]]::new()
        Suggestions = [System.Collections.Generic.List[string]]::new()
    }

    $installGuides = @{
        windows = @{
            git   = "winget install Git.Git"
            cmake = "winget install Kitware.CMake"
            make  = "winget install GnuWin32.Make"
            tar   = "Install 7-Zip: winget install 7zip.7zip"
            curl  = "winget install curl.curl"
        }
        linux = @{
            git   = "sudo apt install git -y"
            cmake = "sudo apt install cmake -y"
            make  = "sudo apt install build-essential -y"
            tar   = "sudo apt install tar -y"
            curl  = "sudo apt install curl -y"
        }
        macos = @{
            git   = "brew install git"
            cmake = "brew install cmake"
            make  = "brew install make"
            tar   = "brew install gnu-tar"
            curl  = "brew install curl"
        }
    }

    foreach ($tool in $Tools) {
        $exists = Get-Command $tool -ErrorAction SilentlyContinue
        if (-not $exists) {
            $result.Available = $false
            $result.Missing.Add($tool)

            if ($installGuides[$os].ContainsKey($tool)) {
                $result.Suggestions.Add($installGuides[$os][$tool])
            }
            else {
                $result.Suggestions.Add("See documentation for $tool installation")
            }
        }
    }

    return $result
}

Export-ModuleMember -Function Get-OSPlatform, Confirm-ToolAvailability
