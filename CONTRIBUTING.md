# Contributing to Reflaxe.Elixir

Thank you for your interest in contributing to Reflaxe.Elixir! This document provides guidelines and instructions for contributing to the project.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Commit Guidelines](#commit-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)

## Code of Conduct

Please be respectful and considerate in all interactions. We aim to maintain a welcoming and inclusive environment for all contributors.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment (see below)
4. Create a new branch for your changes
5. Make your changes following our guidelines
6. Submit a pull request

## Development Setup

### Prerequisites
- Node.js 16+ (for lix package management)
- Elixir 1.14+ (for Phoenix/Ecto ecosystem)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/fullofcaffeine/reflaxe.elixir.git
cd reflaxe.elixir

# Install dependencies (both ecosystems)
npm install       # Installs lix + Haxe dependencies
npx lix download  # Downloads project-specific Haxe libraries
mix deps.get      # Installs Elixir dependencies

# Run tests to verify setup
npm test          # Run Haxe compiler tests
npm run test:mix  # Run Elixir runtime tests
```

## Making Changes

### Branch Naming
- `feat/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or changes
- `chore/` - Maintenance tasks

Example: `feat/add-supervisor-support`

### Code Style
- Follow existing code patterns in the codebase
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Ensure no compilation warnings

### Adding Features
1. Create a helper compiler in `src/reflaxe/elixir/helpers/`
2. Add annotation support to `ElixirCompiler.hx` if needed
3. Write comprehensive tests
4. Update documentation
5. Add examples if applicable

## Commit Guidelines

We use **Conventional Commits** for automated versioning and changelog generation.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat**: A new feature (triggers minor version bump)
- **fix**: A bug fix (triggers patch version bump)
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates
- **ci**: CI/CD configuration changes

### Breaking Changes
Add `BREAKING CHANGE:` in the footer or `!` after the type for major version bumps:

```
feat!: redesign annotation system

BREAKING CHANGE: @:module annotation renamed to @:elixir_module
```

### Examples

```bash
# Feature
git commit -m "feat(liveview): add support for live components"

# Bug fix
git commit -m "fix(compiler): handle null values in pattern matching"

# Documentation
git commit -m "docs(readme): add installation troubleshooting section"

# Breaking change
git commit -m "feat(api)!: change compiler initialization API

BREAKING CHANGE: ElixirCompiler.init() now requires config parameter"
```

### Scope Examples
- `compiler` - Core compiler changes
- `liveview` - Phoenix LiveView features
- `ecto` - Ecto integration
- `otp` - OTP/GenServer features
- `types` - Type system changes
- `docs` - Documentation
- `tests` - Test infrastructure

## Testing

### Running Tests

```bash
# Run all tests
npm test          # Haxe compiler tests
npm run test:mix  # Elixir runtime tests
npm run test:all  # Both test suites

# Update test snapshots
npm run test:update

# Run specific test
npx haxe test/SpecificTest.hxml
```

### Writing Tests

1. **Unit Tests**: Test individual compiler components
2. **Integration Tests**: Test feature combinations
3. **Snapshot Tests**: Verify generated Elixir output
4. **Mix Tests**: Validate runtime behavior

Example test structure:
```haxe
package test;

import reflaxe.elixir.helpers.YourHelper;

class YourHelperTest {
    public static function main() {
        testBasicFunctionality();
        testEdgeCases();
        testErrorHandling();
        trace("✅ All YourHelper tests passed!");
    }
    
    static function testBasicFunctionality() {
        // Test implementation
    }
}
```

## Pull Request Process

1. **Before Submitting**
   - Ensure all tests pass (`npm run test:all`)
   - Update documentation if needed
   - Add tests for new features
   - Follow commit message guidelines
   - Update CHANGELOG.md if making significant changes

2. **PR Description Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] Tests pass locally
   - [ ] Added new tests
   - [ ] Updated snapshots if needed
   
   ## Checklist
   - [ ] Follows code style
   - [ ] Self-reviewed code
   - [ ] Updated documentation
   - [ ] No new warnings
   ```

3. **Review Process**
   - PRs require at least one approval
   - Address review feedback promptly
   - Keep PRs focused and atomic
   - Squash commits if requested

## Project Structure

```
reflaxe.elixir/
├── src/                    # Compiler source code
│   ├── reflaxe/elixir/
│   │   ├── ElixirCompiler.hx    # Main compiler
│   │   ├── helpers/             # Feature compilers
│   │   └── macro/               # Macro processors
├── std/                    # Standard library externs
│   ├── elixir/            # Elixir stdlib
│   └── phoenix/           # Phoenix framework
├── test/                   # Test files
├── examples/               # Example projects
├── documentation/          # Project documentation
└── lib/                    # Mix integration
```

## Getting Help

- Open an issue for bugs or feature requests
- Join discussions in GitHub Discussions
- Check existing issues before creating new ones
- Provide minimal reproducible examples for bugs

## Recognition

Contributors will be acknowledged in:
- CHANGELOG.md for their contributions
- README.md contributors section (for significant contributions)
- Release notes when features are shipped

Thank you for contributing to Reflaxe.Elixir! 🎉