$script:SupportedVersions = @("5.4", "5.3", "5.2", "5.1")

function Get-LatestLuaVersions {
    try {
        $response = Invoke-WebRequest "https://www.lua.org/versions.html" -UseBasicParsing -ErrorAction Stop
        $versions = [regex]::Matches($response.Content, 'lua-(\d+\.\d+\.\d+)\.tar\.gz') |
            ForEach-Object { $_.Groups[1].Value } |
            Where-Object { $_ -match "5\.(1|2|3|4)" } |
            Sort-Object { [System.Version]$_ } -Descending |
            Select-Object -First 4

        return $versions
    }
    catch {
        Write-WarningLog "⚠️ Using fallback versions (network error)"
        return @("5.4.8", "5.3.6", "5.2.4", "5.1.5")
    }
}

function Convert-VersionShorthand {
    param([string]$InputVersion)

    if ($InputVersion -match '^\d+\.\d+\.\d+$') {
        return $InputVersion
    }

    if ($InputVersion -match '^(\d{1})(\d{1})(\d{1})$') {
        return "$($Matches[1]).$($Matches[2]).$($Matches[3])"
    }

    if ($InputVersion -match '^(\d{1})(\d{1})$') {
        return "$($Matches[1]).$($Matches[2]).0"
    }

    return $InputVersion
}

function Test-IsSupportedVersion {
    param([string]$Version)

    $baseVersion = $Version.Substring(0, 3)
    return $script:SupportedVersions -contains $baseVersion
}

Export-ModuleMember -Function Get-LatestLuaVersions, Convert-VersionShorthand, Test-IsSupportedVersion
