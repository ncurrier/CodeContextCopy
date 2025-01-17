BeforeAll {
    Import-Module "$PSScriptRoot\..\src\CodeContextCopy.psd1" -Force
}

Describe "Copy-DirectoryContent" {
    BeforeEach {
        # Create test directory structure
        $testDir = Join-Path $TestDrive "testdir"
        if (Test-Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $testDir | Out-Null

        # Create test files
        $normalFile = Join-Path $testDir "test.txt"
        $dotFile = Join-Path $testDir ".config"
        $largeFile = Join-Path $testDir "large.txt"
        $sensitiveFile = Join-Path $testDir "secrets.txt"
        $binaryFile = Join-Path $testDir "test.exe"

        # Normal text file
        Set-Content -Path $normalFile -Value "This is normal content`nWith multiple lines"

        # Dotfile
        Set-Content -Path $dotFile -Value "config content`nsecret=123"

        # Large file (2KB)
        $largeContent = "A" * 2048
        Set-Content -Path $largeFile -Value $largeContent

        # File with sensitive data
        $sensitiveContent = @"
api_key=1234567890
password=secretpass
aws_access_key_id=AKIA123456789
database_url=mysql://user:pass@localhost/db
"@
        Set-Content -Path $sensitiveFile -Value $sensitiveContent

        # Binary file
        $binaryContent = [byte[]]@(0x4D, 0x5A, 0x90, 0x00) + ([byte[]]@(0) * 100)
        [System.IO.File]::WriteAllBytes($binaryFile, $binaryContent)
    }

    It "Should copy normal file contents" {
        $result = Copy-DirectoryContent -Path $testDir
        $result | Should -Match "This is normal content"
        $result | Should -Match "With multiple lines"
    }

    It "Should respect dotfile filtering" {
        $result = Copy-DirectoryContent -Path $testDir -ExcludeDotFiles
        $result | Should -Not -Match "config content"
        $result | Should -Not -Match "secret=123"
    }

    It "Should include dotfiles when not excluded" {
        $result = Copy-DirectoryContent -Path $testDir
        $result | Should -Match "config content"
    }

    It "Should respect max file size" {
        $result = Copy-DirectoryContent -Path $testDir -MaxSizeKB 1
        $result | Should -Not -Match "^A{2048}$"
    }

    It "Should mask sensitive data" {
        $result = Copy-DirectoryContent -Path $testDir
        $result | Should -Match "<REDACTED>"
        $result | Should -Not -Match "api_key=1234567890"
        $result | Should -Not -Match "password=secretpass"
        $result | Should -Not -Match "AKIA123456789"
        $result | Should -Not -Match "mysql://user:pass@localhost/db"
    }

    It "Should skip binary files" {
        $result = Copy-DirectoryContent -Path $testDir
        $result | Should -Not -Match ([regex]::Escape([System.Text.Encoding]::UTF8.GetString([byte[]]@(0x4D, 0x5A, 0x90, 0x00))))
    }

    It "Should include relative paths in output" {
        $result = Copy-DirectoryContent -Path $testDir
        $result | Should -Match "File: test.txt"
    }

    It "Should handle non-existent directories" {
        $nonExistentPath = Join-Path $TestDrive "nonexistent"
        { Copy-DirectoryContent -Path $nonExistentPath } | Should -Throw
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }
}
