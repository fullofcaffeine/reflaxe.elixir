# Self-Referential Library Configuration: Key Learnings

## Summary of Critical Discoveries

This document captures the key learnings from implementing self-referential library configuration for Reflaxe.Elixir testing infrastructure.

## The Core Problem

When developing a Haxe library that is itself a compiler (reflaxe.elixir), tests need to use `-lib reflaxe.elixir` but the library isn't installed via haxelib - it's the project being developed.

## Critical User Feedback

1. **"You should not use absolute paths in the source"**
   - User explicitly rejected absolute paths in haxe_libraries/reflaxe.elixir.hxml
   - Led to implementing relative paths with symlink strategy

2. **"reflaxe.elixir IS the project"**
   - User clarified that reflaxe.elixir isn't an external dependency
   - It's the actual project being developed, requiring self-reference

## Technical Solutions Implemented

### 1. Self-Referential Configuration
Created `haxe_libraries/reflaxe.elixir.hxml`:
```hxml
-cp src/
-cp std/
-lib reflaxe
-D reflaxe.elixir=0.1.0
--macro reflaxe.elixir.CompilerInit.Start()
```

### 2. Path Resolution Strategy
- Paths in .hxml files resolve from CWD, not file location
- Implemented symlink strategy for test directories
- Created HaxeTestHelper module for consistent setup

### 3. Directory Context Management
- HaxeCompiler changes to correct directory for compilation
- HaxeWatcher uses configurable build_file parameter
- Tests create proper package directory structure

## Problems Solved

1. ✅ Self-referential library configuration
2. ✅ Path resolution for tests in temp directories
3. ✅ Package structure alignment
4. ✅ HaxeWatcher compilation paths
5. ✅ Reduced test failures from 25 to 16

## Remaining Issues

1. **The 35-File Phenomenon**
   - Tests expect 1 compiled file but get 35
   - Caused by symlinked src/ directory making all compiler source visible
   - May need filtering or adjusted expectations

## Documentation Created

1. **SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md**
   - Comprehensive troubleshooting guide
   - Critical path resolution insights
   - Common errors and solutions
   - CI/CD considerations

2. **Enhanced TESTING.md**
   - Added references to troubleshooting guide
   - Updated troubleshooting section with new issues
   - Added links to specific problem solutions

3. **Updated INSTALLATION.md**
   - Added warnings about self-referential issues
   - Linked to troubleshooting documentation
   - Added specific error solutions

## Key Insights for Future Development

1. **Never use absolute paths** - They break portability and CI
2. **Paths resolve from CWD** - Critical for understanding .hxml behavior
3. **Symlinks are essential** - Required for test directory setup
4. **Document non-obvious behaviors** - Like the 35-file phenomenon
5. **Test from multiple directories** - Ensures robust path resolution

## What Made This Hard

1. **Non-obvious path resolution** - Haxe resolves from CWD, not .hxml location
2. **Circular dependency** - Library referencing itself
3. **Multiple directory contexts** - Tests run from temp dirs
4. **No variable substitution** - Can't use env vars in .hxml files
5. **Silent failures** - Some issues only visible in specific scenarios

## Critical Success Factors

1. **User feedback** - "Don't use absolute paths" guided solution
2. **Symlink strategy** - Made relative paths work everywhere
3. **Test helper infrastructure** - Consistent setup across tests
4. **Comprehensive documentation** - Captured all learnings

## Time Investment

This configuration issue consumed significant development time but resulted in:
- Robust test infrastructure
- Comprehensive documentation
- Deep understanding of Haxe library resolution
- Reusable patterns for future projects