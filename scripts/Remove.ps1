# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    exit
}

# Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Removes the "Copy Directory Contents to Clipboard" context menu entry.

.DESCRIPTION
    This script removes the Windows Explorer context menu entry that was
    created by Install.ps1. It will remove both the command and the menu
    entry from the registry.

.NOTES
    - Requires administrative privileges
    - Modifies the Windows Registry
    - Safe to run multiple times (idempotent)
#>

try {
    # Get the root directory (parent of scripts)
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootPath = Split-Path -Parent $scriptPath
    $regFile = Join-Path $rootPath "config\RemoveContextMenu.reg"

    # Verify file exists
    if (-not (Test-Path $regFile)) {
        Write-Host "Error: Registry file not found at: $regFile" -ForegroundColor Red
        exit 1
    }

    # Remove the registry entries
    try {
        Write-Host "Removing context menu entry..." -ForegroundColor Cyan
        $process = Start-Process "reg.exe" -ArgumentList "import `"$regFile`"" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Registry import failed with exit code: $($process.ExitCode)"
        }

        Write-Host "`nUninstallation successful!" -ForegroundColor Green
        Write-Host "The 'Copy Directory Contents' context menu entry has been removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing context menu entry: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error removing context menu entry: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
