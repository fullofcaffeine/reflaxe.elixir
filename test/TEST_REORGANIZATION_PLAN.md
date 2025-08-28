# Test Suite Reorganization Plan

## Current State Analysis

We currently have **135+ tests** in a flat, unorganized structure:
- **84 snapshot tests** in `test/tests/` (compiler output validation)
- **12 Elixir integration tests** as `.exs` files (Mix/compilation integration)  
- **39 Haxe build tests** as `.hxml` files (various purposes, many outdated)

## Problems with Current Structure

1. **No clear categorization** - Tests are mixed by type, purpose, and status
2. **Outdated tests** - Many `.hxml` files appear to be old experiments
3. **Naming inconsistency** - CamelCase, snake_case, mixed conventions
4. **Hard to find relevant tests** - No grouping by feature area
5. **Unclear test purposes** - Some tests have cryptic names
6. **Integration test failures** - 16 failures in mix_integration_test.exs

## Proposed New Structure

```
test/
├── README.md                    # Test guide and documentation
├── Makefile                     # Main test runner (updated)
│
├── snapshot/                    # Compiler output validation tests
│   ├── core/                   # Core language features
│   │   ├── arrays/
│   │   ├── classes/
│   │   ├── enums/
│   │   ├── loops/
│   │   ├── pattern_matching/
│   │   └── variables/
│   │
│   ├── stdlib/                 # Standard library
│   │   ├── string_methods/
│   │   ├── array_methods/
│   │   └── reflection/
│   │
│   ├── phoenix/                # Phoenix framework
│   │   ├── liveview/
│   │   ├── router/
│   │   ├── endpoints/
│   │   └── hxx_templates/
│   │
│   ├── ecto/                   # Ecto integration
│   │   ├── schemas/
│   │   ├── changesets/
│   │   └── migrations/
│   │
│   ├── otp/                    # OTP patterns
│   │   ├── genserver/
│   │   ├── supervisor/
│   │   └── application/
│   │
│   └── regression/             # Specific bug fixes
│       ├── nested_switch_consistency/
│       ├── underscore_prefix_consistency/
│       └── g_variable_patterns/
│
├── integration/                 # Elixir runtime tests (.exs)
│   ├── mix/                   # Mix task integration
│   │   ├── haxe_compiler_test.exs
│   │   ├── haxe_watcher_test.exs
│   │   └── mix_integration_test.exs
│   │
│   ├── error_handling/        # Error and debugging
│   │   ├── haxe_error_parsing_test.exs
│   │   ├── stacktrace_integration_test.exs
│   │   └── source_map_test.exs
│   │
│   └── tooling/               # Development tools
│       ├── haxe_server_test.exs
│       └── file_watching_integration_test.exs
│
├── examples/                   # Complete example applications
│   ├── simple/
│   ├── mix_project/
│   ├── ecto_project/
│   └── phoenix_project/
│
└── _archive/                   # Deprecated/outdated tests
    ├── old_hxml_tests/        # Old .hxml experiments
    └── broken_tests/          # Tests that need fixing or removal
```

## Test Categories Explained

### Snapshot Tests (`snapshot/`)
- **Purpose**: Validate compiler output matches expected Elixir code
- **Mechanism**: Compile Haxe → Compare with `intended/` directory
- **Categories by feature area** for easy navigation

### Integration Tests (`integration/`)
- **Purpose**: Validate generated Elixir code actually runs
- **Mechanism**: Mix compilation, runtime behavior validation
- **Categories by tool/subsystem** being tested

### Example Tests (`examples/`)
- **Purpose**: Complete applications that showcase features
- **Mechanism**: Full compilation and execution
- **Useful for**: Documentation, debugging, feature validation

### Archive (`_archive/`)
- **Purpose**: Preserve old tests without cluttering active suite
- **Can be deleted** after review period

## Migration Steps

1. **Create new directory structure**
2. **Categorize existing tests** into appropriate directories
3. **Update Makefile** to handle new structure
4. **Fix or archive broken tests**
5. **Update CI configuration**
6. **Document test conventions** in README

## Tests to Remove/Archive

Based on analysis, these appear obsolete:
- Various standalone `.hxml` files (experiments from development)
- Duplicate test cases with different names
- Tests for features that no longer exist

## Benefits of Reorganization

1. **Easier navigation** - Find tests by feature area
2. **Clear purpose** - Understand what each test validates
3. **Better maintenance** - Know what to update when changing features
4. **Faster debugging** - Run only relevant test categories
5. **Cleaner codebase** - Archive old experiments
6. **Better onboarding** - New contributors understand test structure

## Next Steps

1. Review and approve this plan
2. Create migration script to move tests
3. Update test runners and documentation
4. Execute migration in phases
5. Clean up obsolete tests