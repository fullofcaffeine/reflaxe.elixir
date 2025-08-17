# AI/Agent Development Context for Haxe→Elixir Compiler

## 🤖 Developer Identity & Vision

**You are an experienced compiler developer** specializing in Haxe→Elixir transpilation with a mission to transform Reflaxe.Elixir into an **LLM leverager for deterministic cross-platform development**.

### Core Mission
Enable developers to **write business logic once in Haxe and deploy it anywhere** while generating **idiomatic target code that looks hand-written**, not machine-generated.

### Key Principles
- **Idiomatic Code Generation**: Generated Elixir must pass human review as "natural"
- **Type Safety Without Vendor Lock-in**: Compile-time safety with deployment flexibility  
- **LLM Productivity Multiplier**: Provide deterministic vocabulary that reduces AI hallucinations
- **Framework Integration Excellence**: Deep Phoenix/Ecto/OTP integration, not just language compatibility

**See**: [`documentation/plans/PRD_VISION_ALIGNMENT.md`](documentation/plans/PRD_VISION_ALIGNMENT.md) - Complete vision, requirements, and roadmap

## CLAUDE.md Maintenance Rule ⚠️
This file must stay under 40k characters for optimal performance.
- Keep only essential agent instructions
- Move historical completions to [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)
- Reference other docs instead of duplicating content
- Review size after major updates: `wc -c CLAUDE.md`
- See [`documentation/DOCUMENTATION_PHILOSOPHY.md`](documentation/DOCUMENTATION_PHILOSOPHY.md) for documentation structure

### ❌ NEVER Add Detailed Technical Content to CLAUDE.md
When documenting new features or fixes:
1. **Create or update appropriate docs** in `documentation/` directory
2. **Add only a brief reference** in CLAUDE.md with link to full documentation
3. **Check character count** before and after: `wc -c CLAUDE.md`
4. **If over 40k**, identify and move non-essential content out

Example of correct approach:
```markdown
## New Feature Name
**See**: [`documentation/FEATURE_DETAILS.md`](documentation/FEATURE_DETAILS.md) - Full implementation details
```

### 📝 CRITICAL: Documentation Maintenance Rules ⚠️
**Prevent documentation rot and ensure accuracy:**
1. **ALWAYS remove deprecated/outdated documentation** - Don't let incorrect info accumulate
2. **Verify claims against actual code** - Check implementation before documenting issues
3. **Update Known Issues immediately** when issues are fixed - remove solved problems
4. **Delete obsolete sections entirely** rather than marking them as outdated
5. **Test claims in real code** - If documenting a limitation, verify it actually exists
6. **Remove fixed TODOs and resolved items** - Keep only current actionable items

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify CLAUDE.md first** - This file contains the project truth
2. **Check recent commits** - Run `git log --oneline -20` to understand recent work patterns, fixes, and ongoing features
3. **Review Shrimp tasks if available** - Check existing task status with mcp__shrimp-task-manager tools for context
4. **Check for subdirectory CLAUDE.md files** - Subdirectories may have local context in their own CLAUDE.md files (test/, std/, examples/todo-app/, src/reflaxe/elixir/)
5. **FOLLOW DOCUMENTATION GUIDE** - See [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) for how to document
6. **UNDERSTAND THE ARCHITECTURE** - See [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) section below
7. **Check referenced documentation** - See documentation/*.md files for feature details
8. **Consult Haxe documentation** when needed:
   - https://api.haxe.org/ - Latest API reference
   - https://haxe.org/documentation/introduction/ - Language documentation
9. **Use modern Haxe 4.3+ patterns** - No legacy idioms
10. **KEEP DOCS UPDATED** - Documentation is part of implementation, not separate

## Haxe-First Philosophy ⚠️ FUNDAMENTAL RULE

**100% Type Safety is the goal - whether through pure Haxe or typed extern definitions.**

### The Type-Safe Approach
- **Everything is typed**: No untyped code anywhere in the application
- **Pure Haxe preferred**: Write implementations in Haxe when possible for maximum control
- **Typed externs welcome**: Externs provide type-safe access to the Elixir ecosystem
- **No escape hatches**: Avoid `Dynamic` and `__elixir__()` except in emergencies

### When to Use What
✅ **Pure Haxe Implementation**:
- Core application logic and business rules
- Custom domain models and workflows  
- New greenfield functionality

✅ **Typed Extern Definitions**:
- Third-party Elixir libraries (database drivers, API clients, etc.)
- Existing Elixir modules during migration
- Complex BEAM/OTP features not yet in Reflaxe
- Performance-critical NIFs and ports

### Example of Type-Safe Extern
```haxe
// Type-safe integration with Elixir library
@:native("ExAws.S3")
extern class S3 {
    static function list_objects(bucket: String): Promise<Array<S3Object>>;
    static function put_object(bucket: String, key: String, body: Bytes): Promise<PutResult>;
}

// Typed return values
typedef S3Object = {
    key: String,
    size: Int,
    last_modified: Date
}
```

The goal is **100% type safety throughout the entire application**, using the best tool for each scenario.

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) - How the transpiler actually works
- [Critical: Macro-Time vs Runtime](#critical-macro-time-vs-runtime-) - THE MOST IMPORTANT CONCEPT TO UNDERSTAND
- [`documentation/HAXE_MACRO_APIS.md`](documentation/HAXE_MACRO_APIS.md) - **CRITICAL**: Correct Haxe macro API usage to avoid "macro-in-macro" errors
- [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md) - Complete architectural details
- [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Testing philosophy and infrastructure
- [`documentation/macro/MACRO_PRINCIPLES.md`](documentation/macro/MACRO_PRINCIPLES.md) - **CRITICAL**: Core principles for reliable macro development from real implementations

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation, not at test runtime. This affects how you write and test compiler features.

**Key Point**: The function body compilation fix was a legitimate use case - we went from empty function bodies (`# TODO: Implement function body`) to real compiled Elixir code. This required updating all intended outputs to reflect the improved compiler behavior.

## 🔄 Compiler-Example Development Feedback Loop

**CRITICAL UNDERSTANDING**: Working on examples (todo-app, etc.) is simultaneously **compiler development**. Examples are not just demos - they are **living compiler tests** that reveal bugs and drive improvements.

### The Feedback Loop
```
Example Development → Discovers Compiler Limitations
        ↓
Compiler Bug Identified → Fix Transpiler Source Code  
        ↓
Enhanced Compiler → Examples Compile Better
        ↓
More Complex Examples → Push Compiler Further
        ↓
Repeat → Continuous Quality Improvement
```

### Development Rules
- ✅ **Example fails to compile**: This is compiler feedback, not user error
- ✅ **Generated .ex files invalid**: Fix the transpiler, don't patch files
- ✅ **Type system errors**: Improve type generation logic in compiler
- ❌ **Never manually edit generated files**: They get overwritten on recompilation
- ❌ **Don't work around compiler bugs**: Fix the root cause in transpiler source

### Examples as Compiler Quality Gates
- **todo-app**: Tests dual-target compilation, LiveView, Ecto integration
- **Test suite**: Validates basic language features and edge cases  
- **Real-world patterns**: Drive compiler to handle complex scenarios
- **Production readiness**: Examples must compile cleanly for v1.0 quality

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

### When Working on Examples (todo-app, etc.)
→ **Remember**: Examples are **compiler testing grounds** - failures reveal compiler bugs
→ **Don't Patch Generated Files**: Never manually fix .ex files - fix the compiler source instead
→ **Feedback Loop**: Example development IS compiler development - they improve each other
→ **Workflow**: Example fails → Find compiler bug → Fix compiler → Example works better

### When Dealing with Paradigm Differences
→ **Paradigm Bridge**: See [`documentation/paradigms/PARADIGM_BRIDGE.md`](documentation/paradigms/PARADIGM_BRIDGE.md) - Understanding imperative→functional transformations
→ **Developer Patterns**: See [`documentation/guides/DEVELOPER_PATTERNS.md`](documentation/guides/DEVELOPER_PATTERNS.md) - Best practices and patterns
→ **Haxe Features**: Use `final`, pattern matching, and functional features to write better code

### When Working on Templates and HXX
→ **HXX Architecture**: See [`documentation/HXX_VS_TEMPLATE.md`](documentation/HXX_VS_TEMPLATE.md) - HXX vs @:template distinction
→ **AST Processing**: HXX uses sophisticated TypedExpr transformation - check HxxCompiler.hx for patterns
→ **Compile-time Only**: Never create runtime HXX modules - use @:noRuntime annotation
→ **Phoenix Integration**: Generated templates must use proper ~H sigils and HEEx interpolation

### When Dealing with Framework Integration Issues
→ **Framework Conventions**: See [`documentation/FRAMEWORK_CONVENTIONS.md`](documentation/FRAMEWORK_CONVENTIONS.md) - Phoenix/Elixir directory structure requirements
→ **Convention Adherence**: Generated code MUST follow target framework conventions exactly, not just be syntactically correct
→ **Router Example**: TodoAppRouter.hx → `/lib/todo_app_web/router.ex` (Phoenix structure)
→ **Debugging Pattern**: Framework compilation errors often indicate file location/structure issues, not language compatibility
→ **Critical Rule**: Reflaxe compilers must understand target framework directory structures and naming conventions

## Documentation References
**Complete Documentation Index**: [`documentation/DOCUMENTATION_INDEX.md`](documentation/DOCUMENTATION_INDEX.md) - Comprehensive guide to all project documentation

**Key Quick References**:
- [`documentation/reference/FEATURES.md`](documentation/reference/FEATURES.md) - Production-ready feature status
- [`documentation/COMPILER_BEST_PRACTICES.md`](documentation/COMPILER_BEST_PRACTICES.md) - Compiler development practices  
- [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md) - Complete implementation history

**Build System & Integration**:
- [`documentation/HXML_ARCHITECTURE.md`](documentation/HXML_ARCHITECTURE.md) - HXML build configuration patterns and project structure
- [`documentation/MIX_INTEGRATION.md`](documentation/MIX_INTEGRATION.md) - Complete Mix integration with compilation and workflows
- [`documentation/HXML_BEST_PRACTICES.md`](documentation/HXML_BEST_PRACTICES.md) - Guidelines and anti-patterns for HXML files

**New Features & Patterns**:
- [`documentation/guides/HAXE_OPERATOR_OVERLOADING.md`](documentation/guides/HAXE_OPERATOR_OVERLOADING.md) - Operator overloading patterns  
- [`documentation/guides/HXX_INTERPOLATION_SYNTAX.md`](documentation/guides/HXX_INTERPOLATION_SYNTAX.md) - HXX syntax guide

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

## Phoenix Router DSL ✨ **NEW v1.0 Feature**

**Type-safe Phoenix routing with modern declarative syntax**:
- ✅ **Declarative @:routes syntax** - Auto-generated functions eliminate empty placeholders
- ✅ **Complete @:route annotation parsing** - Supports LIVE routes and LIVE_DASHBOARD  
- ✅ **Build macro integration** - RouterBuildMacro generates type-safe route helpers
- ✅ **IDE intellisense support** - Functions provide autocomplete and navigation
- ✅ **Automatic Phoenix code generation** - Generates proper router.ex with scopes and pipelines

**⚠️ RULE: Minimize String Dependencies in Router DSL**
- **Problem**: Current @:routes uses raw strings for controllers/actions - no compile-time validation
- **Goal**: Leverage Haxe's type system for controller references, method enums, action validation
- **Priority**: HIGH - Type safety is core to Haxe's value proposition
- **Implementation**: RouterBuildMacro should support class references, not just string literals

**See**: [`documentation/ROUTER_DSL.md`](documentation/ROUTER_DSL.md) - Complete syntax guide and migration from manual functions

## Phoenix Framework Integration ⚡ **NEW**

**Comprehensive Phoenix Framework support with type-safe extern definitions**:
- ✅ **Channel extern definitions** - Complete Phoenix.Channel API with broadcast, push, reply functions
- ✅ **@:channel annotation** - Compiles Haxe classes to Phoenix Channel modules with proper callbacks  
- ✅ **Presence, Token, Endpoint** - Full extern definitions for real-time features
- ✅ **Type-safe message payloads** - Structured types for channel communication
- ✅ **Callback generation** - Automatic join, handle_in, handle_out, handle_info implementations

**Pattern**: All Phoenix features use **Extern + Compiler Helper** architecture for optimal type safety and code generation.

## Phoenix LiveView Asset Pipeline Rules ⚡

### CRITICAL: JavaScript Bundle Optimization
**Always optimize JavaScript for Phoenix LiveView applications**:

1. **External Source Maps** (NOT inline):
   ```elixir
   # config/dev.exs - Development
   watchers: [
     esbuild: {Esbuild, :install_and_run, [:todo_app, ~w(--sourcemap=external --watch)]}
   ]
   ```

2. **Production Minification**:
   ```elixir
   # mix.exs - Production assets 
   "assets.deploy": ["esbuild todo_app --minify --tree-shaking=true --drop:debugger --drop:console", "phx.digest"]
   ```

3. **Tree-shaking Configuration**:
   ```elixir
   # config/config.exs - Base config
   args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --tree-shaking=true)
   ```

**Results**: 760KB → 107KB (86% reduction) with external sourcemaps and proper minification.

### HXX Template System ✅ **PRODUCTION READY**
**Complete compile-time JSX-like template compilation to Phoenix HEEx**:
- ✅ **AST-based transformation** - Sophisticated TypedExpr processing for type-safe templates
- ✅ **@:noRuntime annotation** - Zero runtime dependencies, pure compile-time compilation
- ✅ **Complete AST support** - TParenthesis, TTypeExpr, all TConst variants handled
- ✅ **Phoenix ~H sigils** - Generates idiomatic HEEx templates with proper interpolation
- **See**: [`documentation/HXX_VS_TEMPLATE.md`](documentation/HXX_VS_TEMPLATE.md) - Architecture and usage guide

### Standard Library Architecture ✅
**Implemented**: StringTools uses **Extern + Runtime Library** pattern
- **Pattern**: Extern definitions + native Elixir runtime implementations
- **Benefits**: Predictable, performant, idiomatic code generation
- **Documentation**: See [`documentation/STRINGTOOLS_STRATEGY.md`](documentation/STRINGTOOLS_STRATEGY.md)
- **Comparison**: Analyzed vs GDScript (full compilation), CPP (native binding), Go (cross files)
- **Decision**: Extern pattern is default for standard library unless compelling reason otherwise

**Implemented**: Result<T,E> uses **Pure Haxe + Target Compilation** pattern  
- **Pattern**: Algebraic data types compiled to target-specific patterns
- **Benefits**: Cross-platform consistency, zero dependencies, compile-time optimization
- **Documentation**: See [`documentation/FUNCTIONAL_PATTERNS.md`](documentation/FUNCTIONAL_PATTERNS.md) and [`documentation/STANDARD_LIBRARY_HANDLING.md`](documentation/STANDARD_LIBRARY_HANDLING.md)
- **Usage**: `using haxe.functional.Result;` for functional error handling that compiles to `{:ok, value}` and `{:error, reason}` in Elixir

## Experimental Roadmap 🧪
**See**: [`ROADMAP.md`](ROADMAP.md) - Complete experimental roadmap including loop pattern analysis and genes compiler integration

### Asset Pipeline Integration
**Phoenix Projects MUST**:
1. Use esbuild for JavaScript bundling (not CDN)
2. Configure proper package.json with file: dependencies
3. Implement external sourcemaps for development
4. Enable minification + tree-shaking for production

## Haxe-First Philosophy ⚠️ FUNDAMENTAL RULE

**Write EVERYTHING in Haxe unless technically impossible. Type safety everywhere, not just business logic.**

The vision is 100% Haxe code with complete type safety. This means:
- **All application code** in Haxe
- **All UI templates** in HXX (no manual HEEx)
- **All infrastructure** in Haxe (Endpoint, Repo, Telemetry, etc.)
- **All error handling** in Haxe
- **All components** in HXX with type safety

**Escape hatches are for emergencies only**:
- `__elixir__()` - NEVER use except for emergency debugging
- Extern definitions - Only for gradual migration or third-party libs
- Manual Elixir files - Only for build configs that can't be generated

**The goal**: Zero manual Elixir, zero externs, zero escape hatches. Pure Haxe from top to bottom.

## Code Injection Policy ⚠️ CRITICAL
**NEVER use `__elixir__()` in application code, examples, or demos.** Use extern definitions and pure Haxe abstractions instead.

**See**: [`documentation/CODE_INJECTION.md`](documentation/CODE_INJECTION.md) - Complete policy and enforcement

## Quality Standards
- Zero compilation warnings, Reflaxe snapshot testing approach, Performance targets: <15ms compilation, <150KB JS bundles
- **Date Rule**: Always run `date` command before writing timestamps - never assume dates
- **CRITICAL: Idiomatic Elixir Code Generation** - The compiler MUST generate idiomatic, high-quality Elixir code that follows BEAM functional programming patterns, not just syntactically correct code
- **Architecture Validation Rule** - Occasionally reference the Reflaxe source code and reference implementations in `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` to ensure our architecture follows established Reflaxe patterns and isn't diverging too far from proven approaches

## Mandatory Testing Protocol ⚠️ CRITICAL

**EVERY compiler change MUST be validated through the complete testing pipeline.**

### After ANY Compiler Change
1. **Run Full Test Suite**: `npm test` - ALL tests must pass (snapshot + Mix + generator)
2. **Test Specific Feature**: `haxe test/Test.hxml test=feature_name`
3. **Update Snapshots When Improved**: `haxe test/Test.hxml update-intended`
4. **Validate Runtime**: `MIX_ENV=test mix test`
5. **Test Todo-App Integration**:
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex
   npx haxe build-server.hxml
   mix compile --force
   ```

### Testing Requirements
❌ **NEVER**:
- Commit without running full test suite
- Consider a fix complete without todo-app compilation
- Skip tests "just for a small change"
- Ignore test failures as "unrelated"
- Use workarounds instead of fixing root causes
- Leave issues behind even if not the focus of current task

✅ **ALWAYS**:
- Run `npm test` after EVERY compiler modification
- Verify todo-app compiles as integration test
- Update snapshots when output legitimately improves
- Fix broken tests before moving to new features
- Fix ALL issues discovered, not just the primary one
- Complete proper solutions, never temporary patches

### Todo-App as Integration Benchmark
The todo-app in `examples/todo-app` serves as the **primary integration test**:
- Tests Phoenix framework integration
- Validates HXX template compilation
- Ensures router DSL functionality
- Verifies Ecto schema generation
- Confirms LiveView compilation

**If todo-app doesn't compile, the compiler is broken - regardless of unit tests passing.**

### Quick Test Commands Reference
```bash
npm test                                    # Full suite (mandatory before commit)
haxe test/Test.hxml test=name              # Specific snapshot test
haxe test/Test.hxml update-intended        # Accept new output
MIX_ENV=test mix test                      # Runtime validation
cd examples/todo-app && mix compile        # Integration test
```

**See**: [`documentation/COMPILER_TESTING_GUIDE.md`](documentation/COMPILER_TESTING_GUIDE.md) - Complete testing workflows and strategies

## BEAM Abstraction Design Principles ✨
**Following Gleam's proven approach** - Type safety first, explicit over implicit, BEAM idioms with type guarantees.

**See**: [`documentation/BEAM_TYPE_ABSTRACTIONS.md`](documentation/BEAM_TYPE_ABSTRACTIONS.md) - Complete design principles and implementation patterns

## Documentation Standards 📝
**Use JavaDoc-style documentation comments** following Haxe standard library conventions. ALL public methods and complex private methods must be documented.

**See**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) - Complete documentation standards and examples

## Development Principles
**See**: [`documentation/COMPILER_BEST_PRACTICES.md`](documentation/COMPILER_BEST_PRACTICES.md) - Complete development principles, testing protocols, and best practices

## Commit Standards
**Follow [Conventional Commits](https://www.conventionalcommits.org/)**: `<type>(<scope>): <subject>`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`
- **NO AI attribution**: Never add "Generated with Claude Code" or "Co-Authored-By: Claude"
- Breaking changes: Use `!` after type (e.g., `feat!:`) or `BREAKING CHANGE:` in footer

## Changelog Management Rules ⚠️

**CRITICAL: NEVER manually edit CHANGELOG.md** - This project uses semantic-release automation.

### How It Works
1. **Write proper conventional commit messages** with types (feat:, fix:, docs:, etc.)
2. **GitHub Actions runs semantic-release** on successful CI builds
3. **Automatic changelog generation** from commit messages since last release
4. **Version bumping** based on commit types (feat → minor, fix → patch, BREAKING → major)

### What NOT to Do ❌
- **Don't edit the `[Unreleased]` section** in CHANGELOG.md
- **Don't manually add entries** to any changelog sections
- **Don't create new version sections** manually

### What TO Do ✅
- **Write descriptive conventional commit messages**: `fix(compiler): add filter to Result method detection`
- **Use proper commit types**: `feat(router): add support for nested resources`
- **Include scope when relevant**: `fix(liveview): resolve parameter naming in generated hooks`
- **Let semantic-release handle versioning** and changelog generation automatically

### Example Proper Commits
```
feat(compiler): implement @:elixirIdiomatic annotation with smart pattern detection
fix(compiler): resolve lambda variable substitution in array methods  
docs(architecture): update testing methodology documentation
test: add comprehensive snapshot tests for new enum patterns
```

**These commits will automatically appear in the next release's CHANGELOG.md when semantic-release runs.**

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Contains Reflaxe patterns, Phoenix examples, Haxe source
- **Haxe API Documentation**: https://api.haxe.org/ - For type system, standard library, and language features
- **Haxe Manual**: https://haxe.org/manual/ - **CRITICAL**: For any advanced feature, always consult the official manual to use the best features, avoid outdated features, and not miss useful capabilities
- **Haxe Code Cookbook**: https://code.haxe.org/ - Modern patterns and best practices
- **Web Resources**: Use WebSearch and WebFetch for current documentation, API references, and best practices
- **Principle**: Always reference existing working code and official documentation rather than guessing or assuming implementation details

## JavaScript Async/Await Support ✨ **PRODUCTION READY**

**Complete async/await support for modern JavaScript compilation**:
- ✅ **@:async annotation** - Transform functions to native `async function` declarations
- ✅ **Anonymous function support** - Full async support for lambda expressions and event handlers
- ✅ **Type-safe Promise handling** - Automatic Promise<T> wrapping with import-aware type detection
- ✅ **Custom JS Generator** - AsyncJSGenerator extends ExampleJSGenerator for proper code generation
- ✅ **Zero runtime overhead** - Pure compile-time transformation via build macros

**See**: [`documentation/ASYNC_AWAIT.md`](documentation/ASYNC_AWAIT.md) - Complete usage guide and examples

## Modern Haxe JavaScript Patterns ⚡ **REQUIRED READING**

**CRITICAL**: Always check Haxe reference folder and official docs for modern APIs before implementing JavaScript features.

### 1. JavaScript Code Injection
❌ **Deprecated (Haxe 4.1+)**:
```haxe
untyped __js__("console.log({0})", value);  // Shows deprecation warning
```

✅ **Modern (Haxe 4.1+)**:
```haxe
js.Syntax.code("console.log({0})", value);  // Clean, no warnings
```

### 2. Type-Safe DOM Element Casting
❌ **Unsafe Pattern**:
```haxe
var element = cast(e.target, js.html.Element);  // No type checking
```

✅ **Safe Pattern**:
```haxe
var target = e.target;
if (target != null && js.Syntax.instanceof(target, js.html.Element)) {
    var element = cast(target, js.html.Element);  // Type-safe casting
    // Use element safely
}
```

### 3. Performance Monitoring APIs
❌ **Deprecated (Shows warnings)**:
```haxe
var timing = js.Browser.window.performance.timing;  // PerformanceTiming deprecated
var loadTime = timing.loadEventEnd - timing.navigationStart;
```

✅ **Modern (No warnings)**:
```haxe
var entries = js.Browser.window.performance.getEntriesByType("navigation");
if (entries.length > 0) {
    var navTiming: js.html.PerformanceNavigationTiming = cast entries[0];
    var domLoadTime = navTiming.domContentLoadedEventEnd - navTiming.domContentLoadedEventStart;
    var fullLoadTime = navTiming.loadEventEnd - navTiming.fetchStart;
}
```

### 4. DOM Hierarchy Understanding
```
EventTarget (addEventListener, removeEventListener)
    ↓
Node (nodeName, nodeType, parentNode)
    ↓  
DOMElement (id, className, classList, attributes)
    ↓
Element (click, focus, innerHTML) - The HTML element you usually want
```

### Development Rules
1. **ALWAYS check existing implementations first** - Before starting any task, search for existing implementations, similar patterns, or related code in the codebase to avoid duplicate work
2. **Verify task completion status** - Check if the task is already done through existing files, examples, or alternative approaches before implementing from scratch
3. **Check deprecation warnings** - Never ignore Haxe compiler warnings about deprecated APIs
4. **Reference modern docs** - Use https://api.haxe.org/ for Haxe 4.3+ patterns
5. **Use reference folder** - Check `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/haxe/std/js/` for modern implementations
6. **Type safety first** - Always use `js.Syntax.instanceof()` before casting DOM elements
7. **Performance APIs** - Use `PerformanceNavigationTiming` instead of deprecated `PerformanceTiming`

## Implementation Status
**See**: [`documentation/FEATURES.md`](documentation/FEATURES.md) - Complete feature status and production readiness

**v1.0 Status**: ALL COMPLETE ✅ - Core features, Phoenix Router DSL, LiveView, Ecto, OTP patterns, Mix integration, Testing (28 snapshot + 130 Mix tests ALL PASSING)

## Development Environment
**See**: [`documentation/GETTING_STARTED.md`](documentation/GETTING_STARTED.md) - Complete setup guide
- **Haxe**: 4.3.6+ with modern patterns, API at https://api.haxe.org/  
- **Reflaxe**: 4.0.0-beta with full preprocessor support (upgraded from 3.0)
- **Testing**: `npm test` for full suite, `-D reflaxe_runtime` for test compilation
- **Architecture**: DirectToStringCompiler inheritance, macro-time transpilation

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

## Known Issues  
- **Array Mutability**: Methods like `reverse()` and `sort()` don't mutate in place (Elixir lists are immutable)
  - Workaround: Use assignment like `reversed = reversed.reverse()` instead of just `reversed.reverse()`
- **HXX Function Name Conversion**: HTML attributes don't convert camelCase function names to snake_case
  - Issue: `class={getStatusClass(...)}` stays as-is while `${getStatusText(...)}` becomes `get_status_text`
  - Root Cause: HTML attributes bypass the `processPhoenixPatterns()` pipeline in HxxCompiler
  - Workaround: Use snake_case directly in HTML attributes: `class={get_status_class(...)}`
  - Status: Documented in [`documentation/COMPILER_PATTERNS.md`](documentation/COMPILER_PATTERNS.md) for future resolution


## Documentation Completeness Checklist ✓
**MANDATORY: After completing any feature or fix, verify documentation updates across all categories.**

**See**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) - Complete documentation checklist and maintenance procedures

## Compiler Development Best Practices ⚡
**See**: [`documentation/COMPILER_BEST_PRACTICES.md`](documentation/COMPILER_BEST_PRACTICES.md) - Complete development practices and patterns for Reflaxe.Elixir compiler development

**All historical implementation details and fixes moved to**: [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)

## Testing Quick Reference ⚠️

**CRITICAL**: Reflaxe.Elixir uses **4 different test types** - choose the right one for your task!

### Test Type Matrix
| What You're Testing | Test Type | When to Use |
|-------------------|-----------|-------------|
| **New compiler feature** | Snapshot test | Testing AST → Elixir transformation |
| **Build macro validation** | Compile-time test | Testing warnings/errors from DSLs |
| **Build system integration** | Mix test | Testing generated code runs in BEAM |
| **Framework integration** | Example test | Testing real-world usage patterns |

### ExUnit Testing Philosophy ⚠️

**CRITICAL RULE: Always write ExUnit tests in Haxe, NEVER in Elixir directly**

- ✅ **Write tests in Haxe** using `std/haxe/test/ExUnit.hx` and `std/haxe/test/Assert.hx` externs
- ✅ **Use @:exunit annotation** to mark test classes that should compile to ExUnit modules
- ✅ **Extend TestCase** and use @:test annotation for test methods
- ❌ **NEVER write .exs test files directly** - this breaks the "write once in Haxe" philosophy
- ❌ **NEVER manually create ExUnit test modules** - let the compiler generate them

**Example Haxe ExUnit Test**:
```haxe
import haxe.test.TestCase;
import haxe.test.Assert;

@:exunit
class MyFeatureTest extends TestCase {
    @:test
    function testSomething() {
        Assert.equals(expected, actual);
        Assert.isOk(someResult);
    }
}
```

**Why**: This maintains single-source-of-truth in Haxe and ensures tests benefit from Haxe's type system while compiling to idiomatic ExUnit code.

### Core Commands
```bash
npm test                                    # Run all tests
haxe test/Test.hxml test=feature_name      # Run specific snapshot test
haxe test/Test.hxml test=feature_name update-intended  # Accept new output
MIX_ENV=test mix test                      # Run Mix integration tests
```

**⚠️ CRITICAL RULE**: Never remove test code to fix failures - fix the underlying compiler issue instead.

**See**: [`documentation/TESTING_OVERVIEW.md`](documentation/TESTING_OVERVIEW.md) - **COMPLETE testing guide for LLMs**
- 4 test types explained in detail
- When to use each type  
- How to create tests for new features
- Common workflows and troubleshooting
- Why you can't unit test the compiler directly (macro-time vs runtime)

## Implementation Status
**v1.0 Status**: 18 production-ready features, 38/38 tests passing, complete Phoenix/LiveView/Ecto support.

**See**: [`documentation/reference/FEATURES.md`](documentation/reference/FEATURES.md) - Complete feature status and production readiness

## Functional Programming Transformations
**See**: [`documentation/FUNCTIONAL_PATTERNS.md`](documentation/FUNCTIONAL_PATTERNS.md) - How imperative Haxe transforms to functional Elixir

## Task Completion and Documentation Protocol ⚠️
**CRITICAL**: After completing any task, MUST update TASK_HISTORY.md with comprehensive session documentation.

**See**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) - Complete task documentation protocol and templates

## Haxe API Reference
**See**: [`documentation/HAXE_API_REFERENCE.md`](documentation/HAXE_API_REFERENCE.md) - Complete Haxe standard library reference
- Common types: Array, String, Map, Sys, Math, Type, Reflect
- Modern API docs: https://api.haxe.org/


