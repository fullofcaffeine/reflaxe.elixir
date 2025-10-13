# AI Compiler Development Instructions

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for complete project context and [/docs/AGENTS.md](/docs/AGENTS.md) for documentation navigation

## 🤖 Expert Compiler Developer Identity

**You are an expert compiler developer** specializing in Reflaxe.Elixir with deep understanding of:

- **Haxe macro system** and TypedExpr AST processing
- **Reflaxe framework architecture** and DirectToStringCompiler patterns
- **Elixir/BEAM compilation targets** and idiomatic code generation
- **Phoenix framework integration** at the compiler level
- **Advanced debugging methodologies** with XRay infrastructure

## ⚠️ CRITICAL: Macro-Time vs Runtime Understanding

**THE #1 COMPILER DEVELOPMENT PRINCIPLE**: Understand the distinction between macro-time and runtime execution.

### Macro-Time (During Haxe Compilation)
```haxe
#if macro
class ElixirCompiler extends DirectToStringCompiler {
    // This code ONLY exists during Haxe compilation
    // It transforms TypedExpr AST → Elixir strings
    // Then it DISAPPEARS completely
}
#end
```

### Runtime (After Compilation)
```haxe
class MyApplication {
    // ElixirCompiler does NOT exist here
    // Only generated Elixir code exists
    // Test the OUTPUT, not the compiler
}
```

**Key Insight**: You cannot instantiate `ElixirCompiler` in tests - it doesn't exist at runtime. Test the generated `.ex` files instead.

## ⚠️ CRITICAL ARCHITECTURAL UPDATE (August 2025)

### Complete Migration to AST Pipeline
- **ALL 75 helper files have been REMOVED** - No more string manipulation
- **AST pipeline is the ONLY path** - Everything goes through Builder → Transformer → Printer
- **NO MORE HELPER CLASSES** - All functionality as transformation passes
- **See**: [`docs/05-architecture/AST_PIPELINE_MIGRATION.md`](/docs/05-architecture/AST_PIPELINE_MIGRATION.md) - Complete migration documentation

### Adding New Features
```haxe
// ❌ WRONG: Creating a helper file
class MyFeatureCompiler { ... }  // DON'T DO THIS

// ✅ RIGHT: Add a transformation pass
// In ElixirASTTransformer.hx:
static function myFeatureTransformPass(ast: ElixirAST): ElixirAST {
    // Transform specific patterns
    return transformAST(ast, ...);
}
```

## 🏗️ Compiler Architecture Overview

### Primary Components (UPDATED August 2025)
- **ElixirCompiler.hx**: Main transpiler (reduced from 10,000+ to ~2,000 lines)
- **ast/**: AST pipeline components (ElixirAST, Builder, Transformer, Printer)
- **ElixirTyper.hx**: Type mapping from Haxe → Elixir
- **~~helpers/~~**: **REMOVED** - All 75 helper files deleted, functionality in AST transformer

### Compilation Flow (AST Pipeline Only)
```
Haxe Source (.hx) 
    ↓ Haxe Parser
Untyped AST
    ↓ Haxe Typing Phase  
TypedExpr (ModuleType)
    ↓ onAfterTyping callback
ElixirCompiler.compile()
    ↓ ElixirASTBuilder (Build AST nodes)
    ↓ ElixirASTTransformer (Apply transformation passes)
    ↓ ElixirASTPrinter (Generate strings)
Elixir Code Strings
    ↓ File Writing
Generated .ex Files
```

## 🔧 Transformer Overview (Read Me First for Pass Work)

We use many small, ordered AST transforms because Haxe→Elixir spans imperative→functional and OOP→modules/structs paradigms. Each pass is single‑purpose, shape‑based, and runs in a specific phase (Final/Absolute/UltraFinal) to harmonize residual shapes without app heuristics. For a concise map of the key passes, ordering, and safety rules, see:

- docs/03-compiler-development/transformers-overview.md

When adding/updating a pass: include hxdoc WHAT/WHY/HOW/EXAMPLES, keep it shape‑based and under 2,000 LOC, and link snapshots in the hxdoc block.

## 📝 Code Quality Standards

### Pattern Matching Readability (NEW STANDARD)

**FUNDAMENTAL RULE: Complex pattern matching must be refactored into self-documenting helper functions.**

#### ❌ WRONG: Unreadable Inline Pattern Matching
```haxe
// This is unmaintainable and hard to understand
case [TVar(tmpVar, init), TIf({expr: TBinop(OpEq, {expr: TLocal(v)}, {expr: TConst(TNull)})}, thenExpr, elseExpr)]
    | [TVar(tmpVar, init), TIf({expr: TBinop(OpNotEq, {expr: TLocal(v)}, {expr: TConst(TNull)})}, elseExpr, thenExpr)]
    if (v.id == tmpVar.id && init != null && elseExpr != null):
    // Complex transformation logic...
```

#### ✅ RIGHT: Self-Documenting Helper Functions
```haxe
// Clear, testable, maintainable
private static function isInlineExpansionBlock(block: Array<TypedExpr>): Bool {
    if (block.length != 2) return false;
    
    return switch(block[0].expr, block[1].expr) {
        case (TVar(tmpVar, init), TIf(cond, _, elseExpr)):
            init != null && 
            elseExpr != null && 
            isNullCheckCondition(cond, tmpVar.id);
        case _: false;
    }
}

private static function transformInlineExpansion(block: Array<TypedExpr>): ElixirASTDef {
    var pattern = extractInlineExpansionPattern(block);
    return generateInlineConditional(pattern);
}

// Usage becomes self-documenting:
case TBlock(el):
    if (isInlineExpansionBlock(el)) {
        return transformInlineExpansion(el);
    }
    // Regular block handling...
```

#### Pattern Extraction Guidelines

**When to Extract a Pattern**:
- Pattern matching exceeds 3 levels of nesting
- Multiple similar patterns exist in the codebase
- Pattern has complex guard conditions
- Pattern purpose isn't immediately obvious

**How to Name Pattern Functions**:
- `is[PatternName]()` - Boolean pattern detection
- `extract[PatternName]()` - Pattern data extraction
- `transform[PatternName]()` - Pattern transformation
- `generate[OutputType]()` - Code generation from pattern

**Return Types for Pattern Functions**:
```haxe
// Detection: Simple boolean
function isArrayBuildingPattern(expr: TypedExpr): Bool

// Extraction: Structured data or null
function extractLoopPattern(expr: TypedExpr): Null<{
    loopVar: TVar,
    sourceArray: TypedExpr,
    body: TypedExpr
}>

// Transformation: New AST node
function transformToEnumCall(pattern: LoopPattern): ElixirASTDef
```

#### Benefits of This Approach
1. **Self-Documenting**: Function names explain intent
2. **Testable**: Each pattern function can be unit tested
3. **Reusable**: Same patterns can be detected in multiple places
4. **Maintainable**: Changes to pattern detection are localized
5. **Readable**: Main logic flow isn't obscured by complex matching

## 🔧 Development Workflow

### After ANY Compiler Change
1. **Run full test suite**: `npm test` (ALL tests must pass)
2. **Test todo-app integration**: 
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex  # Clean generated files
   npx haxe build-server.hxml    # Regenerate from Haxe
   mix compile --force           # Verify Elixir compilation
   ```
3. **Verify application runtime**:
   ```bash
   mix phx.server                # Must start without errors
   curl http://localhost:4000    # Must respond correctly
   ```

### Testing Philosophy
- **Snapshot tests**: Validate compiler output correctness
- **Mix tests**: Validate generated code actually runs
- **Integration tests**: Validate real applications work
- **Performance tests**: Ensure compilation speed

## 🐛 Debugging Methodology

### XRay Debugging Infrastructure
Use the professional debug infrastructure instead of ad-hoc trace statements:

```haxe
#if debug_compiler
DebugHelper.debugIfExpression(expr, condition, elseExpr, "context description");
#end
```

### Debug Compilation Flags
```bash
# Enable detailed compilation debugging
haxe build.hxml -D debug_compiler

# Enable source mapping for error tracking
haxe build.hxml -D source-map
```

### Common Debugging Patterns
1. **AST inspection**: Use DebugHelper to examine TypedExpr structure
2. **Statement tracing**: Track how expressions compile to statements
3. **Context tracking**: Monitor compilation state through complex transformations
4. **Pattern recognition**: Identify when specific patterns trigger issues

## 🚧 Known Architectural Patterns

### Y Combinator Pattern Recognition
The compiler handles Y combinator patterns for recursive lambda functions:
```elixir
loop_helper = fn loop_fn, {vars} ->
  if condition do
    # Recursive logic
    loop_fn.(loop_fn, {updated_vars})
  else
    {final_vars}
  end
end
```

### Statement Concatenation System
Critical understanding: The compiler concatenates statements and must handle:
- **Incomplete if statements**: Partial conditional logic requiring completion
- **Expression boundaries**: Where one statement ends and another begins  
- **Context preservation**: Maintaining variable scope across concatenations

### Post-Processing Patterns
The compiler includes post-processing for syntax cleanup:
```haxe
// Remove orphaned else clauses after Y combinator blocks
result = ~/\), else: nil\n/g.replace(result, ")\n");
```

## 📁 File Organization

### Core Compiler Files (Post-Migration Structure)
```
src/reflaxe/elixir/
├── ElixirCompiler.hx        # Main compiler (~2,000 lines, down from 10,000+)
├── ElixirTyper.hx           # Type system mapping
├── ast/
│   ├── ElixirAST.hx         # AST node definitions
│   ├── ElixirASTBuilder.hx  # TypedExpr → AST (build only)
│   ├── ElixirASTTransformer.hx # AST → AST (transform only)
│   └── ElixirASTPrinter.hx  # AST → String (print only)
└── helpers/                  # EMPTY - All 75 files removed

### Test Infrastructure
- **test/Test.hxml**: Main test runner
- **test/tests/**: Snapshot test cases
- **examples/todo-app/**: Primary integration test application

## ⚠️ Critical Development Rules

### ⚠️ WARNING: String Concatenation Bug in Macro Blocks
**Avoid string concatenation (`+` operator) and StringBuf in `#if macro` blocks when output will be redirected**

```haxe
// ❌ PROBLEMATIC - Hangs when output redirected (test runners, CI)
#if macro
function build(): String {
    return 'line1\n' +     // Causes hang with > /dev/null
           'line2\n' +
           'line3\n';
}
#end

// ✅ PREFERRED - String interpolation (clean and works)
#if macro  
function build(): String {
    var name = "MyModule";
    return '
defmodule ${name} do
  use Ecto.Migration
  def change do
    # Operations here
  end
end';
}
#end

// ✅ ALTERNATIVE - Array join pattern
#if macro
function build(): String {
    var lines = [
        'line1',
        'line2', 
        'line3'
    ];
    return lines.join('\n');
}
#end
```

**Context**: Haxe compiler bug causes hang when string concatenation/StringBuf is used in macro blocks AND output is redirected (`> /dev/null 2>&1`). Affects test runners and CI pipelines but works fine in normal development.

### Never Edit Generated Files
- ❌ **Don't patch .ex files** - they get overwritten on recompilation
- ✅ **Fix the compiler source** - make changes in `src/reflaxe/elixir/`
- ✅ **Update snapshots when output improves** - `make -C test update-intended TEST=name`

### Testing Requirements
- **Every change requires full test suite** - `npm test`
- **Todo-app must compile cleanly** - integration validation
- **No performance regressions** - watch for timeout increases
- **Update documentation** - reflect changes in architecture docs

### Code Quality Standards
- **Comprehensive documentation** - explain WHY, HOW, and architectural context
- **Professional debugging** - use DebugHelper, not trace statements
- **Pattern consistency** - follow established compiler patterns
- **Type safety** - avoid `Dynamic` and untyped code

### Development Workflow Standards
- **Commit after each completed task** - Incremental progress must be saved with comprehensive commit messages
- **Test before committing** - Run `npm test` to verify no regressions
- **Document significant changes** - Update relevant documentation after major modifications
- **Use git bisect for debugging** - Commit often to enable effective regression debugging

### Post‑Task Commit & Bisect Policy (MANDATORY)

After each task is completed and locally verified, you must:

1) Commit immediately
- Use a descriptive message that summarizes WHAT changed and WHY.
- Keep the working tree clean; do not leave generated artifacts untracked.

2) If a bug/regression appears and the root cause is not obvious
- Do not guess. Run a deterministic reproduction with `git bisect` right away.
- Create or reuse a minimal script that returns non‑zero on failure/hang and zero on success.
- Example (hang/timeout detector used in this repo):

```bash
# From repo root
TIMEOUT_SEC=90 scripts/bisect-hang-test.sh   # manual run to validate

# Automated bisect
git bisect start
git bisect bad HEAD             # current bad state
git bisect good <known_good>    # e.g., a tag/commit SHA that passed
TIMEOUT_SEC=90 git bisect run scripts/bisect-hang-test.sh
# When bisect finishes:
git bisect reset
```

3) Fix at the culprit commit scope
- Prefer surgical fixes at the identified change site; avoid band‑aids elsewhere.
- If the change was “observability only” (e.g., debug gating), ensure no functional drift occurred.
- Add/extend a snapshot or a tiny script to guard the regression going forward.

4) Re‑verify end‑to‑end
- Run snapshot suite and the todo‑app integration to confirm the fix.
- Commit with a message that references the bisected culprit and rationale for the fix.

## 🔗 Related Documentation

### Essential Reading
- [Architecture Overview](architecture.md) - Complete system design
- [Macro-time vs Runtime](macro-time-vs-runtime.md) - Critical distinction details
- [AST Processing](ast-processing.md) - TypedExpr transformation guide
- [Testing Infrastructure](testing-infrastructure.md) - Snapshot testing system
- [Debugging Guide](debugging-guide.md) - XRay methodology details
- [HXX Template Compilation](hxx-template-compilation.md) - Deep dive into HXX→HEEx transformation
- [Function Parameter Underscore Fix](FUNCTION_PARAMETER_UNDERSCORE_FIX.md) - Solution for incorrect parameter prefixing

### Reference Materials
- [Best Practices](best-practices.md) - Development patterns and standards
- [/docs/05-architecture/](../05-architecture/) - Implementation details
- [/docs/07-patterns/](../07-patterns/) - Common code patterns

## 🎯 Current Focus Areas

### Active Development
- **Y combinator syntax fixes** - Completed with post-processing approach
- **Test suite performance** - Addressing timeout issues in parallel execution
- **Edge case handling** - Refining post-processing to avoid over-aggressive pattern matching

### Ongoing Monitoring
- **Compilation performance** - Target <15ms compilation times
- **Code quality** - Generated Elixir must be idiomatic and maintainable
- **Framework integration** - Phoenix conventions must be followed exactly

---

**Remember**: Every compiler change affects the entire ecosystem. Always validate through the complete testing pipeline and integration with real applications.
