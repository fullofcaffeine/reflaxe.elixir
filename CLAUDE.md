# AI/Agent Development Context for Haxe→Elixir Compiler

## CLAUDE.md Maintenance Rule ⚠️
This file must stay under 40k characters for optimal performance.
- Keep only essential agent instructions
- Move historical completions to [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)
- Reference other docs instead of duplicating content
- Review size after major updates: `wc -c CLAUDE.md`
- See [`documentation/DOCUMENTATION_PHILOSOPHY.md`](documentation/DOCUMENTATION_PHILOSOPHY.md) for documentation structure

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify CLAUDE.md first** - This file contains the project truth
2. **FOLLOW DOCUMENTATION GUIDE** - See [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) for how to document
3. **UNDERSTAND THE ARCHITECTURE** - See [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) section below
4. **Check referenced documentation** - See documentation/*.md files for feature details
5. **Consult Haxe documentation** when needed:
   - https://api.haxe.org/ - Latest API reference
   - https://haxe.org/documentation/introduction/ - Language documentation
6. **Use modern Haxe 4.3+ patterns** - No legacy idioms
7. **KEEP DOCS UPDATED** - Documentation is part of implementation, not separate

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) - How the transpiler actually works
- [Critical: Macro-Time vs Runtime](#critical-macro-time-vs-runtime-) - THE MOST IMPORTANT CONCEPT TO UNDERSTAND
- [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md) - Complete architectural details
- [`documentation/TESTING.md`](documentation/TESTING.md) - Testing philosophy and infrastructure

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation, not at test runtime. This affects how you write and test compiler features.

**Key Point**: The function body compilation fix was a legitimate use case - we went from empty function bodies (`# TODO: Implement function body`) to real compiled Elixir code. This required updating all intended outputs to reflect the improved compiler behavior.

## Critical Testing Rules ⚠️

### Snapshot Testing: Update-Intended Mechanism ✅
**CRITICAL WORKFLOW TOOL**: The `update-intended` mechanism is used to accept new compiler output as the baseline for snapshot tests.

**When to use `npx haxe test/Test.hxml update-intended`:**
- ✅ **Legitimate compiler improvements** - Function body compilation fix, new features working correctly
- ✅ **Architectural changes** - Core compiler changes that improve output quality  
- ✅ **Standard library updates** - New Haxe standard library files being generated correctly
- ✅ **Expression compiler enhancements** - Better code generation producing more complete output

**When NOT to use update-intended:**
- ❌ **Test failures due to bugs** - Fix the bug, don't accept broken output
- ❌ **Compilation errors** - Resolve errors, don't accept error output as intended
- ❌ **Regression issues** - Fix regressions, don't accept degraded output
- ❌ **Non-deterministic output** - Fix consistency issues, don't accept random output

**Workflow:**
```bash
# 1. Verify new output is actually correct and improved
npx haxe test/Test.hxml show-output  # Review what changed

# 2. Accept new output as baseline if improvements are legitimate  
npx haxe test/Test.hxml update-intended

# 3. Verify consistency by running tests again
npx haxe test/Test.hxml  # Should show 28/28 passing
```

### NEVER Remove Test Code to Fix Failures
**ABSOLUTE RULE**: Never remove or simplify test code just to make tests pass. This destroys test coverage and defeats the purpose of testing.

When a test fails:
1. **Fix the underlying compiler/implementation issue** - The test is revealing a real problem
2. **Fix syntax errors properly** - Don't remove functionality, fix the syntax
3. **Enhance the compiler if needed** - If the test reveals missing features, implement them
4. **Document limitations** - If something truly can't be supported, document it clearly

Example of WRONG approach:
```haxe
// BAD: Removing test functionality to avoid syntax errors
// Before: Testing important migration features
t.addColumn("id", "serial", {primary_key: true});
// After: Gutted test that doesn't test anything
// Table columns defined via comments
```

Example of RIGHT approach:
```haxe
// GOOD: Fix the syntax issue while preserving test coverage
// Use alternative syntax that Haxe can parse
addColumn("users", "id", "serial", true, null); // primary_key param
```

**Remember**: Tests exist to ensure quality. Reducing test coverage to achieve "passing tests" is self-defeating.

## User Documentation References

### Core Documentation
- **LLM Documentation Guide**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) 📚
- **Setup & Installation**: [`documentation/GETTING_STARTED.md`](documentation/GETTING_STARTED.md)
- **Feature Status**: [`documentation/FEATURES.md`](documentation/FEATURES.md)
- **Annotations**: [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md)
- **Examples**: [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md)
- **Architecture**: [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md)
- **Testing**: [`documentation/TESTING.md`](documentation/TESTING.md)
- **Development Tools**: [`documentation/DEVELOPMENT_TOOLS.md`](documentation/DEVELOPMENT_TOOLS.md)
- **Task History**: [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)

## Reference Code Location
Reference examples for architectural patterns are located at:
`/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`

This directory contains:
- **Reflaxe projects** - Examples of DirectToStringCompiler implementations and Reflaxe target patterns
- **Phoenix projects** - Phoenix/LiveView architectural patterns and Mix task organization
- **Haxe macro projects** - Compile-time transformation macro examples for HXX processing reference
- **Haxe source code** - The Haxe compiler source at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/haxe` for API reference

## Project Context
Implementing Reflaxe.Elixir - a Haxe compilation target for Elixir/BEAM with gradual typing support for Phoenix applications.

## Reflaxe.CPP Architecture Pattern (Reference)
Based on analysis of `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe.CPP/`:

### Sub-compiler Pattern
- Main `Compiler` delegates to specialized sub-compilers in `subcompilers/` package
- Each sub-compiler handles specific compilation aspects:
  - `Classes.hx` - Class declarations and struct compilation
  - `Enums.hx` - Enum compilation
  - `Expressions.hx` - Expression compilation
  - `Types.hx` - Type resolution and mapping
  - `Includes.hx` - Include management
  - `Dynamic.hx` - Dynamic type handling

### Our Implementation Alignment
Currently using helper pattern instead of sub-compiler pattern:
- `helpers/EnumCompiler.hx` - Enum compilation (similar to Enums sub-compiler)
- `helpers/ClassCompiler.hx` - Class/struct compilation (similar to Classes sub-compiler)
- `helpers/ChangesetCompiler.hx` - Ecto changeset compilation with @:changeset annotation support
- `ElixirTyper.hx` - Type mapping (similar to Types sub-compiler)
- `ElixirPrinter.hx` - AST printing (similar role to expression compilation)

This is acceptable - helpers are simpler for our needs while following similar separation of concerns.

## Quality Standards
- Zero compilation warnings policy (from .claude/rules/elixir-best-practices.md)
- CafeteraOS memory-first architecture patterns
- Testing Trophy approach with integration test focus
- Performance targets: <15ms compilation steps, <100ms HXX template processing

## Commit Message Standards (Conventional Commits)
All commits must follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix  
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or fixing tests
- `chore`: Maintenance tasks, dependency updates
- `ci`: CI/CD configuration changes

### Examples
```bash
fix(watcher): resolve directory context issue for relative paths

fix(tests): update error message expectations for Haxe compiler output

feat(compiler): add comprehensive Ecto query compilation support

docs(testing): add Process.send_after timing notes
```

### Breaking Changes
Mark breaking changes with `BREAKING CHANGE:` in the footer or `!` after the type:
```bash
feat!: change default compilation directory structure
```

### No Co-authorship or Generation Attribution
Do NOT add co-authorship lines or generation notes in commit messages. This includes:
- No `Co-Authored-By: Claude` lines
- No `🤖 Generated with Claude Code` or similar attribution
- No references to AI/agent assistance in commit messages
Commits should appear as direct contributions without attribution notes.

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Contains Reflaxe patterns, Phoenix examples, Haxe source
- **Haxe API Documentation**: https://api.haxe.org/ - For type system, standard library, and language features
- **Web Resources**: Use WebSearch and WebFetch for current documentation, API references, and best practices
- **Principle**: Always reference existing working code and official documentation rather than guessing or assuming implementation details

## Implementation Status
For comprehensive feature status and production readiness, see [`documentation/FEATURES.md`](documentation/FEATURES.md)

## Development Environment Setup
- **Haxe Version**: 4.3.6+ (available at `/opt/homebrew/bin/haxe`)
- **Haxe API Reference**: https://api.haxe.org/ (latest version docs)
- **Haxe Documentation**: https://haxe.org/documentation/introduction/
- **Test Execution**: Use `haxe TestName.hxml` or `npm test` for full suite
- **Compilation Flags**: Always use `-D reflaxe_runtime` for test compilation
- **Test Structure**: All tests in `test/` directory with matching .hxml files
- **Reflaxe Base Classes**: Located at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe/src`

## Compiler Architecture & Modern Haxe Features
- **Output Model**: One `.ex` file per `.hx` file (1:1 mapping maintained)
- **Modern Haxe 4.3+ Features Used**:
  - Pattern matching with exhaustive checks
  - Null safety with `Null<T>` types
  - Abstract types for type-safe wrappers
  - Inline metadata for optimization
  - Expression macros for compile-time code generation
  - `using` for static extensions
  - Arrow functions in expressions
- **Avoided Legacy Patterns**:
  - No `Std.is()` (use `Std.isOfType()`)
  - No untyped code blocks
  - No Dynamic where generics suffice
  - Proper null handling instead of implicit nulls

## Test Status Summary
- **Full Test Suite**: ✅ ALL PASSING (28 snapshot tests + 130 Mix tests)
- **Elixir Tests**: ✅ ALL PASSING (13 tests in Mix/ExUnit)
- **Haxe Tests**: ✅ ALL PASSING (28 snapshot tests via TestRunner.hx)
- **CI Status**: ✅ All GitHub Actions checks passing

## Understanding Reflaxe.Elixir's Compilation Architecture ✅

**For complete architectural details, see [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md)**  

### How Reflaxe.Elixir Actually Works

Reflaxe.Elixir is a **Haxe macro-based transpiler** that transforms typed Haxe AST into Elixir code during compilation. 

#### Correct Compilation Flow

```
Haxe Source (.hx)
       ↓
   Haxe Parser → Untyped AST
       ↓
   Typing Phase → TypedExpr (ModuleType)
       ↓
   onAfterTyping callback (Reflaxe hooks here)
       ↓
   ElixirCompiler (macro-time transpilation)
       ↓
   Elixir Code (.ex files)
```

**Key Points**:
- **TypedExpr is created by Haxe**, not by our compiler
- **ElixirCompiler receives TypedExpr** as input (fully typed AST)
- **Transpilation happens at macro-time** via Context.onAfterTyping
- **No runtime component exists** - the transpiler disappears after compilation

## Critical: Macro-Time vs Runtime ⚠️

### THE FUNDAMENTAL DISTINCTION

**This is the #1 cause of confusion when working with Reflaxe compilers:**

```haxe
// MACRO-TIME: During Haxe compilation
#if macro
class ElixirCompiler extends BaseCompiler {
    // This class ONLY exists while Haxe is compiling
    // It transforms AST → Elixir code
    // Then it DISAPPEARS
}
#end

// RUNTIME: After compilation, when tests/code runs
class MyTest {
    function test() {
        // ElixirCompiler DOES NOT EXIST HERE
        // It already did its job and vanished
        var compiler = new ElixirCompiler(); // ❌ ERROR: Type not found
    }
}
```

### The Two Phases Explained

#### Phase 1: MACRO-TIME (Compilation)
```
When: While running `haxe build.hxml`
What exists: ElixirCompiler, all macro classes
What happens: 
  1. Haxe parses your .hx files
  2. Haxe creates TypedExpr AST
  3. ElixirCompiler receives AST
  4. ElixirCompiler generates .ex files
  5. Compilation ends, ElixirCompiler disappears
```

#### Phase 2: RUNTIME (Execution)
```
When: While running tests or compiled code
What exists: Your regular classes, NOT compiler classes
What happens:
  1. Test framework starts
  2. Tests execute
  3. ElixirCompiler is GONE - it doesn't exist
  4. Any attempt to use it fails
```

### Key Takeaways for Development

1. **Never try to instantiate ElixirCompiler in tests** - it doesn't exist at runtime
2. **Test the OUTPUT** - compile Haxe to Elixir, then validate the .ex files
3. **Use Mix tests** - they test that generated Elixir actually works
4. **The TypeTools.iter error** = wrong test configuration, not API incompatibility

## Known Issues (Updated)
- **Test Environment**: While Haxe 4.3.6 is available and basic compilation works, there are compatibility issues with our current implementation:
  - Missing `using StringTools` declarations causing trim/match method errors
  - Type system mismatches between macro types and expected Reflaxe types
  - Some Dynamic iteration issues that need proper typing
  - Keyword conflicts with parameter names (`interface`, `operator`, `overload`)
- **Pattern Matching Implementation**: Core logic completed but needs type system integration
- **Integration Tests**: Require mock/stub system for TypedExpr structures

## Agent Testing Instructions ✅

### Primary Command
**Always use `npm test` for comprehensive validation** - Currently runs 28 snapshot tests using TestRunner.hx

### Test Architecture: Reflaxe Snapshot Testing
1. **Snapshot Tests** (`npm test`): Compiles Haxe and compares Elixir output - **28 tests**
2. **Mix Tests** (separate): Tests generated Elixir code runs in BEAM (`mix test`)

### Creating New Snapshot Tests

**✅ ALWAYS follow Reflaxe snapshot testing pattern:**

1. **Create test directory**: `test/tests/feature_name/`
2. **Write Haxe source**: `Main.hx` with feature to test
3. **Create compile config**: `compile.hxml` with compilation settings  
4. **Generate expected output**: `haxe test/Test.hxml update-intended`
5. **Verify output**: Check generated Elixir is correct

**Example test structure:**
```
test/tests/my_feature/
├── compile.hxml    # Haxe compilation config
├── Main.hx         # Test source code
├── intended/       # Expected Elixir output
│   └── Main.ex     # Expected generated file
└── out/            # Actual output (for comparison)
```

**✅ Test Commands:**
- `npm test` - Run all 28 snapshot tests
- `haxe test/Test.hxml test=feature_name` - Run specific test  
- `haxe test/Test.hxml update-intended` - Accept current output
- `haxe test/Test.hxml show-output` - Show compilation details

**❌ NEVER do these mistakes:**
- Don't create tests without intended/ directories  
- Don't manually write expected Elixir output (use update-intended)
- Don't ignore test failures (they indicate compilation changes)
- Don't mix testing approaches (use consistent snapshot pattern)

## Current Implementation Status Summary

**For complete feature status, example guides, and usage instructions, see:**
- [`documentation/FEATURES.md`](documentation/FEATURES.md) - Production readiness status
- [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md) - Working example walkthroughs  
- [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md) - Annotation usage guide

**Quick Status**: 11/11 core features production-ready, all 9 examples working, 28/28 snapshot tests + comprehensive test suites passing.