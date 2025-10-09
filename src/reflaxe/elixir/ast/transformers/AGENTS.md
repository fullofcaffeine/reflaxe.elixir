# AST Transformers Development Context

> **Parent Context**: See [/src/reflaxe/elixir/ast/AGENTS.md](/src/reflaxe/elixir/ast/AGENTS.md) for AST-wide conventions

This file contains transformer-specific development guidance to prevent common confusions and mistakes.

## ⚠️ CRITICAL: Understanding Compilation Stages - String Interpolation vs Concatenation

### The Three Stages of Compilation (MUST UNDERSTAND)

When working on AST transformers, you're operating at a specific stage in a multi-stage compilation process:

1. **Stage 1: Compiling the Compiler** (compile-time of Reflaxe.Elixir)
   - When: Running `haxe build.hxml` to build the Reflaxe.Elixir compiler itself
   - What exists: Only compile-time constants and macro context
   - String interpolation: `$variable` only works for variables that exist NOW (at this stage)

2. **Stage 2: Running the Compiler** (macro-time within Reflaxe framework)
   - When: User runs `npx haxe build-server.hxml` to compile their Haxe code
   - Where: Inside the Reflaxe macro context (this is where transformers run!)
   - What exists: Full Haxe runtime, TypedExpr AST, all normal Haxe features
   - String interpolation: `$variable` works normally for any runtime variables

3. **Stage 3: Generated Code Execution** (runtime of generated Elixir)
   - When: User runs `mix phx.server` to execute the generated Elixir
   - What exists: Only the generated Elixir code

### Where Transformers Run: Macro-Time Within Reflaxe

**CRITICAL UNDERSTANDING**: All AST transformer code runs during Stage 2 - macro-time within the Reflaxe framework.

```haxe
// This code in LoopTransforms.hx runs at MACRO-TIME (Stage 2)
static function substituteOuterIndex(ast: ElixirAST, outerVar: String): ElixirAST {
    for (i in 0...3) {
        // At this point:
        // - The Reflaxe.Elixir compiler is already compiled
        // - We're running inside the Haxe macro system
        // - The variable 'i' exists as a real runtime variable (0, 1, 2)
        // - String interpolation works normally!
        
        var searchPattern = '#{$i}';        // ✅ WORKS - becomes "#{0}", "#{1}", "#{2}"
        var replacePattern = '#{$outerVar}'; // ✅ WORKS - becomes "#{i}", "#{j}", etc.
        
        // These are EQUIVALENT at macro-time:
        var pattern1 = '#{$i}';                    // String interpolation
        var pattern2 = '#{' + Std.string(i) + '}'; // Concatenation
        // Both produce the same result!
    }
}
```

### Common Confusion: String Interpolation "Not Working"

**MYTH**: "String interpolation doesn't work in compiler code, must use concatenation"

**REALITY**: String interpolation works perfectly fine in transformer code because:
- Transformers run at macro-time (Stage 2)
- All normal Haxe runtime features are available
- Variables like loop counters exist and have values

**Why the confusion happens**:
1. Developers confuse Stage 1 (compiling the compiler) with Stage 2 (running the compiler)
2. Macro code feels "special" so people assume limitations that don't exist
3. Old compiler bugs get misattributed to language limitations

### The Reflaxe Macro Context

When Reflaxe runs our transformers:

```haxe
// Inside Reflaxe's BaseCompiler or GenericCompiler
class BaseCompiler {
    function compile() {
        // This runs at macro-time
        Context.onAfterTyping(function(types: Array<ModuleType>) {
            // Our ElixirCompiler and transformers run HERE
            // Full Haxe runtime is available
            // String interpolation, loops, everything works normally
            
            for (type in types) {
                var ast = buildAST(type);           // ElixirASTBuilder runs here
                ast = transformAST(ast);            // ElixirASTTransformer runs here
                var code = printAST(ast);           // ElixirASTPrinter runs here
                saveToFile(code);
            }
        });
    }
}
```

### Practical Guidelines

**DO**:
- ✅ Use string interpolation freely in transformer code
- ✅ Use all normal Haxe features (loops, arrays, maps, etc.)
- ✅ Write clear, idiomatic Haxe code
- ✅ Trust that runtime variables exist and work normally

**DON'T**:
- ❌ Avoid string interpolation thinking it won't work
- ❌ Use complex concatenation when interpolation is clearer
- ❌ Assume macro-time has special limitations on normal Haxe features
- ❌ Confuse the three stages of compilation

### Example: Loop Variable Substitution

```haxe
// UNNECESSARILY COMPLEX (based on confusion):
for (i in 0...3) {
    var searchPattern = '(' + Std.string(i) + ',';  // Avoided interpolation
    var replacePattern = '(#{' + outerVar + '},';   // Due to confusion
}

// CLEAR AND SIMPLE (correct understanding):
for (i in 0...3) {
    var searchPattern = '($i,';              // String interpolation works!
    var replacePattern = '(#{$outerVar},';   // Much clearer
}
```

### Historical Context

This confusion arose from debugging the nested loop variable substitution issue. The initial assumption was that string interpolation wasn't working because the output showed literal `#{0}` instead of `#{i}`. However, the real issue was that the transformation wasn't being triggered at all, not that string interpolation wasn't working.

### Key Takeaway

**Transformers run at macro-time within Reflaxe, which is a full Haxe runtime environment. String interpolation and all other Haxe features work normally. There are no special limitations.**

## 📚 Transformer Architecture Guidelines

### Single Responsibility Principle

Each transformer pass should have ONE clear purpose:
- `StringInterpolationPass`: Convert concatenation to interpolation
- `LoopComprehensionPass`: Convert reduce_while to comprehensions
- `PatternMatchingPass`: Optimize pattern matching

### Transformation Order Matters

Passes are applied in sequence. Earlier passes can enable later optimizations:
1. First: Structural transformations (loops, conditionals)
2. Middle: Semantic transformations (pattern matching, typing)
3. Last: Syntactic optimizations (string interpolation, cleanup)

### Testing Transformers

Always test with debug flags to see transformations:
```bash
npx haxe compile.hxml -D debug_ast_transformer -D debug_loop_transforms
```

---

**Remember**: Transformers run at macro-time, which is a normal Haxe runtime. Don't create artificial limitations based on confusion about compilation stages.

## Descriptive Naming & Non‑Expert Documentation (Transformers)

- Use descriptive names for passes and locals. Prefer `guardVars`, `fieldBaseVars`, `bodyUsedLocals`, `binderName`, `clauseBinders` over generic names.
- Avoid one‑letter variables in transformation code; short indices are acceptable only in tiny, obvious scopes.
- Every new pass must include hxdoc with WHY/WHAT/HOW/WHEN, sample Haxe→Elixir snippets showing the intended shape, invariants, and known limitations.
- Document any introduction of bridge variables or aliases, their lifetime, and how downstream references are synchronized. Add transparent comments in generated code when appropriate.
- Cross‑reference relevant debug flags (e.g., `-D debug_ast_transformer`, pass‑specific flags) for future maintainers.

## 📚 Reference Strategy (Mandatory)

- Always cross-check patterns and reference implementations in the local reference repo before introducing or changing transformer logic:
  - Path: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`
  - What to look for: existing Reflaxe compiler patterns (e.g., RemoveTemporaryVariablesImpl, reference handling for TLocal/TEnumParameter), variable reference consistency techniques, and idiomatic transformation sequences.
- Do not guess transformation behavior. Verify against the reference code and adapt patterns faithfully to our AST pipeline.
- When handling variable naming or binder/reference normalization, ensure body references are consistently updated to match pattern binders (no mismatched identifiers). If you remove alias bindings, update all downstream references.
- Always follow `.claude/agents/haxe-reflaxe-compiler-expert.md` when blocked or making architectural decisions. Use it to drive research in the reference repo and synthesize a solution that fits our Builder → Transformer → Printer pipeline without band-aids.
