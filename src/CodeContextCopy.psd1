@{
    ModuleVersion = '1.3.0'
    GUID = '12345678-1234-5678-1234-567812345678'
    Author = 'Nathaniel Currier'
    CompanyName = 'nat.io'
    Copyright = '(c) 2025 Nathaniel Currier. All rights reserved.'
    Description = 'A Windows Explorer context menu utility for copying directory contents to clipboard with LLM token estimation and context optimization.'
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
            ReleaseNotes = 'Improved file content handling, enhanced sensitive data masking, better binary file detection, and fixed dotfile handling'
        }
    }
}
