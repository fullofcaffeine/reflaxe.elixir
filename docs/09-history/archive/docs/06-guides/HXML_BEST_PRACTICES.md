# HXML Best Practices Guide

## When to Create New HXML Files

### ✅ Create a New HXML When:

1. **New Build Target**
   - Different output format (JS, Elixir, C++, etc.)
   - Different platform (browser, server, native)
   - Example: `build-client.hxml`, `build-server.hxml`

2. **New Application/Example**
   - Each demo or example gets its own build config
   - Keeps examples self-contained and portable
   - Example: `examples/todo-app/build.hxml`

3. **Test Suites**
   - Each test category can have its own config
   - Snapshot tests need individual configs
   - Example: `test/tests/*/compile.hxml`

4. **Environment Variants**
   - Development vs production builds
   - Debug vs release configurations
   - Example: `dev.hxml`, `prod.hxml`, `test.hxml`

### ❌ Don't Create New HXML When:

1. **Minor flag differences** - Use command-line overrides instead
2. **Temporary testing** - Use command-line directly
3. **One-off builds** - Document the command instead
4. **Similar configurations exist** - Extend existing HXML

## When to Consolidate HXML Files

### Signs You Should Consolidate:

1. **Duplicate content** across multiple files
2. **Only differs by 1-2 lines** from another HXML
3. **Orphaned files** with no clear purpose
4. **Test files** with identical structure

### Consolidation Strategies:

1. **Use --next for related builds**
   ```hxml
   # all-tests.hxml
   --next test/unit.hxml
   --next test/integration.hxml
   --next test/snapshot.hxml
   ```

2. **Use base configuration with overrides**
   ```hxml
   # base.hxml
   -cp src
   -cp std
   -lib reflaxe
   
   # specific.hxml
   base.hxml
   -D specific-flag
   MainClass
   ```

3. **Use command-line parameters**
   ```bash
   # Instead of multiple HXML files:
   haxe build.hxml -D env=dev
   haxe build.hxml -D env=prod
   ```

## Naming Conventions

### Standard Names:

| File Name | Purpose | Example |
|-----------|---------|---------|
| `build.hxml` | Main entry point | Project root build |
| `build-{target}.hxml` | Target-specific build | `build-server.hxml` |
| `compile.hxml` | Test compilation | `test/tests/*/compile.hxml` |
| `test.hxml` | Test runner config | `test/Test.hxml` |
| `dev.hxml` | Development build | With debug flags |
| `prod.hxml` | Production build | With optimizations |
| `watch.hxml` | File watcher config | With --wait flag |

### Feature-Specific Names:

- `{feature}-test.hxml` - Feature test config
- `{module}.hxml` - Module-specific build
- `{platform}.hxml` - Platform-specific build

## Anti-Patterns to Avoid

### ❌ Common Mistakes:

1. **Hardcoded Absolute Paths**
   ```hxml
   # BAD
   -cp /Users/john/project/src
   
   # GOOD  
   -cp src
   -cp ../shared
   ```

2. **Mixing Concerns**
   ```hxml
   # BAD - Client and server in same file
   -js output.js
   -D elixir_output=lib
   
   # GOOD - Separate files
   # build-client.hxml → JS output
   # build-server.hxml → Elixir output
   ```

3. **No Documentation**
   ```hxml
   # BAD - No context
   -cp src
   -lib somelib
   
   # GOOD - Clear purpose
   # Phoenix LiveView application - Elixir server compilation
   # Generates BEAM-compatible code for production deployment
   -cp src
   -lib reflaxe
   ```

4. **Duplicate Configuration**
   ```hxml
   # BAD - Copy-pasted in 10 files
   -cp ../../../src
   -cp ../../../std
   -lib reflaxe
   
   # GOOD - Shared base
   # base-test.hxml → shared config
   # Individual tests just add specifics
   ```

5. **Orphaned Files**
   - Files with no clear purpose
   - Experimental configs left behind
   - Renamed but not deleted files

## Template Examples

### Basic Test Template
```hxml
# Test: [Test Name]
# Purpose: [What this tests]
# Dependencies: [Required setup]

# Standard paths
-cp ../../../std
-cp ../../../src
-cp .

# Reflaxe setup
-lib reflaxe
-D reflaxe_runtime
--macro reflaxe.elixir.CompilerInit.Start()

# Output
-D elixir_output=out

# Test entry point
TestMain
```

### Application Template
```hxml
# Application: [App Name]
# Description: [What it does]
# Targets: [Platforms]

# Delegation pattern for multi-target
--next build-server.hxml
--next build-client.hxml

# Or single target:
# -cp src
# -lib required-libs
# -D app-config
# MainClass
```

### Library Template
```hxml
# Library: [Library Name]
# Version: [Version]
# Targets: [Supported platforms]

# Multi-target build
--each

# JavaScript
--next
-js bin/lib.js
-D js-es6

# Elixir
--next
-D elixir_output=lib
--macro reflaxe.elixir.CompilerInit.Start()

# Common to all
-cp src
-lib dependencies
LibraryMain
```

## Organization Guidelines

### Directory Structure:
```
project/
├── build.hxml           # Main entry
├── build-*.hxml         # Target-specific
├── config/
│   ├── dev.hxml        # Development config
│   ├── prod.hxml       # Production config
│   └── test.hxml       # Test config
├── test/
│   ├── Test.hxml       # Test runner
│   └── tests/
│       └── */compile.hxml  # Individual tests
└── examples/
    └── */build.hxml    # Example builds
```

### Documentation Requirements:

Every HXML file should have:
1. **Header comment** explaining purpose
2. **Dependencies** listed if non-obvious
3. **Usage examples** for complex configs
4. **Maintenance owner** for organizational code

Example:
```hxml
# Router Compilation Test
# Tests: Phoenix router DSL compilation
# Owner: Compiler Team
# Usage: haxe test/tests/router/compile.hxml
# Dependencies: Phoenix framework stubs

-cp ../../../std
# ... rest of config
```

## CI/CD Considerations

### GitHub Actions Friendly:
```hxml
# CI-friendly configuration
# - No interactive prompts
# - Clear error messages
# - Predictable output paths

-D ci-mode              # Disable color output
-D no-prompt           # Skip confirmations
--no-inline            # Better stack traces
--times                # Performance metrics
```

### Build Matrix Support:
```yaml
# .github/workflows/build.yml can use:
matrix:
  hxml: [build.hxml, test.hxml, examples/*/build.hxml]
```

## Performance Tips

1. **Use --wait for development**
   ```hxml
   # watch.hxml
   build.hxml
   --wait localhost:6000
   ```

2. **Cache dependencies**
   ```hxml
   -D haxelib-cache=/tmp/haxe-cache
   ```

3. **Optimize for production**
   ```hxml
   # prod.hxml
   -D analyzer-optimize
   -D dce=full
   -D no-debug
   ```

4. **Parallel builds with --each**
   ```hxml
   --each
   --next target1.hxml
   --next target2.hxml
   ```

## Maintenance Checklist

### Regular Audits:

- [ ] Remove orphaned HXML files quarterly
- [ ] Update paths when restructuring
- [ ] Consolidate duplicate configs
- [ ] Document purpose of each file
- [ ] Version control all HXML files
- [ ] Test CI builds regularly

### Migration Strategy:

When updating HXML structure:
1. Create new structure alongside old
2. Test thoroughly
3. Update documentation
4. Migrate CI/CD configs
5. Remove old files after verification
6. Communicate changes to team

## Common Patterns in Reflaxe.Elixir

### Standard Reflaxe Setup:
```hxml
-lib reflaxe
-D reflaxe_runtime
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=output_dir
```

### Dual-Target Phoenix App:
```hxml
# Server compilation
--macro exclude('client')
-D app_name=AppName

# Client compilation
--macro exclude('server')
-D js-es6
```

### Test Snapshot Pattern:
```hxml
-cp ../../../std
-cp ../../../src  
-cp .
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
TestMain
```