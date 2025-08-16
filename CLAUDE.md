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

### When Dealing with Framework Integration Issues
→ **Framework Conventions**: See [`documentation/FRAMEWORK_CONVENTIONS.md`](documentation/FRAMEWORK_CONVENTIONS.md) - Phoenix/Elixir directory structure requirements
→ **Convention Adherence**: Generated code MUST follow target framework conventions exactly, not just be syntactically correct
→ **Router Example**: TodoAppRouter.hx → `/lib/todo_app_web/router.ex` (Phoenix structure)
→ **Debugging Pattern**: Framework compilation errors often indicate file location/structure issues, not language compatibility
→ **Critical Rule**: Reflaxe compilers must understand target framework directory structures and naming conventions

## User Documentation References

### Core Documentation
- **Project Overview**: See [README.md](README.md) for project introduction and public interface
- **LLM Documentation Guide**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) 📚
- **Setup & Installation**: [`documentation/GETTING_STARTED.md`](documentation/GETTING_STARTED.md)
- **Mix Integration**: [`documentation/MIX_INTEGRATION.md`](documentation/MIX_INTEGRATION.md) ⚡
- **Feature Status**: [`documentation/FEATURES.md`](documentation/FEATURES.md)
- **Annotations**: [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md)
- **Examples**: [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md)
- **Architecture**: [`documentation/ARCHITECTURE.md`](documentation/ARCHITECTURE.md)
- **Testing**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md)
- **Development Tools**: [`documentation/DEVELOPMENT_TOOLS.md`](documentation/DEVELOPMENT_TOOLS.md)
- **Task History**: [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)

### Paradigm & Development Guides ✨ **NEW**
- **Paradigm Bridge**: [`documentation/paradigms/PARADIGM_BRIDGE.md`](documentation/paradigms/PARADIGM_BRIDGE.md) - How Haxe's imperative patterns translate to Elixir's functional world
- **Haxe for Phoenix**: [`documentation/phoenix/HAXE_FOR_PHOENIX.md`](documentation/phoenix/HAXE_FOR_PHOENIX.md) - Advantages of using Haxe for Phoenix development
- **Developer Patterns**: [`documentation/guides/DEVELOPER_PATTERNS.md`](documentation/guides/DEVELOPER_PATTERNS.md) - Best practices and patterns for effective Haxe→Elixir code

### Macro Development Guides ✨ **NEW**
- **Macro Principles**: [`documentation/macro/MACRO_PRINCIPLES.md`](documentation/macro/MACRO_PRINCIPLES.md) - Core principles for developing reliable Haxe macros based on proven implementations
- **Macro Patterns**: [`documentation/macro/MACRO_PATTERNS.md`](documentation/macro/MACRO_PATTERNS.md) - Reusable patterns and code templates for common macro development tasks
- **Macro Debugging**: [`documentation/macro/MACRO_DEBUGGING.md`](documentation/macro/MACRO_DEBUGGING.md) - Comprehensive debugging strategies for troubleshooting macro transformations and AST processing
- **Macro Case Studies**: [`documentation/macro/MACRO_CASE_STUDIES.md`](documentation/macro/MACRO_CASE_STUDIES.md) - Deep-dive analysis of real macro implementations including async/await anonymous function support

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

### HXX Compile-Time Architecture ✅
**HXX is compile-time only** - never create runtime HXX.ex modules:
- ✅ **HXX templates** compile to HEEx at build time
- ❌ **HXX.ex runtime modules** are unnecessary and should be removed
- 🎯 **Pattern**: Template compilation happens during Haxe transpilation, not at runtime

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

### 1. Comprehensive Loop Pattern Analysis 🔄 **PRIORITY**
**Enhance loop compilation with intelligent pattern detection**:
- **Why**: Transform imperative Haxe loops into idiomatic functional Elixir code
- **Patterns to detect**:
  - **Counting patterns** → `Enum.count/2`
  - **Filtering patterns** → `Enum.filter/2`
  - **Mapping patterns** → `Enum.map/2`
  - **Accumulation patterns** → `Enum.reduce/3`
  - **Find patterns** → `Enum.find/3`
  - **All/Any patterns** → `Enum.all?/2`, `Enum.any?/2`
- **Implementation**: Analyze loop body AST for mutation patterns and transform accordingly
- **Status**: Critical for todo-app and general usability
- **Impact**: Eliminates invalid Elixir code generation, produces idiomatic functional code

### 2. Modern Haxe-to-JS with Genes Compiler
**Replace standard Haxe JS compilation with [genes](https://github.com/benmerckx/genes)**:
- **Why**: Modern JavaScript output, better optimization, smaller bundles
- **Current Issue**: Todo app client (TodoApp.hx) has compilation errors with standard Haxe JS
- **Goals**: 
  - Fix browser API compatibility issues
  - Generate smaller, more efficient client-side code
  - Better integration with Phoenix LiveView hooks
- **Status**: Experimental - needs investigation and testing
- **Impact**: Could significantly reduce client-side JavaScript bundle sizes

### Asset Pipeline Integration
**Phoenix Projects MUST**:
1. Use esbuild for JavaScript bundling (not CDN)
2. Configure proper package.json with file: dependencies
3. Implement external sourcemaps for development
4. Enable minification + tree-shaking for production

## Quality Standards
- Zero compilation warnings, Reflaxe snapshot testing approach, Performance targets: <15ms compilation, <150KB JS bundles
- **Date Rule**: Always run `date` command before writing timestamps - never assume dates
- **CRITICAL: Idiomatic Elixir Code Generation** - The compiler MUST generate idiomatic, high-quality Elixir code that follows BEAM functional programming patterns, not just syntactically correct code
- **Architecture Validation Rule** - Occasionally reference the Reflaxe source code and reference implementations in `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` to ensure our architecture follows established Reflaxe patterns and isn't diverging too far from proven approaches

## Gleam-Inspired BEAM Abstraction Design Principles ✨ **NEW**

**Following [Gleam's proven approach](https://gleam.run/) to type-safe BEAM development**:

1. **Type Safety First** - Sacrifice features that can't be type-safe over untyped flexibility
   - No global mutable state (avoid named processes and global registries)
   - Explicit message types and actor states visible in function signatures
   - Compile-time guarantees over runtime flexibility

2. **Explicit Over Implicit** - Make intentions clear in the type system
   - Use tagged tuples `{:some, value}` instead of `nil` for optional values
   - Explicit error types rather than generic exceptions
   - Clear pattern matching over defensive null checks

3. **BEAM Idioms with Type Guarantees** - Generate idiomatic BEAM code while maintaining compile-time safety
   - Option<T> compiles to `{:some, value}` / `:none` patterns
   - Result<T,E> compiles to `{:ok, value}` / `{:error, reason}` tuples
   - GenServer messages use typed patterns for exhaustive matching

4. **Fault Tolerance Through Types** - Use Result/Option for expected failures, supervision for unexpected ones
   - Option<T> for values that may legitimately be absent
   - Result<T,E> for operations that may fail with known error types
   - Let it crash for programming errors and unexpected conditions

5. **Functional Composition First** - Design APIs for chaining and transformation
   - Full monadic operations (map, flatMap, filter, fold)
   - Collection operations that preserve type safety
   - Seamless conversion between Option and Result types

**Reference**: Gleam's [OTP library](https://hexdocs.pm/gleam_otp/) demonstrates how to build type-safe abstractions over BEAM primitives while maintaining the fault-tolerance benefits of the Actor model.

## Documentation Standards 📝

**Haxe uses JavaDoc-style documentation comments** - Follow Haxe standard library conventions:

### Required Documentation Format
```haxe
/**
 * Brief description of the method/class functionality.
 * 
 * Detailed explanation including:
 * - What the method does
 * - How it fits into the overall architecture
 * - Important patterns or algorithms used
 * - Examples of transformations (for compiler methods)
 * 
 * @param paramName Description of parameter purpose and type
 * @param anotherParam Description with examples if complex
 * @return Description of return value and possible null cases
 * @see RelatedClass or documentation/FILE.md for related information
 */
```

### Documentation Requirements
- **ALL public methods** MUST have comprehensive documentation
- **Complex private methods** (especially pattern matching, transformations) MUST be documented
- **Class-level documentation** MUST explain the purpose and key features
- **Parameter documentation** MUST include purpose, expected format, and edge cases
- **Return value documentation** MUST specify type and null conditions
- **Cross-references** MUST link to related documentation files

### Examples from Standard Library
Haxe's standard library uses this style extensively. See `String.hx`, `Array.hx` for reference patterns.

### Desugaring Documentation
When documenting compiler methods that handle **desugaring reversal**, always include:
- What Haxe pattern is being detected
- What the generated Elixir should look like  
- Example transformation showing before/after code

## Development Principles

### ⚠️ CRITICAL: Test Infrastructure Rule
**NEVER define test infrastructure types in application code**
- **Test types** (Conn, Changeset<T>, LiveView, etc.) belong in the standard library at `/std/phoenix/test/` and `/std/ecto/test/`
- **Applications** should import from standard library: `import phoenix.test.Conn` NOT `typedef Conn = Dynamic`
- **This ensures**: consistency, reusability, proper maintenance, and type safety across all projects
- **Example**: `import ecto.Changeset; var changeset: Changeset<User>` NOT `var changeset: Dynamic`

### ⚠️ CRITICAL: No Simplifications or Workarounds for Testing
**NEVER simplify code just to make tests pass or to bypass compilation issues.**

❌ **Don't**:
- Comment out problematic code "temporarily" 
- Return dummy values to avoid compilation errors
- Skip proper error handling to make tests pass
- Use placeholder values instead of fixing root causes
- Disable features to work around bugs

✅ **Instead**:
- **Fix the root cause** of compilation errors
- **Implement proper error handling** with meaningful messages
- **Address the underlying architectural issue** causing the problem
- **Write comprehensive tests** that validate the actual expected behavior
- **Document why** a particular approach was chosen over alternatives

**Example of Wrong Approach**:
```haxe
// ❌ BAD: Working around Supervisor.startLink compilation error
return {status: "ok", pid: null}; // Simplified for testing
```

**Example of Right Approach**:
```haxe
// ✅ GOOD: Fix the Supervisor extern definition to make startLink work properly
return Supervisor.startLink(children, opts);
```

**Why This Matters**:
- Workarounds mask real problems and create technical debt
- They make the system unreliable in production environments
- They prevent proper learning about the system's architecture
- They lead to incomplete implementations that fail in edge cases

**When You Encounter a Blocker**:
1. **Investigate the root cause** - understand why it's failing
2. **Fix the underlying issue** - don't work around it
3. **Test the proper solution** - ensure it works as intended
4. **Document the learning** - explain what was fixed and why

## Commit Standards
**Follow [Conventional Commits](https://www.conventionalcommits.org/)**: `<type>(<scope>): <subject>`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`
- **NO AI attribution**: Never add "Generated with Claude Code" or "Co-Authored-By: Claude"
- Breaking changes: Use `!` after type (e.g., `feat!:`) or `BREAKING CHANGE:` in footer

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Contains Reflaxe patterns, Phoenix examples, Haxe source
- **Haxe API Documentation**: https://api.haxe.org/ - For type system, standard library, and language features
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
- **Some preprocessor artifacts**: Minor temporary variables may appear in complex nested loops (cosmetic)

## Recently Fixed Issues ✅ (2025-08-15)

**Current Session - Parameter Naming Fix & PRD Vision Refinement:**
- **Parameter Naming Issue RESOLVED** ✨ - Generated functions now use meaningful parameter names instead of arg0/arg1
  - Fixed ClassCompiler.hx parameter extraction to use arg.tvar.name from Haxe AST
  - Fixed ElixirCompiler.hx parameter mapping to preserve original names in snake_case
  - Impact: `def greet(arg0)` → `def greet(name)` - professional, idiomatic code generation
  - Updated all 47 test intended outputs to reflect improved parameter names
  - Result: Generated code now looks hand-written and meets professional adoption standards

**Previous Session - Critical TODO Bug Fix & Test Infrastructure Improvements:**
- **CRITICAL TODO Bug Fixed** ✨ - @:module functions now compile actual implementations instead of "TODO: Implement function body"
  - Fixed generateModuleFunctions() hardcoded TODO placeholders in ClassCompiler.hx
  - Fixed generateFunction() and ElixirCompiler TODO fallbacks
  - Why todo-app worked: @:liveview used different code path, @:module was broken
  - Impact: Business logic, utilities, and contexts in Phoenix apps now work correctly
  - Updated all 46 test intended outputs to reflect proper function compilation
- **Test Infrastructure Timeouts RESOLVED** ✨ - Enhanced npm scripts with proper timeout configuration
  - Added 120s timeout for Mix tests to prevent test failures
  - Created test:quick, test:verify, test:core commands for rapid feedback
  - Updated test count accuracy to 178 total tests (46 Haxe + 19 Generator + 132 Mix)
  - Result: All tests now pass consistently without timeout issues
- **HXX Template Processing COMPLETE** ✨ - HEEx template generation with proper HTML attribute preservation
  - Fixed HTML attribute escaping - templates now generate `class="value"` instead of `class=\"value\"`
  - Implemented raw string extraction from AST before compilation escaping
  - Added specialized TBinop handling for multiline template string concatenation
  - Converted Haxe ${} interpolation to HEEx {} format
  - Result: HXX templates generate valid Phoenix HEEx code with ~H sigil format
- **Todo App Compilation SUCCESS** ✨ - All major compilation errors resolved
  - Fixed super.toString() compilation using __MODULE__ instead of "super"
  - Fixed invalid module naming (___Int64 → Int64) with sanitizeModuleName()
  - Fixed LiveView parameter handling (removed underscore prefixes when parameters are used)
  - Fixed changeset schema references (UserChangeset now references User schema correctly)
  - Fixed invalid Ecto schema field options (removed "null: false")
- **Test Suite 100% SUCCESS** ✨ - All 178/178 tests passing
  - Updated snapshot tests to reflect improved compiler output (46/46)
  - Maintained all Mix integration tests (132/132 passing)
  - Project generator tests working perfectly (19/19 passing)
  - Todo app compiles and runs successfully without errors

## Documentation Completeness Checklist ✓

**MANDATORY: After completing any feature or fix, verify ALL of these:**

### 1. Public-Facing Documentation
- [ ] **README.md** - Update feature list, badges, examples if new user-facing functionality added
- [ ] **CHANGELOG.md** - Document all changes with version, date, and impact
- [ ] **FEATURES.md** - Update production-ready status for new/enhanced features
- [ ] **KNOWN_ISSUES.md** - Remove fixed issues, add new discovered issues

### 2. User Guides
- [ ] **Feature-specific guide** - Create documentation/guides/FEATURE_NAME.md for new features
- [ ] **EXAMPLES.md** - Add working examples demonstrating the feature
- [ ] **COOKBOOK.md** - Add recipes for common use cases
- [ ] **TROUBLESHOOTING.md** - Document potential issues and solutions

### 3. Technical Documentation  
- [ ] **ARCHITECTURE.md** - Update if architectural changes made
- [ ] **API documentation** - Document all public APIs and their usage
- [ ] **Migration guides** - Document breaking changes and upgrade paths
- [ ] **Test documentation** - Explain new test patterns or changes

### 4. Development Documentation
- [ ] **TASK_HISTORY.md** - Comprehensive session documentation
- [ ] **Code TODOs** - Review and remove completed TODOs from code
- [ ] **Inline comments** - Add detailed comments for complex logic
- [ ] **Test counts** - Update test badges/counts in README

### 5. Project Management
- [ ] **Shrimp tasks** - Update task status, mark completed items
- [ ] **Dependencies** - Document new dependencies or requirements
- [ ] **Performance metrics** - Update if performance characteristics changed
- [ ] **Compatibility notes** - Document version requirements or conflicts

### 6. Integration Points
- [ ] **Framework documentation** - Update Phoenix/Ecto/OTP integration docs
- [ ] **External tool docs** - Document Mix tasks, CLI commands, etc.
- [ ] **Configuration docs** - Document new config options or flags
- [ ] **Error messages** - Ensure helpful error messages with solutions

**RULE: This checklist is NOT optional. Every session MUST review all items.**

## Compiler Development Best Practices ⚡

**Continuously refined from implementation experience. See also**: [`documentation/COMPILER_PATTERNS.md`](documentation/COMPILER_PATTERNS.md) for detailed patterns.

### 1. Never Leave TODOs in Production Code
- **Rule**: Fix issues immediately, don't leave placeholders
- **Why**: TODOs accumulate technical debt and indicate incomplete implementation
- **Example**: Don't write `// TODO: Need to substitute variables` - implement the substitution

### 2. Pass TypedExpr Through Pipeline as Long as Possible
- **Rule**: Keep AST nodes (TypedExpr) until the very last moment before string generation
- **Why**: AST provides structural information for proper transformations
- **Anti-pattern**: Converting to strings early then trying to manipulate strings
- **Correct**: Store `conditionExpr: TypedExpr` alongside `condition: String`

### 3. Apply Transformations at AST Level, Not String Level
- **Rule**: Use recursive AST traversal for variable substitution and transformations
- **Why**: String manipulation is fragile and error-prone
- **Implementation**: `compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String)`
- **Benefits**: Type-safe, handles nested expressions, catches edge cases

### 4. Variable Substitution Pattern
- **Problem**: Lambda parameters need different names than original loop variables
- **Solution**: 
  1. Find source variable in AST using `findLoopVariable(expr: TypedExpr)`
  2. Apply recursive substitution with `compileExpressionWithSubstitution()`
  3. Generate consistent lambda parameter names (`"item"`)
- **Result**: `numbers.map(n -> n * 2)` → `Enum.map(numbers, fn item -> item * 2 end)`

### 5. Context-Aware Compilation (Added 2025-08-15)
- **Rule**: Use context flags to track compilation state for different behavior
- **Implementation**: `isInLoopContext` flag to determine variable substitution
- **Why**: Same code needs different treatment in different contexts
- **Example**: Variable substitution only applies inside loops, not in function parameters

### 6. Avoid Hardcoded Variable Lists (Added 2025-08-15)
- **Anti-pattern**: Maintaining hardcoded lists like `["i", "j", "item", "id"]`
- **Solution**: Use function-based detection with `isCommonLoopVariable()` and `isSystemVariable()`
- **Benefits**: More maintainable, extensible, and accurate detection

### 7. Documentation String Generation (Added 2025-08-15)
- **Rule**: Preserve multi-line intent from JavaDoc to generate proper @doc heredocs
- **Fix**: Track `wasMultiLine` during cleaning to force proper formatting
- **Escape properly**: Never use unsafe template strings for documentation content
- **Result**: Professional, idiomatic Elixir documentation that matches language conventions

### 8. Pattern Detection for Optimization (Added 2025-08-15)
- **Pattern**: Detect function call patterns like `item(v)` to generate direct references
- **Example**: `array.map(transform)` → `Enum.map(array, transform)` not `fn item -> item(v) end`
- **Implementation**: Use regex patterns to detect and optimize common cases
- **Why**: Generate cleaner, more efficient target code

### 9. Avoid Ad-hoc Fixes - Implement General Solutions (Added 2025-08-15)
- **Rule**: Never add function-specific workarounds (e.g., "if calling Supervisor.startLink, do X")
- **Principle**: Always solve the root cause that benefits all similar use cases
- **Goal**: The compiler should generate correct idiomatic Elixir for any valid Haxe code
- **Example**: Don't special-case Supervisor child specs; fix how all objects with atom keys compile
- **Why**: Ad-hoc fixes create technical debt, mask architectural issues, and don't scale

### 10. Prefer Simple Solutions Over Clever Ones (Added 2025-08-15)
- **Rule**: Choose straightforward implementations over complex, "clever" solutions
- **Example**: Removed __AGGRESSIVE__ marker system in favor of always doing variable substitution
- **Principle**: Simple code is easier to understand, debug, and maintain
- **Test**: If explaining the code takes more than 30 seconds, it's probably too complex
- **Benefits**: Fewer bugs, easier onboarding for new developers, reduced maintenance overhead
- **Guideline**: Optimize for code clarity first, performance second (unless performance is critical)

### 11. Always Review Recent Work Before Major Changes (Added 2025-08-15)
- **Rule**: Before implementing new features or significant refactors, check what's been done recently
- **Process**: Read TASK_HISTORY.md, recent commit messages, and documentation updates
- **Purpose**: Understand the current direction, avoid duplicating work, and build on recent insights
- **Key Questions**: What patterns were just established? What approaches were tried and rejected?
- **Example**: Before adding new atom key detection, review recent atom key work to avoid repeating mistakes
- **Documentation**: Check for new architectural decisions, patterns, or best practices
- **Why**: Ensures consistency, prevents regression, and leverages recent learning and discoveries

### 12. JavaScript Generation Philosophy: Separation of Concerns (Added 2025-08-16)
- **Rule**: Focus exclusively on Haxe→Elixir compilation; use standard Haxe JS compiler for JavaScript output
- **Custom JS Only When**: Features don't exist in standard Haxe (e.g., async/await) or require specific Phoenix integration
- **Benefits**: Reduced maintenance burden, clear project scope, better compatibility with JS tooling
- **Implementation**: Delegate to Haxe's mature JS compiler unless absolutely necessary for custom features
- **Future**: Consider Genes compiler migration while maintaining separation principle
- **See**: [`documentation/JS_GENERATION_PHILOSOPHY.md`](documentation/JS_GENERATION_PHILOSOPHY.md) - Complete philosophical guide

## Recently Fixed Issues ✅ (2025-08-15)

**Current Session - Documentation Formatting and Test Suite Fixes:**
- **Documentation Generation FIXED** ✨ - All 49/49 tests now passing (was 12/49)
  - Fixed single-line documentation truncation by proper string escaping
  - Enhanced multi-line documentation detection in cleanJavaDoc()
  - Preserved JavaDoc intent to generate proper @doc """...""" heredocs
  - Fixed unsafe template string interpolation causing content loss
  - Result: Professional, idiomatic Elixir documentation matching language conventions
- **Result.traverse() Compilation OPTIMIZED** ✨ - Direct function references instead of lambda wrappers
  - Enhanced generateEnumMapPattern() to detect function call patterns
  - Fixed `array.map(transform)` generating `Enum.map(array, transform)` not `fn item -> item(v) end`
  - Pattern detection for renamed function parameters (transform → v)
  - Result: Cleaner, more efficient Elixir code generation
- **Compiler Patterns Documentation CREATED** ✨ - Comprehensive development guide
  - Created documentation/COMPILER_PATTERNS.md with lessons learned
  - Updated CLAUDE.md with new compiler development best practices
  - Documented AST transformation patterns, variable substitution, context-aware compilation
  - Result: Knowledge preservation for future development

## Recently Fixed Issues ✅ (2025-08-14)

**Latest Session - Variable Substitution and Transformation Extraction Complete:**
- **Variable Scope Issues RESOLVED** ✨ - Generated code now has consistent variable scoping
  - Fixed lambda parameter mismatches where `numbers.map(n -> n * 2)` generated `Enum.map(numbers, fn item -> n * 2 end)`
  - Implemented AST-level variable substitution with `compileExpressionWithVarMapping()` and recursive substitution
  - Result: `numbers.map(n -> n * 2)` → `Enum.map(numbers, fn item -> item * 2 end)` with proper variable consistency
- **Transformation Extraction WORKING** ✨ - Array methods generate actual logic instead of identity functions
  - Fixed `extractTransformationFromBody` to extract real transformations from TCall, TBinop patterns  
  - Added support for array push operations, list concatenation, and conditional transformations
  - Working transformations: `item * 2`, `"Fruit: " + item`, `item * item`, conditionals with proper variable substitution
- **Compiler Development Best Practices** - Added rules to prevent similar issues:
  1. Never leave TODOs in production code - fix issues immediately
  2. Pass TypedExpr through pipeline as long as possible before string generation
  3. Apply transformations at AST level, not string level
  4. Variable substitution pattern with recursive AST traversal

**Previous Session - Transformation Extraction Infrastructure:**
- **Enhanced transformation extraction framework** - Added TBinop, TCall, TField, TLocal, TConst expression support to extractTransformationFromBody
- **Improved array building pattern detection** - Extended recognition for TArrayDecl, push operations, and array concatenation patterns
- **Fixed technical implementation issues** - Resolved keyword conflicts, binary operator compilation, and field access handling
- **Maintained system stability** - Preserved all test compatibility while building infrastructure for future improvements

**Previous Session - Array Method Compilation Fixes:**
- **Array method priority detection** - Reordered pattern detection so Map → Filter → Count → Others prevents misclassification
- **Array methods no longer generate broken Enum.count** - Now properly generate `Enum.map(_g2, fn item -> item end)` instead of `Enum.count(_g2, fn item -> end)`
- **PubSub app name configuration** - Fixed hardcoded "App.PubSub" to use configurable `TodoApp.PubSub` via `-D app_name=TodoApp`
- **Haxe macro API documentation** - Created comprehensive guide preventing "macro-in-macro" errors with Context vs Compiler APIs
- **All 46 tests now pass** - Updated intended outputs to reflect improved code generation

**Previous Session:**
- **While/do-while loops** now generate idiomatic tail-recursive functions with proper state tuples and break/continue support using throw/catch pattern
- **For-in loops** now optimize to `Enum.reduce()` with proper range syntax (`start..end`) for simple accumulation patterns
- **Array iteration patterns** now generate idiomatic Elixir using appropriate Enum functions:
  - Find patterns → `Enum.reduce_while` with `:halt/:cont` tuples
  - Counting patterns → `Enum.count(array, fn item -> condition end)`
  - Loop variable extraction from AST → Correct variable names (todo vs item/1)
  - **See**: [`documentation/LOOP_OPTIMIZATION_LESSONS.md`](documentation/LOOP_OPTIMIZATION_LESSONS.md)
- **Loop code generation** follows functional programming principles instead of generating invalid variable reassignments
- **Standard library cleanup** prevents generation of empty Haxe built-in type modules (Array, String, etc.)
- **Phoenix Framework support** with comprehensive extern definitions for Channel, Presence, Token, Endpoint modules
- **@:channel annotation** support for compiling Phoenix Channel classes with proper callback generation
- **Mutable operations** (`+=`, `-=`, `*=`, `%=`) now correctly compile to reassignment (`x = x + 5`)
- **Increment/decrement operators** (`++`, `--`) now properly generate variable reassignment
- **Variable reassignment** properly handled in immutable Elixir context
- **Type annotations in todo-app** - replaced Dynamic with proper typed structures
- **Dynamic array methods** (.filter, .map) now correctly transform to Enum module functions
- **Dynamic property access** (.length) now generates proper length() function calls
- **String concatenation** properly uses `<>` operator
- **Function body compilation** now works with actual parameter names

## Testing Quick Reference ⚠️

**CRITICAL**: Reflaxe.Elixir uses **4 different test types** - choose the right one for your task!

### Test Type Matrix
| What You're Testing | Test Type | When to Use |
|-------------------|-----------|-------------|
| **New compiler feature** | Snapshot test | Testing AST → Elixir transformation |
| **Build macro validation** | Compile-time test | Testing warnings/errors from DSLs |
| **Build system integration** | Mix test | Testing generated code runs in BEAM |
| **Framework integration** | Example test | Testing real-world usage patterns |

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

## Current Implementation Status Summary

### v1.0 ESSENTIAL Tasks Status (4/4 Complete - 100%) ✅

✅ **1. Essential Elixir Protocol Support** - COMPLETE
   - ProtocolCompiler.hx fully implemented
   - @:protocol and @:impl annotations working
   - Examples in 07-protocols demonstrate functionality

✅ **2. Create Essential Standard Library Extern Definitions** - COMPLETE
   - All 9 essential modules implemented (Process, Registry, Agent, IO, File, Path, Enum, String, GenServer)
   - Full type-safe extern definitions with helper functions
   - Comprehensive test coverage

✅ **3. Implement Haxe Typedef Compilation Support** - COMPLETE ✨ NEW
   - TypedefCompiler.hx helper class fully implemented
   - Complete type mapping for aliases, structures, functions, generics
   - Snake_case field conversion and optional field handling
   - Comprehensive snapshot test coverage

✅ **4. Phoenix Router DSL Implementation** - COMPLETE ✨ **NEW**
   - RouterCompiler.hx fully implemented with @:router annotation support
   - LIVE and LIVE_DASHBOARD route generation working
   - Complete Phoenix scope and pipeline integration  
   - TodoAppRouter.hx example demonstrates full functionality

**For complete feature status, example guides, and usage instructions, see:**
- [`documentation/FEATURES.md`](documentation/FEATURES.md) - Production readiness status
- [`documentation/EXAMPLES.md`](documentation/EXAMPLES.md) - Working example walkthroughs  
- [`documentation/ANNOTATIONS.md`](documentation/ANNOTATIONS.md) - Annotation usage guide

**Quick Status**: 16 production-ready features including Router DSL, 9 working examples, 38/38 tests passing.

## Functional Programming Transformations
**See**: [`documentation/FUNCTIONAL_PATTERNS.md`](documentation/FUNCTIONAL_PATTERNS.md) - How imperative Haxe transforms to functional Elixir

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

## Haxe API Reference
**See**: [`documentation/HAXE_API_REFERENCE.md`](documentation/HAXE_API_REFERENCE.md) - Complete Haxe standard library reference
- Common types: Array, String, Map, Sys, Math, Type, Reflect
- Modern API docs: https://api.haxe.org/


