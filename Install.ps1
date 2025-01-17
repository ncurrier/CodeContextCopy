# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    exit
}

# Enable strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
.SYNOPSIS
    Installs a context menu entry ("Copy Directory Contents to Clipboard")
    pointing to the `CopyDirContentsWithSecurity.ps1` script in this folder.

.DESCRIPTION
    This script adds a Windows Explorer context menu entry for directories
    that allows users to copy the contents of a directory to the clipboard
    using the CopyDirContentsWithSecurity.ps1 script.

.NOTES
    - Requires administrative privileges
    - Modifies the Windows Registry
    - Will overwrite existing entries if they exist
#>

try {
    # Get the directory of this script
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $scriptPath = Join-Path $scriptDirectory "CopyDirContentsWithSecurity.ps1"

    # Check if the script exists
    if (-not (Test-Path $scriptPath)) {
        throw "Could not find 'CopyDirContentsWithSecurity.ps1' in $scriptDirectory"
    }

    # Build the registry command with proper escaping
    $pwshPath = (Get-Command powershell).Source
    $command = "`"$pwshPath`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -Command `"& { Start-Process `"$pwshPath`" -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\`"$scriptPath\`"','\`"%1\`"' -Wait }`""

    # Registry key for the context menu (using PSDrive to ensure proper access)
    $hkcr = Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue
    if (-not $hkcr) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }

    $regKeyPath = "HKCR:\Directory\shell\Copy Directory Contents"
    $regKeyCommandPath = "$regKeyPath\command"

    # Remove existing keys if they exist
    if (Test-Path $regKeyPath) {
        Remove-Item -Path $regKeyPath -Recurse -Force
    }

    # Create the registry keys
    $null = New-Item -Path $regKeyPath -Force
    $null = New-ItemProperty -Path $regKeyPath -Name "(default)" -Value "Copy Directory Contents to Clipboard"
    $null = New-Item -Path $regKeyCommandPath -Force
    $null = New-ItemProperty -Path $regKeyCommandPath -Name "(default)" -Value $command

    Write-Host "Context menu entry installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing context menu entry: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
