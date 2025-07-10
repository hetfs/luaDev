# manifestsExporter.psm1 — Export manifest and logs as Docusaurus-friendly Markdown

# 🛡️ Fallback logging
if (-not (Get-Command Write-InfoLog -ErrorAction SilentlyContinue)) {
    function Write-InfoLog { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
}
if (-not (Get-Command Write-WarningLog -ErrorAction SilentlyContinue)) {
    function Write-WarningLog { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
}
if (-not (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue)) {
    function Write-ErrorLog { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
}

function Export-BuildManifestsToDocs {
    <#
    .SYNOPSIS
        Exports the latest Markdown manifest into the docs/dev/manifests folder
        and adds Docusaurus frontmatter with a fixed filename `manifest.md`.
    #>
    param(
        [string]$OutputPath = (Join-Path (Get-ProjectRoot) "docs/dev/manifests"),
        [switch]$DryRun,
        [switch]$Force
    )

    $manifestRoot = Join-Path (Get-ProjectRoot) "manifests"

    if (-not (Test-Path $manifestRoot)) {
        Write-WarningLog "⚠️ Manifests folder not found: $manifestRoot"
        return
    }

    $mdFiles = Get-ChildItem -Path $manifestRoot -Filter *.md -File | Sort-Object LastWriteTime -Descending
    if ($mdFiles.Count -eq 0) {
        Write-WarningLog "⚠️ No Markdown manifest files found."
        return
    }

    $latest = $mdFiles[0]
    $outputFile = Join-Path $OutputPath "manifest.md"

    # ⛳ Prepend Docusaurus frontmatter
    $frontmatter = @"
---
id: manifest
title: 📦 Build Manifest
sidebar_label: Manifest
sidebar_position: 5
---

"@

    $body = Get-Content -Raw -Path $latest.FullName
    $content = $frontmatter + $body

    if ($DryRun) {
        Write-InfoLog "[DryRun] Would export latest manifest as: $outputFile"
        return
    }

    try {
        if (-not (Test-Path $OutputPath)) {
            Write-InfoLog "📁 Output directory not found. Creating: $OutputPath"
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        $content | Set-Content -Path $outputFile -Encoding UTF8 -Force
        Write-InfoLog "📤 Manifest exported to Docusaurus docs → $outputFile"
    }
    catch {
        Write-ErrorLog "❌ Failed to export manifest: $($_.Exception.Message)"
    }
}

function Export-BuildLogsToDocs {
    <#
    .SYNOPSIS
        Exports successful build logs for each artifact to Docusaurus-friendly markdown files
    .PARAMETER Artifacts
        The build artifacts array with Engine, Version, and Success info
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Artifacts
    )

    foreach ($artifact in $Artifacts) {
        if (-not $artifact.Success) {
            continue
        }

        $versionPath = Get-DocsVersionPath -Engine $artifact.Engine -Version $artifact.Version

        if (-not (Test-Path $versionPath)) {
            New-Item -Path $versionPath -ItemType Directory -Force | Out-Null
        }

        $logPath = Join-Path $versionPath "log.md"

        $logContent = @"
---
id: ${artifact.Engine}-${artifact.Version}-log
title: Build Log – ${artifact.Engine} ${artifact.Version}
sidebar_label: Log
sidebar_position: 2
---

## Build Metadata

- Engine: ${artifact.Engine}
- Version: ${artifact.Version}
- Compiler: ${artifact.Compiler}
- Build Type: ${artifact.BuildType}
- Platform: ${artifact.Platform}
- Architecture: ${artifact.Architecture}
- Duration: ${artifact.Duration}s
- Success: ✅

*This is a placeholder log summary for future extension.*
"@

        try {
            $logContent | Set-Content -Path $logPath -Encoding UTF8
            Write-InfoLog "📤 Exported build log to: $logPath"
        }
        catch {
            Write-WarningLog "⚠️ Failed to write log for ${artifact.Engine} ${artifact.Version}: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function Export-BuildManifestsToDocs, Export-BuildLogsToDocs
