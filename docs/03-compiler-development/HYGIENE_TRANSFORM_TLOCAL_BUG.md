# TLocal Context Lookup Bug - Complete Analysis

**Date**: September 30, 2025
**Status**: Root cause identified, fix in progress
**Related**: HYGIENE_TRANSFORM_VARIABLE_SHADOWING_ISSUE.md

## The Complete Picture

### What We Fixed (Tasks 1-5) ✅
1. **Transformer Phase Context Initialization** - Line 795 of HygieneTransforms.hx
2. **Dual-Key Storage in Builder** - 5 locations now register both ID and name keys
3. **Helper Functions** - `isNumericId()` and `initializeNameMappingFromContext()`

### What's Still Broken ❌
**TLocal case in ElixirASTBuilder.hx (line 492-508) doesn't check context**

## The Bug Manifestation

### Haxe Source
```haxe
static function changeset(user: Dynamic, attrs: Dynamic): Changeset<Dynamic> {
    var changeset = new Changeset(user);  // TVar - declaration
    return changeset;                      // TLocal - reference
}
```

### Generated Elixir (WRONG)
```elixir
defp changeset(user, _attrs) do
  _changeset = user    # TVar with underscore (marked unused)
  changeset            # TLocal without underscore (undefined!)
end
```

### Expected Elixir (CORRECT)
```elixir
defp changeset(user, _attrs) do
  changeset = user     # Variable IS used, no underscore
  changeset
end
```

## Root Cause Analysis (UPDATED - January 2025)

### The Architectural Problem: Premature Underscore Prefixing

**CRITICAL DISCOVERY**: The builder phase is adding underscore prefixes BEFORE usage analysis runs.

#### Execution Flow (What Actually Happens):
1. **Builder Phase - TVar** (Line 1090 of ElixirASTBuilder.hx):
   - Sees `var changeset = ...`
   - Decides it's "unused" using incomplete heuristics
   - Registers `changeset -> _changeset` in context
   - **PROBLEM**: This is PREMATURE - usage analysis hasn't run yet!

2. **Builder Phase - TLocal** (Line 532 of ElixirASTBuilder.hx):
   - Sees `return changeset`
   - Checks context for ID `57776` → NOT FOUND (context was cleared)
   - Checks context for name `"changeset"` → NOT FOUND (stored as `"_changeset"`)
   - Falls back to snake_case conversion: `"changeset"`
   - **RESULT**: References `changeset` (undefined variable!)

3. **Transformer Phase - Usage Analysis** (HygieneTransforms.hx):
   - Collects bindings from the AST
   - Finds variable named `"_changeset"` (the already-renamed one)
   - Marks it as unused (correct - nothing references `_changeset`)
   - **TOO LATE**: The damage is already done in builder phase

### The Core Architectural Violation

**Builder Phase Responsibilities** (WHAT IT SHOULD DO):
- Build AST nodes faithfully from TypedExpr
- NO transformation logic
- NO renaming decisions
- ONLY record metadata for transformer phase

**Transformer Phase Responsibilities** (WHAT IT SHOULD DO):
- Analyze usage patterns
- Determine which variables are unused
- Apply underscore prefixes
- Update all references consistently

**What's Actually Happening** (THE BUG):
- Builder makes renaming decisions ❌
- Builder applies transformations ❌
- Transformer sees already-transformed AST ❌
- Two systems fighting each other ❌

### Current TLocal Implementation (BROKEN)
```haxe
case TLocal(v):
    var varName = VariableAnalyzer.toElixirVarName(v.name);  // Just snake_case
    EVar(varName);  // Uses original name, ignores context!
```

### Required TLocal Implementation (FIX)
```haxe
case TLocal(v):
    // Check context for renamed variable FIRST
    var idKey = Std.string(v.id);
    var nameKey = v.name;

    var varName = if (currentContext.tempVarRenameMap.exists(idKey)) {
        // ID-based lookup (pattern matching context)
        currentContext.tempVarRenameMap.get(idKey);
    } else if (currentContext.tempVarRenameMap.exists(nameKey)) {
        // Name-based lookup (EVar reference context)
        currentContext.tempVarRenameMap.get(nameKey);
    } else {
        // Fallback: convert to snake_case
        VariableAnalyzer.toElixirVarName(v.name);
    };

    #if debug_hygiene
    trace('[TLocal] Variable ${v.name} (id=${v.id}) resolved to: $varName');
    #end

    EVar(varName);
```

## Why This Wasn't Caught Earlier

1. **Transformer Phase Works**: Our fix (Tasks 1-5) correctly handles transformer context
2. **Builder Phase Registration Works**: TVar correctly stores dual-key mappings
3. **TLocal Never Checks**: The reference lookup was never implemented
4. **Tests Passed**: Until we created regression test with simple_return_value

## The Complete Fix Requires (UPDATED)

### Part A: Remove Premature Underscore Prefixing from Builder (ROOT CAUSE)
**Location**: ElixirASTBuilder.hx TVar case (around line 1040-1090)
**Change**: Remove ALL underscore prefixing logic from builder phase
**Reason**: Builder should NOT make renaming decisions - that's transformer's job

**Current Code (WRONG)**:
```haxe
// In TVar case of ElixirASTBuilder.hx
if (isUnused(v)) {  // This detection is WRONG - too early!
    var underscoreName = "_" + baseName;
    currentContext.tempVarRenameMap.set(Std.string(v.id), underscoreName);
    currentContext.tempVarRenameMap.set(v.name, underscoreName);
}
```

**Required Code (RIGHT)**:
```haxe
// In TVar case of ElixirASTBuilder.hx
// NO underscore logic here - just build the AST faithfully
var varName = VariableAnalyzer.toElixirVarName(v.name);  // Just snake_case
// Don't add to tempVarRenameMap here - transformer will handle it
EMatch(PVar(varName), rhs);
```

### Part B: Ensure HygieneTransforms Handles All Renaming (ALREADY WORKS)
**Location**: HygieneTransforms.hx usageAnalysisPassWithContext
**Status**: ✅ Already correctly implemented
**Reason**: Usage analysis properly detects unused variables and renames them

### Part C: Keep TLocal Context Lookup (ALREADY FIXED)
**Location**: ElixirASTBuilder.hx TLocal case (line 492-537)
**Status**: ✅ Already fixed in this session
**Reason**: TLocal needs to check context for transformer-applied renames

## Test Case: simple_return_value

**Purpose**: Validates that variable references use the correct name from context

**Expected Behavior**:
- Variable `changeset` declared and used
- Should NOT get underscore prefix
- Reference should match declaration

**Current Status**: FAILS - demonstrates both issues above

## Action Items (UPDATED)

- [x] ~~Fix TLocal to check context.tempVarRenameMap (dual-key lookup)~~ - ✅ DONE
- [x] ~~Add debug traces for TLocal context lookups~~ - ✅ DONE
- [ ] **CRITICAL**: Remove underscore prefixing logic from TVar in ElixirASTBuilder.hx
- [ ] Verify builder only builds, doesn't transform
- [ ] Re-test simple_return_value regression test
- [ ] Verify todo-app compilation succeeds
- [ ] Run full test suite (npm test)

### Implementation Plan for Part A (Remove Premature Prefixing)

1. **Find the TVar case** in ElixirASTBuilder.hx (around line 1040-1090)
2. **Remove all underscore logic**:
   - Remove `isUnused()` checks
   - Remove `"_" + baseName` creation
   - Remove `tempVarRenameMap` registrations for underscore names
3. **Keep only**:
   - Variable name conversion (camelCase → snake_case)
   - AST node creation
4. **Trust HygieneTransforms** to handle ALL renaming in transformer phase

## Related Files

- `/src/reflaxe/elixir/ast/ElixirASTBuilder.hx` - Lines 492-508 (TLocal case)
- `/src/reflaxe/elixir/ast/transformers/HygieneTransforms.hx` - Line 795 (context init)
- `/test/snapshot/regression/simple_return_value/` - Regression test
- `/docs/03-compiler-development/HYGIENE_TRANSFORM_VARIABLE_SHADOWING_ISSUE.md` - Original investigation

## Lesson Learned

**Cumulative context pattern requires consistency**:
- If builder phase stores decisions in context
- Then ALL phases must check context first
- Not just transformer phase, but builder phase too (for TLocal references)
