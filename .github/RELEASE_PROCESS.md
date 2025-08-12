# Release Process Documentation

This document outlines the automated release process for Reflaxe.Elixir using semantic-release and GitHub Actions.

## Release Workflow Overview

Reflaxe.Elixir uses **semantic-release** for automated versioning and publishing. The release process is fully automated based on conventional commit messages.

### Workflow Triggers

- **Automatic**: Every push to `main` branch triggers the release workflow
- **Manual**: Can be triggered manually from GitHub Actions tab

### Release Types

Based on conventional commit prefixes:

| Commit Type | Version Bump | Example |
|------------|--------------|----------|
| `fix:` | Patch (0.0.x) | `fix(compiler): handle null values correctly` |
| `feat:` | Minor (0.x.0) | `feat(liveview): add component support` |
| `feat!:` or `BREAKING CHANGE:` | Major (x.0.0) | `feat!: redesign annotation system` |
| `docs:`, `style:`, `refactor:` | No release | Documentation and non-functional changes |

## GitHub Actions Workflow

### File: `.github/workflows/release.yml`

The release workflow performs these steps:

1. **Environment Setup**
   ```yaml
   - name: Install Node.js dependencies
     run: npm install
   
   - name: Install Elixir dependencies  
     run: |
       mix deps.get
       MIX_ENV=test mix deps.compile
   ```

2. **Build Process**
   ```yaml
   - name: Build
     run: npm run build  # Dummy build (compiler doesn't need building)
   ```

3. **Release Generation**
   - Analyzes commits since last release
   - Determines version bump based on conventional commits
   - Generates changelog from commit messages
   - Creates GitHub release with automatic source archives

### Recent Improvements

#### Elixir Dependency Compilation Fix
**Problem**: Release workflow was failing due to missing compiled Elixir dependencies.

**Solution**: Added explicit dependency compilation step:
```yaml
- name: Install Elixir dependencies
  run: |
    mix deps.get
    MIX_ENV=test mix deps.compile  # Critical for semantic-release scripts
```

#### Simplified Release Assets  
**Problem**: Custom packaging was complex and redundant with GitHub's automatic archives.

**Solution**: Simplified to use GitHub's automatic source archives:
```json
{
  "@semantic-release/github": {
    "assets": false  // Use automatic .zip and .tar.gz archives
  }
}
```

## Package Configuration

### `package.json` Release Configuration

```json
{
  "release": {
    "branches": ["main"],
    "plugins": [
      "@semantic-release/commit-analyzer",
      "@semantic-release/release-notes-generator", 
      "@semantic-release/changelog",
      ["@semantic-release/exec", {
        "prepareCmd": "node scripts/sync-version.js ${nextRelease.version}"
      }],
      ["@semantic-release/github", {
        "assets": false
      }],
      ["@semantic-release/git", {
        "assets": ["package.json", "package-lock.json", "haxelib.json", "CHANGELOG.md"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\\n\\n${nextRelease.notes}"
      }]
    ]
  }
}
```

### Key Features

1. **Version Synchronization**: `scripts/sync-version.js` keeps `haxelib.json` in sync with `package.json`
2. **Automatic Changelog**: Generated from conventional commit messages
3. **GitHub Releases**: Created with auto-generated release notes
4. **Source Archives**: GitHub automatically provides `.zip` and `.tar.gz` downloads

## Installation from Releases

### Via Lix (Recommended)

Users can install directly from GitHub releases:

```bash
# Install latest version
npx lix install github:fullofcaffeine/reflaxe.elixir

# Install specific version/tag  
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.0.1

# Update to latest
npx lix install github:fullofcaffeine/reflaxe.elixir --force
```

### Via Vendoring

Users can download and vendor the source:

```bash
# Download release archive
wget https://github.com/fullofcaffeine/reflaxe.elixir/archive/refs/tags/v1.0.1.zip

# Extract and copy to project
unzip v1.0.1.zip
cp -r reflaxe.elixir-1.0.1/src/ your-project/vendor/reflaxe.elixir/src/
cp -r reflaxe.elixir-1.0.1/std/ your-project/vendor/reflaxe.elixir/std/
```

## Release Verification

After each release, verify the installation works:

1. **Test Lix Installation**
   ```bash
   # In a temporary directory
   npx lix install github:fullofcaffeine/reflaxe.elixir#latest
   ```

2. **Test Source Archive**
   - Download the release .zip file
   - Extract and test compilation with example projects

3. **Verify Documentation**
   - Check that CHANGELOG.md was updated
   - Verify GitHub release notes are accurate

## Troubleshooting Release Issues

### Release Workflow Fails at Dependencies

**Symptom**: `missing Jason or FileSystem` errors during release.

**Solution**: Ensure Elixir dependencies are compiled:
```yaml
- name: Install Elixir dependencies
  run: |
    mix deps.get
    MIX_ENV=test mix deps.compile
```

### Version Synchronization Issues

**Symptom**: `haxelib.json` version doesn't match `package.json`.

**Solution**: Check `scripts/sync-version.js` is working:
```bash
# Manually test the sync script
node scripts/sync-version.js 1.0.1
```

### No Release Generated

**Symptom**: Workflow runs but no release is created.

**Possible Causes**:
- No conventional commits since last release
- Commits don't trigger version bumps (`docs:`, `style:`, etc.)
- Release already exists for the determined version

**Solution**: 
- Ensure commits use conventional format (`feat:`, `fix:`, etc.)
- Check semantic-release logs in GitHub Actions

### Lix Installation Fails

**Symptom**: Users report `lix install` fails with new release.

**Checks**:
- Verify `haxelib.json` has correct `version` field
- Check that source archives contain all necessary files
- Test installation manually in clean environment

## Manual Release Process

In emergencies, releases can be created manually:

1. **Update Versions**
   ```bash
   # Update package.json version
   npm version patch|minor|major --no-git-tag-version
   
   # Sync haxelib.json
   node scripts/sync-version.js $(node -p "require('./package.json').version")
   ```

2. **Create Git Tag**
   ```bash
   git add package.json haxelib.json
   git commit -m "chore(release): v1.0.1"
   git tag v1.0.1
   git push origin main --tags
   ```

3. **Create GitHub Release**
   - Go to GitHub releases page
   - Create new release from tag
   - GitHub automatically generates source archives

## Best Practices

### For Maintainers

1. **Use Conventional Commits**: Always use proper commit message format
2. **Review Before Merge**: Check that PR commits will trigger appropriate version bump
3. **Monitor Releases**: Watch GitHub Actions for release workflow failures
4. **Test Installations**: Periodically test Lix and vendoring installation methods

### For Contributors

1. **Follow Commit Guidelines**: See [CONTRIBUTING.md](../CONTRIBUTING.md) for conventional commit format
2. **Breaking Changes**: Use `feat!:` or add `BREAKING CHANGE:` footer for major version bumps
3. **Documentation**: Use `docs:` prefix for documentation-only changes (won't trigger release)

## Security Considerations

- **No Secrets Required**: Release process uses GitHub's automatic token (`GITHUB_TOKEN`)
- **Source Only**: No compiled binaries or executable code in releases
- **Verified Commits**: Consider requiring signed commits for release branches

## Monitoring and Analytics

### Release Metrics to Track

- **Release Frequency**: Aim for regular, small releases over large infrequent ones
- **Installation Success**: Monitor GitHub download statistics
- **User Feedback**: Watch for installation issues in GitHub Issues

### Useful GitHub Insights

- **Releases Page**: Track download counts and adoption
- **Actions Tab**: Monitor release workflow success rate  
- **Dependencies**: Review Dependabot security updates

---

**Related Documentation:**
- [Contributing Guidelines](../CONTRIBUTING.md) - Conventional commit format
- [Installation Guide](../INSTALLATION.md) - User installation instructions
- [Development Guide](../DEVELOPMENT.md) - Setting up development environment