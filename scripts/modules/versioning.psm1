# versioning.psm1 - Enhanced version handling
$script:SupportedLuaVersions    = @("5.1", "5.2", "5.3", "5.4")
$script:SupportedLuaJITVersions = @("2.0", "2.1")

function Get-LatestEngineVersions {
    <#
    .SYNOPSIS
        Returns the latest supported versions for a given engine.
    .PARAMETER Engine
        Either 'lua' or 'luajit'
    #>
    param (
        [Parameter(Mandatory)][ValidateSet("lua", "luajit")]
        [string]$Engine
    )

    switch ($Engine) {
        "lua" {
            try {
                $response = Invoke-WebRequest "https://www.lua.org/versions.html" -UseBasicParsing -ErrorAction Stop
                $versions = [regex]::Matches($response.Content, 'lua-(\d+\.\d+\.\d+)\.tar\.gz') |
                    ForEach-Object { $_.Groups[1].Value } |
                    Where-Object { $_ -match "^5\.(1|2|3|4)" } |
                    Sort-Object { [System.Version]$_ } -Descending |
                    Select-Object -First 4

                # Normalize versions
                return $versions | ForEach-Object {
                    Convert-VersionShorthand -InputVersion $_
                }
            } catch {
                Write-WarningLog "⚠️ Could not fetch from lua.org — using offline fallback"
                return @("5.4.8", "5.3.6", "5.2.4", "5.1.5")
            }
        }

        "luajit" {
            return @("2.1.0-beta3", "2.0.5")
        }
    }
}

function Convert-VersionShorthand {
    <#
    .SYNOPSIS
        Normalizes shorthand versions like 540 or 54 to 5.4.0.
    .PARAMETER InputVersion
        Raw version input from user or manifest
    #>
    param (
        [string]$InputVersion
    )

    if ($InputVersion -match '^\d+\.\d+\.\d+$') {
        return $InputVersion
    }

    if ($InputVersion -match '^(\d)(\d)(\d)$') {
        return "$($Matches[1]).$($Matches[2]).$($Matches[3])"
    }

    if ($InputVersion -match '^(\d)(\d)$') {
        return "$($Matches[1]).$($Matches[2]).0"
    }

    return $InputVersion
}

function Test-IsSupportedVersion {
    <#
    .SYNOPSIS
        Determines if a version is supported by luaDev.
    .PARAMETER Engine
        lua or luajit
    .PARAMETER Version
        Semantic version (e.g., 5.4.8 or 2.1.0-beta3)
    #>
    param (
        [Parameter(Mandatory)][ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory)]
        [string]$Version
    )

    $base = ($Version -split '\.')[0..1] -join '.'

    switch ($Engine) {
        "lua"    { return $script:SupportedLuaVersions -contains $base }
        "luajit" { return $script:SupportedLuaJITVersions -contains $base }
    }
}

Export-ModuleMember -Function Get-LatestEngineVersions, Convert-VersionShorthand, Test-IsSupportedVersion
