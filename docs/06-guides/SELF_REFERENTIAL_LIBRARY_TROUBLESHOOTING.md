# Self-Referential Library Configuration: Troubleshooting Guide

## Critical Learnings from Implementation

This document captures critical learnings from implementing self-referential library configuration for Reflaxe.Elixir testing. These are hard-won insights that will save future developers hours of debugging.

## The Core Challenge

When developing a Haxe library that IS ITSELF a compiler (like reflaxe.elixir), tests need to use `-lib reflaxe.elixir` to reference the library being developed. This creates a circular dependency that requires special handling.

## Key Discovery: reflaxe.elixir IS the Project

**Critical Insight**: When tests fail with "Library reflaxe.elixir is not installed", remember that reflaxe.elixir isn't an external dependency - it's the project you're developing! This requires a self-referential configuration.

## Path Resolution: The #1 Source of Confusion

### How Haxe Resolves Paths

**CRITICAL**: Paths in `.hxml` files are resolved from the **current working directory** when Haxe runs, NOT from the location of the `.hxml` file itself.

```hxml
# In haxe_libraries/reflaxe.elixir.hxml
-cp src/  # This is relative to WHERE HAXE IS RUN, not where this file is
```

### The Absolute Path Trap

**User Feedback**: "You should not use absolute paths in the source"

While absolute paths work locally:
```hxml
# DON'T DO THIS - breaks on other machines
-cp /Users/fullofcaffeine/workspace/code/haxe.elixir/src/
```

They break portability and CI/CD pipelines. Always use relative paths.

### The Solution: Symlink Strategy

For tests running in temporary directories, we create symlinks back to the project:

```elixir
# In test/support/haxe_test_helper.ex
def setup_haxe_libraries(project_dir) do
  project_root = find_project_root()
  
  # Symlink the entire haxe_libraries directory
  symlink(Path.join(project_root, "haxe_libraries"), 
          Path.join(project_dir, "haxe_libraries"))
  
  # CRITICAL: Also symlink src/ and std/ for relative paths to work
  symlink(Path.join(project_root, "src"), 
          Path.join(project_dir, "src"))
  symlink(Path.join(project_root, "std"), 
          Path.join(project_dir, "std"))
end
```

## Common Errors and Solutions

### Error: "Library reflaxe.elixir is not installed"

**Cause**: Missing `haxe_libraries/reflaxe.elixir.hxml`

**Solution**: Create the self-referential configuration:
```bash
# Create haxe_libraries/reflaxe.elixir.hxml with:
-cp src/
-cp std/
-lib reflaxe
-D reflaxe.elixir=1.0.5
--macro reflaxe.elixir.CompilerInit.Start()
```

### Error: "classpath src/ is not a directory or cannot be read from"

**Cause**: Relative paths not resolving from test directory

**Solutions**:
1. Ensure symlinks are created (preferred)
2. Change to correct directory before compilation
3. Use HaxeTestHelper.setup_test_project()

### Error: "Type not found : test.SimpleClass"

**Cause**: Package structure doesn't match directory structure

**Solution**: Files with `package test;` must be in `test/` subdirectory:
```elixir
# Create proper directory structure
File.mkdir_p!("src_haxe/test")
File.write!("src_haxe/test/SimpleClass.hx", content)
```

### Error: "unknown option '--elixir'"

**Cause**: Incorrect Haxe syntax

**Solution**: Use `-D elixir_output=lib` instead of `--elixir lib`

## Directory Context Issues

### Problem: Compilation Happening in Wrong Directory

When running from temporary test directories, Haxe compilation may fail because relative paths don't resolve correctly.

**Solution in HaxeCompiler**:
```elixir
# Change to directory containing hxml file
cmd_opts = case Path.dirname(hxml_file) do
  "." -> [stderr_to_stdout: true]
  dir -> [cd: dir, stderr_to_stdout: true]
end
```

**Solution in HaxeWatcher**:
```elixir
# Use configurable build_file parameter
build_file_path = find_build_file(state)
```

## The 35-File Phenomenon

### Symptom
Tests expect 1 compiled file but get 35 files.

### Cause
When `src/` is symlinked into test directories, ALL compiler source files become visible and may get compiled.

### Solutions
1. Use more specific `-cp` paths
2. Filter compilation to specific entry points
3. Adjust test expectations to account for this

## Variable Substitution Attempts (What Doesn't Work)

These approaches were tried but don't work in Haxe:

```hxml
# DOESN'T WORK - Haxe doesn't expand environment variables
-cp ${HAXE_LIBCACHE}/reflaxe.elixir/0.1.0/src/

# DOESN'T WORK - No variable substitution in hxml
-cp $PROJECT_ROOT/src/
```

## Best Practices

### 1. Always Use Relative Paths
```hxml
# Good - portable and CI-friendly
-cp src/
-cp std/

# Bad - machine-specific
-cp /Users/specific/path/src/
```

### 2. Set Up Test Projects Properly
```elixir
# Always use the helper
HaxeTestHelper.setup_test_project(dir: test_dir)
```

### 3. Document Path Assumptions
```hxml
# Note: Paths are relative to project root (where haxe commands are run)
-cp src/
```

### 4. Test from Different Directories
```bash
# Test that compilation works from various locations
cd /tmp && haxe /path/to/project/build.hxml
cd test && haxe ../build.hxml
```

## Integration with Mix

### Key Learning: Build File Discovery

The Mix compiler task needs to find build files in watched directories:

```elixir
defp find_build_file(state) do
  Enum.find_value(state.dirs, fn dir ->
    hxml = Path.join(dir, state.build_file || "build.hxml")
    if File.exists?(hxml), do: hxml
  end)
end
```

### Error Storage in ETS

Compilation errors are stored in ETS tables for retrieval by Mix tasks:

```elixir
:ets.new(:haxe_errors, [:named_table, :set, :public])
:ets.insert(:haxe_errors, {:current_errors, errors})
```

## Debugging Techniques

### 1. Trace Library Resolution
```bash
# See what libraries Haxe is finding
haxe --display haxe-library-path
```

### 2. Check Working Directory
```elixir
IO.inspect(File.cwd!(), label: "Compilation directory")
```

### 3. Verify Symlinks
```bash
ls -la test_dir/haxe_libraries/
ls -la test_dir/src/
```

### 4. Test Minimal Configuration
```hxml
# Simplest possible test
-cp src/
TestClass
```

## CI/CD Considerations

### GitHub Actions Compatibility

Self-referential configuration works in CI because:
1. Relative paths are used
2. Project structure is maintained
3. Symlinks work on Linux runners

### Docker Considerations

If using Docker, ensure:
1. Symlink support is enabled
2. Fallback to copying if needed
3. Project root detection works

## Summary of Critical Learnings

1. **reflaxe.elixir is the project itself**, not an external dependency
2. **Never use absolute paths** - they break portability
3. **Paths resolve from CWD**, not from .hxml file location
4. **Symlinks are essential** for test directories
5. **Package structure must match** directory structure
6. **ETS tables store errors** for Mix task retrieval
7. **The 35-file phenomenon** is expected with symlinked src/
8. **Test from multiple directories** to ensure robustness

## When All Else Fails

If you're still having issues:

1. Start with the minimal configuration
2. Add complexity incrementally
3. Test each step works
4. Use HaxeTestHelper for consistency
5. Check the symlinks are correct
6. Verify working directory is what you expect
7. Look for the 35-file phenomenon as a sign src/ is visible
