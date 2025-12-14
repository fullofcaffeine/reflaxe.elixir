# Guard Condition Flattening - Product Requirements Document

## Executive Summary

This PRD defines a comprehensive solution for the guard condition grouping issue in the Haxe→Elixir compiler, where multiple guard conditions on the same pattern are not being fully flattened into idiomatic Elixir `cond` expressions. The current implementation only extracts the first guard condition, leaving subsequent ones nested with undefined variable issues.

## Problem Statement

### Current Behavior
When compiling Haxe switch statements with multiple guard conditions on the same enum pattern:

```haxe
switch(color) {
    case RGB(r, g, b) if (r > 200): "high red";
    case RGB(r, g, b) if (g > 200): "high green";  
    case RGB(r, g, b) if (b > 200): "high blue";
    case RGB(r, g, b): "normal";
}
```

### Current Output (Problematic)
```elixir
case color do
  {:rgb, r, g, b} ->
    cond do
      (r > 200) -> "high red"
      true ->
        r2 = nil  # Undefined variable issue
        b2 = nil
        if (g > 200) do
          "high green"
        else
          r3 = nil  # More undefined variables
          b3 = nil
          if (b > 200) do
            "high blue"
          else
            "normal"
          end
        end
    end
end
```

### Expected Output (Idiomatic)
```elixir
case color do
  {:rgb, r, g, b} ->
    cond do
      r > 200 -> "high red"
      g > 200 -> "high green"
      b > 200 -> "high blue"
      true -> "normal"
    end
end
```

## Root Cause Analysis

1. **Partial Extraction**: The `extractCondBranches` function only processes conditions at the immediate level
2. **No Recursive Collection**: Doesn't descend into `true ->` branches to find nested conditions
3. **Variable Scope Issues**: Nil assignments (r2=nil, g2=nil) are symptoms of broken scope management
4. **Incremental Transformation**: Current approach transforms as it traverses, missing the full picture

## Proposed Solution: GuardConditionFlattener System

### Architecture Overview

```
Input AST → Collection Phase → Validation Phase → Reconstruction Phase → Output AST
```

### Phase 1: Collection Phase

**Purpose**: Recursively collect ALL guard conditions from nested if-else chains

**Algorithm**:
```elixir
def collect_guard_conditions(ast) do
  case ast do
    ECond(branches) ->
      flatten_branches(branches)
    
    EIf(condition, then_branch, else_branch) ->
      [{condition, then_branch}] ++ collect_guard_conditions(else_branch)
    
    EBlock(exprs) ->
      # Filter out nil assignments
      clean_exprs = filter_nil_assignments(exprs)
      if length(clean_exprs) == 1 do
        collect_guard_conditions(clean_exprs[0])
      else
        []
      end
    
    _ -> []
  end
end
```

**Key Features**:
- Recursive descent through entire nested structure
- Automatic filtering of nil assignments (r2=nil patterns)
- Preservation of condition-result pairs
- Handle blocks that wrap single expressions

### Phase 2: Validation Phase

**Purpose**: Ensure collected conditions are valid for grouping

**Validation Rules**:
1. All conditions must operate on the same bound variables
2. No mixing of different pattern types (e.g., RGB with HSL)
3. Detect and preserve the default case (no guard)
4. Ensure variable references are consistent

**Algorithm**:
```elixir
def validate_guard_group(conditions, bound_vars) do
  conditions
  |> Enum.all?(fn {cond, _} ->
    variables_in_condition(cond) |> MapSet.subset?(bound_vars)
  end)
end
```

### Phase 3: Reconstruction Phase

**Purpose**: Build a single flat ECond with all collected conditions

**Algorithm**:
```elixir
def reconstruct_as_cond(validated_conditions, default_case) do
  branches = validated_conditions ++ [{EAtom("true"), default_case}]
  ECond(branches)
end
```

## Implementation Strategy

### 1. Enhance Metadata System

```haxe
typedef GuardGroupMetadata = {
    patternKey: String,
    boundVars: Array<String>,
    hasGuard: Bool,
    guardDepth: Int,        // NEW: Track nesting depth
    siblingCount: Int,      // NEW: Number of related guards
    isLastInGroup: Bool     // NEW: Mark end of guard sequence
}
```

### 2. Create GuardCollectorPass

Location: `ElixirASTTransformer.hx`

```haxe
static function guardCollectorPass(ast: ElixirAST): ElixirAST {
    return switch(ast.def) {
        case ECase(expr, clauses):
            var enhancedClauses = clauses.map(clause -> {
                if (clause.body.metadata?.patternKey != null) {
                    var collected = collectAllGuardConditions(clause.body);
                    if (collected.length > 1) {
                        clause.body.metadata.collectedGuards = collected;
                    }
                }
                return clause;
            });
            {def: ECase(expr, enhancedClauses), pos: ast.pos};
        default:
            transformAST(ast, guardCollectorPass);
    }
}
```

### 3. Update GuardGroupingPass

```haxe
static function guardGroupingPass(ast: ElixirAST): ElixirAST {
    return switch(ast.def) {
        case ECase(expr, clauses):
            var transformedClauses = clauses.map(clause -> {
                if (clause.body.metadata?.collectedGuards != null) {
                    var flattened = buildFlatCond(
                        clause.body.metadata.collectedGuards,
                        clause.body.metadata.boundVars
                    );
                    return {
                        pattern: clause.pattern,
                        guard: clause.guard,
                        body: flattened
                    };
                }
                return clause;
            });
            {def: ECase(expr, transformedClauses), pos: ast.pos};
        default:
            transformAST(ast, guardGroupingPass);
    }
}
```

## Edge Cases to Handle

1. **Mixed Pattern Types**: RGB guards followed by HSL guards
2. **Deeply Nested Conditions**: 5+ levels of nesting
3. **Guards with Complex Expressions**: `r + g + b > 500`
4. **Default Cases**: Patterns without guards mixed with guarded patterns
5. **Variable Shadowing**: Same variable names in different scopes
6. **Empty Branches**: Guards that produce no body
7. **Side Effects in Guards**: Function calls within guard expressions

## Testing Strategy

### Unit Tests
1. Test collection phase with various nesting depths
2. Test validation with mixed patterns
3. Test reconstruction with edge cases

### Integration Tests
1. Complete enum pattern matching scenarios
2. Performance tests with large switch statements
3. Regression tests for all fixed issues

### Test Cases Required

```haxe
// Test 1: Simple sequential guards
testSimpleGuards()

// Test 2: Complex nested conditions
testDeepNesting()

// Test 3: Mixed patterns
testMixedPatterns()

// Test 4: Guards with expressions
testComplexGuardExpressions()

// Test 5: Default case handling
testDefaultCases()
```

## Success Metrics

1. **Correctness**: All guard conditions properly flattened
2. **No Undefined Variables**: Zero r2, g2, b2 style variables in output
3. **Idiomatic Output**: Generated Elixir indistinguishable from hand-written
4. **Performance**: No compilation slowdown > 5%
5. **Test Coverage**: 100% of edge cases covered

## Rollout Plan

### Phase 1: Foundation (Day 1-2)
- Implement collection algorithm
- Add comprehensive debug traces
- Create unit tests for collection

### Phase 2: Validation (Day 2-3)
- Implement validation rules
- Handle edge cases
- Add validation tests

### Phase 3: Integration (Day 3-4)
- Wire up all three phases
- Update existing GuardGroupingPass
- Run full test suite

### Phase 4: Polish (Day 4-5)
- Fix any remaining issues
- Performance optimization
- Documentation update

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing transformations | High | Feature flag for new algorithm |
| Performance regression | Medium | Benchmark before/after |
| Incomplete edge case handling | Medium | Comprehensive test suite |
| Complex debugging | Low | XRay traces at each phase |

## Alternative Approaches Considered

1. **Single-Pass Deep Transformation**: Rejected due to complexity
2. **Post-Processing Cleanup**: Rejected as band-aid solution
3. **Metadata-Only Solution**: Rejected as insufficient for deep nesting

## Dependencies

- ElixirASTBuilder.hx (metadata generation)
- ElixirASTTransformer.hx (transformation passes)
- ElixirASTPrinter.hx (output generation)

## Documentation Requirements

1. Update PATTERN_METADATA_GENERATION.md
2. Create GUARD_FLATTENING_GUIDE.md
3. Update compiler architecture docs
4. Add inline documentation for all new functions

## Acceptance Criteria

- [ ] All test cases in guard_condition_grouping pass
- [ ] No undefined variables in generated output
- [ ] Todo-app compiles without warnings
- [ ] Performance benchmarks within 5% of baseline
- [ ] Documentation complete and reviewed
- [ ] Code review passed

---

*PRD Version: 1.0*  
*Date: January 2025*  
*Author: AI-Assisted Compiler Development Team*