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
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath | Out-Null
    }

    # Run PSScriptAnalyzer
    $analysis = Invoke-ScriptAnalyzer -Path $srcPath -Recurse
    if ($analysis) {
        Write-Warning "PSScriptAnalyzer found issues:"
        $analysis | Format-Table -AutoSize
    }

    # Copy files to output
    Copy-Item -Path "$srcPath\*" -Destination $outputPath -Recurse -Force
}

function Test-Module {
    $config = New-PesterConfiguration
    $config.Run.Path = $testsPath
    $config.Output.Verbosity = 'Detailed'
    Invoke-Pester -Configuration $config
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
