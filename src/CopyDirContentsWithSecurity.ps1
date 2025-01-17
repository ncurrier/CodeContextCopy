# No admin privileges required for file reading and clipboard operations
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Add required assemblies
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore,PresentationFramework

<#
.SYNOPSIS
    Collects file contents from a directory (and subdirectories),
    while showing progress in a console window. Includes file size limits,
    binary file detection, and sensitive data masking.

.DESCRIPTION
    This script will:
    1. Prompt the user for a maximum file size (in KB). Defaults to 1000 KB (1 MB).
    2. Ask whether to include dotfiles (hidden files and configuration files).
    3. Open a console window for logging and progress display.
    4. Skip common ignored directories/files (e.g., node_modules, build, .git).
    5. Check each file's first ~512 bytes to detect if it is likely binary.
    6. Skip files exceeding the user-defined size limit.
    7. Mask sensitive data such as passwords, API keys, tokens, and secrets.
    8. Copy the combined text content to the Windows clipboard.

.PARAMETER DirectoryPath
    The directory to process. This is automatically passed from the context menu.

.EXAMPLE
    .\CopyDirContentsWithSecurity.ps1 "C:\MyProject"
#>

# Get the directory path from arguments or current location
$DirectoryPath = if ($args.Count -gt 0) { 
    $args[0] 
} elseif ($MyInvocation.UnboundArguments.Count -gt 0) {
    $MyInvocation.UnboundArguments[0]
} else {
    Write-Host "No directory path provided. Using current directory." -ForegroundColor Yellow
    Get-Location
}

Write-Host "Directory path: $DirectoryPath" -ForegroundColor Cyan

# --------------------------
# 1. Prompt for Max File Size
# --------------------------
$inputMsg = "Enter the maximum file size (in KB) to include (Default: 1000 KB):"
$maxSizeKBString = [Microsoft.VisualBasic.Interaction]::InputBox($inputMsg, "Max File Size", "1000")

if ([string]::IsNullOrWhiteSpace($maxSizeKBString)) {
    $maxSizeKB = 1000
} elseif ($maxSizeKBString -match '^\d+$') {
    [int]$maxSizeKB = [int]$maxSizeKBString
} else {
    Write-Host "Invalid input. Using default value of 1000 KB." -ForegroundColor Yellow
    $maxSizeKB = 1000
}

$maxSizeBytes = $maxSizeKB * 1024

# --------------------------
# 2. Prompt for Dotfile Inclusion
# --------------------------
$includeDotfiles = [Microsoft.VisualBasic.Interaction]::MsgBox(
    "Include dotfiles (hidden files and configuration files)?",
    [Microsoft.VisualBasic.MsgBoxStyle]::YesNo -bor [Microsoft.VisualBasic.MsgBoxStyle]::Question,
    "Include Dotfiles?"
) -eq [Microsoft.VisualBasic.MsgBoxResult]::Yes

Write-Host "Processing started for directory: $DirectoryPath" -ForegroundColor Yellow
Write-Host "Maximum file size: $maxSizeKB KB" -ForegroundColor Green
Write-Host "Including dotfiles: $includeDotfiles" -ForegroundColor Green

# --------------------------
# 3. Ignore Patterns
# --------------------------
$ignorePatterns = @(
    "node_modules", "build", "out", "dist", "coverage", "bin", "obj",
    ".git", ".idea", ".vscode", ".vs", "vendor", "*.env", "*.log",
    "*.tmp", ".DS_Store", ".gitignore", "Thumbs.db", "*.exe", "*.dll",
    "*.pdb", "*.zip", "*.rar", "*.7z", "*.tar", "*.gz", "*.iso",
    "*.bin", "*.dat", "*.db", "*.sqlite", "*.mdf", "*.bak", "*.cache"
)

# Add common dotfile patterns if not including dotfiles
if (-not $includeDotfiles) {
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

# --------------------------
# 4. Sensitive Data Patterns
# --------------------------
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

# Function to close PowerShell window
function Close-PowerShell {
    $host.SetShouldExit(0)
    Stop-Process $pid
}

# Function to estimate tokens (simple approximation)
function Get-TokenEstimate {
    param ([string]$Text)
    
    # Simple estimation based on GPT tokenization patterns
    # This is a rough approximation:
    # - Average 4 characters per token
    # - Newlines count as 1 token
    # - Spaces count as part of the next token
    # - Special characters and numbers might be separate tokens
    
    $charCount = $Text.Length
    $newlineCount = ($Text | Select-String -Pattern "`n" -AllMatches).Matches.Count
    $specialCharCount = ($Text | Select-String -Pattern "[^a-zA-Z0-9\s]" -AllMatches).Matches.Count
    $numberCount = ($Text | Select-String -Pattern "\d+" -AllMatches).Matches.Count
    
    # Base estimation: characters/4 + newlines + special chars + numbers
    $estimatedTokens = [math]::Ceiling($charCount / 4) + $newlineCount + ($specialCharCount * 0.5) + $numberCount
    return [int]$estimatedTokens
}

function Format-FileSize {
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

# Initialize statistics
$stats = @{
    TotalFiles = 0
    ProcessedFiles = 0
    SkippedFiles = 0
    TotalSize = 0
    ProcessedSize = 0
    BinaryFiles = 0
    DotFiles = 0
    OversizedFiles = 0
    EncodingErrors = 0
    StartTime = Get-Date
}

# --------------------------
# 5. Helper Functions
# --------------------------
function ShouldSkip {
    param ([string]$Path)
    
    # Check extension first (faster)
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()
    $binaryExtensions = @('.exe', '.dll', '.pdb', '.zip', '.rar', '.7z', '.tar', '.gz', '.iso', 
                         '.bin', '.dat', '.db', '.sqlite', '.mdf', '.bak', '.png', '.jpg', 
                         '.jpeg', '.gif', '.bmp', '.ico', '.pdf', '.doc', '.docx', '.xls', 
                         '.xlsx', '.ppt', '.pptx')
    
    if ($binaryExtensions -contains $extension) { return $true }
    
    foreach ($pattern in $ignorePatterns) {
        if ($Path -like "*$pattern*") { return $true }
    }
    return $false
}

function IsLikelyBinaryFile {
    param ([string]$Path)
    $maxBytesToCheck = 512
    $buffer = New-Object Byte[] $maxBytesToCheck
    
    try {
        $fs = [System.IO.File]::OpenRead($Path)
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
        Write-Host "Warning: Could not check if binary: $Path" -ForegroundColor Yellow
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

# --------------------------
# 6. Validate Directory
# --------------------------
if (-not (Test-Path $DirectoryPath -PathType Container)) {
    Write-Host "Error: '$DirectoryPath' is not a valid directory." -ForegroundColor Red
    exit 1
}

# Process Files
try {
    $files = Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction Stop
    $stats.TotalFiles = $files.Count
    $currentFile = 0
    
    Write-Host "`nFound $($stats.TotalFiles) files to process..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $currentFile++
        $percentComplete = [math]::Round(($currentFile / $stats.TotalFiles) * 100)
        Write-Progress -Activity "Processing Files" -Status "$currentFile of $($stats.TotalFiles)" -PercentComplete $percentComplete
        
        $stats.TotalSize += $file.Length
        
        # Check if it's a dotfile
        if ($file.Name.StartsWith(".") -or $file.FullName.Contains("\.")) {
            $stats.DotFiles++
            if (-not $includeDotfiles) {
                $stats.SkippedFiles++
                continue
            }
        }

        if (ShouldSkip $file.FullName) {
            $stats.SkippedFiles++
            continue
        }

        if ($file.Length -gt $maxSizeBytes) {
            $stats.OversizedFiles++
            $stats.SkippedFiles++
            continue
        }

        if (IsLikelyBinaryFile $file.FullName) {
            $stats.BinaryFiles++
            $stats.SkippedFiles++
            continue
        }

        try {
            $encoding = [System.Text.UTF8Encoding]::new($false, $true)
            $fileContent = [System.IO.File]::ReadAllText($file.FullName, $encoding)
            $fileContent = MaskSensitiveData $fileContent
            $relativePath = $file.FullName.Substring($DirectoryPath.Length + 1)
            $content += "`n`nFile: $relativePath`n$fileContent"
            $stats.ProcessedFiles++
            $stats.ProcessedSize += $file.Length
        }
        catch [System.Text.DecoderFallbackException] {
            Write-Host "Warning: Encoding issues with file: $($file.FullName)" -ForegroundColor Yellow
            $stats.EncodingErrors++
            $stats.SkippedFiles++
            continue
        }
        catch {
            Write-Host "Warning: Error reading file: $($file.FullName)" -ForegroundColor Yellow
            $stats.SkippedFiles++
            continue
        }
    }
    
    Write-Progress -Activity "Processing Files" -Completed
}
catch {
    Write-Host "Error accessing directory: $($_.Exception.Message)" -ForegroundColor Red
    Close-PowerShell
}

# Calculate final statistics
$stats.EndTime = Get-Date
$processingTime = $stats.EndTime - $stats.StartTime
$estimatedTokens = Get-TokenEstimate $content

# Show completion message with detailed statistics
$message = @"
Operation completed successfully!

Directory: $DirectoryPath
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
Processed Size: $(Format-FileSize $stats.ProcessedSize)
Max File Size: $maxSizeKB KB

Content Statistics:
------------------
Characters: $($content.Length)
Lines: $(($content | Select-String "`n" -AllMatches).Matches.Count + 1)
Estimated Tokens: $estimatedTokens
Estimated Cost: $([math]::Ceiling($estimatedTokens/1000) * 0.0005) USD (based on GPT-4 input pricing)

Settings:
---------
Dotfiles Included: $includeDotfiles
Max File Size: $maxSizeKB KB

Content has been copied to clipboard.
Test by pasting in your desired location.
"@

[Microsoft.VisualBasic.Interaction]::MsgBox(
    $message,
    [Microsoft.VisualBasic.MsgBoxStyle]::Information,
    "Operation Complete"
)
Close-PowerShell

# --------------------------
# 8. Copy to Clipboard and Show Results
# --------------------------
try {
    if ([string]::IsNullOrEmpty($content)) {
        [Microsoft.VisualBasic.Interaction]::MsgBox(
            "No content to copy to clipboard.",
            [Microsoft.VisualBasic.MsgBoxStyle]::Information,
            "Operation Complete"
        )
        Close-PowerShell
    }

    Write-Host "`nAttempting to copy content (length: $($content.Length) characters)..." -ForegroundColor Cyan

    # Try Windows Forms clipboard first
    try {
        Write-Host "Trying Windows Forms clipboard method..." -ForegroundColor Yellow
        [System.Windows.Forms.Clipboard]::SetText($content)
        Write-Host "Contents successfully copied to clipboard (Windows Forms method)." -ForegroundColor Green
    }
    catch {
        Write-Host "Windows Forms clipboard method failed: $($_.Exception.Message)" -ForegroundColor Yellow
        
        # Try WPF clipboard
        try {
            Write-Host "Trying WPF clipboard method..." -ForegroundColor Yellow
            [System.Windows.Clipboard]::SetText($content)
            Write-Host "Contents copied to clipboard (WPF method)." -ForegroundColor Green
        }
        catch {
            Write-Host "WPF clipboard method failed: $($_.Exception.Message)" -ForegroundColor Yellow
            
            # Final fallback to Set-Clipboard
            try {
                Write-Host "Trying PowerShell Set-Clipboard method..." -ForegroundColor Yellow
                Set-Clipboard -Value $content -ErrorAction Stop
                Write-Host "Contents copied to clipboard (PowerShell method)." -ForegroundColor Green
            }
            catch {
                Write-Host "PowerShell clipboard method failed: $($_.Exception.Message)" -ForegroundColor Red
                throw "All clipboard methods failed. Last error: $($_.Exception.Message)"
            }
        }
    }

    # Show completion message with statistics
    $message = @"
Operation completed successfully!

Directory: $DirectoryPath
Files Processed: $currentFile of $totalFiles
Max File Size: $maxSizeKB KB
Dotfiles Included: $includeDotfiles

Content has been copied to clipboard.
Test by pasting in your desired location.
"@

    [Microsoft.VisualBasic.Interaction]::MsgBox(
        $message,
        [Microsoft.VisualBasic.MsgBoxStyle]::Information,
        "Operation Complete"
    )
    Close-PowerShell
}
catch {
    $errorMessage = @"
Error copying to clipboard:
$($_.Exception.Message)

Directory: $DirectoryPath
Files Processed: $currentFile of $totalFiles
"@

    [Microsoft.VisualBasic.Interaction]::MsgBox(
        $errorMessage,
        [Microsoft.VisualBasic.MsgBoxStyle]::Critical,
        "Operation Failed"
    )
    Close-PowerShell
}
