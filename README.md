# 📋 CodeContextCopy

> Smart directory content copying for AI analysis

CodeContextCopy is a Windows Explorer extension that makes sharing code with AI language models effortless and secure. With a simple right-click, copy your entire codebase while automatically filtering out binaries and protecting sensitive data.

![GitHub License](https://img.shields.io/github/license/ncurrier/CodeContextCopy)
![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)

## ✨ Key Features

- 🖱️ **One-Click Directory Copy**: Right-click any folder to copy its contents
- 🔒 **Built-in Security**: 
  - Automatically masks passwords, API keys, tokens, and connection strings
  - Skips sensitive configuration files (.env, .npmrc, etc.)
- 🎯 **Smart Filtering**:
  - Detects and skips binary files
  - Configurable file size limits (default 1MB)
  - Optional dotfile filtering
- 📊 **Detailed Statistics**:
  - File counts and sizes
  - Processing time
  - Skipped files breakdown
- 💻 **Developer Friendly**:
  - Preserves relative file paths
  - UTF-8 encoding support
  - Handles large codebases efficiently

## 🚀 Quick Start

1. Download the latest release
2. Run the installer (requires admin privileges)
3. Right-click any folder in Windows Explorer
4. Select "Copy Directory Contents"
5. Paste into your favorite AI tool!

## 💡 Why CodeContextCopy?

- **Secure by Default**: Never accidentally share sensitive data or credentials
- **Time-Saving**: Skip manual file selection and copying
- **Clean Output**: Get properly formatted code without binary files or build artifacts
- **Informative**: See exactly what was copied and what was skipped

## 📖 Documentation

For detailed usage instructions, configuration options, and development guidelines, check out our [documentation](docs/README.md).

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](docs/CONTRIBUTING.md) for details.

## 📜 License

MIT License - feel free to use in your own projects!

## 🙋‍♂️ Author

Created by [Nathaniel Currier](https://github.com/ncurrier)

---

<p align="center">
  <a href="docs/README.md">Documentation</a> •
  <a href="docs/CHANGELOG.md">Changelog</a> •
  <a href="CONTRIBUTORS.md">Contributors</a>
</p>
