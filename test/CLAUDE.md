# Testing Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions, architecture, and core development principles

This file contains testing-specific guidance for agents working on Reflaxe.Elixir's test infrastructure.

## 🧪 Testing Architecture Overview

### Test Types (4 Different Systems)
1. **Snapshot Tests** (TestRunner.hx) - Compare generated Elixir against expected output
2. **Mix Tests** (.exs files) - Validate generated code runs correctly in BEAM VM
3. **Generator Tests** - Validate project template generation  
4. **Integration Tests** - End-to-end compilation and execution

### Critical Commands
```bash
npm test                                    # Run ALL 180 tests (mandatory before commits)
haxe test/Test.hxml test=feature_name      # Run specific snapshot test
haxe test/Test.hxml update-intended        # Accept new output when compiler improves
MIX_ENV=test mix test                      # Run Mix/Elixir tests only
```

## 🎯 Testing Principles ⚠️ CRITICAL

### ❌ NEVER Do This:
- Modify `intended/` files manually to make tests pass
- Remove test code to fix failures
- Skip tests "just for a small change"
- Ignore test failures as "unrelated"
- Use workarounds instead of fixing root causes

### ✅ ALWAYS Do This:
- Run `npm test` after EVERY compiler modification
- Fix the compiler source to improve output
- Update snapshots ONLY when output legitimately improves
- Test todo-app compilation as integration test
- Fix ALL discovered issues, not just the primary one

## 📝 Snapshot Test Methodology

### Understanding Snapshot Tests
- **Input**: Haxe source files in `test/tests/feature_name/`
- **Process**: Compile via `compile.hxml` configuration
- **Output**: Generated Elixir in `out/` directory
- **Validation**: Compare against files in `intended/` directory

### When to Update Snapshots
**ONLY when the compiler legitimately improves:**
- Better error messages
- More idiomatic Elixir output
- Fixed bugs that produce correct code
- New features working as designed

**NEVER update to hide problems:**
- Compilation errors
- Invalid Elixir syntax
- Regression of working features
- Workarounds for broken functionality

## 🔍 Test Structure Patterns

### Snapshot Test Directory Pattern
```
test/tests/feature_name/
├── compile.hxml       # Compilation configuration
├── Main.hx           # Test source code
├── intended/         # Expected output
│   └── Main.ex      # Expected Elixir code
└── out/             # Generated output (for comparison)
```

### Mix Test Patterns
- Place in `test/` directory with `.exs` extension
- Use `test_helper.ex` for common setup
- Test that generated Elixir actually runs
- Validate Phoenix/Ecto/OTP integrations

## 🚨 Macro-Time vs Runtime Testing

### CRITICAL Understanding
**The compiler exists only at macro-time, NOT at runtime:**
- You CANNOT unit test `ElixirCompiler` directly
- You CANNOT instantiate compiler classes in tests
- You MUST test the OUTPUT, not the compiler internals

### Correct Testing Approach
```haxe
// ❌ WRONG: Cannot test compiler directly
var compiler = new ElixirCompiler(); // ERROR: Type not found at runtime

// ✅ CORRECT: Test the generated output
// 1. Compile Haxe → Elixir
// 2. Validate the .ex files
// 3. Run Mix tests to ensure Elixir code works
```

## 📊 Test Integration with Development

### Todo-App as Integration Benchmark
The `examples/todo-app` serves as the **primary integration test**:
- Tests Phoenix framework integration
- Validates HXX template compilation  
- Ensures router DSL functionality
- Verifies Ecto schema generation
- Confirms LiveView compilation

**Rule**: If todo-app doesn't compile, the compiler is broken regardless of unit tests passing.

### Pre-Commit Testing Protocol
```bash
# MANDATORY before any commit
npm test                                    # All 180 tests must pass
cd examples/todo-app && mix compile        # Integration validation
```

## 🎯 Testing Anti-Patterns

### Common Mistakes
1. **Testing compiler classes directly** - They don't exist at runtime
2. **Modifying intended files** - Fix the compiler, not the expected output
3. **Skipping integration tests** - Unit tests alone aren't sufficient
4. **Ignoring Mix test failures** - Generated code must actually work
5. **Not testing with todo-app** - Missing real-world integration issues

### Debugging Test Failures
1. **Read the error carefully** - Often points to the real issue
2. **Check recent commits** - What changed that might affect this?
3. **Compare intended vs actual** - What's different and why?
4. **Test manually** - Can you reproduce the issue?
5. **Fix the root cause** - Don't patch the symptoms

## 📚 Related Documentation
- [`/documentation/TESTING_OVERVIEW.md`](/documentation/TESTING_OVERVIEW.md) - Complete testing guide
- [`/documentation/TESTING_PRINCIPLES.md`](/documentation/TESTING_PRINCIPLES.md) - Testing methodology
- [`/documentation/COMPILER_TESTING_GUIDE.md`](/documentation/COMPILER_TESTING_GUIDE.md) - Compiler-specific testing
- [`/documentation/architecture/TESTING.md`](/documentation/architecture/TESTING.md) - Technical infrastructure

**Remember**: Testing is not separate from implementation - it IS implementation validation. Every test failure teaches us something about the system.