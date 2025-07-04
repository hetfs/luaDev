# globals.psm1
# 🌍 Global path and utility helpers for the luaDev project

function Get-ProjectRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-SourcesRoot {
    $path = Join-Path (Get-ProjectRoot) "sources"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-ScriptsLogsRoot {
    $path = Join-Path (Get-ProjectRoot) "logs"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-LogsBuildRoot {
    $path = Join-Path (Get-ScriptsLogsRoot) "build"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-LogFilePathForTimestamp {
    param(
        [Parameter(Mandatory)][string]$Timestamp
    )
    return Join-Path (Join-Path (Get-LogsBuildRoot) $Timestamp) "build.log"
}

function Get-BuildOutputPaths {
    <#
    .SYNOPSIS
        Returns paths to the log, markdown, and JSON outputs for a given timestamp.
    .PARAMETER Timestamp
        Timestamp string (e.g. 2025-07-02T21-00-00)
    .OUTPUTS
        Hashtable with keys: LogPath, MarkdownPath, JsonPath, OutputFolder
    #>
    param(
        [Parameter(Mandatory)][string]$Timestamp
    )

    $folder = Join-Path (Get-LogsBuildRoot) $Timestamp
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

    $arch = if (Get-Command Get-OSPlatform -ErrorAction SilentlyContinue) {
        (Get-OSPlatform).Architecture
    } else {
        [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    }

    return "$Engine-$Version-$BuildType-$Compiler-$arch"
}

function Get-ArtifactPath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][ValidateSet("static", "shared")]$BuildType,
        [Parameter(Mandatory)][ValidateSet("clang", "msvc", "mingw")]$Compiler,
        [switch]$Create
    )

    $folder = Get-BuildFolderName -Engine $Engine -Version $Version -BuildType $BuildType -Compiler $Compiler
    $path = Join-Path (Get-ProjectRoot) "binaries" $folder

    if ($Create -and -not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    return $path
}

function Get-DocsRoot {
    return Join-Path (Get-ProjectRoot) "docs"
}

function Get-DocsVersionPath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version
    )

    $engineDir = Join-Path (Get-DocsRoot) "builds"
    $fullPath = Join-Path $engineDir $Engine
    if (-not (Test-Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    }

    return Join-Path $fullPath "$Version.md"
}

function Get-ManifestsRoot {
    $path = Join-Path (Get-ProjectRoot) "manifests"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-TemplatesRoot {
    return Join-Path (Get-ProjectRoot) "templates"
}

function Get-SourcePath {
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version
    )
    return Join-Path (Get-SourcesRoot) "$Engine-$Version"
}

Export-ModuleMember -Function `
    Get-ProjectRoot, `
    Get-SourcesRoot, `
    Get-ScriptsLogsRoot, `
    Get-LogsBuildRoot, `
    Get-LogFilePathForTimestamp, `
    Get-BuildOutputPaths, `
    Get-BuildFolderName, `
    Get-ArtifactPath, `
    Get-DocsRoot, `
    Get-DocsVersionPath, `
    Get-ManifestsRoot, `
    Get-TemplatesRoot, `
    Get-SourcePath
