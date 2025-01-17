# Product Requirements Document

## Overview
CodeContextCopy is a PowerShell-based utility for copying directory contents to clipboard with advanced filtering and security features.

## Core Features
- Copy directory contents to clipboard
- Filter by file size and type
- Mask sensitive data
- Progress tracking
- Detailed statistics

## Technical Requirements
- PowerShell 5.1 or higher
- Windows Forms for clipboard operations
- Administrative privileges for installation only

## Security Features
- Sensitive data masking (API keys, passwords, etc.)
- Binary file detection and filtering
- File size limits
- Optional dotfile filtering

## Installation
- Windows Explorer context menu integration
- Self-elevating installation script
- Clean uninstallation process

## User Experience
- Clear progress indicators
- Detailed error messages
- Statistics on completion
- Non-blocking clipboard operations

## Performance Goals
- Process directories with up to 10,000 files
- Handle files up to 10MB in size
- Complete operations within 30 seconds for typical use cases

## Maintenance
- Automated testing with Pester
- PSScriptAnalyzer compliance
- Semantic versioning
- Comprehensive documentation
