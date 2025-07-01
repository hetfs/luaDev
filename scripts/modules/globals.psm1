# globals.psm1
# 🌍 Global path helpers for the luaDev project

function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Returns the root of the luaDev project.
    #>
    return Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

function Get-ArtifactPath {
    <#
    .SYNOPSIS
        Returns the output path for built binaries.
    .PARAMETER Engine
        The engine name: lua or luajit
    .PARAMETER Version
        Full semantic version (e.g., 5.4.8)
    .PARAMETER BuildType
        static or shared
    .PARAMETER Compiler
        msvc, clang, mingw
    .PARAMETER Create
        If set, creates the directory if it doesn't exist
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('lua','luajit')]$Engine,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$BuildType,
        [Parameter(Mandatory)][string]$Compiler,
        [switch]$Create
    )

    $osInfo = Get-OSPlatform
    $path = Join-Path (Get-ProjectRoot) "binaries" "${Engine}-${Version}-${BuildType}-${Compiler}-$($osInfo.Architecture)"

    if ($Create -and -not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    return $path
}

function Get-SourcesRoot {
    <#
    .SYNOPSIS
        Returns the folder where Lua/LuaJIT sources are stored
    #>
    $path = Join-Path (Get-ProjectRoot) "sources"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-ManifestsRoot {
    <#
    .SYNOPSIS
        Returns the folder where build manifests (JSON/Markdown) are saved
    #>
    $path = Join-Path (Get-ProjectRoot) "manifests"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-ScriptsLogsRoot {
    <#
    .SYNOPSIS
        Returns the root logs/ directory (e.g., logs/setup, logs/build)
    #>
    $path = Join-Path (Get-ProjectRoot) "logs"
    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }
    return $path
}

function Get-DocsRoot {
    <#
    .SYNOPSIS
        Returns the root of the Docusaurus docs/ folder
    #>
    return Join-Path (Get-ProjectRoot) "docs"
}

function Get-TemplatesRoot {
    <#
    .SYNOPSIS
        Returns the folder where CMake or config templates are stored
    #>
    return Join-Path (Get-ProjectRoot) "templates"
}

Export-ModuleMember -Function `
    Get-ProjectRoot, `
    Get-ArtifactPath, `
    Get-SourcesRoot, `
    Get-ManifestsRoot, `
    Get-ScriptsLogsRoot, `
    Get-DocsRoot, `
    Get-TemplatesRoot
