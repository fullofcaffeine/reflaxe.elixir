# Guard Condition Transformation - Architectural Plan & PRD

## Executive Summary

This document outlines the comprehensive architectural solution for transforming Haxe switch statements with multiple guard conditions into idiomatic Elixir `cond` statements, completing the final piece of enum compilation to achieve 1.0 quality.

## Problem Analysis

### Current State
The compiler generates nested if-else statements with undefined variables when processing multiple switch cases with the same pattern but different guards:

```haxe
// Haxe input
switch (color) {
    case RGB(r, g, b) if (r > 200 && g < 50 && b < 50): "mostly red";
    case RGB(r, g, b) if (g > 200 && r < 50 && b < 50): "mostly green";
    case RGB(r, g, b): "mixed color";
    case _: "not RGB";
}
```

```elixir
# Current problematic output
case color do
  {:rgb, r, g, b} ->
    if (r > 200 and g < 50 and b < 50) do
      "mostly red"
    else
      r2 = nil  # Undefined!
      g2 = nil  # Undefined!
      if (g2 > 200 and r2 < 50 and b2 < 50) do  # All undefined!
        "mostly green"
      else
        # More undefined variables...
      end
    end
end
```

### Root Cause
Each guard condition creates a new scope in the current implementation, losing access to the pattern-bound variables. The compiler treats each `case Pattern if guard:` as a separate case, generating nested if-else statements instead of recognizing the pattern grouping opportunity.

## Architectural Solution

### Core Design Principles
1. **Metadata-Driven Detection**: Use metadata to mark patterns for transformation
2. **Single Responsibility**: Each phase has one clear purpose
3. **No Hardcoding**: General solution for any enum type
4. **Predictable Pipeline**: Linear flow through all phases
5. **Idiomatic Output**: Generate clean Elixir `cond` expressions

### Three-Phase Pipeline Implementation

```
TypedExpr → ElixirASTBuilder → ElixirAST → ElixirASTTransformer → ElixirAST' → ElixirASTPrinter → String
           (Build & Mark)                  (Detect & Transform)                 (Format & Print)
```

## Phase 1: Builder Phase (ElixirASTBuilder)

### Responsibilities
- Build ElixirAST nodes from TypedExpr
- Mark nodes with metadata for later transformation
- NO transformation logic

### Implementation

```haxe
// In ElixirASTBuilder.hx
function buildCaseClause(pattern: TypedExpr, guard: Null<TypedExpr>, body: TypedExpr): ECaseClause {
    var patternAST = buildPattern(pattern);
    var guardAST = guard != null ? buildExpression(guard) : null;
    var bodyAST = buildExpression(body);
    
    // Compute pattern key for grouping
    var patternKey = computePatternKey(patternAST);
    
    // Extract bound variables for scope preservation
    var boundVars = extractBoundVariables(patternAST);
    
    return {
        pattern: patternAST,
        guard: guardAST,
        body: bodyAST,
        metadata: {
            patternKey: patternKey,        // e.g., "tuple:rgb:3"
            boundVars: boundVars,           // ["r", "g", "b"]
            hasGuard: guard != null,
            sourcePosition: pattern.pos
        }
    };
}

// Pattern key computation (structural, not name-based)
static function computePatternKey(pattern: ElixirAST): String {
    return switch(pattern.def) {
        case EAtom(name): 
            "atom:" + name;
        case ETuple([EAtom(name), ...params]):
            "tuple:" + name + ":" + params.length;
        case EVar(name): 
            "var:" + name;
        case EWildcard: 
            "_";
        default: 
            Std.string(pattern.def);  // Fallback
    };
}
```

## Phase 2: Transformer Phase (ElixirASTTransformer)

### Responsibilities
- Detect patterns requiring transformation
- Group cases by pattern
- Generate `cond` expressions
- Preserve variable scope

### Implementation

```haxe
// New transformation pass in ElixirASTTransformer.hx
static function guardGroupingPass(ast: ElixirAST): ElixirAST {
    return switch(ast.def) {
        case ECase(target, clauses):
            var groups = groupClausesByPattern(clauses);
            var transformedClauses = [];
            
            for (group in groups) {
                if (shouldTransformToCondℍ(group)) {
                    transformedClauses.push(createCondClause(group));
                } else {
                    transformedClauses = transformedClauses.concat(group);
                }
            }
            
            makeASTWithMeta(
                ECase(target, transformedClauses),
                ast.metadata,
                ast.pos
            );
            
        default:
            transformNode(ast, guardGroupingPass);
    };
}

// Group consecutive clauses with same pattern
static function groupClausesByPattern(clauses: Array<ECaseClause>): Array<Array<ECaseClause>> {
    var groups = [];
    var currentGroup = [];
    var currentKey = null;
    
    for (clause in clauses) {
        var key = clause.metadata?.patternKey;
        
        if (key == currentKey && key != null) {
            currentGroup.push(clause);
        } else {
            if (currentGroup.length > 0) {
                groups.push(currentGroup);
            }
            currentGroup = [clause];
            currentKey = key;
        }
    }
    
    if (currentGroup.length > 0) {
        groups.push(currentGroup);
    }
    
    return groups;
}

// Check if group should be transformed
static function shouldTransformToCond(group: Array<ECaseClause>): Bool {
    // Multiple clauses with same pattern, at least one with guard
    return group.length > 1 && 
           group[0].metadata?.patternKey != null &&
           group.exists(c -> c.metadata?.hasGuard == true);
}

// Create single clause with cond body
static function createCondClause(group: Array<ECaseClause>): ECaseClause {
    var condBranches = [];
    var defaultBody = null;
    
    for (clause in group) {
        if (clause.guard != null) {
            condBranches.push({
                condition: clause.guard,
                body: clause.body
            });
        } else {
            // No guard means default case
            defaultBody = clause.body;
        }
    }
    
    // Add true -> default if present
    if (defaultBody != null) {
        condBranches.push({
            condition: makeAST(EBoolean(true)),
            body: defaultBody
        });
    } else if (condBranches.length > 0) {
        // No default, might want to add error handling
        // For now, let Elixir handle the no-match case
    }
    
    return {
        pattern: group[0].pattern,  // Use first pattern (all identical)
        guard: null,                // No guard on outer clause
        body: makeAST(ECond(condBranches)),
        metadata: group[0].metadata // Preserve metadata
    };
}
```

## Phase 3: Printer Phase (ElixirASTPrinter)

### Responsibilities
- Format ECond nodes properly
- Generate clean Elixir syntax
- NO transformation logic

### Implementation

```haxe
// In ElixirASTPrinter.hx (if ECond support missing)
case ECond(branches):
    var lines = ["cond do"];
    
    for (branch in branches) {
        var condition = printExpression(branch.condition, false);
        var body = printExpression(branch.body, false);
        
        // Handle indentation
        var bodyLines = body.split("\n");
        if (bodyLines.length > 1) {
            body = bodyLines.map(l -> "    " + l).join("\n");
            lines.push("  " + condition + " ->");
            lines.push(body);
        } else {
            lines.push("  " + condition + " -> " + body);
        }
    }
    
    lines.push("end");
    return lines.join("\n");
```

## AST Node Additions

### ElixirAST.hx Updates

```haxe
// Add to ElixirASTDef enum
ECond(branches: Array<CondBranch>);

// Supporting types
typedef CondBranch = {
    condition: ElixirAST,
    body: ElixirAST
}

// Update metadata type
typedef ElixirMetadata = {
    // ... existing fields
    ?patternKey: String,
    ?boundVars: Array<String>,
    ?hasGuard: Bool
}
```

## Testing Strategy

### Unit Tests

Create focused regression tests in `test/snapshot/regression/guard_condition_grouping/`:

```haxe
// Main.hx
enum TestEnum {
    Pattern(a: Int, b: Int, c: Int);
    Other;
}

class Main {
    static function testGuards(e: TestEnum): String {
        return switch(e) {
            case Pattern(a, b, c) if (a > 100): "high a";
            case Pattern(a, b, c) if (b > 100): "high b";
            case Pattern(a, b, c) if (c > 100): "high c";
            case Pattern(a, b, c): "default pattern";
            case Other: "other";
        }
    }
    
    static function testMixed(e: TestEnum): String {
        return switch(e) {
            case Pattern(a, b, c) if (a + b > 200): "sum high";
            case Other: "other";
            case Pattern(a, b, c): "default";
        }
    }
    
    static function main() {
        trace(testGuards(Pattern(150, 50, 50)));  // "high a"
        trace(testGuards(Pattern(50, 150, 50)));  // "high b"
        trace(testMixed(Other));                   // "other"
    }
}
```

Expected output:
```elixir
defmodule Main do
  def test_guards(e) do
    case e do
      {:pattern, a, b, c} ->
        cond do
          a > 100 -> "high a"
          b > 100 -> "high b"
          c > 100 -> "high c"
          true -> "default pattern"
        end
      :other -> "other"
    end
  end
  
  def test_mixed(e) do
    case e do
      {:pattern, a, b, c} ->
        cond do
          a + b > 200 -> "sum high"
          true -> "default"
        end
      :other -> "other"
    end
  end
end
```

### Integration Tests
- Verify todo-app compiles without warnings
- Test enum patterns in examples/todo-app
- Ensure no regression in existing tests

## Edge Cases & Considerations

### 1. Non-Contiguous Patterns
Only group adjacent clauses with the same pattern:
```haxe
case A(x) if (x > 0): "positive";
case B(y): "b";           // Different pattern, breaks group
case A(x): "default a";   // Not grouped with first A
```

### 2. No Default Case
If all cases have guards and no default:
```elixir
cond do
  guard1 -> result1
  guard2 -> result2
  # No true -> branch, might raise CondClauseError at runtime
end
```

### 3. Complex Guards
Support arbitrary guard expressions:
```haxe
case RGB(r, g, b) if (r > g && g > b && b > 0): "gradient";
```

### 4. Nested Switches
Handle switches within case bodies correctly.

## Implementation Timeline

### Phase 1: Core Implementation (2-3 days)
- [ ] Add ECond to ElixirAST.hx
- [ ] Implement metadata in Builder
- [ ] Create guardGroupingPass
- [ ] Add ECond printing support

### Phase 2: Testing & Refinement (1-2 days)
- [ ] Create comprehensive test suite
- [ ] Fix edge cases
- [ ] Optimize pattern detection
- [ ] Update documentation

### Phase 3: Integration (1 day)
- [ ] Verify all existing tests pass
- [ ] Update todo-app if needed
- [ ] Run qa_sentinel verification
- [ ] Create PR with complete solution

## Success Metrics

1. **All enum tests pass** - No compilation errors or warnings
2. **Generated code is idiomatic** - Clean `cond` expressions
3. **No undefined variables** - Proper scope preservation
4. **Todo-app compiles cleanly** - Real-world validation
5. **Performance maintained** - No compilation speed regression

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing patterns | Feature flag for gradual rollout |
| Complex AST manipulation | Comprehensive test coverage |
| Performance impact | Profile transformation passes |
| Edge case bugs | Extensive edge case testing |

## Alternative Approaches Considered

1. **String Post-Processing** - Rejected: Fragile, not architectural
2. **Modified Builder Logic** - Rejected: Violates single responsibility
3. **Custom Guard Node Type** - Rejected: Over-engineering
4. **With Statement Generation** - Rejected: Not appropriate for this use case

## Conclusion

This architectural solution provides a clean, maintainable approach to transforming guard conditions into idiomatic Elixir. By following the three-phase pipeline and using metadata-driven detection, we achieve:

- **Correct semantics** - Variables stay in scope
- **Idiomatic output** - Clean `cond` expressions
- **Maintainable code** - Clear separation of concerns
- **General solution** - Works for any pattern type

This completes the final major issue for enum compilation, bringing us to 1.0 quality.

## References

- [Elixir Case/Cond Documentation](https://elixir-lang.org/getting-started/case-cond-and-if.html)
- [Reflaxe Compiler Architecture](https://github.com/RobertBorghese/reflaxe)
- [ENUM_GUARD_CONDITIONS_PRD.md](./ENUM_GUARD_CONDITIONS_PRD.md)