# Lix Vendored Dependencies Guide

**Date**: 2025-01-19  
**Purpose**: Document the correct approach for vendored dependencies in lix-based Haxe projects

## Summary

When working with vendored dependencies in lix (like our vendored Reflaxe), there are specific patterns and commands that ensure portable, maintainable dependency management.

## The Official Lix Approach for Local Dependencies

According to the [official lix documentation](https://github.com/lix-pm/lix.client), **manually editing `.hxml` files is the official method** for local development dependencies.

### Method 1: Direct .hxml Editing (Most Common)

```bash
# Edit haxe_libraries/libraryname.hxml directly
vim haxe_libraries/reflaxe.hxml
```

Change from auto-generated path:
```hxml
-cp ${HAXESHIM_LIBCACHE}/reflaxe/4.0.0-beta/path/to/src
```

To local vendored path:
```hxml
-cp vendor/reflaxe/src/
```

**Benefits**:
- Simple and direct
- Works immediately
- Follows official lix patterns
- Relative paths work across machines

**Note**: This will show as a modified file in git, which is expected and acceptable for vendored dependencies.

### Method 2: Using `lix dev` Command (Recommended)

For proper lix integration, use the `dev` command:

```bash
# Set up vendored library as development dependency
lix dev reflaxe vendor/reflaxe
```

**Requirements**:
- The vendored directory must contain `haxelib.json`
- The haxelib.json must specify the correct `classPath`

**Example haxelib.json**:
```json
{
  "name": "reflaxe",
  "url": "https://github.com/SomeRanDev/reflaxe",
  "license": "MIT",
  "tags": ["compiler", "transpiler", "codegen"],
  "description": "A source-to-source transpiler framework for Haxe (vendored with patches)",
  "version": "4.0.0-beta",
  "classPath": "src/",
  "releasenote": "Vendored version with critical filesystem bug fixes",
  "contributors": ["SomeRanDev"],
  "dependencies": {}
}
```

**Result**: Lix automatically updates the .hxml file to use `${SCOPE_DIR}/vendor/reflaxe/src/`

### Method 3: GitHub Branch Installation (Alternative)

For work-in-progress changes:
```bash
lix install github:username/repository#branch_name
```

This allows sharing development versions without vendoring.

## Why We Chose Vendoring

For Reflaxe.Elixir, we vendored Reflaxe for these reasons:

1. **Critical Bug Fixes**: Our vendored version includes filesystem bug fixes not yet in upstream
2. **Stability**: Ensures consistent behavior across all development environments  
3. **Offline Development**: No dependency on network connectivity for builds
4. **Patch Management**: Easy to apply and maintain project-specific patches

## Best Practices

### ✅ Do This:
- Use `lix dev` for proper lix integration when possible
- Include `haxelib.json` in vendored libraries
- Use relative paths in .hxml files for portability
- Document vendoring reasons in `vendor/library/PATCHES.md`
- Commit .hxml modifications for vendored dependencies

### ❌ Avoid This:
- Absolute paths in .hxml files (breaks on other machines)
- Vendoring without documentation
- Ignoring .hxml changes in git (breaks builds for others)
- Forgetting to include required metadata files

## Troubleshooting

### "classpath vendor/library/src/ is not a directory"
- **Cause**: Working directory issues or missing vendored files
- **Solution**: Use `lix dev` command or check vendored directory exists

### "Library not found" errors
- **Cause**: Missing haxelib.json in vendored directory
- **Solution**: Create minimal haxelib.json with correct classPath

### Path resolution issues
- **Cause**: Absolute paths in .hxml files
- **Solution**: Use relative paths or `${SCOPE_DIR}` variable

## Our Implementation

In this project:
```bash
# What we did:
lix dev reflaxe vendor/reflaxe

# This created:
# haxe_libraries/reflaxe.hxml with:
-cp ${SCOPE_DIR}/vendor/reflaxe/src/
-D reflaxe=4.0.0-beta
--macro Sys.println("haxe_libraries/reflaxe.hxml:2: [Warning] Using dev version of library reflaxe")
```

The `${SCOPE_DIR}` variable ensures paths work across different machines and environments.

## References

- [Lix Client Repository](https://github.com/lix-pm/lix.client) - Official documentation
- [Haxe Library Management](https://haxe.org/manual/haxelib.html) - General haxelib concepts
- [vendor/reflaxe/PATCHES.md](../vendor/reflaxe/PATCHES.md) - Our specific patches applied

---

**Key Takeaway**: Lix's approach to local dependencies is more flexible than traditional package managers, allowing both manual .hxml editing and automated `dev` command workflows.