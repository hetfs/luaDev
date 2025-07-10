function Export-LuaBuildManifest {
    <#
    .SYNOPSIS
        Exports structured JSON + Markdown manifest of Lua builds.

    .PARAMETER Artifacts
        The build metadata to include in the manifest.

    .PARAMETER DefaultArchitecture
        Optional fallback architecture if none is provided per build.

    .PARAMETER OutputPath
        Optional override path to store manifest files (defaults to /manifests).

    .PARAMETER DryRun
        Simulates export without writing to disk.
    #>
    param(
        [Parameter(Mandatory)][array]$Artifacts,
        [string]$DefaultArchitecture,
        [string]$OutputPath,
        [switch]$DryRun
    )

    $osInfo = Get-OSPlatform
    if (-not $DefaultArchitecture) {
        $DefaultArchitecture = $osInfo.Architecture
    }

    $timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

    # 🗂️ Set output root (custom or default)
    $manifestsRoot = if ($OutputPath) { $OutputPath } else { Get-ManifestsRoot }

    if (-not $DryRun -and -not (Test-Path $manifestsRoot)) {
        New-Item -ItemType Directory -Path $manifestsRoot -Force | Out-Null
    }

    $jsonPath = Join-Path $manifestsRoot "manifest.json"
    $mdPath   = Join-Path $manifestsRoot "manifest.md"

    # 📦 Normalize artifact data
    $manifestArtifacts = $Artifacts | ForEach-Object {
        $artifactArch = if ($_.Architecture) { $_.Architecture } else { $DefaultArchitecture }

        [PSCustomObject]@{
            Engine       = $_.Engine
            Version      = $_.Version
            BuildType    = $_.BuildType
            Compiler     = $_.Compiler
            Success      = $_.Success
            Architecture = $artifactArch
            Path         = "binaries/$($_.Engine)-$($_.Version)-$($_.BuildType)-$($_.Compiler)-$artifactArch"
        }
    }

    # 🧱 JSON Structure
    $manifest = @{
        Timestamp = $timestamp
        System    = $osInfo
        Artifacts = $manifestArtifacts
    }

    if (-not $DryRun) {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
        Write-InfoLog "📄 JSON manifest exported: $jsonPath"
    } else {
        Write-VerboseLog "[DryRun] Would export JSON to: $jsonPath"
    }

    # 📝 Markdown formatting
    $successCount = ($manifestArtifacts | Where-Object { $_.Success }).Count
    $totalCount   = $manifestArtifacts.Count

    $mdHeader = @"
# 📦 Lua Build Manifest

**Generated:** $timestamp
**System:** $($osInfo.Platform) / $($osInfo.Architecture)
**Success Rate:** $successCount / $totalCount builds succeeded

## 🔍 Artifacts

| Engine  | Version | Build Type | Compiler | Architecture | Status     | Binary Path |
|---------|---------|------------|----------|--------------|------------|-------------|
"@

    $mdRows = $manifestArtifacts | ForEach-Object {
        $status = if ($_.Success) { "✅ Success" } else { "❌ Failed" }
        "| $($_.Engine) | $($_.Version) | $($_.BuildType) | $($_.Compiler) | $($_.Architecture) | $status | $($_.Path) |"
    }

    $mdContent = $mdHeader + ($mdRows -join "`n") + "`n"

    if (-not $DryRun) {
        $mdContent | Set-Content -Path $mdPath -Encoding UTF8
        Write-InfoLog "📝 Markdown manifest exported: $mdPath"
    } else {
        Write-VerboseLog "[DryRun] Would export Markdown to: $mdPath"
    }
}

Export-ModuleMember -Function Export-LuaBuildManifest
