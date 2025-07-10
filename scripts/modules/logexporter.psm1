# logExporter.psm1 — Log Export Helpers for luaDev (Markdown formatter)

# 🛡️ Fallback logging in case main logging module isn't loaded
if (-not (Get-Command Write-InfoLog -ErrorAction SilentlyContinue)) {
    function Write-InfoLog { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
}
if (-not (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue)) {
    function Write-ErrorLog { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
}
if (-not (Get-Command Write-WarningLog -ErrorAction SilentlyContinue)) {
    function Write-WarningLog { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
}

function Export-LogAsMarkdown {
    <#
    .SYNOPSIS
        Converts log lines into a structured Markdown log.

    .PARAMETER LogLines
        Array of raw log lines to export.

    .PARAMETER Title
        Optional title for the Markdown file.

    .PARAMETER Path
        Full path to the output Markdown file.

    .PARAMETER DryRun
        If present, simulates export without writing to disk.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$LogLines,
        [string]$Title = "📝 Build Log",
        [string]$Path = (Join-Path -Resolve $PSScriptRoot "../logs/build.md"),
        [switch]$DryRun
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    $newline = [Environment]::NewLine
    $dir = Split-Path -Parent $Path

    function Group-LogLinesByEngineAndVersion {
        param ([string[]]$Lines)

        $groups = @{}

        foreach ($line in $Lines) {
            if ($line -match '\[(?<level>[A-Z]+)\]\s+\[(?<engine>lua|luajit)\]\s+(?<version>[^\s]+)\s*-\s*(?<message>.+)') {
                $level = $matches.level
                $engine = $matches.engine.ToUpper()
                $version = $matches.version
                $key = "$engine $version"

                if (-not $groups.ContainsKey($key)) {
                    $groups[$key] = @{
                        Success  = @()
                        Warnings = @()
                        Errors   = @()
                        Other    = @()
                    }
                }

                switch ($level) {
                    "INFO" {
                        if ($matches.message -match "Build successful") {
                            $groups[$key].Success += $line
                        } else {
                            $groups[$key].Other += $line
                        }
                    }
                    "WARN"  { $groups[$key].Warnings += $line }
                    "ERROR" { $groups[$key].Errors += $line }
                    default { $groups[$key].Other += $line }
                }
            }
            else {
                if (-not $groups.ContainsKey("Global")) {
                    $groups["Global"] = @{
                        Success  = @()
                        Warnings = @()
                        Errors   = @()
                        Other    = @()
                    }
                }
                $groups["Global"].Other += $line
            }
        }

        return $groups
    }

    try {
        $header = @"
# $Title

**Generated on:** $timestamp

"@

        $grouped = Group-LogLinesByEngineAndVersion -Lines $LogLines
        $content = $header

        foreach ($section in $grouped.Keys) {
            $logs = $grouped[$section]
            $content += "$newline---$newline### 🧹 $section$newline"

            if ($logs.Success.Count -gt 0) {
                $content += "#### ✅ Success$newline```log$newline"
                $content += ($logs.Success -join $newline)
                $content += "$newline```$newline"
            }

            if ($logs.Warnings.Count -gt 0) {
                $content += "#### ⚠️ Warnings$newline```log$newline"
                $content += ($logs.Warnings -join $newline)
                $content += "$newline```$newline"
            }

            if ($logs.Errors.Count -gt 0) {
                $content += "#### ❌ Errors$newline```log$newline"
                $content += ($logs.Errors -join $newline)
                $content += "$newline```$newline"
            }

            if ($logs.Other.Count -gt 0) {
                $content += "#### 📄 Other Logs$newline```log$newline"
                $content += ($logs.Other -join $newline)
                $content += "$newline```$newline"
            }
        }

        if ($DryRun) {
            Write-InfoLog "[DryRun] Would export Markdown log to: $Path"
            return
        }

        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }

        # 🛉 Clean other md files in same folder except the target one
        Get-ChildItem -Path $dir -Filter "*.md" -File |
            Where-Object { $_.FullName -ne $Path } |
            Remove-Item -Force -ErrorAction SilentlyContinue

        Set-Content -Path $Path -Value $content -Encoding UTF8
        Write-InfoLog "📄 Markdown log exported: $Path"
    }
    catch {
        Write-ErrorLog "❌ Failed to export Markdown log: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Export-LogAsMarkdown
