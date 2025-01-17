BeforeAll {
    Import-Module "$PSScriptRoot\..\src\CodeContextCopy.psd1" -Force
}

Describe "Copy-DirectoryContents" {
    BeforeEach {
        # Create test directory structure
        $testDir = "TestDrive:\testdir"
        New-Item -ItemType Directory -Path $testDir
        Set-Content -Path "$testDir\test.txt" -Value "test content"
        Set-Content -Path "$testDir\.config" -Value "config content"
    }

    It "Should copy directory contents to clipboard" {
        $result = Copy-DirectoryContents -Path $testDir
        $result | Should -Not -BeNullOrEmpty
    }

    It "Should respect dotfile filtering" {
        $result = Copy-DirectoryContents -Path $testDir -ExcludeDotFiles
        $result | Should -Not -Match "\.config"
    }

    It "Should respect max file size" {
        $result = Copy-DirectoryContents -Path $testDir -MaxSizeKB 1
        $result | Should -Not -Match "test\.txt"
    }
}
