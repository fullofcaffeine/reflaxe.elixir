# AST Development Context for Reflaxe.Elixir

> **⚠️ SYNC DIRECTIVE**: This file (`AGENTS.md`) and `CLAUDE.md` in the same directory must be kept in sync. When updating either file, update the other as well.

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) and [/src/reflaxe/elixir/AGENTS.md](/src/reflaxe/elixir/AGENTS.md) for project-wide conventions

This file contains AST-specific development guidance for agents working on the Reflaxe.Elixir AST transformation pipeline.

## 🚨 CRITICAL: ElixirASTBuilder.hx Size Crisis - EXTRACT AND REFACTOR

### ⚠️ RULE: MODIFY BUT EXTRACT - Keep ElixirASTBuilder.hx Maintainable

**CURRENT SIZE**: 4,778 lines (as of October 2025)
**PREVIOUS SIZE**: 11,137 lines (January 2025) - **57% reduction achieved!**
**VIOLATION LEVEL**: Still 2.4x larger than recommended maximum (2,000 lines)
**STATUS**: IMPROVED but ongoing refactoring needed

### The Directive

**When modifying ElixirASTBuilder.hx, you MUST follow SOLID principles:**

- ✅ **FIX issues directly** - Don't work around bugs in other files
- ✅ **EXTRACT while fixing** - Move related code to specialized builders
- ✅ **REFACTOR as you go** - Improve structure, don't just add code
- ❌ **NO net increase in size** - Every fix should extract more than it adds
- ❌ **NO quick patches** - Fix properly and refactor simultaneously
- ❌ **NO monolithic additions** - Large features go to specialized modules

### Where New Code MUST Go Instead

All new AST-related functionality MUST be placed in:

1. **Specialized Builders** (`src/reflaxe/elixir/ast/builders/`)
   - Create new builder classes for specific AST node types
   - Example: `LoopBuilder.hx`, `PatternBuilder.hx`, `SwitchBuilder.hx`

2. **Transformation Passes** (`src/reflaxe/elixir/ast/transformers/`)
   - Add new transformation passes to `ElixirASTTransformer.hx`
   - Create specialized transformers like `AnnotationTransforms.hx`

3. **Helper Classes** (`src/reflaxe/elixir/helpers/`)
   - Extract utility functions to dedicated helper classes
   - Example: `VariableCompiler.hx`, `PatternMatchingCompiler.hx`

### Historical Context

**Failed Modularization Attempt (Commit ecf50d9d - September 2025)**
- An attempt was made to extract ElixirASTBuilder into modular builders
- Multiple builder files were created then deleted:
  - `ModuleBuilder.hx` (1,492 lines)
  - `LoopBuilder.hx` (448 lines)
  - `PatternMatchBuilder.hx` (388 lines)
  - `ArrayBuilder.hx` (386 lines)
  - `ControlFlowBuilder.hx` (375 lines)
  - `ExUnitCompiler.hx` (345 lines)
  - `CallExprBuilder.hx` (322 lines - later re-added)
  - `ClassBuilder.hx` (451 lines)
- The refactoring was incomplete and abandoned
- Critical functionality (like @:application handling) was lost in the process
- **LESSON**: Modularization must be done incrementally with full testing at each step

### Why This Rule Exists

1. **Unmaintainable Size**: At 11,137 lines, the file is impossible to navigate or understand
2. **Single Responsibility Violation**: The file does EVERYTHING - a complete violation of SRP
3. **Performance Impact**: Compilation is slower due to massive file size
4. **Bug Breeding Ground**: Finding and fixing bugs in 11k lines is nearly impossible
5. **Merge Conflicts**: Every change conflicts with other changes in such a large file
6. **Testing Nightmare**: Cannot unit test a monolithic file effectively

### The Refactoring Plan

**Phase 1: Stop the Bleeding** (CURRENT)
- Enforce absolute prohibition on additions
- All new features go to specialized modules

**Phase 2: Incremental Extraction** (FUTURE)
- Extract logical sections one at a time
- Each extraction must maintain full test suite passing
- Target: Reduce to under 2,000 lines

**Phase 3: Final Architecture** (GOAL)
- ElixirASTBuilder becomes a thin orchestrator
- All logic in specialized, testable modules
- Each module under 500 lines

### Enforcement

**If you're about to add code to ElixirASTBuilder.hx:**

1. **STOP** - Do not add the code
2. **IDENTIFY** - What type of functionality is it?
3. **CREATE** - Make a new specialized builder or transformer
4. **INTEGRATE** - Call your new module from the appropriate place
5. **TEST** - Ensure full test suite passes

**NO EXCEPTIONS** - Not even for "critical fixes" or "temporary solutions"

### Verification Checklist

Before ANY commit:
- [ ] ElixirASTBuilder.hx line count has NOT increased
- [ ] New functionality is in a specialized module
- [ ] All tests pass
- [ ] No "TODO: extract later" comments

## 🏗️ AST Pipeline Architecture

The AST pipeline is the core of the Reflaxe.Elixir compiler, transforming Haxe's TypedExpr into idiomatic Elixir code through three phases:

1. **Builder Phase** (`ElixirASTBuilder.hx`) - Converts TypedExpr → ElixirAST
2. **Transformer Phase** (`ElixirASTTransformer.hx`) - Applies idiomatic transformations
3. **Printer Phase** (`ElixirASTPrinter.hx`) - Generates final Elixir strings

## 🛠️ ASTUtils: Robust AST Transformation Utilities (NEW - January 2025)

### Overview
`ASTUtils.hx` provides defensive utilities for robust AST transformation and manipulation. Created to prevent "hard-to-debug mismatchers" that were causing transformation failures.

### Key Functions

#### `flattenBlocks(ast: ElixirAST): Array<ElixirAST>`
**Purpose**: Recursively flatten nested EBlock structures into a single array
- Handles arbitrary nesting depth (EBlock inside EBlock inside EBlock...)
- Returns empty array for null input (defensive)
- Example: `EBlock([EBlock([expr1, expr2]), expr3])` → `[expr1, expr2, expr3]`

#### `extractBlockExprs(ast: ElixirAST): Array<ElixirAST>`
**Purpose**: Extract expressions from various block structures with fallbacks
- Only unwraps ONE level of nesting (unlike flattenBlocks)
- Handles single nested blocks gracefully
- Safe for null input

#### `containsIteratorPattern(ast: ElixirAST): Bool`
**Purpose**: Exhaustively detect Map iterator patterns anywhere in AST
- Detects: `key_value_iterator`, `has_next`, `next`, `key`, `value`
- Uses ElixirASTTransformer.transformNode for complete traversal
- Never misses deeply nested patterns

#### `filterIteratorAssignments(exprs: Array<ElixirAST>): Array<ElixirAST>`
**Purpose**: Remove Map iterator-related assignments from expression lists
- Filters assignments like: `name = colors.key_value_iterator().next().key`
- Preserves all non-iterator expressions
- Essential for cleaning Map iteration transformations

#### `extractFieldChain(ast: ElixirAST): Array<String>`
**Purpose**: Extract field/method names from nested access chains
- Returns names in reverse order (innermost first)
- Example: `colors.key_value_iterator().next().key` → `["key", "next", "key_value_iterator"]`

#### `makeAST(def: ElixirASTDef, ?pos: Position): ElixirAST`
**Purpose**: Convenience wrapper for AST node creation
- Initializes metadata properly
- Reduces boilerplate code

### Usage Example
```haxe
// In a transformation pass
var allExprs = ASTUtils.flattenBlocks(thenBranch);  // Handle nested blocks
var cleanExprs = ASTUtils.filterIteratorAssignments(allExprs);  // Remove iterator patterns

// Detect patterns
if (ASTUtils.containsIteratorPattern(rhs)) {
    // Skip or transform this node
}
```

### Design Principles
- **Defensive Programming**: Never crashes on unexpected input
- **Pure Functions**: No side effects (except debug output)
- **Exhaustive Handling**: Handles all edge cases gracefully
- **Reusability**: Used by multiple transformation passes

### Historical Context
Created in response to Map iterator transformation failures where pattern matching failed on unexpected AST structures (nested EBlock issues). User specifically requested "abstractions/patterns to prevent hard-to-debug mismatchers" - ASTUtils is the solution.

## 🔍 Hygiene & Usage Analysis — Single Source of Truth (NEW - October 2025)

### WHAT
- Centralize variable usage detection in a single analyzer used by all hygiene-related passes.
- File: `src/reflaxe/elixir/ast/analyzers/VarUseAnalyzer.hx`

### WHY
- Multiple passes had ad‑hoc `usedLater`/`stmtUsesVar` implementations with inconsistent coverage (missed EFn closures, string interpolation, ERaw, map/keyword/struct fields, case clause bodies). This led to discarding locals actually used in closures/interpolations and produced undefined‑variable errors at runtime.

### HOW
- All hygiene/binder passes MUST import and use `VarUseAnalyzer.usedLater` and `VarUseAnalyzer.stmtUsesVar`.
- Analyzer responsibilities (non‑negotiable):
  - Traverse EFn clause bodies (closures)
  - Scan `"#{...}"` string interpolations
  - Token‑boundary search inside ERaw
  - Walk maps/keyword lists/struct updates/access/field/tuples
  - Include case/with clause bodies

### RULES (Do/Don’t)
- Do
  - Use VarUseAnalyzer everywhere you need usage checks (discard, underscore, promotion, aliasing).
  - Add missing coverage to VarUseAnalyzer first — never in individual passes.
  - Add focused tests for newly covered constructs before using them in passes.
- Don’t
  - Re‑implement usage scans in passes.
  - Special‑case specific modules or app names.

### CLOSURE EMISSION REQUIREMENT
- Structured transforms depend on structured AST. ERaw closures block analysis/rewrites.
- Builders MUST emit EFn for predicate/closure arguments (e.g., `Enum.filter`, `Enum.each`).
- Printers MUST render EFn as `fn ... -> ... end` in all positions.

### REGISTRY ORDERING
- Run binder synthesis/promotions BEFORE discard/underscore passes.
- Late/ultra‑final sentinel cleanup must follow any pass that can re‑introduce numeric literals.

### CHECKLIST (Gate before merging hygiene changes)
- [ ] Passes use `VarUseAnalyzer` (no local scanners)
- [ ] EFn emitted for closures that passes will touch (no ERaw in those positions)
- [ ] Registry order: binder synth/promote → discard/underscore → sentinel cleanup (final)
- [ ] Focused tests cover EFn, string interpolation, ERaw, maps/keyword, case bodies
- [ ] No app‑specific heuristics or invented var names

### CROSS‑REFS
- Analyzer: `src/reflaxe/elixir/ast/analyzers/VarUseAnalyzer.hx`
- Examples of adoption:
  - `BlockUnusedAssignmentDiscardTransforms.hx`
  - `LocalAssignUnderscoreLateTransforms.hx`

## ⚠️ CRITICAL: Context Preservation in Builders (January 2025)

**FUNDAMENTAL RULE: Builders must NEVER call `compiler.compileExpressionImpl` - use `ElixirASTBuilder.buildFromTypedExpr` instead.**

### The Context Isolation Bug

When builders call `context.compiler.compileExpressionImpl()`, it creates a **NEW** compilation context, losing critical state:
- `ClauseContext.localToName` - Pattern variable registrations
- `tempVarRenameMap` - Infrastructure variable mappings
- Scope information and feature flags

**Symptom**: Pattern variables get nil assignments instead of being used directly from patterns:
```elixir
# BUGGY OUTPUT:
{:ok, value} ->
  value = nil          # ❌ Wrong!
  "Success: #{value}"

# CORRECT OUTPUT:
{:ok, value} ->
  "Success: #{value}"  # ✅ Direct use
```

### The Fix Pattern

```haxe
// ❌ WRONG: Creates new context
var result = context.compiler.compileExpressionImpl(expr, false);

// ✅ RIGHT: Preserves context
var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
```

### Status
- ✅ **Fixed**: SwitchBuilder.hx, BlockBuilder.hx
- ⚠️ **Needs Review**: ObjectBuilder, FunctionBuilder, ReturnBuilder, FieldAccessBuilder, ExceptionBuilder

**See**: [`/docs/03-compiler-development/CONTEXT_PRESERVATION_PATTERN.md`](/docs/03-compiler-development/CONTEXT_PRESERVATION_PATTERN.md) - Complete documentation

## ⚠️ CRITICAL: Empty Expression Handling (October 2025)

### Empty If-Branches Must Use Block Syntax

**Problem Discovered**: Empty inline syntax `if x, do: , else:` generates invalid Elixir (missing expressions).

**Root Cause**: `isSimpleExpression()` in ElixirASTPrinter.hx incorrectly returned `true` for `EBlock([])`.

**The Fix** (ElixirASTPrinter.hx line 1368):
```haxe
case EBlock(expressions):
    // ✅ FIX: Empty blocks are NOT simple - they need block syntax to generate nil
    if (expressions.length == 0) {
        return false;  // Force block syntax for empty branches
    }
    expressions.length == 1 && isSimpleExpression(expressions[0]);
```

**Why Empty Blocks Aren't "Simple"**:
- Simple expressions use inline syntax: `if cond, do: expr, else: expr`
- Empty blocks need block syntax to generate `nil`:
  ```elixir
  if cond do
    nil  # Explicit value for empty block
  end
  ```
- Elixir requires all branches to return a value (nil is a value)

**Correct Generated Code**:
```elixir
# ✅ CORRECT: Block syntax with explicit nil
if c == nil do
  nil
else
  "not null"
end

# ❌ WRONG: Invalid inline syntax
if c == nil, do: , else: "not null"  # Syntax error!
```

**Regression Test**: `test/snapshot/regression/EmptyIfBranches/` validates this fix forever.

**See**: [`/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md`](/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md) - Complete bug documentation

## ⚠️ KNOWN ISSUE: Switch Side-Effects in Loops (October 2025)

### Problem: Switch Cases Disappear Inside Loops

**Symptom**: Switch statements with compound assignments (`result += "string"`) inside for/while loops have their case branches completely disappear from generated output.

**Root Cause Identified**: Pipeline coordination issue between LoopBuilder and SwitchBuilder.

**Evidence**:
- Switches **outside loops**: Compile correctly ✅
- Switches **inside loops**: Cases disappear ❌
- Debug tracing proves: Switch never reaches SwitchBuilder when inside loop

**Current Status**: ⚠️ **NOT YET FIXED** - Requires architectural investigation

**Affected Code**:
```haxe
// Haxe - This pattern fails
for (i in 0...length) {
    switch (charCode) {
        case 34: result += '\\"';   // These cases disappear!
        case 92: result += '\\\\';
        default: result += "other";
    }
}
```

**Expected Elixir**:
```elixir
# Should generate case expression with rebinding
Enum.reduce(0..(length-1), result, fn i, result ->
  result = case char_code do
    34 -> result <> "\\\""    # Should have all cases
    92 -> result <> "\\\\"
    _ -> result <> "other"
  end
  result
end)
```

**Actual Generated**:
```elixir
# Cases are missing - empty if-else instead
if char_code == nil do
  # Empty - cases disappeared!
else
  # Empty - cases disappeared!
end
```

**Investigation Path**:
1. LoopBuilder calls `context.buildFromTypedExpr(e2)` for loop body
2. Loop body contains TSwitch expression
3. **Switch structure is lost before reaching SwitchBuilder**
4. Need to trace where switch cases are dropped in pipeline

**Workaround**: Avoid compound assignments in switch cases inside loops until this is fixed.

**Regression Test**: `test/snapshot/regression/SwitchSideEffects/` created and waiting for fix.

**See**: [`/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md`](/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md#bug-2-switch-side-effects-disappear) - Complete investigation findings

## 🎯 Compound Assignment → Rebinding Transformation

### Elixir Immutability Pattern

**Haxe Pattern**: `result += "string"` (mutation)
**Elixir Pattern**: `result = result <> "string"` (rebinding with new value)

**Why This Matters**:
- Elixir is immutable - no in-place modification exists
- `+=` operator doesn't exist in Elixir
- Must transform to rebinding pattern
- The variable name stays the same, but points to new value

**Transformation Examples**:
```haxe
// Haxe compound assignments
result += "string"    →  result = result <> "string"   // String concatenation
counter += 1          →  counter = counter + 1         // Number addition
list += [item]        →  list = list ++ [item]        // List concatenation
```

**Common Pitfalls to Avoid**:
- ❌ Don't treat += as mutation (doesn't exist in Elixir)
- ❌ Don't generate `result += "string"` (invalid Elixir)
- ✅ Always generate rebinding: `result = result <> "string"`
- ✅ Choose correct operator: `<>` for strings, `+` for numbers, `++` for lists

---

**Remember**: Every line added to ElixirASTBuilder.hx makes the compiler harder to maintain, debug, and extend. The prohibition is absolute and non-negotiable.
