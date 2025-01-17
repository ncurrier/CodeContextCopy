# Import module for Test-IsAdmin function
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDirectory = Split-Path -Parent $scriptDirectory
$modulePath = Join-Path $rootDirectory "output\Copy-DirectoryContent.ps1"
Import-Module $modulePath -Force

# Self-elevate the script if required
if (-Not (Test-IsAdmin)) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    exit
}

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
    # Registry key for the context menu
    $regKeyPath = "HKCU:\Software\Classes\Directory\shell\Copy Directory Contents"

    # Remove the registry keys if they exist
    if (Test-Path $regKeyPath) {
        Write-Host "Removing context menu entry..." -ForegroundColor Cyan
        Remove-Item -Path $regKeyPath -Recurse -Force
        Write-Host "Context menu entry removed successfully." -ForegroundColor Green
    } else {
        Write-Host "Context menu entry not found. Nothing to remove." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error removing context menu entry: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
