@{
    ModuleVersion = '1.4.0'
    GUID = '12345678-1234-5678-1234-567812345678'
    Author = 'Nathaniel Currier'
    CompanyName = 'nat.io'
    Copyright = '(c) 2025 Nathaniel Currier. All rights reserved.'
    Description = 'PowerShell module for securely copying directory contents to clipboard with LLM token estimation.'
    PowerShellVersion = '5.1'
    RootModule = 'Copy-DirectoryContent.ps1'
    FunctionsToExport = @('Copy-DirectoryContent', 'Test-IsAdmin')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'Explorer', 'Context-Menu', 'Clipboard', 'LLM', 'AI')
            LicenseUri = 'https://github.com/ncurrier/CodeContextCopy/blob/main/LICENSE'
            ProjectUri = 'https://github.com/ncurrier/CodeContextCopy'
            ReleaseNotes = @'
## [1.4.0] - 2025-01-18
- Added clear file delimiters in output for better readability
- Added both full and relative paths for each file in output
- Added proper UTF-8 encoding handling for special characters
- Improved file content formatting and clipboard output
- Enhanced error handling and progress display
- Fixed all PSScriptAnalyzer issues and code style
- Fixed character encoding issues with special characters
'@
        }
    }
}
