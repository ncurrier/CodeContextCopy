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
$rootPath = Split-Path $PSScriptRoot -Parent
$srcPath = Join-Path $rootPath 'src'
$testsPath = Join-Path $rootPath 'tests'
$binPath = Join-Path $rootPath 'bin'

# Task functions
function Build-Module {
    # Create output directory
    if (Test-Path $binPath) {
        Remove-Item -Path $binPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $binPath | Out-Null

    # Run PSScriptAnalyzer
    $analysis = Invoke-ScriptAnalyzer -Path $srcPath -Recurse
    if ($analysis) {
        Write-Warning "PSScriptAnalyzer found issues:"
        $analysis | Format-Table -AutoSize
    }

    # Copy source files to output
    $srcFiles = @(
        'Copy-DirectoryContent.ps1',
        'CodeContextCopy.psd1'
    )

    foreach ($file in $srcFiles) {
        $sourcePath = Join-Path $srcPath $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $binPath -Force
        } else {
            Write-Warning "Source file not found: $sourcePath"
        }
    }

    # Copy script files to output
    $scriptFiles = @(
        'Install.ps1',
        'Remove.ps1'
    )

    foreach ($file in $scriptFiles) {
        $sourcePath = Join-Path $PSScriptRoot $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $binPath -Force
        } else {
            Write-Warning "Script file not found: $sourcePath"
        }
    }
}

function Test-Module {
    Write-Host "Running tests..."
    $config = New-PesterConfiguration
    $config.Run.Path = $testsPath
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = Join-Path $binPath "test-results.xml"
    $config.Output.Verbosity = "Detailed"
    
    $result = Invoke-Pester -Configuration $config
    if ($result.FailedCount -gt 0) {
        throw "Tests failed!"
    }
}

function Install-Module {
    $installScript = Join-Path $binPath "Install.ps1"
    if (Test-Path $installScript) {
        & $installScript
    } else {
        Write-Error "Install script not found: $installScript"
    }
}

function Uninstall-Module {
    $removeScript = Join-Path $binPath "Remove.ps1"
    if (Test-Path $removeScript) {
        & $removeScript
    } else {
        Write-Error "Remove script not found: $removeScript"
    }
}

# Run the specified task
switch ($Task) {
    'Build' {
        Build-Module
    }
    'Test' {
        Build-Module
        Test-Module
    }
    'Install' {
        Build-Module
        Install-Module
    }
    'Uninstall' {
        Uninstall-Module
    }
}
