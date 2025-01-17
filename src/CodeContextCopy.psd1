@{
    ModuleVersion = '1.1.0'
    GUID = 'f8b0e1b5-7c1d-4c4f-9e1a-9b9b8b1b1b1b'
    Author = 'Nathaniel Currier'
    CompanyName = 'nat.io'
    Copyright = '(c) 2025 nat.io. All rights reserved.'
    Description = 'Windows Explorer context menu utility for copying directory contents to clipboard with LLM token estimation and context optimization'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Copy-DirectoryContents')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @(
                'Windows',
                'Explorer',
                'Clipboard',
                'Security',
                'LLM',
                'GPT',
                'AI',
                'Context-Window',
                'Token-Estimation',
                'Code-Context'
            )
            LicenseUri = 'https://github.com/ncurrier/CodeContextCopy/blob/main/LICENSE'
            ProjectUri = 'https://github.com/ncurrier/CodeContextCopy'
        }
    }
}
