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
        Provides a rough approximation of GPT tokens based on character count.

    .PARAMETER Text
        The text to estimate tokens for.

    .OUTPUTS
        System.Int32
        Estimated number of tokens.
    #>
    param ([string]$Text)
    try {
        # Simple estimation: 1 token per 4 characters
        return [math]::Ceiling($Text.Length / 4)
    }
    catch {
        Write-Warning "Error estimating tokens: $($_.Exception.Message)"
        return 0
    }
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

function Test-IsBinaryFile {
    <#
    .SYNOPSIS
        Tests if a file is binary by checking its extension and content.

    .PARAMETER FilePath
        The path to the file to test.

    .OUTPUTS
        System.Boolean
        Returns $true if the file is binary, $false otherwise.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    # Check extension first (faster)
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $binaryExtensions = @(
        '.exe', '.dll', '.pdb', '.zip', '.rar', '.7z', '.tar', '.gz', '.iso',
        '.bin', '.dat', '.db', '.sqlite', '.mdf', '.bak', '.png', '.jpg',
        '.jpeg', '.gif', '.bmp', '.ico', '.pdf', '.doc', '.docx', '.xls',
        '.xlsx', '.ppt', '.pptx'
    )
    if ($binaryExtensions -contains $extension) { return $true }

    # Check file content
    $maxBytesToCheck = 512
    $buffer = New-Object Byte[] $maxBytesToCheck
    try {
        $fs = [System.IO.File]::OpenRead($FilePath)
        try {
            $bytesRead = $fs.Read($buffer, 0, $buffer.Length)
            $countNonText = 0
            for ($i = 0; $i -lt $bytesRead; $i++) {
                if ($buffer[$i] -lt 32 -and $buffer[$i] -notin 9,10,13) {
                    $countNonText++
                }
            }
            return ($countNonText / $bytesRead -gt 0.1)
        }
        finally {
            $fs.Close()
            $fs.Dispose()
        }
    }
    catch {
        Write-Warning "Could not check if binary: $FilePath"
        return $true
    }
}

function MaskSensitiveData {
    <#
    .SYNOPSIS
        Masks sensitive data in text content.

    .PARAMETER Text
        The text content to mask sensitive data in.

    .OUTPUTS
        System.String
        The text content with sensitive data masked.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $patterns = @(
        # API Keys and Tokens
        '(?i)(api[_-]?key|token|secret)["\s]*[:=]\s*["]*([^"\s]+)["]*',
        # Passwords
        '(?i)(password|passwd|pwd)["\s]*[:=]\s*["]*([^"\s]+)["]*',
        # AWS Keys
        '(?i)(aws[_-]?access[_-]?key[_-]?id|aws[_-]?secret[_-]?access[_-]?key)["\s]*[:=]\s*["]*([^"\s]+)["]*',
        # Database URLs
        '(?i)(jdbc:|\w+://)([^:]+):([^@]+)@',
        # Email addresses
        '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    )

    $maskedText = $Text
    foreach ($pattern in $patterns) {
        $maskedText = $maskedText -replace $pattern, '$1=<REDACTED>'
    }

    return $maskedText
}

function Copy-DirectoryContent {
    <#
    .SYNOPSIS
        Copies the contents of a directory to the clipboard with advanced filtering.

    .DESCRIPTION
        This function copies the contents of a directory to the clipboard, while providing
        options for filtering files based on size and type. It can exclude binary files,
        large files, and provides options for handling dotfiles. The function also masks
        sensitive data and estimates token usage.

    .PARAMETER Path
        The path to the directory to copy.

    .PARAMETER MaxSizeKB
        The maximum file size in KB to include in the copy. Default is 1000 KB.

    .PARAMETER IncludeDotfiles
        Whether to include dotfiles in the copy. Default is true.

    .EXAMPLE
        Copy-DirectoryContent -Path "C:\MyProject" -MaxSizeKB 500 -IncludeDotfiles $false
        Copies files from C:\MyProject, excluding files larger than 500KB and dotfiles.

    .NOTES
        Author: Nathaniel Currier
        Copyright: (c) 2025 Nathaniel Currier
        License: MIT
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [int]$MaxSizeKB = 1000,
        [Parameter(Mandatory=$false)]
        [bool]$IncludeDotfiles = $true
    )

    # Initialize statistics
    $stats = @{
        StartTime = Get-Date
        EndTime = $null
        TotalFiles = 0
        ProcessedFiles = 0
        SkippedFiles = 0
        OversizedFiles = 0
        BinaryFiles = 0
        DotFiles = 0
        EncodingErrors = 0
        TotalSize = 0
    }

    # Process files
    $content = ""
    try {
        $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction Stop | Sort-Object FullName
        $stats.TotalFiles = $files.Count
        if ($stats.TotalFiles -eq 0) {
            Write-Warning "No files found in directory."
            return
        }

        foreach ($file in $files) {
            Write-Progress -Activity "Processing Files" -Status $file.Name -PercentComplete (($stats.ProcessedFiles / $stats.TotalFiles) * 100)
            $stats.ProcessedFiles++

            # Check if it's a dotfile
            if ($file.Name.StartsWith('.')) {
                $stats.DotFiles++
                if (-not $IncludeDotfiles) {
                    $stats.SkippedFiles++
                    continue
                }
            }

            # Check file size
            $stats.TotalSize += $file.Length
            if ($file.Length -gt ($MaxSizeKB * 1KB)) {
                $stats.OversizedFiles++
                $stats.SkippedFiles++
                continue
            }

            # Check if binary
            if (Test-IsBinaryFile -FilePath $file.FullName) {
                $stats.BinaryFiles++
                $stats.SkippedFiles++
                continue
            }

            try {
                # Read file with UTF-8 encoding
                $fileContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                if ($null -eq $fileContent) {
                    $fileContent = ""
                }
                else {
                    # Convert any non-UTF8 characters to their proper UTF-8 representation
                    $bytes = [System.Text.Encoding]::Default.GetBytes($fileContent)
                    $fileContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                }
                # Only mask content if it's not already marked as redacted
                if (-not $fileContent.Contains("<REDACTED>")) {
                    $fileContent = MaskSensitiveData $fileContent
                }
                $relativePath = $file.FullName.Substring($Path.Length + 1)
                $delimiter = "=" * 80
                $content += "`n$delimiter`nFile: $($file.FullName)`nRelative Path: $relativePath`n$delimiter`n$fileContent`n"
            }
            catch {
                Write-Warning "Error reading file: $($file.FullName) - $($_.Exception.Message)"
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

    # Copy to clipboard if we have content
    if (-not [string]::IsNullOrWhiteSpace($content)) {
        try {
            # Try Windows Forms clipboard first
            try {
                [System.Windows.Forms.Clipboard]::SetText($content)
            }
            catch {
                Write-Warning "Primary clipboard method failed, trying alternative..."
                # Try WPF clipboard
                try {
                    [System.Windows.Clipboard]::SetText($content)
                }
                catch {
                    # Final fallback to Set-Clipboard
                    Set-Clipboard -Value $content -ErrorAction Stop
                }
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

            # Display message box and exit
            $null = [Microsoft.VisualBasic.Interaction]::MsgBox(
                $message,
                [Microsoft.VisualBasic.MsgBoxStyle]::Information,
                "Operation Complete"
            )
            
            # Exit if running in a separate window
            if ($Host.Name -eq 'ConsoleHost' -and $Host.UI.RawUI.WindowTitle -match 'PowerShell') {
                [System.Environment]::Exit(0)
            }
        }
        catch {
            Write-Error "Error copying to clipboard: $($_.Exception.Message)"
            return
        }
    }
    else {
        Write-Warning "No content to copy to clipboard."
    }
}

# Only export when being imported as a module
if ($MyInvocation.Line -match 'Import-Module') {
    Export-ModuleMember -Function Copy-DirectoryContent, Test-IsAdmin
}
