<#
    luaDev-prereqs.ps1 — LuaDev Windows Bootstrap Script
    https://github.com/hetfs/luaDev

    Author: Fredaws Lomdo
    Location: Accra, Ghana

    Description:
    - Installs Git, CMake, LLVM, Ninja, Python, Rust, Perl, direnv, git-cliff
    - Includes extra tools: Cppcheck, Clangd, LuaLS, 7-Zip, Make
    - Supports flags: --ci, --Minimal, --All, --DryRun
    - Cleans up old logs (keeps last 5)
    - Verifies all tools after install
#>

param (
    [switch]$ci,
    [switch]$Minimal,
    [switch]$All,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Set log folder and rotate logs
$logDir = "$PSScriptRoot\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = "$logDir\luaDev-prereqs-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Get-ChildItem -Path $logDir -Filter "luaDev-prereqs-*.log" |
    Sort-Object CreationTime -Descending |
    Select-Object -Skip 5 |
    Remove-Item -Force -ErrorAction SilentlyContinue

function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )
    $timestamp = "[$(Get-Date -Format u)]"
    $logMessage = "$timestamp $Message"
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
    $logMessage | Out-File -FilePath $logFile -Append -Encoding UTF8
}

Write-Log "=== 🚀 luaDev Setup (Windows) ===" -Color Cyan
Write-Log "Log file: $logFile"
Write-Log "CI Mode: $($ci.IsPresent)" -Color DarkGray
Write-Log "Minimal: $($Minimal.IsPresent) | DryRun: $($DryRun.IsPresent)" -Color DarkGray

function Assert-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log "❌ WinGet is not available" -Color Red
        Write-Log "ℹ️ Install from: https://aka.ms/winget-install" -Color Yellow
        exit 1
    }
}

function Install-Tool {
    param (
        [string]$Command,
        [string]$WingetId,
        [string]$Name = $Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Log "✅ ${Name} already installed" -Color Green
        return $true
    }

    if ($DryRun) {
        Write-Log "🔍 [DryRun] Would install: ${Name} ($WingetId)" -Color Yellow
        return $true
    }

    Write-Log "⬇️ Installing ${Name} ($WingetId)..." -Color Yellow
    $installResult = winget install --id=$WingetId -e --accept-package-agreements --accept-source-agreements 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ ${Name} installed successfully" -Color Green
        return $true
    }

    Write-Log "❌ ${Name} installation failed (Code: $LASTEXITCODE)" -Color Red
    Write-Log "Error details: $installResult" -Color Red
    return $false
}

function Update-Environment {
    Write-Log "🔄 Refreshing environment variables..." -Color DarkGray
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH","User") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH","Process")
}

# Define tool groups
$coreTools = @(
    @{Command = "git"; WingetId = "Git.Git"; Name = "Git"},
    @{Command = "cmake"; WingetId = "Kitware.CMake"; Name = "CMake"},
    @{Command = "clang"; WingetId = "LLVM.LLVM"; Name = "LLVM/Clang"},
    @{Command = "clangd"; WingetId = "LLVM.clangd"; Name = "Clangd"},
    @{Command = "ninja"; WingetId = "Ninja-build.Ninja"; Name = "Ninja"},
    @{Command = "python"; WingetId = "Python.Python.3.13"; Name = "Python"},
    @{Command = "rustc"; WingetId = "Rustlang.Rustup"; Name = "Rust Toolchain"},
    @{Command = "perl"; WingetId = "StrawberryPerl.StrawberryPerl"; Name = "Perl"},
    @{Command = "direnv"; WingetId = "direnv.direnv"; Name = "direnv"},
    @{Command = "git-cliff"; WingetId = "Orhun.git-cliff"; Name = "git-cliff"}
)

$extraTools = @(
    @{Command = "cppcheck"; WingetId = "Cppcheck.Cppcheck"; Name = "Cppcheck"},
    @{Command = "make"; WingetId = "GnuWin32.Make"; Name = "GNU Make"},
    @{Command = "7z"; WingetId = "7zip.7zip"; Name = "7-Zip"},
    @{Command = "lua-language-server"; WingetId = "LuaLS.lua-language-server"; Name = "LuaLS"}
)

$toolsToInstall = if ($All) {
    $coreTools + $extraTools
} elseif ($Minimal) {
    $coreTools | Where-Object { $_.Name -in @("Git", "CMake", "Python", "Rust Toolchain") }
} else {
    $coreTools
}

# Start installs
Assert-Winget
Write-Log "`n=== 🔧 Installing Tools ===" -Color Cyan

$allSuccess = $true
foreach ($tool in $toolsToInstall) {
    if (-not (Install-Tool @tool)) {
        $allSuccess = $false
        if ($ci) { exit 1 }
    }
}

# Rust setup
if ((Get-Command rustup -ErrorAction SilentlyContinue) -and -not $DryRun) {
    Write-Log "🦀 Configuring Rust toolchain..." -Color Gray
    rustup install stable | Out-File $logFile -Append
    rustup default stable | Out-File $logFile -Append
}

Update-Environment

# Tool Verification
Write-Log "`n=== 🔍 Verifying Tools ===" -Color Cyan
$verifyTools = $toolsToInstall | ForEach-Object {
    $cmd = $_.Command
    $args = "--version"
    if ($cmd -eq "perl") { $args = "-v" }
    if ($cmd -eq "lua-language-server") { $args = "--version" }
    if ($cmd -eq "7z") { $cmd = "7z"; $args = "" }
    @{ Name = $_.Name; Command = $cmd; Arguments = $args }
}

foreach ($tool in $verifyTools) {
    $Name = $tool.Name
    $Command = $tool.Command
    $Arguments = $tool.Arguments

    try {
        if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
            Write-Log "❌ ${Name}: Command not found" -Color Red
            $allSuccess = $false
            continue
        }

        $output = & $Command $Arguments 2>&1 | Select-Object -First 1
        if ($Name -eq "Perl") {
            $output = ($output -split "`n")[0]
        }

        Write-Log "✅ ${Name}: $($output.Trim())" -Color Green
    } catch {
        Write-Log "❌ ${Name}: Verification failed" -Color Red
        $allSuccess = $false
    }
}

# Final Summary
if ($DryRun) {
    Write-Log "`n[DryRun] Completed preview mode. No changes made." -Color Cyan
} elseif ($allSuccess) {
    Write-Log "`n=== ✅ Setup Completed Successfully! ===" -Color Green
} else {
    Write-Log "`n=== ⚠️ Setup Completed With Issues ===" -Color Yellow
    Write-Log "Review the log file: $logFile" -Color Yellow
}

$keptLogs = Get-ChildItem -Path $logDir -Filter "luaDev-prereqs-*.log" |
    Sort-Object CreationTime -Descending |
    Select-Object -First 5

Write-Log "`n🗑️ Log cleanup complete — Kept $($keptLogs.Count) logs in $logDir" -Color DarkGray
