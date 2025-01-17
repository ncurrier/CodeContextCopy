# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" `"$DirectoryPath`""
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    exit
}

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
    2. Open a console window for logging and progress display.
    3. Skip common ignored directories/files (e.g., node_modules, build, .git).
    4. Check each file's first ~512 bytes to detect if it is likely binary.
    5. Skip files exceeding the user-defined size limit.
    6. Mask sensitive data such as passwords, API keys, tokens, and secrets.
    7. Copy the combined text content to the Windows clipboard.

.PARAMETER DirectoryPath
    The directory to process. This is automatically passed from the context menu.

.EXAMPLE
    .\CopyDirContentsWithSecurity.ps1 "C:\MyProject"

.NOTES
    Requires administrative privileges for reliable clipboard access.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$DirectoryPath
)

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
# 2. Open Console for Output
# --------------------------
if (-not $Host.Name -like "*ConsoleHost*") {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { . '$($MyInvocation.MyCommand.Definition)' '$DirectoryPath'; Pause }`"" -NoNewWindow
    exit
}

Write-Host "Processing started for directory: $DirectoryPath" -ForegroundColor Yellow
Write-Host "Maximum file size: $maxSizeKB KB" -ForegroundColor Green

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

# --------------------------
# 7. Process Files
# --------------------------
$content = ""
try {
    $files = Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction Stop
    $totalFiles = $files.Count
    $currentFile = 0
    
    Write-Host "`nFound $totalFiles files to process..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $currentFile++
        $percentComplete = [math]::Round(($currentFile / $totalFiles) * 100)
        Write-Progress -Activity "Processing Files" -Status "$currentFile of $totalFiles" -PercentComplete $percentComplete
        
        if (ShouldSkip $file.FullName) {
            continue
        }

        if ($file.Length -gt $maxSizeBytes) {
            continue
        }

        if (IsLikelyBinaryFile $file.FullName) {
            continue
        }

        try {
            $encoding = [System.Text.UTF8Encoding]::new($false, $true)
            $fileContent = [System.IO.File]::ReadAllText($file.FullName, $encoding)
            $fileContent = MaskSensitiveData $fileContent
            $relativePath = $file.FullName.Substring($DirectoryPath.Length + 1)
            $content += "`n`nFile: $relativePath`n$fileContent"
        }
        catch [System.Text.DecoderFallbackException] {
            Write-Host "Warning: Encoding issues with file: $($file.FullName)" -ForegroundColor Yellow
            continue
        }
        catch {
            Write-Host "Warning: Error reading file: $($file.FullName)" -ForegroundColor Yellow
            continue
        }
    }
    
    Write-Progress -Activity "Processing Files" -Completed
}
catch {
    Write-Host "Error accessing directory: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --------------------------
# 8. Copy to Clipboard
# --------------------------
try {
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "No content to copy to clipboard." -ForegroundColor Yellow
        exit 0
    }

    # Try Windows Forms clipboard first
    try {
        [System.Windows.Forms.Clipboard]::SetText($content)
        Write-Host "`nContents successfully copied to clipboard." -ForegroundColor Green
    }
    catch {
        Write-Host "Primary clipboard method failed, trying alternative..." -ForegroundColor Yellow
        
        # Try WPF clipboard
        try {
            [System.Windows.Clipboard]::SetText($content)
            Write-Host "`nContents copied to clipboard (WPF method)." -ForegroundColor Green
        }
        catch {
            # Final fallback to Set-Clipboard
            try {
                Set-Clipboard -Value $content -ErrorAction Stop
                Write-Host "`nContents copied to clipboard (PowerShell method)." -ForegroundColor Green
            }
            catch {
                throw "All clipboard methods failed. Last error: $($_.Exception.Message)"
            }
        }
    }
}
catch {
    Write-Host "Error copying to clipboard: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Processing complete." -ForegroundColor Yellow
