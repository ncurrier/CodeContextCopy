BeforeAll {
    # Get paths
    $script:scriptPath = Split-Path -Parent $PSScriptRoot
    $script:outputPath = Join-Path $scriptPath "output"
    $script:modulePath = Join-Path $outputPath "Copy-DirectoryContent.ps1"

    # Import module
    Import-Module $modulePath -Force
    
    # Mock elevation check to always return true
    Mock -CommandName 'Test-IsAdmin' -MockWith { return $true }
}

Describe "Installation and Removal Scripts" {
    BeforeAll {
        # Setup test registry path
        $script:testRegKeyPath = "HKCU:\Software\Classes\Directory\shell\Copy Directory Contents"
        $script:testRegKeyCommandPath = "$testRegKeyPath\command"
    }

    BeforeEach {
        # Clean up any existing test keys
        if (Test-Path $testRegKeyPath) {
            Remove-Item -Path $testRegKeyPath -Recurse -Force
        }
    }

    Context "Install.ps1" {
        It "Should create registry keys with correct values" {
            # Run the installation script
            & "$scriptPath\scripts\Install.ps1"

            # Verify registry keys exist
            Test-Path $testRegKeyPath | Should -Be $true
            Test-Path $testRegKeyCommandPath | Should -Be $true

            # Verify registry values
            $defaultValue = (Get-ItemProperty -Path $testRegKeyPath).'(default)'
            $defaultValue | Should -Be "Copy Directory Contents to Clipboard"

            # Verify icon path
            $iconValue = (Get-ItemProperty -Path $testRegKeyPath).Icon
            $iconValue | Should -Be (Join-Path $scriptPath "assets\folder_icon_with_arrow.ico")

            $commandValue = (Get-ItemProperty -Path $testRegKeyCommandPath).'(default)'
            $commandValue | Should -Match ([regex]::Escape($modulePath))
            $commandValue | Should -Match "Copy-DirectoryContent"
        }

        It "Should throw if module file doesn't exist" {
            # Temporarily rename the module file
            if (Test-Path $modulePath) {
                Rename-Item -Path $modulePath -NewName "temp.ps1"
            }

            # Installation should throw
            { & "$scriptPath\scripts\Install.ps1" } | Should -Throw

            # Restore the module file
            if (Test-Path (Join-Path $outputPath "temp.ps1")) {
                Rename-Item -Path (Join-Path $outputPath "temp.ps1") -NewName "Copy-DirectoryContent.ps1"
            }
        }
    }

    Context "Remove.ps1" {
        It "Should remove registry keys" {
            # First install
            & "$scriptPath\scripts\Install.ps1"
            Test-Path $testRegKeyPath | Should -Be $true

            # Then remove
            & "$scriptPath\scripts\Remove.ps1"
            Test-Path $testRegKeyPath | Should -Be $false
        }

        It "Should not throw if registry keys don't exist" {
            # Make sure keys don't exist
            if (Test-Path $testRegKeyPath) {
                Remove-Item -Path $testRegKeyPath -Recurse -Force
            }

            # Should not throw when trying to remove non-existent keys
            { & "$scriptPath\scripts\Remove.ps1" } | Should -Not -Throw
        }
    }

    AfterAll {
        # Final cleanup
        if (Test-Path $testRegKeyPath) {
            Remove-Item -Path $testRegKeyPath -Recurse -Force
        }
    }
}
