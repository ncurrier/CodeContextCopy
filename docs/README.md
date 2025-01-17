# CodeContextCopy

A Windows Explorer context menu utility for copying directory contents to clipboard with LLM token estimation and context optimization.

## Features

- Copy directory contents to clipboard with a right-click
- Smart filtering of binary and large files
- Optional dotfile inclusion/exclusion
- Secure handling of sensitive data
- Progress tracking and detailed statistics
- Token estimation for LLM compatibility
- Cost estimation based on GPT-4 pricing
- Optimized for AI code analysis

## Example Output

When you copy a directory containing sample text files, you'll see a completion dialog like this:

```
Operation completed successfully!

Directory: C:\Example\TextFiles
Processing Time: 0.24 seconds

File Statistics:
---------------
Total Files Found: 3
Files Processed: 3
Files Skipped: 0
Binary Files: 0
Dotfiles: 0
Oversized Files: 0
Encoding Errors: 0

Size Statistics:
---------------
Total Size: 1.25 KB
Processed Size: 1.25 KB
Max File Size: 1000 KB

Content Statistics:
------------------
Characters: 1,280
Lines: 15
Estimated Tokens: 356
Estimated Cost: $0.0002 USD (based on GPT-4 input pricing)

Settings:
---------
Dotfiles Included: False
Max File Size: 1000 KB
```

Example copied content:
```
File: sample1.txt
The quick brown fox jumps over the lazy dog. This pangram contains every letter of the English alphabet at least once. Jackdaws love my big sphinx of quartz.

File: sample2.txt
Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump! The five boxing wizards jump quickly.

File: code.py
def generate_pangram():
    return "The quick brown fox jumps over the lazy dog."
```

## Project Structure

```
CodeContextCopy/
├── src/                    # Source code
│   ├── CodeContextCopy.psd1       # Module manifest
│   └── CopyDirContentsWithSecurity.ps1  # Main script
├── scripts/                # Installation scripts
│   ├── Install.ps1        # Installation script
│   └── Remove.ps1         # Uninstallation script
├── config/                # Configuration files
│   ├── AddContextMenu.reg    # Registry entries for context menu
│   └── RemoveContextMenu.reg # Registry cleanup
├── docs/                  # Documentation
│   ├── README.md         # This file
│   └── CHANGELOG.md      # Version history
├── tests/                 # Test files
│   └── Copy-DirectoryContents.Tests.ps1
└── build.ps1             # Build and deployment script
```

## Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/ncurrier/CodeContextCopy.git
   ```

2. Run the installation script:
   ```powershell
   .\build.ps1 -Task Install
   ```

## Usage

1. Right-click on any directory in Windows Explorer
2. Select "Copy Directory Contents"
3. Review the statistics in the completion dialog:
   - See total files processed
   - Check estimated token count for LLM usage
   - Review estimated API costs
   - Verify content size and processing details
4. Paste the contents into your LLM tool or code editor

## Development

### Prerequisites
- PowerShell 5.1 or later
- Administrator privileges (for installation only)

### Build and Test
```powershell
# Run all tests
.\build.ps1 -Task Test

# Build the module
.\build.ps1 -Task Build

# Install the module
.\build.ps1 -Task Install

# Uninstall the module
.\build.ps1 -Task Uninstall
```

### Running Tests
```powershell
Invoke-Pester .\tests
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes (following [Conventional Commits](https://www.conventionalcommits.org/))
4. Push to the branch
5. Create a Pull Request

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

Current Version: 1.1.0

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Nathaniel Currier (nat.io)
