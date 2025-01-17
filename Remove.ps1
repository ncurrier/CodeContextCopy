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

# Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    # Registry key for the context menu (using PSDrive to ensure proper access)
    $hkcr = Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue
    if (-not $hkcr) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }

    $regKeyPath = "HKCR:\Directory\shell\Copy Directory Contents"

    # Remove the registry key if it exists
    if (Test-Path $regKeyPath) {
        Remove-Item -Path $regKeyPath -Recurse -Force -ErrorAction Stop
        Write-Host "Context menu entry uninstalled successfully." -ForegroundColor Green
    } else {
        Write-Host "Context menu entry not found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error removing context menu entry: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
