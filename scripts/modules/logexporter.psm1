# logexporter.psm1 — Export Build Logs to docs/dev/logs/
# Example Usage:
# Export-BuildLogsToDocs -DryRun -Verbose
# Export-BuildLogsToDocs -Force

function Export-BuildLogsToDocs {
    <#
    .SYNOPSIS
        Copies all Markdown build logs to the Docusaurus documentation folder.

    .PARAMETER DocsRoot
        Destination path (defaults to 'docs/dev/logs' inside the project root).

    .PARAMETER Force
        Overwrites existing logs if present.

    .PARAMETER DryRun
        Simulates log export without actually copying files.
    #>
    param(
        [string]$DocsRoot = (Join-Path (Get-ProjectRoot) "docs/dev/logs"),
        [switch]$Force,
        [switch]$DryRun
    )

    $logsRoot = Get-ScriptsLogsRoot
    if (-not (Test-Path $logsRoot)) {
        Write-WarningLog "⚠️ No logs found at: $logsRoot"
        return
    }

    if (-not (Test-Path $DocsRoot) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $DocsRoot -Force | Out-Null
    }

    $logFiles = Get-ChildItem -Path $logsRoot -Recurse -Filter *.md -File
    if ($logFiles.Count -eq 0) {
        Write-WarningLog "⚠️ No Markdown logs to export"
        return
    }

    foreach ($file in $logFiles) {
        $relativePath = $file.FullName.Substring($logsRoot.Length).TrimStart('\', '/')
        $targetPath = Join-Path $DocsRoot $relativePath
        $targetDir  = Split-Path $targetPath -Parent

        if ($DryRun) {
            Write-VerboseLog "[DryRun] Would export log → $targetPath"
            continue
        }

        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if (-not (Test-Path $targetPath) -or $Force) {
            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            Write-InfoLog "📤 Exported log → $targetPath"
        }
        else {
            Write-VerboseLog "ℹ️ Skipped existing log: $targetPath"
        }
    }

    if (-not $DryRun) {
        Write-InfoLog "✅ All logs exported to Docusaurus: $DocsRoot"
    } else {
        Write-InfoLog "✅ [DryRun] Log export simulation complete"
    }
}

Export-ModuleMember -Function Export-BuildLogsToDocs
