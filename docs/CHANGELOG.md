# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2025-01-18

### Added
- Added automatic window closing after operation completion

### Changed
- Improved user experience with cleaner process termination

## [1.4.0] - 2025-01-18

### Added
- Added clear file delimiters in output for better readability
- Added both full and relative paths for each file in output
- Added proper UTF-8 encoding handling for special characters

### Changed
- Improved file content formatting and clipboard output
- Enhanced error handling and progress display
- Fixed all PSScriptAnalyzer issues and code style
- Improved handling of already redacted content
- Enhanced file encoding with explicit UTF-8 support

### Fixed
- Fixed content building to properly format file content
- Fixed message box display issues
- Fixed character encoding issues with special characters
- Removed trailing whitespace throughout codebase

## [1.3.0] - 2025-01-18

### Added
- Enhanced sensitive data masking with comprehensive patterns
- Improved binary file detection with extension and content checks
- Added Test-IsBinaryFile function for better file type detection
- Added more robust sensitive data pattern matching

### Changed
- Updated file content processing to properly handle and format output
- Fixed dotfile filtering parameter handling
- Improved code organization and readability
- Enhanced sensitive data masking patterns
- Updated module version and release notes
- Changed build output from /output to /bin directory
- Improved build script organization for source and script files

### Fixed
- File content not being properly returned in output
- Inconsistent dotfile handling
- Binary file detection issues
- Sensitive data masking inconsistencies
- File path formatting in output
- Build script file organization and output location

## [1.2.0] - 2025-01-18

### Added
- User prompts for maximum file size and dotfile inclusion
- Improved file encoding handling with Get-Content
- Enhanced error tracking for encoding issues
- Progress display during file processing
- Detailed error messages for file access issues
- Self-elevation capabilities to Install.ps1 and Remove.ps1
- Automatic administrative privilege requests
- Improved error handling in installation scripts
- Added Windows Forms assembly for clipboard operations
- Added WPF clipboard support as fallback method
- Added dotfile filtering option
- Added pause at script completion
- Added more detailed progress messages

### Changed
- Updated README with comprehensive documentation
- Improved installation and removal process
- Enhanced script documentation and comments
- Fixed clipboard operations in CopyDirContentsWithSecurity.ps1
- Improved argument passing during self-elevation
- Made admin privileges optional for copying operations
- Improved user interaction with clear prompts
- Enhanced completion dialog with detailed statistics
- Simplified statistics output for better readability
- Improved file content reading with better encoding support
- Enhanced error handling for file operations
- Updated file processing to handle empty directories
- Optimized array handling for better performance
- Moved all scripts to /scripts directory for better organization

### Fixed
- Clipboard access issues in CopyDirContentsWithSecurity.ps1
- Administrative privileges handling across all scripts
- Self-elevation argument passing
- Multiple clipboard method support for better reliability
- Window closing too quickly
- Directory path parameter handling
- File encoding errors with UTF8 files
- Missing property errors in statistics tracking
- Progress counter accuracy
- Empty directory handling
- Error messages for inaccessible files

## [1.1.0] - 2025-01-17

### Added
- Token estimation for LLM compatibility
- Detailed file and size statistics
- Processing time tracking
- Cost estimation based on GPT-4 pricing
- Project restructuring for better organization
- Build script with automated tasks
- Unit tests with Pester
- Module manifest for PowerShell Gallery compatibility

### Changed
- Improved project structure with dedicated directories
- Enhanced installation scripts for new structure
- Updated documentation with LLM-specific information
- Improved completion dialog with detailed statistics
- Registry files moved to config directory
- Scripts updated to use relative paths

### Fixed
- Installation script paths for new structure
- Registry file template placeholders
- Documentation organization
- Window closing behavior
- Directory path handling

## [1.0.0] - 2025-01-17

### Added
- Initial release
- Install.ps1: Script to install context menu entry
- Remove.ps1: Script to remove context menu entry
- CopyDirContentsWithSecurity.ps1: Main script for copying directory contents
- Added strict mode and error handling
- Added admin privilege checks
- Added progress bar for file processing
- Added UTF-8 encoding support
- Added comprehensive binary file detection
- Added sensitive data masking
- Added proper registry access handling

### Security
- Added admin requirement checks
- Improved sensitive data pattern matching
- Added secure clipboard handling
- Added proper error handling and resource cleanup

### Documentation
- Added comprehensive documentation
- Added .gitignore file
- Added .clinerules for coding standards
- Added CHANGELOG.md for version tracking
