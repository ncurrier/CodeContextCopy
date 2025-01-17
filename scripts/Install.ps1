# Enable strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import module for Test-IsAdmin function
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDirectory = Split-Path -Parent $scriptDirectory
$modulePath = Join-Path $rootDirectory "output\Copy-DirectoryContent.ps1"
Import-Module $modulePath -Force

# Self-elevate the script if required
if (-Not (Test-IsAdmin)) {
    Write-Host "Requesting administrative privileges for registry modification..." -ForegroundColor Yellow
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    exit
}

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Installs a context menu entry ("Copy Directory Contents to Clipboard")
    pointing to the `Copy-DirectoryContent` function.

.DESCRIPTION
    This script adds a Windows Explorer context menu entry for directories
    that allows users to copy the contents of a directory to the clipboard
    using the Copy-DirectoryContent function.

.NOTES
    - Requires administrative privileges (for registry modification only)
    - Modifies the Windows Registry
    - Will overwrite existing entries if they exist
#>

try {
    # Get the directory of this script
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $rootDirectory = Split-Path -Parent $scriptDirectory
    $modulePath = Join-Path $rootDirectory "output\Copy-DirectoryContent.ps1"
    $iconPath = Join-Path $rootDirectory "assets\folder_icon_with_arrow.ico"

    # Check if the script exists
    if (-not (Test-Path $modulePath)) {
        throw "Could not find 'Copy-DirectoryContent.ps1' in $modulePath"
    }

    # Check if the icon exists
    if (-not (Test-Path $iconPath)) {
        throw "Could not find icon file at $iconPath"
    }

    # Build the registry command with proper escaping
    $pwshPath = (Get-Command powershell).Source
    $command = "`"$pwshPath`" -NoProfile -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -Command `"& { param([string]`$path) Import-Module '$modulePath'; Copy-DirectoryContent -Path `$path } -path '%V'`""

    # Registry key for the context menu
    $regKeyPath = "HKCU:\Software\Classes\Directory\shell\Copy Directory Contents"
    $regKeyCommandPath = "$regKeyPath\command"

    # Remove existing keys if they exist
    if (Test-Path $regKeyPath) {
        Remove-Item -Path $regKeyPath -Recurse -Force
    }

    # Create the registry keys
    $null = New-Item -Path $regKeyPath -Force
    $null = New-ItemProperty -Path $regKeyPath -Name "(default)" -Value "Copy Directory Contents to Clipboard"
    $null = New-ItemProperty -Path $regKeyPath -Name "Icon" -Value $iconPath
    $null = New-Item -Path $regKeyCommandPath -Force
    $null = New-ItemProperty -Path $regKeyCommandPath -Name "(default)" -Value $command

    Write-Host "Context menu entry installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing context menu entry: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
