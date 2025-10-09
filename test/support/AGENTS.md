# Test Support Infrastructure - DO NOT DELETE

## ⚠️ CRITICAL: These Are Essential Test Support Files

**IMPORTANT**: The files in this `test/support/` directory are **essential test infrastructure**, NOT generated files. They provide critical test helpers and configuration for the Reflaxe.Elixir test suite.

**DO NOT DELETE THESE FILES** - They are required for tests to run.

## 📁 Directory Contents

```
test/support/
├── haxe_test_helper.ex        # Elixir test helper module
├── test_reflaxe_elixir.hxml   # Haxe test configuration
└── AGENTS.md                   # This documentation file
```

## 🔧 File Purposes

### `haxe_test_helper.ex`
- **Purpose**: Provides test utility functions for Elixir integration tests
- **Key Functions**:
  - Sets up test projects with proper Haxe configuration
  - Creates temporary test directories
  - Manages Haxe library paths for tests
  - Handles compilation and verification
- **Used By**: All Mix integration tests (`test/*.exs` files)

### `test_reflaxe_elixir.hxml`
- **Purpose**: Haxe configuration for test compilation
- **Contents**: 
  - Compiler flags for test runs
  - Library paths and dependencies
  - Reflaxe.Elixir macro configuration
- **Used By**: Test helper when setting up Haxe projects

## ⚠️ Historical Context

These files were accidentally deleted in commit `45b5a06` on August 28, 2025, with the message "chore(tests): remove unnecessary test directories". They were restored immediately after discovering that tests could not run without them.

## 🚫 Why These Cannot Be Deleted

1. **Test Infrastructure**: The test_helper.exs file explicitly requires `haxe_test_helper.ex`
2. **Mix Integration Tests**: All integration tests depend on HaxeTestHelper module
3. **Test Configuration**: The .hxml file provides essential Haxe configuration for tests
4. **CI/CD Pipeline**: Continuous integration will fail without these files

## 🧪 How These Files Are Used

### In test_helper.exs
```elixir
# Compile test support modules
Code.compile_file("test/support/haxe_test_helper.ex")
```

### In Integration Tests
```elixir
defmodule MixIntegrationTest do
  use ExUnit.Case
  
  test "setup haxe project" do
    test_project_dir = "test/fixtures/test_project"
    HaxeTestHelper.setup_haxe_project(test_project_dir)
    # ... test continues
  end
end
```

## 🔍 Identifying Test Support vs Generated Files

### Test Support Files (DO NOT DELETE)
- Located in `test/support/` directory
- Provide test infrastructure and helpers
- Written in Elixir to support test execution
- Required by test_helper.exs

### Generated Test Files (Can be regenerated)
- Located in `test/snapshot/*/out/` directories
- Created during test runs
- Can be safely deleted and regenerated
- Never committed to version control

## 📚 Related Documentation

- [/test/AGENTS.md](/test/AGENTS.md) - Complete test suite documentation
- [/docs/03-compiler-development/testing-infrastructure.md](/docs/03-compiler-development/testing-infrastructure.md) - Testing infrastructure guide
- [/test/README.md](/test/README.md) - Test suite user documentation

## 🚨 Maintenance Rules

1. **NEVER delete these files** - They are not generated code
2. **Test before modifying** - Changes can break the entire test suite
3. **Document changes** - Update this file when modifying support files
4. **Keep synchronized** - Ensure test_helper.exs and support files match

---

**Remember**: If tests fail with "could not load test/support/haxe_test_helper.ex", check if these files exist first before assuming they need to be created. They are essential infrastructure, not optional helpers.