# export.psm1 — Log Export Helpers for luaDev (Markdown formatter)

# 🛡️ Fallback logging in case main logging module isn't loaded
if (-not (Get-Command Write-InfoLog -ErrorAction SilentlyContinue)) {
    function Write-InfoLog { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
}
if (-not (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue)) {
    function Write-ErrorLog { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
}

function Export-LogAsMarkdown {
    <#
    .SYNOPSIS
        Converts PowerShell log lines to a themed Markdown `.md` file grouped by engine and version.
    .PARAMETER MarkdownPath
        Full path to the output `.md` file.
    .PARAMETER LogLines
        Raw log lines (array from Get-Content).
    .PARAMETER Title
        Optional page title.
    #>
    param(
        [Parameter(Mandatory = $true)] [string]$MarkdownPath,
        [Parameter(Mandatory = $true)] [string[]]$LogLines,
        [string]$Title = "📝 Build Log"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    $newline = [Environment]::NewLine

    $header = @"
# $Title

**Generated on:** $timestamp

"@

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
        $grouped = Group-LogLinesByEngineAndVersion -Lines $LogLines
        $content = $header

        foreach ($section in $grouped.Keys) {
            $logs = $grouped[$section]
            $content += "$newline---$newline### 🧩 $section$newline"

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

        Set-Content -Path $MarkdownPath -Value $content -Encoding UTF8
        Write-InfoLog "📄 Markdown log exported: $MarkdownPath"
    }
    catch {
        Write-ErrorLog "❌ Failed to export Markdown log: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Export-LogAsMarkdown
