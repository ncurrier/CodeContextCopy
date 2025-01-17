# No admin privileges required for file reading and clipboard operations
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Add required assemblies
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore,PresentationFramework

function Test-IsAdmin {
    <#
    .SYNOPSIS
        Tests if the current PowerShell session is running with administrative privileges.

    .DESCRIPTION
        This function checks if the current PowerShell session is running with administrative privileges
        by verifying if the current user is a member of the built-in Administrators group.

    .OUTPUTS
        System.Boolean
        Returns $true if running with administrative privileges, $false otherwise.
    #>
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

function Get-TokenEstimate {
    <#
    .SYNOPSIS
        Estimates the number of tokens in a text string.

    .DESCRIPTION
        Provides a rough approximation of GPT tokens based on character count,
        newlines, special characters, and numbers.

    .PARAMETER Text
        The text to estimate tokens for.

    .OUTPUTS
        System.Int32
        Estimated number of tokens.
    #>
    param ([string]$Text)
    
    $charCount = $Text.Length
    $newlineCount = ($Text | Select-String -Pattern "`n" -AllMatches).Matches.Count
    $specialCharCount = ($Text | Select-String -Pattern "[^a-zA-Z0-9\s]" -AllMatches).Matches.Count
    $numberCount = ($Text | Select-String -Pattern "\d+" -AllMatches).Matches.Count
    
    # Base estimation: characters/4 + newlines + special chars + numbers
    $estimatedTokens = [math]::Ceiling($charCount / 4) + $newlineCount + ($specialCharCount * 0.5) + $numberCount
    return [int]$estimatedTokens
}

function Format-FileSize {
    <#
    .SYNOPSIS
        Formats a file size in bytes to a human-readable string.

    .PARAMETER Size
        The size in bytes to format.

    .OUTPUTS
        System.String
        The formatted size string (e.g., "1.5 MB").
    #>
    param ([long]$Size)
    
    if ($Size -ge 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    } elseif ($Size -ge 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    } elseif ($Size -ge 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    } else {
        return "$Size Bytes"
    }
}

function Copy-DirectoryContent {
    <#
    .SYNOPSIS
        Collects file contents from a directory (and subdirectories),
        while showing progress in a console window. Includes file size limits,
        binary file detection, and sensitive data masking.

    .DESCRIPTION
        This function will:
        1. Prompt for max file size (default 1000 KB)
        2. Prompt for dotfile inclusion
        3. Skip common ignored directories/files
        4. Skip binary files
        5. Skip oversized files
        6. Mask sensitive data
        7. Copy content to clipboard
        8. Show detailed statistics

    .PARAMETER Path
        The directory to process.

    .PARAMETER MaxSizeKB
        Maximum file size in KB to include. Default is 1000 KB.

    .PARAMETER IncludeDotfiles
        Whether to include dotfiles (hidden files and configuration files).

    .OUTPUTS
        System.String
        The collected content that was copied to clipboard.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [int]$MaxSizeKB = 1000,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeDotfiles = $false
    )

    # If parameters aren't provided, prompt for them
    if (-not $PSBoundParameters.ContainsKey('MaxSizeKB')) {
        $result = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Enter maximum file size in KB (default: 1000):", 
            "Max File Size",
            "1000"
        )
        if ([string]::IsNullOrEmpty($result)) { return }
        $MaxSizeKB = [int]$result
    }

    if (-not $PSBoundParameters.ContainsKey('IncludeDotfiles')) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Include dotfiles and hidden files?",
            "Include Dotfiles",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        $IncludeDotfiles = $result -eq [System.Windows.Forms.DialogResult]::Yes
    }

    Write-Verbose "Directory path: $Path"
    Write-Verbose "Processing started for directory:`n$Path"
    Write-Verbose "Maximum file size: $MaxSizeKB KB"
    Write-Verbose "Including dotfiles: $IncludeDotfiles"

    # If running in ISE or other host, open console window
    if (-not $Host.Name -like "*ConsoleHost*") {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { . '$($MyInvocation.MyCommand.Definition)' '$Path'; Pause }`"" -NoNewWindow
        return
    }

    # Initialize statistics
    $stats = @{
        TotalFiles = 0
        ProcessedFiles = 0
        SkippedFiles = 0
        OversizedFiles = 0
        BinaryFiles = 0
        DotFiles = 0
        TotalSize = 0
        TokenEstimate = 0
        StartTime = Get-Date
        EncodingErrors = 0
    }

    # Ignore patterns
    $ignorePatterns = @(
        "node_modules", "build", "out", "dist", "coverage", "bin", "obj",
        ".git", ".idea", ".vscode", ".vs", "vendor", "*.env", "*.log",
        "*.tmp", ".DS_Store", ".gitignore", "Thumbs.db", "*.exe", "*.dll",
        "*.pdb", "*.zip", "*.rar", "*.7z", "*.tar", "*.gz", "*.iso",
        "*.bin", "*.dat", "*.db", "*.sqlite", "*.mdf", "*.bak", "*.cache"
    )

    # Add dotfile patterns if not including dotfiles
    if (-not $IncludeDotfiles) {
        $ignorePatterns += @(
            ".*",              # Any file/directory starting with a dot
            ".config",         # Configuration directories
            ".settings",       # Settings directories
            ".env*",          # Environment files
            ".editorconfig",  # Editor configuration
            ".prettierrc*",   # Prettier configuration
            ".eslintrc*",     # ESLint configuration
            ".babelrc*",      # Babel configuration
            ".npmrc",         # NPM configuration
            ".yarnrc",        # Yarn configuration
            ".dockerignore",  # Docker ignore file
            ".gitlab-ci*",    # GitLab CI configuration
            ".travis*",       # Travis CI configuration
            ".circleci*",     # Circle CI configuration
            ".github"         # GitHub configuration directory
        )
    }

    # Sensitive data patterns
    $sensitivePatterns = @(
        '(?i)(password\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(api[-_]?key\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(secret\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(token\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(private[-_]?key\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(aws_access_key_id\s*=\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(aws_secret_access_key\s*=\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(database_url\s*=\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(client_secret\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(access_token\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(connectionstring\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)',
        '(?i)(jwt\s*[:=]\s*[''"]?[^''"}\s]+[''"]?)'
    )

    # Helper functions
    function ShouldSkip {
        param ([string]$FilePath)
        
        # Check extension first (faster)
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        $binaryExtensions = @('.exe', '.dll', '.pdb', '.zip', '.rar', '.7z', '.tar', '.gz', '.iso', 
                             '.bin', '.dat', '.db', '.sqlite', '.mdf', '.bak', '.png', '.jpg', 
                             '.jpeg', '.gif', '.bmp', '.ico', '.pdf', '.doc', '.docx', '.xls', 
                             '.xlsx', '.ppt', '.pptx')
        
        if ($binaryExtensions -contains $extension) { return $true }
        
        foreach ($pattern in $ignorePatterns) {
            if ($FilePath -like "*$pattern*") { return $true }
        }
        return $false
    }

    function IsLikelyBinaryFile {
        param ([string]$FilePath)
        $maxBytesToCheck = 512
        $buffer = New-Object Byte[] $maxBytesToCheck
        
        try {
            $fs = [System.IO.File]::OpenRead($FilePath)
            try {
                $bytesRead = $fs.Read($buffer, 0, $buffer.Length)
                $countNonText = 0
                for ($i = 0; $i -lt $bytesRead; $i++) {
                    if ($buffer[$i] -lt 32 -and $buffer[$i] -notin 9,10,13) { $countNonText++ }
                }
                return ($countNonText / $bytesRead -gt 0.1)
            }
            finally {
                $fs.Close()
                $fs.Dispose()
            }
        }
        catch {
            Write-Information "Warning: Could not check if binary: $FilePath" -InformationAction Continue
            return $true
        }
    }

    function MaskSensitiveData {
        param ([string]$Content)
        foreach ($pattern in $sensitivePatterns) {
            $Content = [System.Text.RegularExpressions.Regex]::Replace(
                $Content, 
                $pattern, 
                '<REDACTED>', 
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        }
        return $Content
    }

    # Validate directory
    if (-not (Test-Path $Path -PathType Container)) {
        Write-Error "'$Path' is not a valid directory."
        return
    }

    # Process files
    $content = ""
    try {
        $files = @(Get-ChildItem -Path $Path -Recurse -File -ErrorAction Stop)
        $stats.TotalFiles = $files.Count
        Write-Verbose "Found $($stats.TotalFiles) files to process..."
        if ($stats.TotalFiles -eq 0) {
            Write-Information "No files found in directory." -InformationAction Continue
            return
        }
        foreach ($file in $files) {
            $stats.ProcessedFiles++
            $percentComplete = [math]::Round(($stats.ProcessedFiles / $stats.TotalFiles) * 100)
            Write-Progress -Activity "Processing Files" -Status "Checking file $($stats.ProcessedFiles + 1) of $($stats.TotalFiles)" -PercentComplete $percentComplete
            $stats.TotalSize += $file.Length
            # Skip dotfiles if not included
            if (-not $IncludeDotfiles -and $file.Name.StartsWith('.')) {
                $stats.DotFiles++
                $stats.SkippedFiles++
                continue
            }
            # Skip binary files
            if (IsLikelyBinaryFile $file.FullName) {
                $stats.BinaryFiles++
                $stats.SkippedFiles++
                continue
            }
            if ($file.Length -gt ($MaxSizeKB * 1KB)) {
                Write-Information "Skipping large file: $($file.Name) ($([math]::Round($file.Length / 1KB, 2)) KB)" -InformationAction Continue
                $stats.SkippedFiles++
                continue
            }
            try {
                $fileContent = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                if ($null -eq $fileContent) { $fileContent = "" }
                $fileContent = MaskSensitiveData $fileContent
                $relativePath = $file.FullName.Substring($Path.Length + 1)
                $content += "`n`nFile: $relativePath`n$fileContent"
            }
            catch {
                Write-Information "Error reading file: $($file.FullName)" -InformationAction Continue
                $stats.EncodingErrors++
                $stats.SkippedFiles++
                continue
            }
        }
        Write-Progress -Activity "Processing Files" -Completed
    }
    catch {
        Write-Error "Error accessing directory: $($_.Exception.Message)"
        return
    }

    # Copy to clipboard
    try {
        if ([string]::IsNullOrEmpty($content)) {
            Write-Information "No content to copy to clipboard." -InformationAction Continue
            return
        }

        # Try Windows Forms clipboard first
        try {
            [System.Windows.Forms.Clipboard]::SetText($content)
        }
        catch {
            Write-Information "Primary clipboard method failed, trying alternative..." -InformationAction Continue
            
            # Try WPF clipboard
            try {
                [System.Windows.Clipboard]::SetText($content)
            }
            catch {
                # Final fallback to Set-Clipboard
                Set-Clipboard -Value $content -ErrorAction Stop
            }
        }
    }
    catch {
        Write-Error "Error copying to clipboard: $($_.Exception.Message)"
        return
    }

    # Calculate final statistics
    $stats.EndTime = Get-Date
    $processingTime = $stats.EndTime - $stats.StartTime
    $estimatedTokens = Get-TokenEstimate $content

    # Show completion message with detailed statistics
    $message = @"
Operation completed successfully!

Directory: $Path
Processing Time: $($processingTime.TotalSeconds.ToString("N2")) seconds

File Statistics:
---------------
Total Files Found: $($stats.TotalFiles)
Files Processed: $($stats.ProcessedFiles)
Files Skipped: $($stats.SkippedFiles)
Binary Files: $($stats.BinaryFiles)
Dotfiles: $($stats.DotFiles)
Oversized Files: $($stats.OversizedFiles)
Encoding Errors: $($stats.EncodingErrors)

Size Statistics:
---------------
Total Size: $(Format-FileSize $stats.TotalSize)

Content Statistics:
------------------
Lines: $(($content | Select-String "`n" -AllMatches).Matches.Count + 1)
Estimated Tokens: $estimatedTokens

Content has been copied to clipboard.
Test by pasting in your desired location.
"@

    [Microsoft.VisualBasic.Interaction]::MsgBox(
        $message,
        [Microsoft.VisualBasic.MsgBoxStyle]::Information,
        "Operation Complete"
    )

    return $content
}

# Only export when being imported as a module
if ($MyInvocation.Line -match 'Import-Module') {
    Export-ModuleMember -Function Copy-DirectoryContent, Test-IsAdmin
}
