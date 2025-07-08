# globals.psm1 - Robust path utilities with enhanced error handling
function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Finds the project root directory using reliable methods
    .DESCRIPTION
        Searches for project root by checking for known markers (.git directory or luaDev.root file),
        with fallback to script path calculation. Ensures consistent path resolution.
    #>
    $current = $PSScriptRoot
    $maxDepth = 6  # Prevent infinite loops

    # Try to find .git directory or marker file
    for ($i = 0; $i -lt $maxDepth; $i++) {
        if (Test-Path (Join-Path $current ".git") -PathType Container) {
            return $current
        }
        if (Test-Path (Join-Path $current "luaDev.root") -PathType Leaf) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) {
            break
        }
        $current = $parent
    }

    # Fallback: Calculate based on module location
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    if (-not $projectRoot) {
        Write-Warning "Project root not found! Using fallback: $PSScriptRoot"
        $projectRoot = $PSScriptRoot
    }

    return $projectRoot
}

function Get-SourcesRoot {
    $path = Join-Path (Get-ProjectRoot) "sources"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-LogsRoot {
    $path = Join-Path (Get-ProjectRoot) "logs"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-BuildOutputPaths {
    param(
        [Parameter(Mandatory)][string]$Timestamp
    )

    $folder = Join-Path (Get-LogsRoot) $Timestamp
    return @{
        OutputFolder = $folder
        LogPath      = Join-Path $folder "build.log"
        MarkdownPath = Join-Path $folder "build.md"
        JsonPath     = Join-Path $folder "build.json"
    }
}

function Get-BuildFolderName {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][ValidateSet("static", "shared")]$BuildType,
        [Parameter(Mandatory)][ValidateSet("clang", "msvc", "mingw")]$Compiler
    )

    $osInfo = Get-OSPlatform
    return "${Engine}-${Version}-${BuildType}-${Compiler}-$($osInfo.Architecture)"
}

function Get-ArtifactPath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][ValidateSet("static", "shared")]$BuildType,
        [Parameter(Mandatory)][ValidateSet("clang", "msvc", "mingw")]$Compiler,
        [switch]$Create
    )

    $folder = Get-BuildFolderName @PSBoundParameters
    $binRoot = Join-Path (Get-ProjectRoot) "luaBinary"
    $path = Join-Path $binRoot $folder

    if ($Create -and -not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    return $path
}

function Get-DocsRoot {
    return Join-Path (Get-ProjectRoot) "docs"
}

function Get-DocsBuildsPath {
    $path = Join-Path (Get-DocsRoot) "builds"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-DocsVersionPath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version
    )

    $engineDir = Join-Path (Get-DocsBuildsPath) $Engine
    if (-not (Test-Path $engineDir)) {
        New-Item -Path $engineDir -ItemType Directory -Force | Out-Null
    }

    return Join-Path $engineDir "${Version}.md"
}

function Get-ManifestsRoot {
    $path = Join-Path (Get-ProjectRoot) "manifests"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-TemplatesRoot {
    $path = Join-Path (Get-ProjectRoot) "templates"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-SourcePath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version
    )
    return Join-Path (Get-SourcesRoot) "${Engine}-${Version}"
}

# Create marker file for root detection
if (-not (Test-Path (Join-Path (Get-ProjectRoot) "luaDev.root"))) {
    try {
        Set-Content -Path (Join-Path (Get-ProjectRoot) "luaDev.root") -Value "Project root marker" -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to create root marker: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function *
