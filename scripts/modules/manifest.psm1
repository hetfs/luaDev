function Export-LuaBuildManifest {
    param([array]$Artifacts)

    function Get-OSPlatform {
        return @{
            Platform     = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription.Trim()
            Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        }
    }

    function Get-ManifestsRoot {
        $root = Join-Path $PSScriptRoot "..\..\manifests"
        if (-not (Test-Path $root)) {
            New-Item -ItemType Directory -Path $root -Force | Out-Null
        }
        return $root
    }

    $manifestsRoot = Get-ManifestsRoot
    $jsonPath = Join-Path $manifestsRoot "manifest.json"
    $mdPath   = Join-Path $manifestsRoot "manifest.md"
    $timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $osInfo = Get-OSPlatform

    # 🧱 Build structured JSON
    $manifest = @{
        Timestamp = $timestamp
        System = @{
            Platform     = $osInfo.Platform
            Architecture = $osInfo.Architecture
        }
        Artifacts = $Artifacts | ForEach-Object {
            @{
                Engine      = $_.Engine
                Version     = $_.Version
                BuildType   = $_.BuildType
                Compiler    = $_.Compiler
                Success     = $_.Success
                Path        = Join-Path "binaries" "$($_.Engine)-$($_.Version)-$($_.BuildType)-$($_.Compiler)-$($osInfo.Architecture)"
            }
        }
    }

    # 💾 Save JSON
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Host "📄 JSON manifest exported: $jsonPath"

    # 📝 Markdown table
    $successCount = ($Artifacts | Where-Object { $_.Success }).Count
    $totalCount   = $Artifacts.Count

    $mdHeader = @"
# 📦 Lua Build Manifest

**Generated:** $timestamp
**System:** $($osInfo.Platform) / $($osInfo.Architecture)
**Success Rate:** $successCount / $totalCount builds succeeded

## 🔍 Artifacts

| Engine  | Version | Build Type | Compiler | Status     | Binary Path |
|---------|---------|------------|----------|------------|-------------|
"@

    $mdRows = $Artifacts | ForEach-Object {
        $status = if ($_.Success) { "✅ Success" } else { "❌ Failed" }
        $binPath = "binaries/$($_.Engine)-$($_.Version)-$($_.BuildType)-$($_.Compiler)-$($osInfo.Architecture)"
        "| $($_.Engine) | $($_.Version) | $($_.BuildType) | $($_.Compiler) | $status | $binPath |"
    }

    $mdContent = $mdHeader + ($mdRows -join "`n") + "`n"
    $mdContent | Set-Content -Path $mdPath -Encoding UTF8
    Write-Host "📝 Markdown manifest exported: $mdPath"
}

Export-ModuleMember -Function Export-LuaBuildManifest
