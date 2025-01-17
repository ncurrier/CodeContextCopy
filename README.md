<#
.SYNOPSIS
    Collects file contents from a directory (and subdirectories),
    prompting for a max file size (in KB), skipping common build directories,
    skipping likely binary files, and masking sensitive data.
    The results are copied to the clipboard.

.DESCRIPTION
    This script will:
    1. Prompt the user for a maximum file size (in KB) to include. Defaults to 1000 KB (1 MB).
    2. Skip common ignored directories/files (e.g., node_modules, build, .git).
    3. Check each file's first ~512 bytes to detect if it is likely binary (skip if so).
    4. Skip any file exceeding the user-defined size limit.
    5. Read and concatenate text content.
    6. Mask sensitive data such as passwords, API keys, tokens, secrets.
    7. Copy the combined content to the Windows clipboard.

.PARAMETER DirectoryPath
    The path to the directory from which to collect file contents.

.EXAMPLE
    .\CopyDirContentsWithSecurity.ps1 "C:\MyProject"
#>

param (
    [string]$DirectoryPath
)

# ---------------------------------------
# 1. PROMPT FOR FILE SIZE LIMIT (KB)
# ---------------------------------------
Add-Type -AssemblyName Microsoft.VisualBasic

$inputMsg = "Enter the maximum file size (in KB) to include. (Default = 1000 KB)"
$maxSizeKBString = [Microsoft.VisualBasic.Interaction]::InputBox($inputMsg, "Max File Size", "1000")

if ([string]::IsNullOrWhiteSpace($maxSizeKBString)) {
    # If user cancels or leaves blank, default to 1000
    $maxSizeKB = 1000
}
else {
    # Try to parse user input; fallback to 1000 if invalid
    if ([int]::TryParse($maxSizeKBString, [ref] $null)) {
        $maxSizeKB = [int]$maxSizeKBString
    } else {
        $maxSizeKB = 1000
    }
}

$maxSizeBytes = $maxSizeKB * 1024

# ---------------------------------------
# 2. IGNORE PATTERNS (Directories/Files)
# ---------------------------------------
# Directories or file name patterns to skip if they appear in the path.
$ignorePatterns = @(
    "node_modules",
    "build",
    "out",
    "dist",
    "coverage",
    "bin",
    "obj",
    ".git",
    ".idea",
    ".vscode",
    ".vs",
    "vendor",
    "*.env",
    "*.log",
    "*.tmp",
    ".DS_Store",
    ".gitignore",
    "Thumbs.db"
)

# ---------------------------------------
# 3. SENSITIVE DATA PATTERNS
# ---------------------------------------
# Regex to detect typical secrets or credentials (case-insensitive).
$sensitivePatterns = @(
    '(?i)(password\s*[:=]\s*\S+)',           
    '(?i)(api[-_]?key\s*[:=]\s*\S+)',        
    '(?i)(secret\s*[:=]\s*\S+)',             
    '(?i)(token\s*[:=]\s*\S+)',　　 　 　 　
    '(?i)(private[-_]?key\s*[:=]\s*\S+)',    
    '(?i)(aws_access_key_id\s*=\s*\S+)',     
    '(?i)(aws_secret_access_key\s*=\s*\S+)', 
    '(?i)(database_url\s*=\s*\S+)',          
    '(?i)(client_secret\s*[:=]\s*\S+)',      
    '(?i)(access_token\s*[:=]\s*\S+)'
)

# ---------------------------------------
# 4. HELPER FUNCTIONS
# ---------------------------------------

function ShouldSkip {
    param (
        [string]$Path
    )
    foreach ($pattern in $ignorePatterns) {
        if ($Path -like "*$pattern*") {
            return $true
        }
    }
    return $false
}

function IsLikelyBinaryFile {
    param([string]$Path)

    # If the file is missing or zero-length, skip the check
    if (-not (Test-Path $Path) -or (Get-Item $Path).Length -eq 0) {
        return $false
    }

    # Read up to the first 512 bytes
    $maxBytesToCheck = 512
    $buffer = New-Object Byte[] $maxBytesToCheck

    try {
        $fs = [System.IO.File]::OpenRead($Path)
        $bytesRead = $fs.Read($buffer, 0, $buffer.Length)
        $fs.Close()

        # Count how many bytes are below ASCII 32 (control),
        # excluding tab (9), newline (10), carriage return (13).
        $countNonText = 0
        for ($i = 0; $i -lt $bytesRead; $i++) {
            $b = $buffer[$i]
            if ($b -lt 32 -and $b -notin 9,10,13) {
                $countNonText++
            }
        }
        # If more than 10% of the examined bytes are non-text, consider it binary
        return (($countNonText / $bytesRead) -gt 0.1)
    }
    catch {
        # If there's an error reading, assume it's binary
        return $true
    }
}

function MaskSensitiveData {
    param ([string]$Content)

    foreach ($pattern in $sensitivePatterns) {
        try {
            $Content = [System.Text.RegularExpressions.Regex]::Replace(
                $Content,
                $pattern,
                '<REDACTED>',
                'IgnoreCase'
            )
        }
        catch {
            Write-Host "Regex error: $pattern - $($_.Exception.Message)"
        }
    }
    return $Content
}

# ---------------------------------------
# 5. VALIDATE DIRECTORY
# ---------------------------------------
if (-not (Test-Path $DirectoryPath)) {
    Write-Host "The specified path does not exist: $DirectoryPath"
    exit 1
}

# ---------------------------------------
# 6. GATHER CONTENT
# ---------------------------------------
$content = ""

try {
    # Gather files recursively
    $files = Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction Stop
}
catch {
    Write-Host "Error reading directory: $DirectoryPath"
    Write-Host $_.Exception.Message
    exit 1
}

foreach ($file in $files) {
    # Skip if the path matches ignore patterns
    if (ShouldSkip $file.FullName) {
        continue
    }

    # Skip if file size exceeds user-defined limit
    if ($file.Length -gt $maxSizeBytes) {
        continue
    }

    # Skip if file appears to be binary
    if (IsLikelyBinaryFile $file.FullName) {
        continue
    }

    # Attempt to read text content
    try {
        $fileContent = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

        # Mask sensitive data
        $fileContent = MaskSensitiveData $fileContent

        # Append file path and contents
        $content += "`r`n`r`nFile: $($file.FullName)`r`n"
        $content += $fileContent
    }
    catch {
        Write-Host "Skipping file due to read error: $($file.FullName)"
        Write-Host $_.Exception.Message
    }
}

# ---------------------------------------
# 7. COPY TO CLIPBOARD
# ---------------------------------------
try {
    Set-Clipboard -Value $content
    Write-Host "All eligible text contents have been copied to the clipboard."
}
catch {
    Write-Host "Failed to copy to clipboard."
    Write-Host $_.Exception.Message
}

# Code Context Copy

A Windows Explorer context menu utility that securely copies directory contents to the clipboard, with built-in security features and progress tracking.

## Features

- Copy directory contents to clipboard via context menu
- Built-in sensitive data masking (passwords, API keys, tokens)
- Real-time progress tracking with visual feedback
- Smart binary file detection and filtering
- Configurable file size limits
- UTF-8 encoding support
- Efficient file processing
- Administrative privileges protection

## Installation

1. Clone this repository or download the files
2. Right-click `Install.ps1` and select "Run with PowerShell"
   - Note: Administrative privileges are required
   - If you get a security warning, you may need to run:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

## Usage

1. Right-click on any directory in Windows Explorer
2. Select "Copy Directory Contents to Clipboard"
3. Enter maximum file size when prompted (default: 1000 KB)
4. Wait for processing to complete
5. Contents are now in your clipboard!

## Security Features

- Automatic detection and masking of sensitive data:
  - Passwords
  - API keys
  - Tokens
  - Connection strings
  - Private keys
  - AWS credentials
- Binary file detection and exclusion
- Size limit enforcement
- Secure clipboard handling

## Excluded Content

The following are automatically excluded:
- Binary files
- System directories (.git, node_modules, etc.)
- Files exceeding size limit
- Common ignored files (.env, .log, etc.)
- Files with encoding issues

## Uninstallation

1. Right-click `Remove.ps1` and select "Run with PowerShell"
   - Note: Administrative privileges are required

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later
- Administrative privileges (for installation/uninstallation)

## Development

- Main branch: Production-ready code
- Develop branch: Integration branch
- Feature branches: feature/
- Bug fix branches: bugfix/
- Hotfix branches: hotfix/

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history.
