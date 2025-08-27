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
- **⚠️ API Faithfulness**: Follow Elixir and Phoenix APIs exactly - never invent functions that don't exist. Provide Haxe conveniences via proper overloads, not fake APIs
- **Hand-Written Quality**: Generated code should look like it was written by an Elixir expert, not a machine
- **Transparent Bridge Variables**: When compiler-generated variables are needed (like `g` for switch expressions), add comments explaining their purpose
- **🔥 Pragmatic Stdlib Implementation**: Use `__elixir__()` for efficient native stdlib - [see Standard Library Philosophy](#standard-library-philosophy--pragmatic-native-implementation)

## 📚 Complete Documentation Index

**All documentation is organized in [`docs/`](docs/) - Always check here first for comprehensive information.**

### 🚀 Quick Navigation by Task Type

#### **New to Reflaxe.Elixir?**
→ **[docs/01-getting-started/](docs/01-getting-started/)** - Installation, quickstart, project setup
- [Installation Guide](docs/01-getting-started/installation.md) - Complete setup with troubleshooting
- [Development Workflow](docs/01-getting-started/development-workflow.md) - Day-to-day practices

#### **Building Applications?**
→ **[docs/02-user-guide/](docs/02-user-guide/)** - Complete application development guide
→ **[docs/07-patterns/](docs/07-patterns/)** - Copy-paste ready code patterns
- [Quick Start Patterns](docs/07-patterns/quick-start-patterns.md) - Essential copy-paste patterns

#### **Working on the Compiler?**
→ **[docs/03-compiler-development/](docs/03-compiler-development/)** - Specialized compiler development context
- [Compiler Development CLAUDE.md](docs/03-compiler-development/CLAUDE.md) - **AI context for compiler work**
- [Architecture Overview](docs/03-compiler-development/architecture.md) - How the compiler works
- [Testing Infrastructure](docs/03-compiler-development/testing-infrastructure.md) - Snapshot testing system

#### **Need Technical Reference?**
→ **[docs/04-api-reference/](docs/04-api-reference/)** - Technical references and API docs
→ **[docs/05-architecture/](docs/05-architecture/)** - System design documentation
→ **[`__elixir__()` Usage](#standard-library-philosophy--pragmatic-native-implementation)** - Native Elixir code injection for stdlib

#### **Troubleshooting Problems?**
→ **[docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)** - Comprehensive problem solving

## 🔗 Shared AI Context (Import System)

@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md
@docs/claude-includes/code-style.md
@docs/claude-includes/framework-integration.md

## 🚀 Essential Commands

### Development Workflow
```bash
# Build and test
npm test                          # Full test suite (mandatory before commit)
npx haxe build-server.hxml       # Compile Haxe to Elixir
mix compile --force               # Compile generated Elixir
mix phx.server                    # Run Phoenix application

# Integration testing
cd examples/todo-app && npx haxe build-server.hxml && mix compile
curl http://localhost:4000        # Test application response
```

### Quick Testing
```bash
make -C test test-name                     # Specific snapshot test
make -C test update-intended TEST=name     # Accept new output
MIX_ENV=test mix test                      # Runtime validation
```

### Advanced Debugging
```bash
# Enable macro stack traces for complex compiler issues
npx haxe build-server.hxml -D eval-stack -D debug_enum_introspection_compiler

# Profile compilation performance
npx haxe build-server.hxml -D eval-times

# Maximum debug visibility for AST issues
npx haxe build-server.hxml -D eval-stack -D debug_pattern_matching -D debug_expression_variants

# Interactive debugging support
npx haxe build-server.hxml -D eval-debugger
```

## CLAUDE.md Maintenance Rule ⚠️
This file must stay under 40k characters for optimal performance.
- Keep only essential agent instructions  
- Use imports from `docs/claude-includes/` for shared content
- Move detailed content to appropriate [docs/](docs/) sections
- Reference docs instead of duplicating content
- Review size after major updates: `wc -c CLAUDE.md`

### ❌ NEVER Add Detailed Technical Content to CLAUDE.md
When documenting new features or fixes:
1. **Create or update appropriate docs** in `docs/` directory
2. **Add only a brief reference** in CLAUDE.md with link to full documentation
3. **Check character count** before and after: `wc -c CLAUDE.md`
4. **If over 40k**, identify and move non-essential content out

## 📁 Project Directory Structure Map

**CRITICAL FOR NAVIGATION**: This monorepo contains multiple important projects and directories:

```
haxe.elixir/                          # Project root
├── docs/                             # 📚 ALL DOCUMENTATION (NEW STRUCTURE)
│   ├── 01-getting-started/           # Setup and quickstart
│   ├── 02-user-guide/                # Application development
│   ├── 03-compiler-development/      # Compiler contributor docs (with CLAUDE.md)
│   ├── 04-api-reference/             # Technical references
│   ├── 05-architecture/              # System design
│   ├── 06-guides/                    # How-to guides and troubleshooting
│   ├── 07-patterns/                  # Copy-paste code patterns
│   ├── 08-roadmap/                   # Vision and planning
│   ├── 09-history/                   # Historical records
│   └── 10-contributing/              # Contribution guidelines
├── src/reflaxe/elixir/                # 🔧 Compiler source code
│   ├── ElixirCompiler.hx              # Main transpiler
│   ├── helpers/                       # Specialized compilers
│   └── ...
├── std/                               # 📚 Standard library & framework types
├── test/                              # 🧪 Compiler snapshot tests
├── examples/todo-app/                 # 🎯 Main integration test & showcase
└── ...
```

**Key Locations for Common Tasks**:
- **Compiler bugs**: `src/reflaxe/elixir/`
- **Integration testing**: `examples/todo-app/`
- **Documentation**: `docs/` (ALL documentation)
- **Snapshot tests**: `test/tests/`

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify docs/ first** - All documentation is in the organized docs/ structure
2. **USE THE DIRECTORY MAP** - Navigate correctly using the structure above
3. **Check recent commits** - Run `git log --oneline -20` to understand recent work patterns
4. **Use specialized CLAUDE.md** - Check [docs/03-compiler-development/CLAUDE.md](docs/03-compiler-development/CLAUDE.md) for compiler work
5. **FOLLOW DOCUMENTATION GUIDE** - See [docs/](docs/) for comprehensive guides
6. **Check Haxe documentation** when needed:
   - https://api.haxe.org/ - Latest API reference
   - https://haxe.org/manual/ - Language documentation

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- **[docs/03-compiler-development/](docs/03-compiler-development/)** - Complete compiler development guide
- **[docs/03-compiler-development/macro-time-vs-runtime.md](docs/03-compiler-development/macro-time-vs-runtime.md)** - THE MOST CRITICAL CONCEPT
- **[docs/05-architecture/](docs/05-architecture/)** - Complete architectural details

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation.

## ⚠️ CRITICAL: NO BAND-AID FIXES EVER

**FUNDAMENTAL RULE: NEVER USE POST-PROCESSING OR BAND-AID FIXES. ALWAYS FIX THE ROOT CAUSE.**

**What counts as a band-aid fix:**
- ❌ **Post-processing filters** to clean up bad output after generation
- ❌ **String manipulation** to fix generated code issues  
- ❌ **Workarounds** that patch symptoms instead of fixing the cause
- ❌ **"Quick fixes"** that add complexity without solving the underlying issue
- ❌ **Conditional patches** for specific edge cases without understanding why they occur

**The correct approach:**
- ✅ **Understand WHY the issue happens** - Find the exact compilation step causing problems
- ✅ **Fix at the source** - Modify the compiler logic that generates the problematic code
- ✅ **Test the root fix** - Ensure the underlying problem is completely resolved
- ✅ **Comprehensive solution** - Fix should work for all similar cases, not just the specific instance

**Example of wrong vs right approach:**
```haxe
// ❌ WRONG: Band-aid fix
var result = patternMatchingCompiler.compile(...);
result = cleanupOrphanedVariables(result); // Post-processing patch
return result;

// ✅ RIGHT: Root cause fix  
// Modify the pattern matching compiler itself to not generate orphaned variables
// by detecting empty case bodies and avoiding parameter extraction
```

**Remember**: If you're adding a "cleanup" step, you're probably doing it wrong. Fix the generator, not the output.

## ⚠️ CRITICAL: Use Reflaxe's Established Architecture Patterns

**FUNDAMENTAL RULE: NEVER INVENT AD-HOC DETECTION SYSTEMS. USE REFLAXE'S ESTABLISHED PATTERNS.**

**What counts as ad-hoc architectural deviation:**
- ❌ **Custom detection systems** when Reflaxe provides standard solutions
- ❌ **Hardcoded pattern matching** instead of using metadata systems
- ❌ **Timing-dependent fixes** that rely on compilation order assumptions
- ❌ **Context-specific workarounds** that don't scale to other use cases

**The Reflaxe way:**
- ✅ **Use Reflaxe's preprocessor system** - MarkUnusedVariablesImpl for unused variable detection
- ✅ **Check established metadata** - Look for `-reflaxe.unused` instead of inventing detection
- ✅ **Follow DirectToStringCompiler patterns** - Extend established base class methods
- ✅ **Study reference implementations** - Check `/haxe.elixir.reference/reflaxe/` for patterns

**LESSON LEARNED: Orphaned Variable Detection**
When we encountered orphaned `g_array` variables:
- ❌ **WRONG**: Invented custom `isParameterTrulyOrphaned()` detection
- ❌ **WRONG**: Made assumptions based on compilation timing
- ✅ **RIGHT**: Use Reflaxe's `MarkUnusedVariablesImpl` + `-reflaxe.unused` metadata
- ✅ **RIGHT**: Check existing VariableCompiler patterns that already handle this metadata

**Example of architectural alignment:**
```haxe
// ❌ WRONG: Ad-hoc detection
private function isParameterTrulyOrphaned(ef: EnumField, index: Int): Bool {
    // Custom logic based on assumptions...
}

// ✅ RIGHT: Use Reflaxe metadata system
if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
    return ""; // Skip generation - Reflaxe preprocessor marked this as unused
}
```

**Remember**: Reflaxe is a mature framework. If you're inventing something from scratch, check if Reflaxe already provides it.

## ⚠️ CRITICAL: NO ENUM-SPECIFIC HARDCODING EVER

**FUNDAMENTAL RULE: NEVER HARDCODE SPECIFIC ENUM NAMES OR TYPES IN COMPILER LOGIC. ALWAYS USE GENERAL PATTERNS.**

**What counts as enum-specific hardcoding:**
- ❌ **Hardcoded enum names** like `if (ef.name == "TypeSafeChildSpec")` in compiler logic
- ❌ **Constructor-specific switches** like `switch(ef.name) { case "Repo": ...; case "Telemetry": ...; }`
- ❌ **Parameter index hardcoding** for specific enum constructors
- ❌ **Type-specific workarounds** that only work for particular enum definitions
- ❌ **Maintenance nightmares** that require updating compiler code when enums change

**The correct approach:**
- ✅ **Detect patterns, not names** - Analyze AST structure and usage patterns
- ✅ **Context-aware detection** - Use compilation context to determine parameter usage
- ✅ **General algorithms** - Write code that works for ANY enum with similar patterns
- ✅ **AST analysis** - Look at actual usage in the AST, not hardcoded type assumptions

**Example of wrong vs right approach:**
```haxe
// ❌ WRONG: Hardcoded enum-specific logic
var orphaned = switch(ef.name) {
    case "Repo": index == 0;      // Hardcoded!
    case "Telemetry": index == 0; // Hardcoded!
    case "Endpoint": index == 1;  // Hardcoded!
    case _: false;
};

// ✅ RIGHT: General pattern detection
var orphaned = isParameterUnusedInCurrentContext(e, ef, index);
// Uses AST analysis to detect unused parameters regardless of enum type
```

**Why this matters:**
- **Maintenance**: Adding new enums shouldn't require compiler changes
- **Generalization**: The compiler should work for user-defined enums, not just stdlib
- **Architectural integrity**: Type-specific logic belongs in type definitions, not the compiler
- **Future-proofing**: Enum definitions will evolve - the compiler should adapt automatically

**Remember**: If you're checking specific enum names in the compiler, you're creating technical debt that will break when enums change.

## ⚠️ CRITICAL: Comprehensive Documentation Rule for ALL Compiler Code

**FUNDAMENTAL RULE: Every piece of compiler logic MUST include comprehensive documentation and XRay debug traces.**

### The Five Mandatory Elements:
1. **Class-Level HaxeDoc with WHY/WHAT/HOW** - Comprehensive class purpose and architecture documentation
2. **Function-Level WHY/WHAT/HOW Documentation** - Explain reasoning, purpose, and implementation
3. **XRay Debug Traces** - Provide runtime visibility with `#if debug_feature` blocks
4. **Pattern Detection Visibility** - Show what patterns are detected and why
5. **Edge Case Documentation** - Document known limitations and special handling

### 1. Class-Level HaxeDoc Requirements (NEW MANDATE)

**ALL compiler classes MUST have comprehensive class-level documentation following the WHY/WHAT/HOW pattern:**

```haxe
/**
 * CLASS_NAME: Brief class purpose
 * 
 * WHY: Explain the problem this class solves and architectural decisions
 * - What problem in compiler design this addresses
 * - Why this separation/extraction was needed
 * - What happens if this class doesn't exist
 * - How it fits into overall compiler architecture
 * 
 * WHAT: High-level class responsibilities and capabilities
 * - Primary operations and transformations
 * - Key patterns handled or generated
 * - Integration points with other compiler components
 * - Public API surface and usage patterns
 * 
 * HOW: Implementation approach and internal architecture
 * - Key algorithms and data structures used
 * - Major internal methods and their responsibilities
 * - Collaboration patterns with other classes
 * - Extension points and future considerations
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Clear separation of concerns
 * - Open/Closed Principle: Extension without modification
 * - Testability: Independent testing capabilities
 * - Maintainability: Clear boundaries and interfaces
 * - Performance: Optimized for specific use cases
 * 
 * EDGE CASES:
 * - Known limitations and workarounds
 * - Special handling requirements
 * - Integration complexity points
 * - Future improvement areas
 * 
 * @see documentation/RELATED_ARCHITECTURE.md - Related patterns and designs
 */
@:nullSafety(Off)
class CompilerClass {
    // Implementation...
}
```

**Example**: See `VariableCompiler.hx` for a complete implementation of this pattern.

### Example Template:
```haxe
/**
 * FEATURE NAME: Brief description
 * 
 * WHY: Problem being solved and rationale
 * WHAT: High-level operation description  
 * HOW: Step-by-step implementation details
 * EDGE CASES: Special scenarios and limitations
 */
function compilerFunction() {
    #if debug_feature
    trace("[XRay Feature] OPERATION START");
    trace('[XRay Feature] Input: ${input.substring(0, 100)}...');
    #end
    
    // Implementation with visibility
    
    #if debug_feature
    trace("[XRay Feature] ✓ PATTERN DETECTED");
    trace("[XRay Feature] OPERATION END");
    #end
}
```

**See**: [`docs/03-compiler-development/COMPREHENSIVE_DOCUMENTATION_STANDARD.md`](docs/03-compiler-development/COMPREHENSIVE_DOCUMENTATION_STANDARD.md) - Complete documentation standards and XRay patterns

## ⚠️ CRITICAL: File Size and Maintainability Standards

**FUNDAMENTAL RULE: Large files are maintenance debt and MUST be refactored.**

### File Size Guidelines (Based on Reflaxe Reference Implementations)

| File Type | Target Size | Maximum Size | Current State |
|-----------|-------------|--------------|---------------|
| **Utility Classes** | 100-300 lines | 500 lines | ✅ Most helpers good |
| **Helper Compilers** | 300-800 lines | 1,200 lines | ✅ Most helpers good |
| **Main Compiler** | 800-1,500 lines | 2,000 lines | ❌ **ElixirCompiler.hx: 10,661 lines!** |
| **Complex Compilers** | 1,000-2,000 lines | 2,500 lines | Expression compilation |

### ⚠️ MANDATORY REFACTORING TRIGGERS

A file MUST be refactored when:
- [ ] Size exceeds maximum guidelines (ElixirCompiler.hx is 5x too large!)
- [ ] Multiple responsibilities are mixed (loops + expressions + patterns + utilities)
- [ ] Changes frequently break unrelated functionality  
- [ ] Debugging requires scrolling through thousands of lines
- [ ] New developers struggle to understand the file

### Single Responsibility Principle

Each file should have **one clear reason to change**:

✅ **GOOD Examples**:
- `LoopCompiler.hx` - Only handles loop compilation and optimization
- `PatternDetector.hx` - Only detects AST patterns  
- `CompilerUtilities.hx` - Only provides shared utility functions

❌ **BAD Examples**:
- `ElixirCompiler.hx` (current) - Handles loops, expressions, patterns, utilities, types, etc.

### Refactoring Standards

**Every extraction must include**:
- Complete HaxeDoc for all functions
- **⚠️ MANDATORY WHY/WHAT/HOW documentation** - Every new class, entity, or code must comprehensively justify its existence with WHY (problem being solved), WHAT (responsibilities and capabilities), HOW (implementation approach)
- XRay debug traces for compilation functions
- Single responsibility focus
- Test coverage to prevent regressions

**Validation**: `npm test && cd examples/todo-app && npx haxe build-server.hxml && mix compile`

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

## 🔄 Compiler-Example Development Feedback Loop

**CRITICAL UNDERSTANDING**: Working on examples (todo-app, etc.) is simultaneously **compiler development**. Examples are **living compiler tests** that reveal bugs and drive improvements.

### Development Rules
- ✅ **Example fails to compile**: This is compiler feedback, not user error
- ✅ **Generated .ex files invalid**: Fix the transpiler, don't patch files
- ❌ **Never manually edit generated files**: They get overwritten on recompilation
- ❌ **Don't work around compiler bugs**: Fix the root cause in transpiler source
- ❌ **NEVER keep dead code 'just in case'**: Only keep code that's actually used
- ❌ **No unnecessary abstraction layers**: Don't add indirection without value (e.g., routers that don't route)

### Architectural Component Naming Rule
**CRITICAL**: Name components by what they actually DO, not what you wish they did:
- A "Router" must make routing decisions between multiple destinations
- A "Compiler" must compile/transform code
- A "Manager" must manage state or lifecycle
- Pure delegation/passthrough is NOT routing, managing, or controlling
- If you can't describe the component's value in one sentence, it shouldn't exist

## 📍 Agent Navigation Guide

### When Writing or Fixing Tests
→ **[docs/03-compiler-development/testing-infrastructure.md](docs/03-compiler-development/testing-infrastructure.md)** - Critical testing rules and snapshot testing

### When Implementing New Features  
→ **[docs/07-patterns/](docs/07-patterns/)** - Code patterns and examples
→ **[docs/03-compiler-development/best-practices.md](docs/03-compiler-development/best-practices.md)** - Development practices

### When Working on Examples (todo-app, etc.)
→ **Remember**: Examples are **compiler testing grounds** - failures reveal compiler bugs
→ **[docs/01-getting-started/development-workflow.md](docs/01-getting-started/development-workflow.md)** - Complete workflow guide

### When Dealing with Framework Integration Issues
→ **[docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)** - Comprehensive troubleshooting
→ **Framework Integration**: Generated code MUST follow target framework conventions exactly

## Haxe-First Philosophy ⚠️ FUNDAMENTAL RULE

**Write EVERYTHING in Haxe unless technically impossible. Type safety everywhere, not just business logic.**

### Developer Choice and Flexibility
- **Pure Haxe preferred**: Write implementations in Haxe for maximum control
- **Typed externs welcome**: Leverage the rich Elixir ecosystem with full type safety
- **Dual-API standard library**: Use cross-platform OR platform-specific methods as needed
- **NO DYNAMIC OR ANY**: Never use Dynamic or Any in any Haxe code

**The goal**: Maximum developer flexibility with complete type safety.

## Standard Library Philosophy ⚡ **PRAGMATIC NATIVE IMPLEMENTATION**

### The `__elixir__()` Function - Available and Encouraged for Stdlib

**IMPORTANT CLARIFICATION**: `__elixir__()` IS available and can be strategically used for standard library implementations.

```haxe
// ✅ AVAILABLE: Direct Elixir code injection for efficient stdlib implementation
var result = untyped __elixir__('IO.puts("Direct Elixir code")');
var formatted = untyped __elixir__('Jason.encode!(data)');
```

### Pragmatic Stdlib Implementation Strategy

**Philosophy**: Use the right tool for the job - combine Haxe's type safety with Elixir's native efficiency.

1. **Type-Safe Interface**: Haxe provides the typed API surface
2. **Native Implementation**: Use `__elixir__()` or `@:native` for efficient Elixir implementation  
3. **Best of Both Worlds**: Cross-platform API with idiomatic target code

#### Example: StringBuf Implementation
```haxe
// Type-safe Haxe interface
class StringBuf {
    var iolist: Dynamic;
    
    public function new() {
        // Use native Elixir IO lists for efficiency
        iolist = untyped __elixir__('[]');
    }
    
    public function add(x: String): Void {
        // Native Elixir list concatenation
        iolist = untyped __elixir__('$iolist ++ [$x]');
    }
    
    public function toString(): String {
        // Native Elixir binary conversion
        return untyped __elixir__('IO.iodata_to_binary($iolist)');
    }
}
```

### Implementation Priority

1. **Prefer Native Efficiency**: Use `__elixir__()` for performance-critical stdlib
2. **Maintain Type Safety**: Wrap all native code in typed Haxe interfaces
3. **Support All Haxe Code**: Ensure Turing completeness and full Haxe compatibility
4. **Idiomatic Output**: Generated code should leverage target platform strengths

**The Goal**: Complete Haxe standard library support with efficient, idiomatic Elixir implementations.

**See**: [`docs/05-architecture/`](docs/05-architecture/) - Complete implementation guidelines

## Quality Standards
- Zero compilation warnings, Reflaxe snapshot testing approach
- **Date Rule**: Always run `date` command before writing timestamps
- **CRITICAL: Idiomatic Elixir Code Generation** - Generate high-quality, functional Elixir code
- **Testing Protocol**: ALWAYS run `npm test` after compiler changes

## Mandatory Testing Protocol ⚠️ CRITICAL

**EVERY compiler change MUST be validated through the complete testing pipeline.**

### After ANY Compiler Change
1. **Run Full Test Suite**: `npm test` - ALL tests must pass
2. **Test Todo-App Integration**:
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex
   npx haxe build-server.hxml
   mix compile --force
   ```

**Rule**: If ANY step fails, the compiler change is incomplete. Fix the root cause.

**See**: [docs/03-compiler-development/testing-infrastructure.md](docs/03-compiler-development/testing-infrastructure.md) - Complete testing guide

## Development Principles

### ⚠️ CRITICAL: Create Focused Regression Tests for Every Bug Fix
**FUNDAMENTAL RULE: Every bug fix MUST have a dedicated regression test to prevent reoccurrence.**

When fixing a bug:
1. **Create a focused test** in `test/tests/` that reproduces the exact bug scenario
2. **Name it descriptively** (e.g., `underscore_prefix_consistency`, `orphaned_enum_parameters`)
3. **Document the bug** in the test file's header comment with:
   - What the bug was
   - Why it happened
   - What the fix does
   - Link to relevant commits/issues
4. **Generate intended output** after the fix is verified
5. **Add to CI** to ensure the bug never returns

**Example**: The `underscore_prefix_consistency` test ensures variables with underscore prefixes maintain consistency throughout generated code - preventing the duplicate instance bug where VariableCompiler's state wasn't shared.

**Benefits**:
- **Prevents regressions** - Bugs stay fixed forever
- **Documents issues** - Future developers understand what went wrong
- **Fast validation** - Run specific test to verify fix still works
- **Confidence in refactoring** - Know immediately if changes break fixes

### ⚠️ CRITICAL: Always Check Recent Work Before Starting
**FUNDAMENTAL RULE: Check git history and recent commits to understand what's been done and avoid repeating work.**
- Run `git log --oneline -20` to see recent commits  
- Review related files for recent changes
- Never start debugging without understanding what's already been tried
- Avoid repeating fixes that were already attempted

### ⚠️ CRITICAL: Never Confirm Something Works Without Actual Tests
**FUNDAMENTAL RULE: Don't confirm something is working before being 100% sure by verifying with actual tests.**
- Always run `npm test` after changes
- Test todo-app compilation: `cd examples/todo-app && npx haxe build-server.hxml && mix compile`
- Verify the application runs: `mix phx.server`
- Check for runtime errors, not just compilation success
- Never say "it's fixed" without running the complete test suite

### ⚠️ CRITICAL: Avoid Regressions and Circular Work
**FUNDAMENTAL RULE: Avoid regressions and walking in circles by checking previous work.**
- Check git history before attempting a fix: `git log --oneline -30 --grep="issue_keywords"`
- Review git blame for recently changed code: `git blame path/to/file`
- Look for TODO/FIXME comments in related files
- If something was already tried and reverted, understand WHY before trying again
- Document WHY previous approaches failed to prevent repeating mistakes

### ⚠️ CRITICAL: No Ad-Hoc Fixes - Solve Root Architectural Problems
**FUNDAMENTAL RULE: Never apply band-aid fixes - always solve the root architectural problem.**
- **NO string replacements** like `if (x == "wrong") x = "right"` - find WHY it's wrong
- **NO special case handling** without understanding the general pattern
- **NO symptom patching** - trace back to where the problem originates
- **NO quick fixes** - even if they work, refactor to fix the root cause
- **NO fallback mechanisms** - fix the primary system instead of adding backup logic
- **Always ask**: Why is this happening? What's the root cause?
- **The fix must be general** - it should solve ALL similar cases, not just the one you found
- **Example of wrong approach**: Replacing "g_counter" with "g" in output
- **Example of wrong approach**: Adding fallback to check secondary mapping when primary fails
- **Example of right approach**: Fix the variable mapping system that creates "g_counter" incorrectly
- **Example of right approach**: Register mappings at TVar creation time, not retroactively
- **ZERO TOLERANCE FOR QUICK FIXES**: The user has explicitly stated they don't want quick fixes in this compiler. Always implement the proper architectural solution, even if it takes more time.

### ⚠️ CRITICAL: Debug-First Development - No Assumptions
**FUNDAMENTAL RULE: Always rely on debug data first. If you don't see the data/AST, don't assume things.**
- Add comprehensive debug traces to understand actual behavior
- Use XRay debug patterns to visualize AST transformations
- Never guess what the compiler is doing - instrument and observe
- When debugging issues, add traces FIRST, then analyze

### ⚠️ CRITICAL: No Untyped Usage in Compiler Code
**FUNDAMENTAL RULE: NEVER use `untyped` or `Dynamic` in compiler code unless there's a very good justified reason.**

- All field access must be properly typed
- If fields are public, access them directly instead of using `untyped`
- Document any exceptional cases where `untyped` is absolutely necessary with full justification
- Prefer explicit typing and proper interfaces over dynamic access
- **See**: [`docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md`](docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md) - Complete type safety standards

### ⚠️ CRITICAL: No Direct Elixir Files - Everything Through Haxe
**FUNDAMENTAL RULE: NEVER write .ex files directly. Everything must be generated from Haxe.**

### ⚠️ CRITICAL: Check Haxe Standard Library First
**FUNDAMENTAL RULE: Always check if Haxe stdlib already offers something before implementing it ourselves.**

### ⚠️ CRITICAL: Type Safety and String Avoidance
**FUNDAMENTAL RULE: Avoid strings in compiler code unless absolutely necessary.**

### ⚠️ CRITICAL: No Dead Code - Remove Unused Functions
**FUNDAMENTAL RULE: NEVER keep dead code "just in case" - only keep code that's actually used.**
- **NO keeping unused methods** for "compatibility" or "future use"
- **NO commented-out code blocks** - use git history if you need to recover old code
- **NO delegation methods** that just return null or empty values
- **Delete immediately** when functionality is moved elsewhere
- **If it's not called, delete it** - the codebase must be clean and maintainable
- **Example of wrong approach**: Keeping detectArrayBuildingPattern() that returns null "for compatibility"
- **Example of right approach**: Delete the method entirely when WhileLoopCompiler is removed

### ⚠️ CRITICAL: No Untyped Usage
**FUNDAMENTAL RULE: NEVER use `untyped` or `Dynamic` unless there's a very good justified reason.**
- All field access must be properly typed
- If fields are public, access them directly instead of using `untyped`
- Document any exceptional cases where `untyped` is absolutely necessary
- Prefer explicit typing and proper interfaces over dynamic access

## 🏗️ Architecture & Refactoring Guidelines

### ⚠️ CRITICAL: Prevent Monolithic Files (LEARNED FROM 10,668-LINE DISASTER)

**FUNDAMENTAL RULE: NO SOURCE FILE MAY EXCEED 2000 LINES. IDEAL: 200-500 LINES.**

#### The Single Responsibility Principle (ENFORCED)
- **One file = One responsibility** - If you can't describe a file's purpose in one sentence, split it
- **Extract early, extract often** - Don't wait until a file is 10k+ lines to refactor
- **Helper pattern** - Use `helpers/` directory for specialized compilers (PatternMatchingCompiler, SchemaCompiler, etc.)

#### File Size Limits (MANDATORY)
```
✅ IDEAL:       200-500 lines   (focused, maintainable)
⚠️  ACCEPTABLE:  500-1000 lines  (consider splitting)
🚨 WARNING:     1000-2000 lines (must have justification)
❌ FORBIDDEN:   >2000 lines     (automatic refactoring required)
```

#### Extraction Guidelines
When a file approaches 1000 lines, IMMEDIATELY:
1. **Identify logical sections** - Look for groups of related functions
2. **Extract helper modules** - Create specialized compilers in `helpers/`
3. **Use delegation pattern** - Main compiler delegates to helpers
4. **Document with WHY/WHAT/HOW** - Every extracted module needs comprehensive docs

#### Example Structure (FROM OUR REFACTORING)
```
ElixirCompiler.hx (main orchestrator, <2000 lines)
├── helpers/PatternMatchingCompiler.hx  (~400 lines - switch/case compilation)
├── helpers/SchemaCompiler.hx           (~350 lines - @:schema/@:changeset)
├── helpers/MigrationCompiler.hx        (~150 lines - @:migration)
├── helpers/LiveViewCompiler.hx         (~220 lines - @:liveview)
├── helpers/GenServerCompiler.hx        (~280 lines - @:genserver)
├── helpers/ExpressionCompiler.hx       (~500 lines - expression utilities)
├── helpers/ReflectionCompiler.hx       (~450 lines - Reflect.fields)
└── helpers/LoopCompiler.hx            (~500 lines - for/while optimization)
```

#### Red Flags That Demand Immediate Refactoring
- 🚨 **191 switch statements in one file** - Extract pattern matching
- 🚨 **100+ repeated code patterns** - Create utility functions
- 🚨 **Multiple responsibilities** - Split into focused modules
- 🚨 **Deep nesting (>4 levels)** - Extract helper methods
- 🚨 **Long functions (>100 lines)** - Break into smaller functions

### Testing During Refactoring (MANDATORY)
```bash
# After EVERY extraction:
npm test                    # Must pass ALL tests

# After 2-3 extractions:
cd examples/todo-app && npx haxe build-server.hxml && mix compile --force
```

**NEVER** complete a refactoring session without full test validation.

## Known Issues  
- **Array Mutability**: Methods like `reverse()` and `sort()` don't mutate in place (Elixir lists are immutable)

## Recently Resolved Issues ✅
- **Array Desugaring & Y Combinator Patterns**: Discovered how Haxe desugars array.filter/map into TBlock/TWhile patterns and implemented detection framework (see [`docs/03-compiler-development/ARRAY_DESUGARING_PATTERNS.md`](docs/03-compiler-development/ARRAY_DESUGARING_PATTERNS.md))
- **Untyped Usage Violations**: Eliminated all unnecessary `untyped` usage in compiler code (VariableCompiler, OperatorCompiler, ControlFlowCompiler) for better type safety and IDE support
- **Orphaned Enum Parameter Variables**: Fixed compilation errors from unused TEnumParameter expressions in switch cases by implementing comprehensive AST-level detection and mitigation. First Reflaxe compiler to solve this fundamental issue caused by bypassing Haxe's optimizer (see [`docs/03-compiler-development/AST_CLEANUP_PATTERNS.md`](docs/03-compiler-development/AST_CLEANUP_PATTERNS.md))
- **Y Combinator Struct Update Patterns**: Fixed malformed inline if-else expressions with struct updates by forcing block syntax (see [`docs/03-compiler-development/Y_COMBINATOR_PATTERNS.md`](docs/03-compiler-development/Y_COMBINATOR_PATTERNS.md))
- **Variable Substitution in Lambda Expressions**: Fixed with proper AST variable tracking
- **Hardcoded Application Dependencies**: Removed all hardcoded references

## Commit Standards
**Follow [Conventional Commits](https://www.conventionalcommits.org/)**: `<type>(<scope>): <subject>`
- **NO AI attribution**: Never add "Generated with Claude Code" or "Co-Authored-By: Claude"

## Development Loop ⚡ **CRITICAL WORKFLOW**

**MANDATORY: Every development change MUST follow this complete validation loop:**

```bash
# 1. Run full test suite (ALL tests must pass)
npm test

# 2. Verify todo-app compiles and runs
cd examples/todo-app && npx haxe build-server.hxml && mix compile --force && mix phx.server
```

**Rule**: If ANY step in this loop fails, the development change is incomplete.

## Implementation Status
**See**: [`docs/08-roadmap/`](docs/08-roadmap/) - Complete feature status and production readiness

**v1.0 Status**: ALL COMPLETE ✅ - Core features, Phoenix Router DSL, LiveView, Ecto, OTP patterns, Mix integration, Testing

## Test Status Summary
**See**: [`docs/03-compiler-development/testing-infrastructure.md`](docs/03-compiler-development/testing-infrastructure.md) - Complete test architecture and status

## Development Resources & Reference Strategy
- **Reference Codebase**: `/REDACTED_LOCAL_PATH` - **CRITICAL**: Contains working Reflaxe compiler patterns, Haxe API usage examples, and Phoenix integration patterns. ALWAYS check here first for:
  - Haxe macro API usage patterns
  - Reflaxe compiler implementation examples  
  - Working AST processing patterns
  - Test infrastructure patterns
- **Haxe API Documentation**: https://api.haxe.org/ - For type system and language features  
- **Haxe Manual**: https://haxe.org/manual/ - **CRITICAL**: Always consult for advanced features
- **Web Resources**: Use WebSearch and WebFetch for current documentation
- **Principle**: Always reference existing working code rather than guessing

## Documentation References
**Complete Documentation Index**: [`docs/README.md`](docs/README.md) - Comprehensive guide to all project documentation

**Quick Access**:
- **Installation**: [docs/01-getting-started/installation.md](docs/01-getting-started/installation.md)
- **Development Workflow**: [docs/01-getting-started/development-workflow.md](docs/01-getting-started/development-workflow.md)
- **Quick Patterns**: [docs/07-patterns/quick-start-patterns.md](docs/07-patterns/quick-start-patterns.md)
- **Troubleshooting**: [docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)
- **Compiler Development**: [docs/03-compiler-development/CLAUDE.md](docs/03-compiler-development/CLAUDE.md)

---

**Remember**: All detailed information is in the organized [docs/](docs/) structure. This file provides navigation and critical rules only.