# globals.psm1 - Robust path utilities for LuaDev with enhanced consistency

function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Finds the LuaDev project root directory.
    .DESCRIPTION
        Walks upward from current module path to detect .git or luaDev.root file.
        Falls back to calculated path if no markers found.
    #>
    $current = $PSScriptRoot
    $maxDepth = 6

    for ($i = 0; $i -lt $maxDepth; $i++) {
        if (Test-Path (Join-Path $current ".git") -PathType Container) {
            return $current
        }
        if (Test-Path (Join-Path $current "luaDev.root") -PathType Leaf) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }

    $fallback = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    if (-not $fallback) {
        Write-Warning "⚠️ Could not resolve project root — falling back to $PSScriptRoot"
        return $PSScriptRoot
    }
    return $fallback
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
    return $Path
}

function Get-SourcesRoot      { Ensure-Directory (Join-Path (Get-ProjectRoot) "sources") }
function Get-LogsRoot         { Ensure-Directory (Join-Path (Get-ProjectRoot) "logs") }
function Get-ManifestsRoot    { Ensure-Directory (Join-Path (Get-ProjectRoot) "manifests") }
function Get-TemplatesRoot    { Ensure-Directory (Join-Path (Get-ProjectRoot) "templates") }
function Get-DocsRoot         { Join-Path (Get-ProjectRoot) "docs" }

function Get-BuildOutputPaths {
    param([Parameter(Mandatory)][string]$Timestamp)
    $folder = Join-Path (Get-LogsRoot) $Timestamp
    return @{
        OutputFolder  = $folder
        LogPath       = Join-Path $folder "build.log"
        MarkdownPath  = Join-Path $folder "build.md"
        JsonPath      = Join-Path $folder "build.json"
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
    return "${Engine}-${Version}-${BuildType}-${Compiler}-${($osInfo.Architecture)}"
}

function Get-ArtifactPath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][ValidateSet("static", "shared")]$BuildType,
        [Parameter(Mandatory)][ValidateSet("clang", "msvc", "mingw")]$Compiler,
        [switch]$Create
    )

    $folderName = Get-BuildFolderName @PSBoundParameters
    $path = Join-Path (Join-Path (Get-ProjectRoot) "luaBinary") $folderName

    if ($Create -and -not (Test-Path $path)) {
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

function Get-DocsBuildsPath {
    Ensure-Directory (Join-Path (Get-DocsRoot) "builds")
}

function Get-DocsVersionPath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version
    )
    $enginePath = Ensure-Directory (Join-Path (Get-DocsBuildsPath) $Engine)
    return Join-Path $enginePath "${Version}.md"
}

function Get-DocsManifestsPath {
    Ensure-Directory (Join-Path (Get-DocsRoot) "dev/manifests")
}

# Create the root marker if not present
$markerPath = Join-Path (Get-ProjectRoot) "luaDev.root"
if (-not (Test-Path $markerPath)) {
    try {
        Set-Content -Path $markerPath -Value "Project root marker" -Encoding UTF8 -Force
    }
    catch {
        Write-Warning "⚠️ Failed to create luaDev.root marker: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function *
