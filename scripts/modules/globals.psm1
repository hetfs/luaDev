function Get-ProjectRoot {
    # Project root is parent of scripts directory
    return Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

function Get-ArtifactPath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('lua','luajit')]
        $Engine,
        [Parameter(Mandatory)]
        [string]$Version,
        [switch]$Create
    )

    $osInfo = Get-OSPlatform
    $path = Join-Path (Join-Path (Get-ProjectRoot) "LuaBinaries") "${Engine}-${Version}-$($osInfo.Platform)-$($osInfo.Architecture)"

    if ($Create -and -not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-SourcesRoot {
    $scriptsDir = Split-Path $PSScriptRoot -Parent
    $path = Join-Path $scriptsDir "sources"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-ManifestsRoot {
    $path = Join-Path (Get-ProjectRoot) "manifests"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-ScriptsLogsRoot {
    $scriptsDir = Split-Path $PSScriptRoot -Parent
    $path = Join-Path $scriptsDir "logs"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

Export-ModuleMember -Function *
