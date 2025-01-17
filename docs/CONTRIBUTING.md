# Contributing to CodeContextCopy

First off, thank you for considering contributing to CodeContextCopy! It's people like you that make CodeContextCopy such a great tool.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:

- Use welcoming and inclusive language
- Be respectful of different viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- Use a clear and descriptive title
- Describe the exact steps which reproduce the problem
- Provide specific examples to demonstrate the steps
- Describe the behavior you observed after following the steps
- Explain which behavior you expected to see instead and why
- Include error messages and stack traces if any

### Suggesting Enhancements

If you have a suggestion for a new feature or enhancement:

1. Use a clear and descriptive title
2. Provide a step-by-step description of the suggested enhancement
3. Provide specific examples to demonstrate the steps
4. Describe the current behavior and explain the behavior you expected to see
5. Explain why this enhancement would be useful

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing style

## Development Setup

1. Install Prerequisites:
   - PowerShell 5.1 or later
   - Pester (for testing)
   - PSScriptAnalyzer (for linting)

2. Clone the repository:
   ```powershell
   git clone https://github.com/ncurrier/CodeContextCopy.git
   cd CodeContextCopy
   ```

3. Run the build script:
   ```powershell
   .\scripts\build.ps1 -Task Build
   ```

4. Run the tests:
   ```powershell
   .\scripts\build.ps1 -Task Test
   ```

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line
- Consider starting the commit message with an applicable emoji:
    - 🎨 `:art:` when improving the format/structure of the code
    - 🐎 `:racehorse:` when improving performance
    - 🚱 `:non-potable_water:` when plugging memory leaks
    - 📝 `:memo:` when writing docs
    - 🐛 `:bug:` when fixing a bug
    - 🔥 `:fire:` when removing code or files
    - 💚 `:green_heart:` when fixing the CI build
    - ✅ `:white_check_mark:` when adding tests
    - 🔒 `:lock:` when dealing with security
    - ⬆️ `:arrow_up:` when upgrading dependencies
    - ⬇️ `:arrow_down:` when downgrading dependencies

### PowerShell Styleguide

- Follow the [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Use consistent indentation (4 spaces)
- Use descriptive variable names
- Include comment-based help for functions
- Use proper error handling with try/catch blocks
- Use parameter validation attributes
- Follow verb-noun naming convention for functions

### Documentation Styleguide

- Use [Markdown](https://daringfireball.net/projects/markdown/) for documentation
- Reference function and parameter names in backticks
- Include code examples where appropriate
- Keep line length to a maximum of 100 characters
- Use proper heading hierarchy
- Include links to referenced documentation

## Testing

- Write tests for new features using Pester
- Ensure all tests pass before submitting a pull request
- Include both unit tests and integration tests where appropriate
- Mock external dependencies in tests
- Test error conditions and edge cases

## Additional Notes

### Issue and Pull Request Labels

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `question` - Further information is requested
- `security` - Security-related issues
- `performance` - Performance-related issues

## Recognition

Contributors who submit a valid pull request will be added to our [CONTRIBUTORS.md](../CONTRIBUTORS.md) file.
