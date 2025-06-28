<#
    setup-prereqs.ps1 — LuaDev Windows Bootstrap Script
    https://github.com/hetfs/luaDev

    Author: Fredaws Lomdo
    Location: Accra, Ghana
    Description:
    - Installs Git, CMake, LLVM, Ninja, Python, Rust, Perl, direnv, git-cliff
    - Supports CI mode with --ci flag
    - Auto-updates packages with winget upgrade
    - Cleans up old log files (keeps last 5 logs)
#>

param (
    [switch]$ci
)

$ErrorActionPreference = "Stop"

# Log directory setup with cleanup
$logDir = "$PSScriptRoot\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

# Clean up old logs (keep last 5)
Get-ChildItem -Path $logDir -Filter "luaDev-prereqs-*.log" |
    Sort-Object CreationTime -Descending |
    Select-Object -Skip 5 |
    Remove-Item -Force -ErrorAction SilentlyContinue

# Create new log file
$logFile = "$logDir\luaDev-prereqs-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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
Write-Log "🔧 Starting Lua Dev Setup" -Color DarkGray
Write-Log "Log file: $logFile"
Write-Log "CI Mode: $($ci.IsPresent)" -Color DarkGray

# Winget validation
function Assert-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log "❌ WinGet is not available" -Color Red
        Write-Log "ℹ️ Install from: https://aka.ms/winget-install" -Color Yellow
        exit 1
    }
}

# Enhanced installation function
function Install-Tool {
    param (
        [string]$Command,
        [string]$WingetId,
        [string]$DisplayName = $Command
    )

    # Check if already installed
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Log "✅ $DisplayName already installed" -Color Green
        return $true
    }

    Write-Log "⬇️ Installing $DisplayName ($WingetId)..." -Color Yellow
    $installResult = winget install --id $WingetId --source winget `
        --accept-package-agreements --accept-source-agreements `
        --silent 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ $DisplayName installed successfully" -Color Green
        return $true
    }
    
    Write-Log "❌ $DisplayName installation failed (Code: $LASTEXITCODE)" -Color Red
    Write-Log "Error details: $installResult" -Color Red
    return $false
}

# Environment refresh function
function Update-Environment {
    Write-Log "🔄 Refreshing environment variables..." -Color DarkGray
    foreach ($level in "Machine", "User") {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            if ($_.Name -eq 'PATH') {
                $_.Value = [Environment]::GetEnvironmentVariable($_.Name, $level)
            } else {
                Set-Item "env:$($_.Name)" $_.Value
            }
        }
    }
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [Environment]::GetEnvironmentVariable("PATH", "User") + ";" +
                [Environment]::GetEnvironmentVariable("PATH", "Process")
}

# ------------------------- Main Execution -------------------------
Assert-Winget

# Auto-upgrade packages
if ($ci) {
    Write-Log "🔄 Upgrading installed packages..." -Color DarkYellow
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Log "⚠️ Package upgrades completed with errors" -Color Yellow
    }
}

# Install tools
Write-Log "`n=== 🔧 Installing Tools ===" -Color Cyan
$tools = @(
    @{Command = "git"; WingetId = "Git.Git"; Name = "Git"},
    @{Command = "cmake"; WingetId = "Kitware.CMake"; Name = "CMake"},
    @{Command = "clang"; WingetId = "LLVM.LLVM"; Name = "LLVM/Clang"},
    @{Command = "ninja"; WingetId = "Microsoft.Ninja"; Name = "Ninja"},
    @{Command = "python"; WingetId = "Python.Python.3"; Name = "Python 3"},
    @{Command = "rustc"; WingetId = "Rustlang.Rustup"; Name = "Rust Toolchain"},
    @{Command = "perl"; WingetId = "StrawberryPerl.StrawberryPerl"; Name = "Perl"},
    @{Command = "direnv"; WingetId = "direnv.direnv"; Name = "direnv"},
    @{Command = "git-cliff"; WingetId = "Orhun.git-cliff"; Name = "git-cliff"}
)

$allSuccess = $true
foreach ($tool in $tools) {
    if (-not (Install-Tool @tool)) {
        $allSuccess = $false
        if ($ci) { exit 1 }
    }
}

# Setup Rust
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    Write-Log "🦀 Configuring Rust toolchain..." -Color DarkGray
    rustup install stable 2>&1 | Out-File $logFile -Append
    rustup default stable 2>&1 | Out-File $logFile -Append
}

# Add Cargo to PATH
$cargoPath = "$env:USERPROFILE\.cargo\bin"
if (-not ($env:Path -split ';' -contains $cargoPath)) {
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$cargoPath", "User")
    $env:Path += ";$cargoPath"
    Write-Log "🔧 Added Cargo to PATH" -Color Cyan
}

# Refresh environment after installations
Update-Environment

# Verification
Write-Log "`n=== 🔍 Verifying Tools ===" -Color Cyan
$toolsToVerify = @(
    @{Name = "Git"; Command = "git"; Arguments = "--version"},
    @{Name = "CMake"; Command = "cmake"; Arguments = "--version"},
    @{Name = "Clang"; Command = "clang"; Arguments = "--version"},
    @{Name = "Ninja"; Command = "ninja"; Arguments = "--version"},
    @{Name = "Python"; Command = "python"; Arguments = "--version"},
    @{Name = "Rust"; Command = "rustc"; Arguments = "--version"},
    @{Name = "Cargo"; Command = "cargo"; Arguments = "--version"},
    @{Name = "Perl"; Command = "perl"; Arguments = "-v"},  # Standard version output
    @{Name = "direnv"; Command = "direnv"; Arguments = "--version"},
    @{Name = "git-cliff"; Command = "git-cliff"; Arguments = "--version"}
)

foreach ($tool in $toolsToVerify) {
    try {
        $output = & $tool.Command $tool.Arguments 2>&1 | Select-Object -First 1
        
        # For Perl's -v output, clean up the first line
        if ($tool.Name -eq "Perl") {
            $output = ($output -split "`n")[0]  # Get first line of multi-line output
        }
        
        Write-Log "✅ $($tool.Name): $($output.Trim())" -Color Green
    } catch {
        Write-Log "❌ $($tool.Name): Verification failed" -Color Red
        $allSuccess = $false
    }
}

# Final status
if ($allSuccess) {
    Write-Log "`n=== ✅ Setup Completed Successfully! ===" -Color Green
} else {
    Write-Log "`n=== ⚠️ Setup Completed With Warnings ===" -Color Yellow
    Write-Log "Check log file for details: $logFile" -Color Yellow
}

# Log cleanup report
$keptLogs = Get-ChildItem -Path $logDir -Filter "luaDev-prereqs-*.log" | 
    Sort-Object CreationTime -Descending |
    Select-Object -First 5

Write-Log "`n🗑️ Log cleanup: Kept ${$keptLogs.Count} most recent logs" -Color DarkGray
