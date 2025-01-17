param(
    [Parameter()]
    [ValidateSet('Build', 'Test', 'Install', 'Uninstall')]
    [string]$Task = 'Build'
)

# Import required modules
if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
}
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Scope CurrentUser -Force
}

# Define paths
$srcPath = Join-Path $PSScriptRoot 'src'
$testsPath = Join-Path $PSScriptRoot 'tests'
$outputPath = Join-Path $PSScriptRoot 'output'

# Task functions
function Build-Module {
    # Create output directory
    if (Test-Path $outputPath) {
        Remove-Item -Path $outputPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $outputPath | Out-Null

    # Run PSScriptAnalyzer
    $analysis = Invoke-ScriptAnalyzer -Path $srcPath -Recurse
    if ($analysis) {
        Write-Warning "PSScriptAnalyzer found issues:"
        $analysis | Format-Table -AutoSize
    }

    # Copy only the necessary files to output
    $filesToCopy = @(
        'Copy-DirectoryContent.ps1',
        'CodeContextCopy.psd1'
    )

    foreach ($file in $filesToCopy) {
        $sourcePath = Join-Path $srcPath $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $outputPath
        } else {
            Write-Warning "Source file not found: $sourcePath"
        }
    }
}

function Test-Module {
    $config = New-PesterConfiguration
    $config.Run.Path = $testsPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    
    Write-Host "Running tests..." -ForegroundColor Cyan
    $results = Invoke-Pester -Configuration $config

    if ($results.FailedCount -gt 0) {
        Write-Host "Tests failed!" -ForegroundColor Red
        exit 1
    }
}

function Install-Module {
    & "$PSScriptRoot\scripts\Install.ps1"
}

function Uninstall-Module {
    & "$PSScriptRoot\scripts\Remove.ps1"
}

# Execute requested task
switch ($Task) {
    'Build' { Build-Module }
    'Test' { Test-Module }
    'Install' { Install-Module }
    'Uninstall' { Uninstall-Module }
}
