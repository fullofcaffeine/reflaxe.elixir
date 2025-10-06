# Reflaxe.Elixir Compiler 1.0 Roadmap

**Date**: 2025-10-06
**Current State**: 40/208 tests passing (19.2%)
**Critical Blocker**: TodoApp compilation fails with undefined `_g` variable in enum parameter extraction

---

## Executive Summary

The Reflaxe.Elixir compiler has a **critical architectural bug** in enum parameter extraction that prevents the todo-app (primary integration test) from compiling. This bug manifests as undefined variable `_g` references in generated Elixir code where enum pattern parameters should be used directly.

**Status**:
- ✅ **Test cleanup completed** (Phases 1-5 from recent session)
- ❌ **TodoApp BLOCKED** - Cannot compile due to enum parameter bug
- ⚠️ **Test pass rate declining** - Down from 18.5% to 16.1%

---

## 1. Root Cause Analysis: The `_g` Variable Bug

### The Problem

**Generated Code (BROKEN)**:
```elixir
# Function: TodoPubSub.message_to_elixir/1
case message do
  {:todo_created, todo} ->
    todo = _g  # ❌ ERROR: undefined variable "_g"
    %{:type => "todo_created", :todo => todo}
  {:todo_updated, todo} ->
    todo = _g  # ❌ ERROR: undefined variable "_g"
    %{:type => "todo_updated", :todo => todo}
  {:user_online, user_id} ->
    user_id = _g  # ❌ ERROR: undefined variable "_g"
    %{:type => "user_online", :user_id => user_id}
end
```

**Expected Code (CORRECT)**:
```elixir
case message do
  {:todo_created, todo} ->
    %{:type => "todo_created", :todo => todo}  # ✅ Direct use
  {:todo_updated, todo} ->
    %{:type => "todo_updated", :todo => todo}
  {:user_online, user_id} ->
    %{:type => "user_online", :user_id => user_id}
end
```

### Where the Bug Occurs

**Source File**: `examples/todo-app/src_haxe/server/pubsub/TodoPubSub.hx:141-179`

```haxe
public static function messageToElixir(message: TodoPubSubMessage): Dynamic {
    var basePayload = switch (message) {
        case TodoCreated(todo):
            {
                type: "todo_created",
                todo: todo  // ← This reference triggers TEnumParameter extraction
            };
        case TodoUpdated(todo):
            {
                type: "todo_updated",
                todo: todo  // ← Bug here too
            };
        // ... similar patterns for other cases
    };
}
```

**Generated File**: `lib/server/pubsub/todo_pub_sub.ex:22-44`

All enum parameter references generate `param = _g` assignments where `_g` doesn't exist.

---

## 2. Technical Investigation Findings

### 2.1 Compilation Pipeline Flow

The bug occurs in this sequence:

1. **SwitchBuilder.hx** - Creates pattern: `{:todo_created, todo}`
   - Pattern correctly binds `todo` variable
   - Creates `ClauseContext` with `enumBindingPlan`
   - Registers parameter binding: `{index: 0, name: "todo", isUsed: false}`

2. **ElixirASTBuilder.hx** - Compiles case body
   - Encounters `TLocal(todo)` reference in object literal
   - Haxe generates `TEnumParameter` to extract the parameter
   - **BUG**: TEnumParameter compilation returns `EVar("_g")` instead of `null`

3. **Result** - Invalid assignment generated:
   ```elixir
   todo = _g  # _g never defined!
   ```

### 2.2 Why TEnumParameter Returns `_g`

**Critical Code**: `src/reflaxe/elixir/ast/ElixirASTBuilder.hx:2770-2965`

The TEnumParameter handling has multiple fallback paths:
- ✅ **Line 2823-2852**: Check if pattern extracted parameter → return `EVar(info.finalName)`
- ✅ **Line 2874-2948**: Use `enumBindingPlan` → return `null` to skip
- ❌ **Line 2965+**: **FALLBACK PATH** - This is where `_g` comes from!

**The Issue**: When `enumBindingPlan` is empty or index doesn't exist, the code falls through to a fallback that generates infrastructure variable references.

### 2.3 Evidence from Codebase Search

**Infrastructure Variable Pattern (`_g`)**: Found in 40+ locations across:
- `SwitchBuilder.hx`: Lines 31, 52, 1230, 1235-1236
- `VariableBuilder.hx`: Lines 19, 92, 96-97, 106
- `BlockBuilder.hx`: Lines 554, 559-560, 812, 827
- `LoopBuilder.hx`: Lines 646, 715-717, 1336, 1799, 1811, 1816

**Purpose**: `_g`, `g`, `g1`, `_g1` are Haxe's infrastructure variables for desugared expressions.

**Problem**: These should be **substituted or eliminated** before code generation, NOT appear in final output.

---

## 3. Architectural Assessment

### 3.1 Is This a Pipeline Coordination Issue?

**YES** - Similar to the issue documented in `/docs/03-compiler-development/CONTEXT_PRESERVATION_PATTERN.md`:

> **The Context Isolation Bug**: When builders call `context.compiler.compileExpressionImpl()`, it creates a **NEW** compilation context, losing critical state:
> - `ClauseContext.localToName` - Pattern variable registrations
> - `tempVarRenameMap` - Infrastructure variable mappings

**From CLAUDE.md findings (January 2025)**:
```haxe
// ❌ WRONG: Creates new context
var result = context.compiler.compileExpressionImpl(expr, false);

// ✅ RIGHT: Preserves context
var result = ElixirASTBuilder.buildFromTypedExpr(expr, context);
```

**Investigation Needed**: Are we calling `compileExpressionImpl` somewhere in the switch case body compilation?

### 3.2 Is enumBindingPlan Being Populated?

**Hypothesis**: The `enumBindingPlan` might be empty when TEnumParameter is compiled.

**Check Required**:
1. Does SwitchBuilder actually populate `enumBindingPlan`?
2. Is it passed correctly to the case body compilation?
3. Is there a timing issue where body compiles before plan is created?

### 3.3 Multiple Detection Paths (Architecture Smell)

From `/CLAUDE.md`:
> **CRITICAL: Predictable Pipeline Architecture - No Logic Bypassing Logic**
>
> ❌ **Multiple detection paths** for the same pattern (builder detecting AND transformer detecting)
> ❌ **Bypass routes** where some code paths skip transformation entirely

**Current State**: Enum parameter handling has:
- Pattern extraction in `PatternBuilder.hx`
- Parameter binding in `SwitchBuilder.hx`
- TEnumParameter compilation in `ElixirASTBuilder.hx`
- Multiple fallback paths with different behaviors

**This violates**: Single Responsibility and Predictable Pipeline principles.

---

## 4. Fix Strategy Options

### Option A: Fix TEnumParameter to Always Use enumBindingPlan ⭐ RECOMMENDED

**Approach**: Make enumBindingPlan the **single source of truth** for all enum parameters.

**Changes**:
1. **SwitchBuilder.hx**: Ensure `enumBindingPlan` is ALWAYS populated, even for simple cases
2. **ElixirASTBuilder.hx**: Remove ALL fallback paths in TEnumParameter - use enumBindingPlan or fail
3. **Add defensive check**: If enumBindingPlan doesn't exist when TEnumParameter is called, log error and return null

**Pros**:
- ✅ Architectural alignment - single source of truth
- ✅ Predictable behavior - no fallback confusion
- ✅ Prevents future regressions - forces proper plan creation

**Cons**:
- ⚠️ Requires understanding entire enum binding flow
- ⚠️ May break edge cases we haven't tested

### Option B: Pre-process to Remove Redundant TEnumParameter

**Approach**: Add transformation pass to detect and eliminate TEnumParameter when pattern already extracts.

**Changes**:
1. **New transformer**: `RedundantEnumParameterCleanup`
2. **Detect**: TVar with TEnumParameter init where pattern already binds variable
3. **Transform**: Remove the entire TVar node

**Pros**:
- ✅ Surgical fix - doesn't change existing logic
- ✅ Easier to test in isolation
- ✅ Can be feature-flagged for gradual rollout

**Cons**:
- ❌ Band-aid approach - doesn't fix root cause
- ❌ Adds another transformation pass (complexity)
- ❌ Violates "no band-aid fixes" principle

### Option C: Detect at TVar Level and Skip

**Approach**: When compiling TVar assignment, check if initValue is TEnumParameter that pattern already handled.

**Changes**:
1. **ElixirASTBuilder.hx TVar handling**: Check if TEnumParameter would return null
2. **If yes**: Skip entire TVar assignment
3. **If no**: Compile normally

**Pros**:
- ✅ Minimal code changes
- ✅ Catches issue at assignment level

**Cons**:
- ❌ Reactive fix, not proactive
- ❌ Doesn't address architectural issues

### Option D: Fix Context Passing (Architecture Fix) ⭐⭐ BEST LONG-TERM

**Approach**: Ensure ClauseContext is NEVER lost during case body compilation.

**Changes**:
1. **SwitchBuilder.hx**: Verify context is passed to body compilation
2. **Check for**: Any `compileExpressionImpl` calls that create new context
3. **Replace with**: `ElixirASTBuilder.buildFromTypedExpr` to preserve context
4. **Add assertions**: Fail fast if ClauseContext is null when compiling enum patterns

**Pros**:
- ✅ ✅ ✅ Fixes root cause - context preservation
- ✅ ✅ Architectural alignment with CONTEXT_PRESERVATION_PATTERN.md
- ✅ Prevents entire class of bugs, not just this one

**Cons**:
- ⚠️ Requires careful analysis of context flow
- ⚠️ May uncover other context-related bugs

---

## 5. Recommended Fix Approach (Hybrid)

**Combine Option A + Option D for maximum robustness**:

### Phase 1: Immediate Context Fix
1. ✅ Search for `compileExpressionImpl` calls in switch case body compilation
2. ✅ Replace with `ElixirASTBuilder.buildFromTypedExpr` to preserve ClauseContext
3. ✅ Add assertion: `if (currentContext.currentClauseContext == null) throw error`

### Phase 2: EnumBindingPlan Robustness
1. ✅ Ensure SwitchBuilder ALWAYS populates enumBindingPlan
2. ✅ Add debug traces to show when plan is created and accessed
3. ✅ Make TEnumParameter REQUIRE enumBindingPlan - no fallbacks

### Phase 3: Validation
1. ✅ Add regression test: `test/snapshot/regression/EnumParameterInSwitch/`
2. ✅ Test with TodoPubSub pattern specifically
3. ✅ Verify all enum tests pass

---

## 6. Prioritized Roadmap to 1.0

### Critical Path (MUST FIX FOR 1.0)

#### Task 1: Fix _g Variable Bug in Enum Parameter Extraction ⚠️ BLOCKER
**Priority**: P0 - Blocks TodoApp compilation
**Estimate**: 2-4 hours
**Approach**: Hybrid Option A+D

**Subtasks**:
1. ✅ Add debug traces to show enumBindingPlan state in TEnumParameter
2. ✅ Search SwitchBuilder for `compileExpressionImpl` calls
3. ✅ Replace with `buildFromTypedExpr` if found
4. ✅ Verify enumBindingPlan is populated before case body compilation
5. ✅ Add assertion in TEnumParameter if enumBindingPlan is missing
6. ✅ Test with TodoPubSub.messageToElixir specifically
7. ✅ Create regression test

**Success Criteria**:
- ✅ TodoApp compiles without `undefined variable "_g"` errors
- ✅ Generated code uses pattern variables directly
- ✅ Regression test passes

#### Task 2: TodoApp Full Compilation
**Priority**: P0 - Primary integration test
**Estimate**: 2-4 hours
**Depends On**: Task 1

**Subtasks**:
1. ✅ Fix any additional compilation errors after Task 1
2. ✅ Verify `mix compile --force` succeeds
3. ✅ Verify `mix phx.server` starts without crashes
4. ✅ Test basic HTTP request: `curl http://localhost:4000`

**Success Criteria**:
- ✅ TodoApp compiles cleanly
- ✅ Phoenix server starts
- ✅ Basic routes respond

#### Task 3: Stabilize Test Suite to 50%+ Pass Rate
**Priority**: P1 - Quality gate
**Estimate**: 4-8 hours
**Depends On**: Task 1, 2

**Approach**:
1. ✅ Run full test suite: `npm test`
2. ✅ Categorize failures by type
3. ✅ Fix highest-impact categories first:
   - Enum pattern matching issues
   - Infrastructure variable leakage
   - Context preservation bugs
4. ✅ Update intended outputs where compiler improved

**Success Criteria**:
- ✅ 50%+ tests passing (104+/208)
- ✅ No regressions in working tests
- ✅ TodoApp still compiles

### High Priority (SHOULD FIX FOR 1.0)

#### Task 4: Fix Switch Side-Effects in Loops Bug
**Priority**: P1 - Known architectural issue
**Estimate**: 4-6 hours
**Reference**: `/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md`

**Problem**: Switch cases disappear when inside loops with compound assignments.

**Investigation Path**:
1. ✅ Trace LoopBuilder → SwitchBuilder coordination
2. ✅ Find where switch structure is lost
3. ✅ Fix pipeline coordination issue
4. ✅ Enable regression test

#### Task 5: Infrastructure Variable Elimination
**Priority**: P1 - Code quality
**Estimate**: 6-8 hours

**Problem**: `_g`, `g`, `g1` variables still appearing in some generated code.

**Approach**:
1. ✅ Audit all infrastructure variable generation
2. ✅ Ensure proper substitution in all contexts
3. ✅ Add transformation pass to catch any leaks
4. ✅ Add validation that final AST has no infrastructure vars

### Medium Priority (NICE TO HAVE FOR 1.0)

#### Task 6: Test Suite Categorization and Tooling
**Priority**: P2 - Developer experience
**Estimate**: 2-4 hours

**Improvements**:
- ✅ Better test runner with category filtering
- ✅ Parallel test execution
- ✅ Failure reporting with diffs
- ✅ Easy intended output updates

#### Task 7: Compiler Performance Optimization
**Priority**: P2 - Development velocity
**Estimate**: 4-6 hours

**Targets**:
- ✅ Reduce ElixirASTBuilder.hx size (currently 4,778 lines)
- ✅ Extract more specialized builders
- ✅ Profile compilation time
- ✅ Optimize hot paths

---

## 7. Post-1.0 Improvements

### Architecture Cleanup
1. ✅ Complete modularization of ElixirASTBuilder
2. ✅ Unified pattern matching system
3. ✅ Proper feature flag system for experimental features
4. ✅ Comprehensive debug infrastructure

### Feature Completeness
1. ✅ Full Phoenix LiveView support
2. ✅ Complete Ecto integration
3. ✅ OTP behaviors
4. ✅ ExUnit testing framework

### Documentation
1. ✅ Complete API reference
2. ✅ Migration guides
3. ✅ Best practices documentation
4. ✅ Example applications

---

## 8. Testing Strategy

### Regression Test Creation
For each bug fix, create focused regression test:

```haxe
// test/snapshot/regression/EnumParameterInSwitch/Main.hx
enum Message {
    Created(value: String);
    Updated(value: String);
}

class Main {
    static function test(msg: Message): String {
        return switch (msg) {
            case Created(val):
                "Created: " + val;  // Should use 'val' directly, not via _g
            case Updated(val):
                "Updated: " + val;
        };
    }
}
```

**Expected Output**:
```elixir
def test(msg) do
  case msg do
    {:created, val} ->
      "Created: #{val}"  # ✅ Direct use, no _g
    {:updated, val} ->
      "Updated: #{val}"
  end
end
```

### Validation Checklist
Before marking 1.0 complete:
- [ ] TodoApp compiles and runs
- [ ] 50%+ test pass rate
- [ ] No undefined variable errors
- [ ] No infrastructure variable leakage
- [ ] All critical bugs documented or fixed
- [ ] Regression tests for all P0/P1 bugs

---

## 9. Timeline Estimates

**Optimistic** (if no major blockers):
- Week 1: Fix _g bug + TodoApp compilation (Tasks 1-2)
- Week 2: Stabilize tests to 50% (Task 3)
- Week 3: High priority bugs (Tasks 4-5)
- Week 4: Polish and documentation

**Realistic** (accounting for unknowns):
- Week 1-2: Fix _g bug + TodoApp (Tasks 1-2)
- Week 3-4: Stabilize tests (Task 3)
- Week 5-6: High priority bugs (Tasks 4-5)
- Week 7-8: Polish and 1.0 release

**Pessimistic** (if architectural issues deeper than expected):
- Week 1-3: Fix _g bug thoroughly (Task 1)
- Week 4-6: TodoApp + critical blockers (Tasks 2-4)
- Week 7-10: Test stabilization (Task 3, 5)
- Week 11-12: 1.0 release prep

---

## 10. Success Metrics for 1.0

### Mandatory (Release Blockers)
- ✅ TodoApp compiles cleanly
- ✅ TodoApp runs and serves HTTP
- ✅ Zero undefined variable errors
- ✅ 50%+ test pass rate
- ✅ No known P0 bugs

### Desirable (Quality Gates)
- ✅ 60%+ test pass rate
- ✅ No known P1 bugs
- ✅ Comprehensive documentation
- ✅ Performance benchmarks documented

### Stretch Goals
- ✅ 75%+ test pass rate
- ✅ All Phoenix features working
- ✅ Example applications beyond todo-app
- ✅ Community contributions enabled

---

## Conclusion

The path to 1.0 is clear but requires **disciplined architectural fixes, not band-aids**. The _g variable bug is a symptom of deeper context preservation and pipeline coordination issues. Fixing it properly will improve the entire compilation architecture.

**Critical Next Steps**:
1. ✅ Deep-dive debug of enumBindingPlan state during TEnumParameter compilation
2. ✅ Search for context isolation bugs (compileExpressionImpl calls)
3. ✅ Fix the root cause in context passing
4. ✅ Validate with TodoApp compilation
5. ✅ Create regression tests to prevent recurrence

**Remember**: The todo-app is the PRIMARY integration test. Getting it to compile and run is more important than improving individual snapshot test pass rates. Once TodoApp works, the test suite improvements will follow naturally.
