# PRD: Infrastructure Variable Elimination System Fix

**Date**: January 2025
**Status**: In Progress
**Priority**: P0 (Blocking 1.0 release)

## Problem Statement

The infrastructure variable elimination system in TypedExprPreprocessor has two critical bugs that prevent successful compilation:

### Bug 1: Missing Infrastructure Variable Assignments
**Symptom**: Generated code contains `case g do` with no preceding `g = ...` assignment, causing "undefined variable 'g'" errors.

**Example**:
```elixir
# Generated (BROKEN):
def parse_message_impl(msg) do
    if not SafePubSub.isValidMessage(msg) do
      :none
    end
    case g do  # ERROR: undefined variable 'g'
      "bulk_update" -> ...
```

**Expected**:
```elixir
# Should generate:
def parse_message_impl(msg) do
    if not SafePubSub.isValidValid(msg) do
      :none
    end
    case Map.get(msg, :type) do  # Inlined expression
      "bulk_update" -> ...
```

### Bug 2: Empty Blocks in Expression Contexts
**Symptom**: Empty blocks generate empty strings (`''`) in expression positions, causing syntax errors.

**Example**:
```elixir
# Generated (BROKEN):
if c == nil, do: , else:   # SYNTAX ERROR

# Should generate:
if c == nil, do: nil, else: nil
```

## Root Cause Analysis

### Researcher Agent Findings

The researcher agent conducted a comprehensive investigation and identified:

#### Bug 1 Root Cause: Inverted Substitution Logic
**Location**: `TypedExprPreprocessor.hx:239`

**Original Code**:
```haxe
case TLocal(v) if (isInfrastructureVar(v.name) && !substitutions.exists(v.name)):
    // Only handles UNDEFINED variables (inverted logic!)
```

**What Happens**:
1. Pattern detection registers substitution: `_g → msg.type` (lines 553-559)
2. Switch processing checks: `!substitutions.exists("_g")`
3. Result: `false` → substitution NOT applied
4. Switch compiles with undefined variable reference

**The Fix**:
```haxe
case TLocal(v) if (isInfrastructureVar(v.name) && substitutions.exists(v.name)):
    // Apply substitution when it EXISTS
    substitutions.get(v.name);
```

#### Bug 2 Root Cause: No Context Awareness
**Location**: `ElixirASTPrinter.hx:1053-1057`

Empty blocks always generate empty strings regardless of context:
```haxe
case EBlock(expressions):
    if (expressions.length == 0) {
        '';  // ALWAYS empty string - no context awareness
    }
```

In Elixir, expression contexts (if branches, case branches) MUST return values.

## Attempted Solutions

### Attempt 1: BlockBuilder Fix
**What**: Changed `BlockBuilder.hx:86` from `return ENil` to `return EBlock([])`
**Result**: Removed `nil` from statement contexts but broke expression contexts (Bug 2)

### Attempt 2: Printer Fix
**What**: Changed `ElixirASTPrinter.hx:1057` from `'nil'` to `''`
**Result**: Fixed statement contexts but broke expression contexts

### Attempt 3: Substitution Logic Fix
**What**: Fixed condition in `TypedExprPreprocessor.hx:240` from `!substitutions.exists()` to `substitutions.exists()`
**Result**: Bug still persists - suggests different code path

## Current Hypothesis

The fix targets `processExpr TSwitch` case, but the actual switch may be processed through:
1. **processBlock** pattern detection (lines 476-565)
2. **processSwitchExpr** (line 681) which calls `processExpr(e, substitutions)`

The substitution may not reach the switch due to:
- Multiple processing paths
- Substitutions not propagating correctly
- Pattern detection failing in certain AST structures

## Required Investigation

### Phase 1: Diagnostic Instrumentation
1. Add comprehensive debug traces to track:
   - Where substitutions are registered
   - Where switches are processed
   - Which code path is taken
   - Why substitutions aren't applied

2. Test with minimal reproduction case

### Phase 2: Architectural Solution
Based on researcher agent recommendation:

#### Fix 1: Correct Substitution Application
**File**: `TypedExprPreprocessor.hx:237-249`

Ensure substitutions are applied in ALL code paths:
- Direct `processExpr TSwitch` case
- `processBlock` pattern detection
- `processSwitchExpr` processing

#### Fix 2: Context-Aware Empty Block Handling

**Step A**: Add context metadata
```haxe
// ElixirAST.hx
typedef ElixirMetadata = {
    ?inExpressionContext: Bool,
    // ... existing fields
}
```

**Step B**: Mark expression contexts
```haxe
// ConditionalBuilder.hx
var thenAst = compileExpressionImpl(eif, false);
if (thenAst.metadata == null) thenAst.metadata = {};
thenAst.metadata.inExpressionContext = true;
```

**Step C**: Context-aware printing
```haxe
// ElixirASTPrinter.hx:1053
case EBlock(expressions):
    if (expressions.length == 0) {
        var inExprCtx = ast.metadata?.inExpressionContext == true;
        inExprCtx ? 'nil' : '';  // Context-aware
    }
```

## Success Criteria

### Bug 1 Fixed
- [ ] `parseMessageImpl` generates `case Map.get(msg, :type) do`
- [ ] No undefined variable `g` errors
- [ ] Mix compilation succeeds
- [ ] All test cases pass

### Bug 2 Fixed
- [ ] Empty if branches generate `nil` not `''`
- [ ] No syntax errors in expression contexts
- [ ] `json_printer.ex` compiles successfully
- [ ] Context-aware empty block handling works

### Regression Prevention
- [ ] Snapshot tests updated with correct intended output
- [ ] New tests added for infrastructure variable patterns
- [ ] Documentation updated with architectural explanation

## Files Requiring Changes

1. **TypedExprPreprocessor.hx**:
   - Lines 237-249: Fix substitution logic
   - Add comprehensive debug traces

2. **ElixirAST.hx**:
   - Add `inExpressionContext` metadata field

3. **ConditionalBuilder.hx** (or similar):
   - Mark if/case expression branches with context metadata

4. **ElixirASTPrinter.hx**:
   - Lines 1053-1057: Context-aware empty block printing

5. **BlockBuilder.hx**:
   - Verify empty block handling is correct

## Testing Strategy

### Unit Tests
- Test substitution registration
- Test substitution application
- Test context metadata propagation

### Integration Tests
- `examples/todo-app` compilation must succeed
- `parseMessageImpl` generates correct code
- `json_printer.ex` generates correct code

### Regression Tests
- All existing snapshot tests must pass
- Add new tests for edge cases

## Timeline Estimate

- **Phase 1 (Diagnostics)**: 2-3 hours
- **Phase 2 (Implementation)**: 3-4 hours
- **Phase 3 (Testing)**: 2-3 hours
- **Total**: 7-10 hours

## Dependencies

- Researcher agent analysis (completed)
- Understanding of Haxe TypedExpr processing
- Knowledge of Reflaxe AST pipeline

## Risks

1. **Multiple Code Paths**: Switch processing may have multiple paths we haven't identified
2. **Metadata Propagation**: Context metadata may not propagate correctly through transformers
3. **Regression Impact**: Changes may affect other compilation patterns

## Mitigation Strategies

1. **Comprehensive Debugging**: Add extensive traces before making changes
2. **Incremental Testing**: Test each fix independently
3. **Snapshot Validation**: Update intended outputs carefully
4. **Rollback Plan**: Git branches for each attempted fix

## References

- [Researcher Agent Analysis](../infrastructure-variable-bug-analysis.md)
- [TypedExprPreprocessor Source](../../src/reflaxe/elixir/preprocessor/TypedExprPreprocessor.hx)
- [ElixirASTPrinter Source](../../src/reflaxe/elixir/ast/ElixirASTPrinter.hx)
- [Todo-App parseMessageImpl](../../examples/todo-app/src_haxe/server/pubsub/TodoPubSub.hx:189-226)
