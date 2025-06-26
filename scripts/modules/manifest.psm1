function Export-LuaBuildManifest {
    param([array]$Artifacts)

    $jsonPath = Join-Path (Get-ManifestsRoot) "manifest.json"
    $mdPath = Join-Path (Get-ManifestsRoot) "manifest.md"
    $timestamp = [DateTime]::UtcNow.ToString("o")
    $osInfo = Get-OSPlatform

    # JSON Manifest
    $manifest = @{
        Timestamp = $timestamp
        System = @{
            Platform = $osInfo.Platform
            Architecture = $osInfo.Architecture
            Cores = $osInfo.Cores
        }
        Artifacts = $Artifacts | ForEach-Object {
            @{
                Engine = $_.Engine
                Version = $_.Version
                Platform = $_.Platform
                Architecture = $_.Architecture
                BuildTime = $_.BuildTime.ToString("o")
                Success = $_.Success
                BinaryPath = Join-Path "LuaBinaries" "$($_.Engine)-$($_.Version)-$($osInfo.Platform)-$($osInfo.Architecture)"
            }
        }
    }
    $manifest | ConvertTo-Json -Depth 3 | Set-Content $jsonPath

    # Markdown Report
    $mdContent = @"
# Lua Build Manifest

## Summary
- **Timestamp**: $timestamp
- **System**: $($osInfo.Platform)-$($osInfo.Architecture)
- **Success Rate**: $($Artifacts.Where({$_.Success}).Count)/$($Artifacts.Count) succeeded

## Artifacts
| Engine  | Version   | Platform | Architecture | Status   | Binary Path |
|---------|-----------|----------|--------------|----------|-------------|
"@

    $Artifacts | ForEach-Object {
        $status = if ($_.Success) { "✅ Success" } else { "❌ Failed" }
        $binaryPath = "$($_.Engine)-$($_.Version)-$($osInfo.Platform)-$($osInfo.Architecture)"
        $mdContent += "| $($_.Engine) | $($_.Version) | $($_.Platform) | $($_.Architecture) | $status | \`$LuaBinaries/$binaryPath |`n"
    }

    $mdContent | Set-Content $mdPath
}

Export-ModuleMember -Function Export-LuaBuildManifest
