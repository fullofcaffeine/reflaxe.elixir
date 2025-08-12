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
- [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Testing philosophy and infrastructure

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation, not at test runtime. This affects how you write and test compiler features.

**Key Point**: The function body compilation fix was a legitimate use case - we went from empty function bodies (`# TODO: Implement function body`) to real compiled Elixir code. This required updating all intended outputs to reflect the improved compiler behavior.

## 📍 Agent Navigation Guide

### When Writing or Fixing Tests
→ **MUST READ**: [`documentation/TESTING_PRINCIPLES.md`](documentation/TESTING_PRINCIPLES.md) - Critical testing rules, snapshot testing, simplification principles
→ **Architecture**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Technical testing infrastructure
→ **Deep Dive**: [`documentation/TEST_SUITE_DEEP_DIVE.md`](documentation/TEST_SUITE_DEEP_DIVE.md) - What each test validates

### When Implementing New Features  
→ **Process**: Follow TDD methodology (RED-GREEN-REFACTOR)
→ **Testing**: Create snapshot tests following patterns in TESTING_PRINCIPLES.md
→ **Documentation**: Update relevant guides in `documentation/`

### When Refactoring Code
→ **Safety**: Ensure all tests pass before and after changes
→ **Simplification**: Apply "as simple as needed" principle (see TESTING_PRINCIPLES.md)
→ **Documentation**: Update if behavior or API changes

### When Debugging Compilation Issues
→ **Source Maps**: See [`documentation/SOURCE_MAPPING.md`](documentation/SOURCE_MAPPING.md)
→ **Architecture**: Understand macro-time vs runtime (see sections below)
→ **Examples**: Check `test/tests/` for similar patterns

## User Documentation References

### Core Documentation
- **Project Overview**: See [README.md](README.md) for project introduction and public interface
- **LLM Documentation Guide**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) 📚
- **Setup & Installation**: [`documentation/GETTING_STARTED.md`](documentation/GETTING_STARTED.md)
- **Feature Status**: [`documentation/FEATURES.md`](documentation/FEATURES.md)
- **Annotations**: [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md)
- **Examples**: [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md)
- **Architecture**: [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md)
- **Testing**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md)
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
- **Reflaxe source** - The Reflaxe framework source for understanding compiler patterns
- **Reference implementations** - Working Reflaxe targets for comparison and pattern reference
- **Haxe API documentation** - Can check API at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/haxe/std/` for standard library

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
- Testing Trophy approach with integration test focus
- Performance targets: <15ms compilation steps, <100ms HXX template processing

## Date and Timestamp Rule 📅
**ALWAYS check current date before writing timestamps**:
```bash
date  # Get current date/time before writing any timestamps
```
- Never assume dates - always verify with `date` command
- Use consistent format: "August 2025" or "2025-08-11"
- Update "Last Updated" timestamps when modifying documentation

## Commit Message Standards (Conventional Commits)
All commits must follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Important: No AI Attribution in Commits
**NEVER add AI attribution lines to commit messages**:
- ❌ Don't add "Generated with Claude Code"
- ❌ Don't add "Co-Authored-By: Claude"
- ✅ Write clean, professional commit messages without AI references

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

## Dynamic Type Usage Guidelines ⚠️
**Dynamic should be used with caution** and only when necessary:
- ✅ **When to use Dynamic**: Catch blocks (error types vary), reflection operations, external API integration
- ✅ **Always add justification comment** when using Dynamic to explain why it's necessary
- ❌ **Avoid Dynamic when generics or specific types work** - prefer type safety
- 📝 **Example of proper Dynamic usage**:
  ```haxe
  } catch (e: Dynamic) {
      // Dynamic used here because Haxe's catch can throw various error types
      // Converting to String for error reporting
      EctoErrorReporter.reportSchemaError(className, Std.string(e), pos);
  }
  ```

## Test Status Summary
- **Full Test Suite**: ✅ ALL PASSING (snapshot tests + Mix tests)
- **Elixir Tests**: ✅ ALL PASSING (13 tests in Mix/ExUnit)
- **Haxe Tests**: ✅ ALL PASSING (snapshot tests via TestRunner.hx)
- **CI Status**: ✅ All GitHub Actions checks passing

## Reflaxe Snapshot Testing Architecture ✅

### Testing Approach
Reflaxe.Elixir uses **snapshot testing** following Reflaxe.CPP patterns:

- **TestRunner.hx**: Main test orchestrator that compiles Haxe files and compares output
- **test/tests/** directory structure with `compile.hxml` and `intended/` folders per test
- **Snapshot comparison**: Generated Elixir code compared against expected output files
- **Dual ecosystem**: Haxe compiler tests + separate Mix tests for runtime validation

### Test Structure
```
test/
├── TestRunner.hx          # Main test runner (Reflaxe snapshot pattern)
├── Test.hxml             # Entry point configuration
└── tests/
    ├── test_name/
    │   ├── compile.hxml  # Test compilation config
    │   ├── Main.hx       # Test source
    │   ├── intended/     # Expected Elixir output
    │   └── out/          # Generated output (for comparison)
```

### Key Commands
- `npm test` - Run all tests via TestRunner.hx
- `haxe test/Test.hxml test=name` - Run specific test
- `haxe test/Test.hxml update-intended` - Update expected output files
- `haxe test/Test.hxml show-output` - Show compilation details

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

## Testing Quick Reference

→ **CRITICAL: Test code modification rules**: See [`documentation/TESTING_PRINCIPLES.md`](documentation/TESTING_PRINCIPLES.md#never-remove-test-code-to-fix-failures)
→ **All testing rules and patterns**: See [`documentation/TESTING_PRINCIPLES.md`](documentation/TESTING_PRINCIPLES.md)
→ **Primary command**: `npm test` - runs all validation
→ **Architecture details**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md)

## Current Implementation Status Summary

### v1.0 ESSENTIAL Tasks Status (2/4 Complete - 50%)

✅ **1. Essential Elixir Protocol Support** - COMPLETE
   - ProtocolCompiler.hx fully implemented
   - @:protocol and @:impl annotations working
   - Examples in 07-protocols demonstrate functionality

✅ **2. Create Essential Standard Library Extern Definitions** - COMPLETE
   - All 9 essential modules implemented (Process, Registry, Agent, IO, File, Path, Enum, String, GenServer)
   - Full type-safe extern definitions with helper functions
   - Comprehensive test coverage

❌ **3. Implement Haxe Typedef Compilation Support** - PENDING
   - compileTypedef() method returns null with TODO
   - Needed for type aliases commonly used in Elixir

❌ **4. Add Essential OTP Supervision Patterns** - PARTIALLY COMPLETE
   - Registry ✅ (completed as part of stdlib externs)
   - Supervisor ❌ (needs extern implementation)
   - Task/Task.Supervisor ❌ (needs extern implementation)

**For complete feature status, example guides, and usage instructions, see:**
- [`documentation/FEATURES.md`](documentation/FEATURES.md) - Production readiness status
- [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md) - Working example walkthroughs  
- [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md) - Annotation usage guide

**Quick Status**: 14+ production-ready features, 9 working examples, 37/37 tests passing.

## Task Completion and Documentation Protocol

### CRITICAL AGENT INSTRUCTION ⚠️
After completing and verifying any task, you MUST:

1. **Update TASK_HISTORY.md** with comprehensive session documentation including:
   - Context and problem identification
   - Detailed implementation steps
   - Technical insights gained
   - Files modified
   - Key achievements
   - Development insights
   - Session summary with status

2. **Document task completion** before finalizing the session

This ensures:
- ✅ **Knowledge preservation** across development sessions
- ✅ **Context continuity** for future development
- ✅ **Quality tracking** and process improvement
- ✅ **Comprehensive project history** for team collaboration

**Example Pattern**:
```
## Session: [Date] - [Task Description]
### Context: [Problem/Request background]
### Tasks Completed ✅: [Detailed implementation list]
### Technical Insights Gained: [Architecture/pattern learnings]
### Files Modified: [Complete file change list]
### Key Achievements ✨: [Impact and value delivered]
### Session Summary: [Status and completion confirmation]
```

**NEVER skip task history documentation** - it's as important as the implementation itself.