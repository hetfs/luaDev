function Export-LuaBuildManifest {
    param([array]$Artifacts)

    $jsonPath = Join-Path (Get-ManifestsRoot) "manifest.json"
    $timestamp = [DateTime]::UtcNow.ToString("o")
    $osInfo = Get-OSPlatform

    # JSON Manifest with increased depth
    $manifest = @{
        Timestamp = $timestamp
        System = @{
            Platform = $osInfo.Platform
            Architecture = $osInfo.Architecture
        }
        Artifacts = $Artifacts | ForEach-Object {
            @{
                Engine = $_.Engine
                Version = $_.Version
                BuildType = $_.BuildType
                Compiler = $_.Compiler
                Success = $_.Success
                Path = Join-Path "binaries" "$($_.Engine)-$($_.Version)-$($_.BuildType)-$($_.Compiler)-$($osInfo.Architecture)"
            }
        }
    }

    # Increased depth to 10 to prevent truncation
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $jsonPath

    # Markdown Report
    $mdPath = Join-Path (Get-ManifestsRoot) "manifest.md"
    $mdContent = @"
# Lua Build Manifest

## Summary
- **Timestamp**: $timestamp
- **System**: $($osInfo.Platform)-$($osInfo.Architecture)
- **Success Rate**: $($Artifacts.Where({$_.Success}).Count)/$($Artifacts.Count) succeeded

## Artifacts
| Engine  | Version   | Build Type | Compiler | Status   | Binary Path |
|---------|-----------|------------|----------|----------|-------------|
"@

    $Artifacts | ForEach-Object {
        $status = if ($_.Success) { "✅ Success" } else { "❌ Failed" }
        $binaryPath = "$($_.Engine)-$($_.Version)-$($_.BuildType)-$($_.Compiler)-$($osInfo.Architecture)"
        $mdContent += "| $($_.Engine) | $($_.Version) | $($_.BuildType) | $($_.Compiler) | $status | \`$binaries/$binaryPath |`n"
    }

    $mdContent | Set-Content $mdPath
}

Export-ModuleMember -Function Export-LuaBuildManifest
