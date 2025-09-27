# Enum Compilation Redesign PRD

**Date**: January 2025  
**Status**: Problem Discovery Phase  
**Priority**: Critical (87% of enum tests failing)  
**Author**: QA Sentinel Analysis

## Executive Summary

The Haxe→Elixir compiler's enum compilation system has fundamental architectural issues that prevent it from generating idiomatic Elixir code. While recent fixes addressed underscore prefixing for unused variables, comprehensive testing revealed that the core enum compilation logic generates incorrect patterns that fail Elixir's idiomatic standards.

## Problem Statement

### Current State
The compiler incorrectly handles enum compilation in three critical areas:

1. **Atom vs Tuple Generation**: All enum constructors generate tuples, even simple ones that should be atoms
2. **Variable Name Consistency**: Pattern variables don't match their usage in case bodies
3. **Guard Condition Corruption**: Nested conditions generate undefined variables

### Impact
- **87% of enum tests failing** - Near-complete failure of enum functionality
- **Non-idiomatic output** - Generated code doesn't match Elixir conventions
- **Runtime errors** - Undefined variable references cause compilation failures
- **Developer experience** - Generated code is unreadable and unmaintainable

## Root Cause Analysis

### Issue 1: Uniform Tuple Generation

**Current Behavior:**
```elixir
# Simple enum constructor (WRONG)
case color do
  {:red} ->  # Should be :red
    "red"
```

**Root Cause:**
- `ElixirASTBuilder.hx:3105` - All enum constructors generate `ETuple([makeAST(EAtom(atomName))])`
- No distinction between simple and parameterized constructors
- Pattern generation at lines 8355, 8400, 8560 wraps all constructors in tuples

**Expected Behavior:**
```elixir
# Simple constructor -> Atom
case color do
  :red ->     # Correct: plain atom
    "red"
  {:rgb, r, g, b} ->  # Correct: tuple for parameters
    "rgb(#{r}, #{g}, #{b})"
```

### Issue 2: Variable Name Mismatches

**Current Behavior:**
```elixir
case color do
  {:rgb, r, g1, b} ->  # Pattern uses g1
    "rgb(#{r}, #{g}, #{b})"  # Body uses g (undefined!)
```

**Root Cause:**
- Variable extraction in `analyzeEnumParameterExtraction()` generates temporary names
- `ClauseContext` mapping doesn't properly coordinate with pattern generation
- Multiple competing variable naming systems (EnumBindingPlan, varMapping, tempVarRenameMap)

**Expected Behavior:**
```elixir
case color do
  {:rgb, r, g, b} ->  # Consistent names
    "rgb(#{r}, #{g}, #{b})"  # Same names used
```

### Issue 3: Guard Condition Variable Scoping

**Current Behavior:**
```elixir
case color do
  {:rgb, r, g, b} ->
    if (r > 200 and g < 50 and b < 50) do
      "mostly red"
    else
      r2 = nil  # What is r2?
      b2 = nil  # What is b2?
      if (g2 > 200 and r2 < 50 and b2 < 50) do  # All undefined!
        "mostly green"
```

**Root Cause:**
- Guard conditions being transformed into nested if-else instead of `cond`
- Variable renaming system creates phantom variables
- Scope isolation between pattern and guard expressions

**Expected Behavior:**
```elixir
case color do
  {:rgb, r, g, b} ->
    cond do
      r > 200 && g < 50 && b < 50 -> "mostly red"
      g > 200 && r < 50 && b < 50 -> "mostly green"
      b > 200 && r < 50 && g < 50 -> "mostly blue"
      true -> "mixed color"
    end
```

## Requirements

### Functional Requirements

#### FR1: Atom vs Tuple Distinction
- **FR1.1**: Simple enum constructors (no parameters) MUST generate atoms
- **FR1.2**: Parameterized constructors MUST generate tuples with atom tag
- **FR1.3**: Pattern matching MUST use same representation as constructor generation

#### FR2: Variable Name Consistency
- **FR2.1**: Pattern variable names MUST match their usage in case bodies
- **FR2.2**: Single source of truth for variable naming per scope
- **FR2.3**: No phantom or undefined variables in generated code

#### FR3: Idiomatic Guard Patterns
- **FR3.1**: Complex conditionals MUST use `cond` blocks
- **FR3.2**: Variables in guards MUST reference pattern-bound variables
- **FR3.3**: No unnecessary variable rebinding or nil assignments

### Non-Functional Requirements

#### NFR1: Code Quality
- Generated Elixir code MUST be indistinguishable from hand-written code
- No `elem()` extraction when pattern matching is available
- Use string interpolation `#{}` instead of concatenation

#### NFR2: Compatibility
- Support both regular enums and `@:elixirIdiomatic` enums
- Maintain backward compatibility where possible
- Clear migration path for existing code

#### NFR3: Performance
- No unnecessary temporary variables
- Direct pattern matching without intermediate extraction
- Minimize AST transformation passes

## Proposed Solution Architecture

### Phase 1: Atom/Tuple Distinction

**Location**: `ElixirASTBuilder.hx`

1. Modify enum constructor generation (lines ~3100-3105):
```haxe
// Determine constructor type
var hasParameters = switch(ef.type) {
    case TFun(args, _): args.length > 0;
    default: false;
};

// Generate appropriate representation
if (hasParameters) {
    // Parameterized: generate tuple
    ETuple([makeAST(EAtom(atomName))].concat(argExprs));
} else {
    // Simple: generate atom only
    makeAST(EAtom(atomName));
}
```

2. Update pattern generation (lines ~8355, 8400, 8560) with same logic

3. Ensure consistency across all enum-handling code paths

### Phase 2: Variable Name Coordination

**Location**: `ElixirASTBuilder.hx` + `helpers/VariableCompiler.hx`

1. Establish `EnumBindingPlan` as single source of truth
2. Remove competing naming systems
3. Ensure pattern generation uses same names as body compilation
4. Add debug tracing for variable name mapping

### Phase 3: Guard Condition Transformation

**Location**: `ast/transformers/ElixirASTTransformer.hx`

1. Add `GuardToCondTransform` pass
2. Detect nested if-else in case bodies
3. Transform to `cond` blocks for multiple conditions
4. Preserve variable bindings from patterns

## Implementation Plan

### Step 1: Create Regression Test Suite
- Capture current failing tests as regression markers
- Create minimal reproductions for each issue
- Document expected idiomatic output

### Step 2: Implement Atom/Tuple Fix
- Most critical issue affecting all enum usage
- Estimated effort: 4 hours
- Risk: Medium (touches core compilation)

### Step 3: Fix Variable Naming
- Requires careful coordination between systems
- Estimated effort: 8 hours
- Risk: High (affects multiple subsystems)

### Step 4: Guard Condition Cleanup
- Can be done as transformation pass
- Estimated effort: 4 hours
- Risk: Low (isolated to transformer)

### Step 5: Comprehensive Testing
- Run full enum test suite
- Verify with qa_sentinel
- Test todo-app compilation
- Performance benchmarking

## Success Metrics

- **100% enum test pass rate** (currently 12.5%)
- **Zero undefined variable errors** in generated code
- **Idiomatic score ≥ 90** from qa_sentinel
- **Generated code matches hand-written Elixir** patterns

## Risk Assessment

### High Risk
- **Variable naming changes** could break existing working code
- **Large file refactoring** (ElixirASTBuilder.hx is 11,000+ lines)

### Medium Risk
- **Atom/tuple changes** affect all enum usage
- **Pattern matching** modifications could introduce edge cases

### Low Risk
- **Guard transformation** is additive, not destructive
- **String interpolation** is straightforward replacement

## Dependencies

- No external dependencies
- Requires understanding of Haxe's TypedExpr AST
- Knowledge of Elixir idiomatic patterns

## Timeline

- **Phase 1** (Atom/Tuple): 1 day
- **Phase 2** (Variable Naming): 2 days  
- **Phase 3** (Guards): 1 day
- **Testing & Validation**: 1 day
- **Total**: 5 days

## Alternatives Considered

### Alternative 1: Post-Processing Fixes
- Add transformation passes to clean up bad generation
- **Rejected**: Band-aid approach, doesn't fix root cause

### Alternative 2: Complete Enum System Rewrite
- Start fresh with new enum compilation system
- **Rejected**: Too risky, would break existing code

### Alternative 3: Metadata-Driven Approach
- Use `@:atom` and `@:tuple` annotations
- **Rejected**: Adds complexity for users

## Open Questions

1. Should `@:elixirIdiomatic` affect atom/tuple generation differently?
2. How to handle enum abstracts vs regular enums?
3. Should we support custom atom names via metadata?
4. How to maintain backward compatibility during transition?

## Appendix: Test Cases

### Test 1: Simple Enum
```haxe
enum Color { Red; Green; Blue; }
// Should generate: :red, :green, :blue
```

### Test 2: Parameterized Enum
```haxe
enum Color { RGB(r:Int, g:Int, b:Int); }
// Should generate: {:rgb, r, g, b}
```

### Test 3: Mixed Enum
```haxe
enum Option<T> { Some(v:T); None; }
// Should generate: {:some, v} and :none
```

### Test 4: Guard Conditions
```haxe
switch(color) {
    case RGB(r, g, b) if (r > 200): "red-ish";
}
// Should use same r, g, b in guard as in pattern
```

## References

- [Elixir Pattern Matching Guide](https://elixir-lang.org/getting-started/pattern-matching.html)
- [Idiomatic Elixir Patterns](https://github.com/christopheradams/elixir_style_guide)
- Original issue: OrphanedEnumParameters test failures
- QA Sentinel Report: January 2025

---

**Document Status**: This PRD documents the current state of enum compilation issues and proposes solutions. Implementation has not yet begun. The underscore prefixing fix completed earlier addresses only a small subset of these issues.