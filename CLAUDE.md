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
- **Framework-Agnostic Architecture**: Support any Elixir application pattern (Phoenix, Nerves, pure OTP) without compiler assumptions

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
**See**: [`documentation/LLM_DOCUMENTATION_INDEX.md`](documentation/LLM_DOCUMENTATION_INDEX.md) - Complete documentation navigation guide
```

### 📝 CRITICAL: Documentation Maintenance Rules ⚠️
**Prevent documentation rot and ensure accuracy:**
1. **ALWAYS remove deprecated/outdated documentation** - Don't let incorrect info accumulate
2. **Verify claims against actual code** - Check implementation before documenting issues
3. **Update Known Issues immediately** when issues are fixed - remove solved problems
4. **Delete obsolete sections entirely** rather than marking them as outdated
5. **Test claims in real code** - If documenting a limitation, verify it actually exists
6. **Remove fixed TODOs and resolved items** - Keep only current actionable items

### 🧹 MANDATORY Cleanup Protocol ⚠️ CRITICAL

**RULE: Always purge deprecated, unused, and duplicate files proactively**

#### Regular Cleanup Audits
1. **File Duplication Check**: Look for `*New.hx`, `*TypeSafe.hx`, `*Old.hx` patterns
2. **Build Configuration Validation**: Verify all .hxml files reference existing classes
3. **Documentation Link Verification**: Check all referenced docs actually exist
4. **Test File Justification**: Remove test stubs that don't provide real validation
5. **Experimental Code Removal**: Delete experimental versions once direction decided

#### When to Trigger Cleanup
- Before any major commit
- After completing feature implementations  
- When discovering duplicate files
- During documentation updates
- After refactoring sessions

#### Cleanup Priority
1. **Remove broken references immediately** - Fix dead links in docs
2. **Consolidate duplicate functionality** - No multiple versions of same feature
3. **Update documentation to reflect removals** - Keep docs accurate
4. **Verify builds after cleanup** - Ensure nothing breaks
5. **Document cleanup decisions** - Record why files were removed

## 📁 Project Directory Structure Map

**CRITICAL FOR NAVIGATION**: This monorepo contains multiple important projects and directories:

```
haxe.elixir/                          # Project root
├── src/reflaxe/elixir/                # 🔧 Compiler source code
│   ├── ElixirCompiler.hx              # Main transpiler
│   ├── helpers/                       # Specialized compilers
│   │   ├── NamingHelper.hx            # Snake_case conversion
│   │   ├── EndpointCompiler.hx        # @:endpoint annotation
│   │   ├── LiveViewCompiler.hx        # @:liveview annotation
│   │   └── ...                        # Other helpers
│   └── ...
├── std/                               # 📚 Standard library & framework types
│   ├── phoenix/                       # Phoenix framework integration
│   │   ├── Phoenix.hx                 # Core Phoenix externs
│   │   └── types/Assigns.hx           # Type-safe assigns abstract
│   ├── haxe/test/ExUnit.hx           # ExUnit testing from Haxe
│   └── ...
├── examples/todo-app/                 # 🎯 Main integration test & showcase
│   ├── src_haxe/                      # Haxe source files
│   │   ├── TodoApp.hx                 # Application entry point
│   │   ├── server/                    # Server-side code
│   │   │   ├── live/TodoLive.hx       # LiveView components
│   │   │   ├── infrastructure/Endpoint.hx  # @:endpoint class
│   │   │   └── ...
│   │   └── client/                    # Client-side code
│   ├── lib/                           # 🤖 GENERATED Elixir files (DO NOT EDIT)
│   ├── mix.exs                        # Elixir project config
│   └── ...
├── test/                              # 🧪 Compiler snapshot tests
│   ├── Test.hxml                      # Test runner
│   ├── tests/                         # Individual test cases
│   └── ...
├── documentation/                     # 📖 Comprehensive docs
│   ├── ARCHITECTURE.md                # System architecture
│   ├── TESTING_PRINCIPLES.md          # Testing methodology
│   └── ...
└── CLAUDE.md                          # This file
```

**Key Locations for Common Tasks**:
- **Compiler bugs**: `src/reflaxe/elixir/`
- **Type abstracts**: `std/phoenix/types/`, `std/haxe/`
- **Phoenix externs**: `std/phoenix/Phoenix.hx`
- **Integration testing**: `examples/todo-app/`
- **Snapshot tests**: `test/tests/`

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify CLAUDE.md first** - This file contains the project truth
2. **USE THE DIRECTORY MAP** - Navigate correctly using the structure above
3. **Check recent commits** - Run `git log --oneline -20` to understand recent work patterns, fixes, and ongoing features
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

**100% Type Safety with Maximum Flexibility - Choose your abstraction level while maintaining complete type safety.**

### The Type-Safe Flexibility Approach
- **Everything is typed**: No untyped code anywhere in the application
- **Developer choice**: Pick the right abstraction level for your needs
- **Mix and match**: Combine cross-platform and platform-specific APIs as needed
- **No Dynamic**: Avoid `Dynamic` and `__elixir__()` except for debugging

### When to Use What
✅ **Pure Haxe Implementation** (Maximum Portability):
- Core application logic that needs to run on multiple platforms
- Business rules that should be platform-agnostic
- New functionality where you control the implementation

✅ **Dual-API Approach** (Balanced Power):
- Standard library usage where you want both options
- Mix cross-platform methods with platform-specific enhancements
- Example: `date.getTime()` (cross-platform) + `date.add(7, Day)` (Elixir-style)

✅ **Typed Extern Definitions** (Ecosystem Access):
- Third-party Elixir libraries (database drivers, API clients, etc.)
- Existing Elixir modules you want to leverage
- Complex BEAM/OTP features not yet in standard library
- Performance-critical NIFs and ports

### Example of Mixed Approach
```haxe
// Pure Haxe for business logic
class OrderService {
    public function calculateTotal(items: Array<Item>): Float {
        return items.reduce((sum, item) -> sum + item.price, 0);  // Cross-platform
    }
    
    public function processPayment(order: Order): Result<Receipt, Error> {
        // Use typed extern for payment gateway
        var result = StripeGateway.charge(order.total, order.currency);
        
        // Use Elixir-style date methods
        var processedAt = Date.now().truncate(Second);
        
        return switch(result) {
            case Ok(charge): Ok({id: charge.id, date: processedAt});
            case Error(e): Error(e);
        }
    }
}

// Typed extern for existing Elixir library
@:native("Stripe")
extern class StripeGateway {
    static function charge(amount: Float, currency: String): Result<Charge, String>;
}
```

The goal is **100% type safety with maximum developer flexibility**, using the right abstraction for each scenario.

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- [Understanding Reflaxe.Elixir's Compilation Architecture](#understanding-reflaxeelixirs-compilation-architecture-) - How the transpiler actually works
- [Critical: Macro-Time vs Runtime](#critical-macro-time-vs-runtime-) - THE MOST IMPORTANT CONCEPT TO UNDERSTAND
- [`documentation/HAXE_MACRO_APIS.md`](documentation/HAXE_MACRO_APIS.md) - **CRITICAL**: Correct Haxe macro API usage to avoid "macro-in-macro" errors
- [`documentation/architecture/ARCHITECTURE.md`](documentation/architecture/ARCHITECTURE.md) - Complete architectural details
- [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Testing philosophy and infrastructure
- [`documentation/macro/MACRO_PRINCIPLES.md`](documentation/macro/MACRO_PRINCIPLES.md) - **CRITICAL**: Core principles for reliable macro development from real implementations

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation, not at test runtime. This affects how you write and test compiler features.

**Key Point**: The function body compilation fix was a legitimate use case - we went from empty function bodies (`# TODO: Implement function body`) to real compiled Elixir code. This required updating all intended outputs to reflect the improved compiler behavior.

## Framework-Agnostic Design Pattern ✨ **ARCHITECTURAL PRINCIPLE**

**CRITICAL RULE**: The compiler generates plain Elixir by default. Framework conventions are applied via annotations, not hardcoded assumptions.

### Design Philosophy
```haxe
// ✅ CORRECT: Framework conventions via annotations
@:native("AppNameWeb.TodoLive")  // Explicit Phoenix convention
@:liveview
class TodoLive {}

// ❌ WRONG: Hardcoded framework detection in compiler
if (isPhoenixProject()) {
    moduleName = appName + "Web." + className;  // Compiler assumption
}
```

### Benefits
- **Universal compatibility**: Works with Phoenix, Nerves, pure OTP, custom frameworks
- **Zero framework coupling**: Compiler core remains framework-neutral
- **Explicit control**: Developers choose conventions per project/class
- **Migration friendly**: Easy transition from manual to automatic naming

### Implementation Pattern
1. **@:native annotation**: Explicit module name override
2. **Project configuration**: Optional bulk convention application  
3. **Convention detection**: Future automatic framework detection
4. **Fallback**: Package-based naming when no convention specified

**See**: [`documentation/MODULE_RESOLUTION_ROADMAP.md`](documentation/MODULE_RESOLUTION_ROADMAP.md) - Complete module resolution strategy

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

## ⚠️ CRITICAL: Debug Infrastructure for Compiler Development

**FUNDAMENTAL RULE: Use conditional debug infrastructure for compiler development, not temporary trace statements.**

### The Problem with Ad-hoc Debug Traces
- **Production pollution**: Manual traces leak into committed code
- **Performance impact**: Traces execute even when not needed
- **Inconsistent format**: Each developer uses different debug styles
- **Cleanup overhead**: Must remember to remove temporary traces
- **Lost debugging**: Delete useful traces, then need them again

### Professional Debug Infrastructure Solution

#### 1. Conditional Compilation Pattern
```haxe
#if debug_compiler
    DebugHelper.debugForLoop("TFor compilation", tvar, iterExpr, blockExpr);
#end
```

#### 2. Categorized Debug Functions
```haxe
#if debug_patterns
    DebugHelper.debugPattern("Map.merge detection", pattern, result);
#end

#if debug_optimizations  
    DebugHelper.debugOptimization("Enum.map transformation", before, after);
#end

#if debug_annotations
    DebugHelper.debugInfo("@:liveview processing", "Found LiveView class: " + className);
#end

#if debug_expressions
    DebugHelper.debugExpression("TCall compilation", expr, result);
#end
```

#### 3. Build-Time Control
```bash
# Enable all debugging
npx haxe build-server.hxml -D debug_compiler

# Enable specific categories
npx haxe build-server.hxml -D debug_patterns -D debug_for_loops -D debug_annotations

# Production build (no debug output)
npx haxe build-server.hxml
```

### Debug Infrastructure Implementation

#### Required Components
1. **DebugHelper.hx** - Central debug infrastructure module
   - Pretty-printing for TypedExpr AST nodes
   - Structured output formatting
   - Category management and filtering

2. **Conditional Compilation Guards** - Wrap all debug calls
   - `#if debug_compiler` for general debugging
   - `#if debug_[category]` for specific areas
   - Zero performance impact in production builds

3. **Documentation Standards** - Clear debug categories
   - `debug_compiler` - General compiler debugging (enables all categories)
   - `debug_for_loops` - For-loop compilation and optimization
   - `debug_patterns` - Pattern detection and matching (Map.merge, Y combinator, etc.)
   - `debug_optimizations` - Optimization decisions and results  
   - `debug_ast` - AST structure analysis
   - `debug_expressions` - Expression compilation details
   - `debug_types` - Type resolution and mapping
   - `debug_annotations` - Annotation processing (@:liveview, @:router, etc.)
   - `debug_helpers` - Helper compiler debugging (EnumCompiler, ClassCompiler, etc.)

### Usage Guidelines

#### ❌ NEVER Do This:
```haxe
// Ad-hoc traces that clutter code without documentation
trace('Debugging TFor: ${expr}');
trace('Pattern result: $result');

// OR: Debug infrastructure without proper documentation
#if debug_for_loops
    DebugHelper.debugForLoop("TFor compilation", tvar, iterExpr, blockExpr);
#end
```

#### ✅ ALWAYS Do This:
```haxe
/**
 * TFor COMPILATION: Transform Haxe for-loops to idiomatic Elixir
 * 
 * WHY: Haxe for-loops need to be converted to functional Elixir patterns
 * - Reflect.fields iterations → Map.merge optimizations  
 * - Array iterations → Enum.map/filter/reduce operations
 * - Complex patterns → Y combinator recursion as fallback
 * 
 * HOW: Direct delegation to compileForLoop for optimization detection
 * - Pattern detection happens at AST level before string compilation
 * - Avoids generating and then re-parsing string representations
 */
#if debug_for_loops
    DebugHelper.debugForLoop("TFor compilation", tvar, iterExpr, blockExpr);
#end
return compileForLoop(tvar, iterExpr, blockExpr);
```

### Critical Rule: Documentation AND Debug Infrastructure
**Both comprehensive code documentation AND debug infrastructure are mandatory:**

1. **Documentation Comments**: Explain WHY, HOW, ARCHITECTURE, EDGE CASES
2. **Debug Infrastructure**: Enable runtime observation of complex logic
3. **Combined Benefit**: Comments explain the design, debug shows the execution

### Debug Output Format Standards
```
[DEBUG:FOR_LOOP] ============================================
Context: TFor compilation - Reflect.fields iteration
Variable: field (String)
Iterator: Reflect.fields(config) 
Block: TCall(Reflect.setField, [target, field, value])
Pattern: Simple field copying detected
Optimization: Applying Map.merge(target, source)
Result: endpoint_config = Map.merge(endpoint_config, config)
[DEBUG:END] ================================================
```

### Benefits of Professional Debug Infrastructure
- **Zero production overhead**: Debug code completely eliminated in production builds
- **Persistent debugging**: Keep useful debug information in codebase without pollution
- **Consistent format**: All debug output follows the same structured format
- **Selective debugging**: Enable only the categories you need for specific issues
- **Documentation value**: Debug calls serve as inline documentation of complex logic
- **Collaboration**: Other developers can easily enable debugging for their issues

### When to Use Debug Infrastructure
- **Complex AST transformations**: Understanding TypedExpr processing
- **Pattern detection logic**: Diagnosing why optimizations aren't triggering
- **Optimization decisions**: Tracking which code paths are taken
- **Performance analysis**: Understanding compilation bottlenecks
- **Integration debugging**: Tracking data flow between compiler components

**Why This Matters**: The compiler is a complex system with many interdependent components. Professional debug infrastructure makes development faster, more reliable, and more collaborative while keeping production builds clean and performant.

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
- [`documentation/ELIXIR_RUNTIME_ARCHITECTURE.md`](documentation/ELIXIR_RUNTIME_ARCHITECTURE.md) - Complete explanation of development infrastructure vs production runtime
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

## Phoenix LiveView Development ⚡ **COMPLETE DOCUMENTATION**

**Comprehensive guides for building idiomatic Phoenix LiveView applications with Haxe→Elixir**:
- **See**: [`documentation/PHOENIX_LIVEVIEW_ARCHITECTURE.md`](documentation/PHOENIX_LIVEVIEW_ARCHITECTURE.md) - Core philosophy, server-centric patterns, and client code size limits (<200 lines)
- **See**: [`documentation/PHOENIX_LIVEVIEW_PATTERNS.md`](documentation/PHOENIX_LIVEVIEW_PATTERNS.md) - Where Haxe makes LiveView better: compile-time type safety, zero runtime errors, exhaustive pattern matching
- **See**: [`documentation/guides/PHOENIX_LIVEVIEW_GUIDE.md`](documentation/guides/PHOENIX_LIVEVIEW_GUIDE.md) - Step-by-step implementation with real-world examples
- **See**: [`documentation/PHOENIX_LIVEVIEW_TESTING.md`](documentation/PHOENIX_LIVEVIEW_TESTING.md) - Multi-layer testing strategy with type-safe test data

**Key Insight**: Haxe brings **compile-time safety to a runtime environment** - catching entire classes of production errors that traditional LiveView applications only discover at runtime.

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

## ⚠️ CRITICAL: Mix Tasks Are Core Infrastructure - NEVER DELETE

**The `/lib/mix/tasks/` directory contains essential Mix task infrastructure that enables Haxe compilation in Mix projects. These files are NOT generated and MUST NOT be deleted.**

### Essential Mix Tasks (Never Delete)
- **`compile.haxe.ex`** - Core Mix compiler integration that enables `mix compile` to work with Haxe
- **`haxe.watch.ex`** - File watching for development workflow
- **`haxe.gen.*.ex`** - Code generation tasks for scaffolding

### Why This Matters
Without these Mix tasks, the todo-app and other Mix projects CANNOT compile Haxe source code. The `mix compile` command will fail with "The task 'compile.haxe' could not be found."

### If Accidentally Deleted
Restore from git history:
```bash
git show 16a8bec:examples/todo-app/lib/mix/tasks/compile.haxe.ex > lib/mix/tasks/compile.haxe.ex
```

**These are infrastructure files, not generated output. They are permanent project components.**

## Haxe-First Philosophy ⚠️ FUNDAMENTAL RULE

**Write EVERYTHING in Haxe unless technically impossible. Type safety everywhere, not just business logic.**

The vision is 100% Haxe code with complete type safety. This means:
- **All application code** in Haxe
- **All UI templates** in HXX (no manual HEEx)
- **All infrastructure** in Haxe (Endpoint, Repo, Telemetry, etc.)
- **All error handling** in Haxe
- **All components** in HXX with type safety

**Developer Choice and Flexibility**:
- **Pure Haxe preferred**: Write implementations in Haxe for maximum control and cross-platform compatibility
- **Typed externs welcome**: Leverage the rich Elixir ecosystem with full type safety
- **Dual-API standard library**: Use cross-platform OR platform-specific methods as needed
- **Mix and match**: Combine approaches based on project requirements

**Abstraction Level Choice**:
- **100% Cross-Platform**: Use only Haxe standard APIs (`date.getTime()`, `array.map()`)
- **Platform-Enhanced**: Mix Haxe + Elixir APIs (`date.getTime()` + `date.add(7, Day)`)
- **Ecosystem Integration**: Use typed externs for existing Elixir libraries
- **Emergency Only**: `__elixir__()` code injection for debugging/prototyping

**The goal**: Maximum developer flexibility with complete type safety. Choose your abstraction level.

## Standard Library Philosophy ⚡ **DUAL-API PATTERN**

**Every standard library type provides BOTH cross-platform AND native APIs** - Maximum developer flexibility:

✅ **Dual-API Benefits**:
- **Cross-platform compatibility** using Haxe standard methods (`getTime()`, `getMonth()`)
- **Platform-specific power** using Elixir-style methods (`add()`, `diff()`, `toIso8601()`)
- **Gradual migration** from pure Elixir to type-safe Haxe
- **Developer choice** between portability and platform features

**Example - Date Type**:
```haxe
var date = Date.now();
var timestamp = date.getTime();        // ✅ Cross-platform Haxe API
var nextWeek = date.add(7, Day);       // ✅ Elixir-native API
var iso = date.toIso8601();            // ✅ Platform-specific feature
```

**See**: [`/std/CLAUDE.md`](/std/CLAUDE.md#dual-api-pattern) - Complete implementation guidelines and patterns

## Type-Safe Code Injection ⚡ **PRODUCTION READY**

**Modern type-safe injection using `elixir.Syntax.code()` - working excellently in production!**

### ✅ NEW: elixir.Syntax API (Recommended)
```haxe
import elixir.Syntax;
var result = Syntax.code("DateTime.utc_now()");           // Type-safe, IDE support
var formatted = Syntax.code("String.slice({0}, {1})", str, start);  // Parameter interpolation
```

### 🔄 LEGACY: untyped __elixir__() (Backward Compatibility Only)
```haxe
var result = untyped __elixir__("DateTime.utc_now()");    // Legacy approach
```

### Usage Guidelines
- **Standard Library**: Use `elixir.Syntax.code()` for new implementations
- **Application Code**: Prefer pure Haxe abstractions and extern definitions
- **Migration**: Gradually convert `untyped __elixir__()` to `elixir.Syntax.code()`

### Implementation Success ⭐
- ✅ **100% call interception**: All `elixir.Syntax.code()` calls properly detected and transformed
- ✅ **Zero runtime pollution**: No Syntax modules generated, perfect compile-time processing
- ✅ **Idiomatic output**: Generates clean Elixir (String.trim_leading, Map.keys, Enum.reduce)
- ✅ **Type safety**: Full type constraints maintained with excellent error messages
- ✅ **Standard library integration**: StringTools, MapTools, ArrayTools all migrated successfully

**See**: 
- [`documentation/ELIXIR_SYNTAX_IMPLEMENTATION.md`](documentation/ELIXIR_SYNTAX_IMPLEMENTATION.md) - **NEW**: Complete success analysis and why regular class approach works perfectly
- [`documentation/ELIXIR_INJECTION_GUIDE.md`](documentation/ELIXIR_INJECTION_GUIDE.md) - Complete injection guide with examples
- [`documentation/CRITICAL_ARCHITECTURE_LESSONS.md`](documentation/CRITICAL_ARCHITECTURE_LESSONS.md) - Why idiomatic code generation matters

## Quality Standards
- Zero compilation warnings, Reflaxe snapshot testing approach, Performance targets: <15ms compilation, <150KB JS bundles
- **Date Rule**: Always run `date` command before writing timestamps - never assume dates
- **CRITICAL: Idiomatic Elixir Code Generation** - The compiler MUST generate idiomatic, high-quality Elixir code that follows BEAM functional programming patterns, not just syntactically correct code
- **Architecture Validation Rule** - Occasionally reference the Reflaxe source code and reference implementations in `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` to ensure our architecture follows established Reflaxe patterns and isn't diverging too far from proven approaches

## Parallel Testing Infrastructure ⚡ **PRODUCTION READY**

**Two parallel testing systems implemented for different test types**:

### Snapshot Test Parallelization (ParallelTestRunner.hx)
**87% performance improvement achieved with production-ready parallel test execution**:
- ✅ **Performance**: 261s → 27s execution time (16 workers optimized)
- ✅ **Reliability**: 57 snapshot tests + 133 Mix tests passing
- ✅ **Default Mode**: `npm test` now runs parallel by default
- ✅ **File-Based Locking**: Simple, maintainable solution eliminates race conditions
- ✅ **CPU Optimization**: Maximum multi-core utilization for compilation processes

### Mix Test Parallelization (ExUnit native)
**Enabled ExUnit parallel execution with proper resource management**:
- ✅ **ExUnit Integration**: Leverages native ExUnit parallelization (2x CPU cores)
- ✅ **Resource Management**: Tests categorized by shared resource usage (async: true/false)
- ✅ **Performance Ready**: Foundation for future improvements as more tests become parallel-safe
- ✅ **Documentation**: Complete strategy documented in [`documentation/MIX_TEST_PARALLELIZATION.md`](documentation/MIX_TEST_PARALLELIZATION.md)

**See**: [`documentation/HAXE_THREADING_ANALYSIS.md`](documentation/HAXE_THREADING_ANALYSIS.md) - Complete threading research and worker process architecture for future enhancement

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

### 🔄 Development Loop Validation ⚠️ MANDATORY

**After ANY compiler change, ALWAYS verify the complete development loop:**

1. **Run Full Test Suite**: `npm test` - ALL tests must pass (snapshot + Mix + generator)
2. **Test Todo-App Compilation**: 
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex  # Clean generated files
   npx haxe build-server.hxml    # Regenerate from Haxe
   mix compile --force           # Verify Elixir compilation
   ```
3. **Test Todo-App Runtime**:
   ```bash
   mix phx.server                # Start Phoenix server
   curl http://localhost:4000    # Verify expected response
   ```
4. **Verify TypeSafeChildSpec Patterns**: 
   ```bash
   haxe test/Test.hxml test=type_safe_child_specs  # Validate new child spec compilation
   ```

**Critical Rule**: If ANY step fails, the compiler change is incomplete. Fix the root cause in the compiler source, never patch generated files.

### ⚠️ CRITICAL: No Direct Elixir Files - Everything Through Haxe
**FUNDAMENTAL RULE: NEVER write .ex files directly. Everything must be generated from Haxe.**

**Why This Matters:**
- **Vision Integrity**: The entire point of Reflaxe.Elixir is to write everything in Haxe
- **Type Safety**: Manual .ex files bypass Haxe's type system entirely
- **Maintainability**: Two sources of truth (Haxe + manual Elixir) create confusion
- **Compiler Evolution**: The compiler should handle ALL Elixir generation needs

**When You Need Complex Elixir Features:**
1. **Create a compiler helper**: Add to `src/reflaxe/elixir/helpers/`
2. **Use annotations**: Create DSLs through @:annotation patterns
3. **Enhance the compiler**: Add new capabilities to handle the use case
4. **Use Haxe macros**: Create compile-time transformations in Haxe

**Examples:**
- ❌ **WRONG**: Writing `lib/todo_app_web.ex` manually for Phoenix macros
- ✅ **RIGHT**: Creating `WebModuleCompiler.hx` to generate Phoenix web modules from @:phoenixWebModule annotation

- ❌ **WRONG**: Creating manual migration files in `priv/repo/migrations/`
- ✅ **RIGHT**: Using @:migration annotation with MigrationCompiler

**The Rule**: If you're typing in a .ex file, you're doing it wrong. Find or create the Haxe way.

### ⚠️ CRITICAL: Code Replacement Safety Protocol
**ALWAYS double-check before removing code - compare implementations thoroughly and keep the SUPERIOR version, not just resolve duplicates blindly.**

When resolving duplicate code or methods:
1. **Analyze both implementations** - Compare logic, patterns, robustness
2. **Identify the superior approach** - Better error handling, proper patterns, extensibility
3. **Replace inferior with superior** - Don't just remove to fix conflicts
4. **Verify the decision** - Ensure the kept implementation handles all cases

**Example**: When finding duplicate `compileElixirSyntaxCall()` methods, compare:
- ❌ Simple `string.replace('{$i}')` approach (brittle, no bounds checking)
- ✅ Regex `~/{(\d+)}/g.map()` approach (robust, follows js.Syntax patterns)
- **Decision**: Replace simple approach with regex approach, don't just remove newer code

### ⚠️ CRITICAL: Check Haxe Standard Library First
**FUNDAMENTAL RULE: Always check if Haxe stdlib already offers something before implementing it ourselves.**

**Why This Matters:**
- **Avoid Duplicate Work**: Don't reimplement well-tested, cross-platform solutions
- **Better Quality**: Haxe stdlib code is optimized, tested, and maintained by the core team
- **Cross-Platform Compatibility**: Standard library works consistently across all targets
- **Type Safety**: Official APIs have better type definitions and documentation

**Examples of Common Implementations to Check:**
```haxe
// ❌ BAD: Reimplementing localStorage
class LocalStorage {
    static function setItem(key: String, value: String) { ... }
    static function getItem(key: String): String { ... }
}

// ✅ GOOD: Using existing Haxe stdlib
import js.Browser;
var storage = js.Browser.getLocalStorage(); // js.html.Storage
storage.setItem(key, value);
var value = storage.getItem(key);
```

**Always Check Before Implementing:**
- **Storage APIs**: js.Browser.getLocalStorage(), js.Browser.getSessionStorage()
- **HTTP/Fetch**: js.lib.Promise, native fetch() via js.Syntax.code()
- **Date/Time**: Date class (cross-platform), target-specific DateTime
- **JSON**: haxe.Json for parsing/stringifying
- **Collections**: Array, Map, Set, List with rich standard library methods
- **String Operations**: StringTools, EReg for regex
- **Math**: Math class with comprehensive mathematical functions
- **File/IO**: sys.io.File, sys.FileSystem for system targets

**Development Process:**
1. **Search Haxe API docs first**: https://api.haxe.org/
2. **Check target-specific APIs**: js.html.*, sys.*, eval.*, etc.
3. **Look at reference code**: Check `/haxe/std/` in reference folder
4. **Only implement if missing**: Create abstracts/externs for new functionality

### ⚠️ CRITICAL: Type Safety and String Avoidance
**FUNDAMENTAL RULE: Avoid strings in compiler code unless absolutely necessary. When strings ARE necessary, they must be type-checked.**

#### Comprehensive File Naming System ⚡ **PRODUCTION READY**
**Complete DRY naming architecture that follows idiomatic Elixir/Phoenix conventions**:
- ✅ **Universal snake_case conversion** - ALL files get proper Elixir naming (TodoApp → todo_app)
- ✅ **Package-to-directory mapping** - Haxe packages become snake_case directories
- ✅ **Idiomatic Phoenix placement** - Framework files go exactly where Phoenix developers expect
- ✅ **DRY implementation** - Single `getComprehensiveNamingRule()` function handles ALL cases

**Idiomatic Elixir/Phoenix File Placement**:
```
TodoApp.hx @:application   → lib/todo_app/application.ex     # Phoenix convention
TodoAppRouter.hx @:router   → lib/todo_app_web/router.ex      # Always router.ex
UserLive.hx @:liveview      → lib/todo_app_web/live/user_live.ex
Endpoint.hx @:endpoint      → lib/todo_app_web/endpoint.ex    # Always endpoint.ex
Todo.hx @:schema            → lib/todo_app/schemas/todo.ex    # Domain models
server.contexts.Users       → lib/server/contexts/users.ex    # Package preservation
```

**The Architecture**: 
- **Single source of truth**: `getComprehensiveNamingRule()` in ElixirCompiler.hx
- **No string duplication**: One naming system for ALL file generation
- **Phoenix-aware**: Knows where Phoenix developers expect files
- **Future-proof**: Easy to add new annotations without breaking existing ones

**See**: [`documentation/FILE_NAMING_ARCHITECTURE.md`](documentation/FILE_NAMING_ARCHITECTURE.md) - Complete naming system documentation

#### String Usage Guidelines
**❌ NEVER**:
- Duplicate string manipulation functions
- Hardcode file paths or module names
- Use string concatenation for complex logic
- Skip type checking for string-based APIs

**✅ ALWAYS**:
- Use type-safe abstracts for structured strings (URLs, paths, module names)
- Centralize string utilities in helper classes
- Validate string inputs at boundaries
- Use enums instead of string constants where possible

**See**: [`documentation/COMPILER_BEST_PRACTICES.md`](documentation/COMPILER_BEST_PRACTICES.md) - Complete development principles, testing protocols, and best practices
**See**: [`documentation/ANNOTATION_SYSTEM.md`](documentation/ANNOTATION_SYSTEM.md) - Complete annotation documentation and usage guidelines

## ⚠️ CRITICAL: Comprehensive Code Documentation Rule

**FUNDAMENTAL RULE: All complex compiler code MUST be comprehensively documented with context-aware comments.**

### Documentation Requirements by Complexity
- **Simple operations**: Brief inline comments explaining what
- **Complex logic**: Multi-line comments explaining WHY, HOW, and architectural context
- **Compiler infrastructure**: Full architectural documentation with integration details

### Required Elements for Complex Code
1. **WHY the code exists**: What problem does it solve? What pattern does it implement?
2. **HOW it works**: Step-by-step explanation of the algorithm or approach
3. **Architectural context**: How does it fit into the overall compiler architecture?
4. **Integration points**: What other compiler components does it interact with?
5. **Edge cases**: What scenarios require special handling and why?

### Documentation Template for Complex Code
```haxe
/**
 * COMPLEX FUNCTIONALITY: Brief description of what this does
 * 
 * WHY: Explain the problem this solves and why this approach was chosen
 * - Specific issue or pattern being addressed
 * - Alternative approaches considered and why rejected
 * 
 * HOW: Detailed explanation of the implementation
 * - Step-by-step algorithm or process
 * - Key data structures and transformations
 * - Important implementation decisions
 * 
 * ARCHITECTURE: How this fits into the compiler
 * - Which compiler phase/component this belongs to
 * - Integration with other helpers/systems
 * - Data flow in and out of this component
 * 
 * EDGE CASES: Special handling scenarios
 * - Specific patterns that require different treatment
 * - Known limitations or assumptions
 * 
 * @param param Description of input parameters
 * @return Description of return values and possible states
 */
function complexCompilerFunction(param: Type): ReturnType {
    // Implementation with inline comments for complex steps
}
```

### Examples Requiring Full Documentation
- Y combinator generation and detection logic
- AST transformation algorithms
- Context-sensitive compilation decisions
- Pattern matching and optimization strategies
- Framework-specific code generation
- Error handling and recovery mechanisms

**Why This Matters**: The compiler is a complex system with many interdependent components. Without comprehensive documentation, future modifications become error-prone and architectural understanding is lost.

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

## Development Loop ⚡ **CRITICAL WORKFLOW**

**MANDATORY: Every development change MUST follow this complete validation loop:**

### Complete Development Validation Loop
```bash
# 1. Run full test suite (ALL tests must pass)
npm test

# 2. Verify todo-app compiles in Haxe
cd examples/todo-app
npx haxe build-server.hxml

# 3. Ensure Elixir compilation succeeds
mix compile --force

# 4. Verify application starts properly
mix phx.server &
sleep 5

# 5. Test expected functionality via curl
curl -s http://localhost:4000/ | grep -q "TodoApp"
if [ $? -eq 0 ]; then
    echo "✅ TodoApp responds correctly"
else
    echo "❌ TodoApp response failed"
fi

# 6. Clean up
pkill -f "mix phx.server"
```

### Why This Matters
- **Tests validate compiler correctness** - Snapshot and Mix tests catch regressions
- **Todo-app validates integration** - Real Phoenix application compilation
- **Elixir compilation validates syntax** - Generated code must be syntactically correct  
- **Server start validates runtime** - Code must actually execute in BEAM VM
- **Curl validates functionality** - Application must respond to HTTP requests correctly

### Quick Commands for Development
```bash
# Full validation (run after ANY compiler change)
npm test && cd examples/todo-app && mix compile && echo "✅ All validations passed"

# Quick integration test
cd examples/todo-app && npx haxe build-server.hxml && mix compile

# Test application response
mix phx.server & sleep 3 && curl localhost:4000 && pkill -f "mix phx.server"
```

**Rule**: If ANY step in this loop fails, the development change is incomplete. Fix all issues before moving to the next task.

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Contains Reflaxe patterns, Phoenix examples, Haxe source
- **Haxe API Documentation**: https://api.haxe.org/ - For type system, standard library, and language features
- **Haxe Manual**: https://haxe.org/manual/ - **CRITICAL**: For any advanced feature, always consult the official manual to use the best features, avoid outdated features, and not miss useful capabilities
- **Haxe Code Cookbook**: https://code.haxe.org/ - Modern patterns and best practices
- **Web Resources**: Use WebSearch and WebFetch for current documentation, API references, and best practices
- **Principle**: Always reference existing working code and official documentation rather than guessing or assuming implementation details

## JavaScript Development Patterns ⚡

**See**: [`documentation/JAVASCRIPT_PATTERNS.md`](documentation/JAVASCRIPT_PATTERNS.md) - Modern Haxe JavaScript patterns, async/await support, and type-safe DOM handling

## Implementation Status
**See**: [`documentation/reference/FEATURES.md`](documentation/reference/FEATURES.md) - Complete feature status and production readiness

**v1.0 Status**: ALL COMPLETE ✅ - Core features, Phoenix Router DSL, LiveView, Ecto, OTP patterns, Mix integration, Testing (57 snapshot + 133 Mix tests ALL PASSING, file naming conventions fixed)

## Development Environment
**See**: [`documentation/guides/GETTING_STARTED.md`](documentation/guides/GETTING_STARTED.md) - Complete setup guide
- **Haxe**: 4.3.6+ with modern patterns, API at https://api.haxe.org/  
- **Reflaxe**: 4.0.0-beta with full preprocessor support (upgraded from 3.0)
- **Testing**: `npm test` for full suite, `-D reflaxe_runtime` for test compilation
- **Architecture**: DirectToStringCompiler inheritance, macro-time transpilation

## Dynamic Type Usage Guidelines ⚠️
**See**: [`documentation/guides/DEVELOPER_PATTERNS.md`](documentation/guides/DEVELOPER_PATTERNS.md) - Complete Dynamic usage guidelines with examples and justification patterns

## Test Status Summary
**See**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Complete test status and architecture details

## Reflaxe Snapshot Testing Architecture ✅
**See**: [`documentation/architecture/TESTING.md`](documentation/architecture/TESTING.md) - Complete snapshot testing architecture, test structure, and commands

## Understanding Reflaxe.Elixir's Compilation Architecture ✅

**For complete architectural details, see [`documentation/architecture/ARCHITECTURE.md`](documentation/architecture/ARCHITECTURE.md)**  

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

## Critical: Vendoring and Dependency Management ⚠️

### Lesson Learned: Missing Reflaxe Macro Registration
**Issue**: When vendoring Reflaxe locally to fix the EReg module corruption bug, the critical `--macro reflaxe.ReflectCompiler.Start()` was accidentally removed from `haxe_libraries/reflaxe.hxml`, causing complete compilation failure where no .ex files were generated.

**Root Cause**: The vendored configuration only included the classpath but missed the essential macro registration that actually starts the Reflaxe compiler framework.

**Fix**: Always ensure vendored Reflaxe includes these critical lines in `haxe_libraries/reflaxe.hxml`:
```hxml
-cp ${SCOPE_DIR}/vendor/reflaxe/src/
-D reflaxe=4.0.0-beta
--macro nullSafety("reflaxe")
--macro reflaxe.ReflectCompiler.Start()  # CRITICAL: Without this, no compilation happens!
```

**Prevention**: When vendoring any Haxe library:
1. Compare the original `.hxml` configuration with the vendored version
2. Preserve ALL macro calls and compiler directives
3. Test immediately after vendoring to catch missing functionality
4. Document why vendoring was necessary (in our case: EReg module corruption bug specific to Reflaxe.Elixir)

**See**: [`vendor/reflaxe/src/reflaxe/helpers/BaseTypeHelper.hx`](vendor/reflaxe/src/reflaxe/helpers/BaseTypeHelper.hx) - Contains the EReg fix documentation

## Known Issues  
- **Array Mutability**: Methods like `reverse()` and `sort()` don't mutate in place (Elixir lists are immutable)
  - Workaround: Use assignment like `reversed = reversed.reverse()` instead of just `reversed.reverse()`

## Recently Resolved Issues ✅
- **Variable Substitution in Lambda Expressions**: Fixed undefined variable issues (e.g., `fn item -> (!v.completed)` now correctly generates `fn item -> (!item.completed)`)
- **Hardcoded Application Dependencies**: Removed all hardcoded "TodoApp" references from compiler - now works with any Phoenix application
- **Phoenix CoreComponents Integration**: Added type-safe @:component annotations and automatic component detection


## Documentation Completeness Checklist ✓
**MANDATORY: After completing any feature or fix, verify documentation updates across all categories.**

**See**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) - Complete documentation checklist and maintenance procedures

## Compiler Development Best Practices ⚡
**See**: [`documentation/COMPILER_BEST_PRACTICES.md`](documentation/COMPILER_BEST_PRACTICES.md) - Complete development practices and patterns for Reflaxe.Elixir compiler development

**All historical implementation details and fixes moved to**: [`documentation/TASK_HISTORY.md`](documentation/TASK_HISTORY.md)

## Testing Strategy ⚠️

**⚠️ CRITICAL RULE: ALWAYS run `npm test` after any compiler changes to avoid regressions**

**See**: [`documentation/TESTING_ARCHITECTURE.md`](documentation/TESTING_ARCHITECTURE.md) - **Complete testing architecture**
- **Key insight**: Examples (todo-app) ARE E2E tests for the compiler
- **Two layers**: Compiler testing vs Application testing  
- **Testing matrix**: Snapshot, Integration, Examples-as-E2E, Browser tests
- **Commands**: `npm test`, `MIX_ENV=test mix test`, `mix compile` (in examples)
- **Mandatory**: Every change must pass the complete test suite before commit


## Functional Programming Transformations
**See**: [`documentation/FUNCTIONAL_PATTERNS.md`](documentation/FUNCTIONAL_PATTERNS.md) - How imperative Haxe transforms to functional Elixir

## Task Completion and Documentation Protocol ⚠️
**CRITICAL**: After completing any task, MUST update TASK_HISTORY.md with comprehensive session documentation.

**See**: [`documentation/LLM_DOCUMENTATION_GUIDE.md`](documentation/LLM_DOCUMENTATION_GUIDE.md) - Complete task documentation protocol and templates

## Haxe API Reference
**See**: [`documentation/HAXE_API_REFERENCE.md`](documentation/HAXE_API_REFERENCE.md) - Complete Haxe standard library reference
- Common types: Array, String, Map, Sys, Math, Type, Reflect
- Modern API docs: https://api.haxe.org/


