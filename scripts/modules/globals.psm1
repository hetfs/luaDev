function Get-ProjectRoot {
    return Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

function Get-ArtifactPath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('lua','luajit')]
        $Engine,
        [Parameter(Mandatory)]
        [string]$Version,
        [Parameter(Mandatory)]
        [string]$BuildType,
        [Parameter(Mandatory)]
        [string]$Compiler,
        [switch]$Create
    )

    $osInfo = Get-OSPlatform
    $path = Join-Path (Get-ProjectRoot) "binaries" "${Engine}-${Version}-${BuildType}-${Compiler}-$($osInfo.Architecture)"

    if ($Create -and -not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-SourcesRoot {
    $path = Join-Path (Get-ProjectRoot) "sources"
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
    $path = Join-Path (Get-ProjectRoot) "logs"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

Export-ModuleMember -Function *
