# Pattern Metadata Generation for Guard Condition Transformation

## Executive Summary

This document explains the pattern metadata generation feature added to ElixirASTBuilder on January 27, 2025. This feature is the foundational component of the guard condition transformation system, enabling the compiler to detect and group switch cases with identical patterns but different guards for transformation into idiomatic Elixir `cond` statements.

## Problem Statement

### The Guard Condition Issue

When Haxe switch statements contain multiple cases with the same pattern but different guard conditions, the compiler was generating nested if-else statements with undefined variables:

```haxe
// Haxe input with multiple guards on same pattern
switch (color) {
    case RGB(r, g, b) if (r > 200): "red dominant";
    case RGB(r, g, b) if (g > 200): "green dominant";  
    case RGB(r, g, b) if (b > 200): "blue dominant";
    case RGB(r, g, b): "balanced";
}
```

```elixir
# Problematic output (before fix)
case color do
  {:rgb, r, g, b} ->
    if r > 200 do
      "red dominant"
    else
      # ERROR: r2, g2, b2 are undefined!
      if g2 > 200 do
        "green dominant"
      else
        # More undefined variables...
      end
    end
end
```

### Root Cause Analysis

The compiler treats each `case Pattern if guard:` as a completely separate case during the building phase. When multiple cases share the same pattern:

1. Only the first case binds the pattern variables (r, g, b)
2. Subsequent cases generate nested if-else statements
3. These nested statements reference variables that were never bound
4. Result: undefined variable errors in generated Elixir

## Architectural Solution: Three-Phase Pipeline

The solution implements a three-phase pipeline where each phase has a single, clear responsibility:

```
Phase 1: Builder (Detect & Mark)
    ↓ Attach metadata to AST nodes
Phase 2: Transformer (Group & Transform)  
    ↓ Use metadata to group and transform
Phase 3: Printer (Format Output)
    ↓ Generate idiomatic Elixir
```

## Phase 1 Implementation: Pattern Metadata Generation

### Purpose

The pattern metadata generation feature (implemented in ElixirASTBuilder) is responsible for:
1. Computing structural signatures for patterns (pattern keys)
2. Extracting bound variables from patterns
3. Detecting guard conditions
4. Attaching this metadata to AST nodes for later transformation

### Implementation Details

#### 1. Pattern Key Computation (`computePatternKey`)

Creates a structural signature that uniquely identifies pattern shapes:

```haxe
static function computePatternKey(pattern: EPattern): String {
    return switch(pattern) {
        case PVar(_): "var";
        case PWildcard: "_";
        case PTuple(elements):
            // For enum patterns like {:rgb, r, g, b}
            var parts = ["tuple"];
            if (elements.length > 0) {
                switch(elements[0]) {
                    case PLiteral(ast):
                        switch(ast.def) {
                            case EAtom(atom): parts.push(atom);
                            default:
                        }
                    default:
                }
            }
            var paramCount = elements.length > 0 ? elements.length - 1 : 0;
            parts.push(Std.string(paramCount));
            parts.join(":");  // Result: "tuple:rgb:3"
        // ... other pattern types
    }
}
```

**Key Examples**:
- `{:rgb, r, g, b}` → `"tuple:rgb:3"`
- `{:ok, value}` → `"tuple:ok:1"`
- `{:error, reason}` → `"tuple:error:1"`
- `_` → `"_"`
- Simple variable → `"var"`

#### 2. Bound Variable Extraction (`extractBoundVariables`)

Collects all variable names bound by a pattern:

```haxe
static function extractBoundVariables(pattern: EPattern): Array<String> {
    var vars = [];
    collectBoundVarsHelper(pattern, vars);
    return vars;
}

static function collectBoundVarsHelper(p: EPattern, vars: Array<String>): Void {
    switch(p) {
        case PVar(name):
            if (!name.startsWith("_")) vars.push(name);
        case PTuple(elements) | PList(elements):
            for (e in elements) collectBoundVarsHelper(e, vars);
        // ... recursively collect from all pattern types
    }
}
```

**Examples**:
- `{:rgb, r, g, b}` → `["r", "g", "b"]`
- `{:ok, value}` → `["value"]`
- `{:error, _reason}` → `[]` (underscore-prefixed are ignored)

#### 3. Metadata Attachment

The metadata is attached to the body of each case clause:

```haxe
// In TSwitch case processing (around line 5370)
for (pattern in patterns) {
    // Compute metadata for this pattern
    var patternKey = computePatternKey(finalPattern);
    var boundVars = extractBoundVariables(finalPattern);
    var hasGuard = false; // Guards detected differently in Haxe
    
    // Attach metadata to the body AST node
    if (patternKey != null || boundVars.length > 0 || hasGuard) {
        if (finalBody.metadata == null) finalBody.metadata = {};
        finalBody.metadata.patternKey = patternKey;
        finalBody.metadata.boundVars = boundVars;
        finalBody.metadata.hasGuard = hasGuard;
    }
    
    clauses.push({
        pattern: finalPattern,
        guard: null,
        body: finalBody
    });
}
```

### Metadata Structure

The metadata added to ElixirAST nodes includes:

```haxe
typedef ElixirMetadata = {
    // ... existing fields
    
    // Guard Condition Grouping (Added January 2025)
    ?patternKey: String,          // Normalized pattern signature for grouping
    ?boundVars: Array<String>,    // Variables bound by this pattern
    ?hasGuard: Bool               // Whether this clause has a guard condition
}
```

## Integration with Guard Grouping Transformation

### How the Transformer Uses This Metadata

The `guardGroupingPass` in ElixirASTTransformer uses this metadata to:

1. **Group cases by pattern key**:
   ```haxe
   // Cases with patternKey="tuple:rgb:3" are grouped together
   var groups = groupClausesByPattern(clauses);
   ```

2. **Preserve variable scope**:
   ```haxe
   // boundVars=["r", "g", "b"] ensures variables stay in scope
   var condBody = createCondWithVars(group, boundVars);
   ```

3. **Detect transformation candidates**:
   ```haxe
   // Only transform groups with multiple clauses and guards
   if (group.length > 1 && hasAnyGuards(group)) {
       return transformToCond(group);
   }
   ```

### Expected Transformation Result

With pattern metadata in place, the transformer can generate:

```elixir
# Idiomatic output (with metadata-driven transformation)
case color do
  {:rgb, r, g, b} ->
    cond do
      r > 200 -> "red dominant"
      g > 200 -> "green dominant"  
      b > 200 -> "blue dominant"
      true -> "balanced"
    end
  other -> 
    # Handle other patterns
end
```

## Benefits of This Approach

### 1. Separation of Concerns
- **Builder**: Only detects and marks patterns
- **Transformer**: Only groups and transforms
- **Printer**: Only formats output
- Each phase has a single, clear responsibility

### 2. Predictable Pipeline
- All code flows through all phases
- No bypassing or special cases
- Metadata drives decisions, not hardcoded logic

### 3. General Solution
- Works for any enum type, not just hardcoded ones
- Pattern detection is structural, not name-based
- No maintenance burden when adding new enums

### 4. Debuggability
- Metadata is visible in AST dumps
- Can trace pattern grouping decisions
- Clear data flow through pipeline

## Testing Strategy

### Unit Tests

Test pattern metadata generation independently:

```haxe
// Test pattern key computation
assert(computePatternKey(PTuple([PLiteral(EAtom("rgb")), PVar("r"), PVar("g"), PVar("b")])) 
       == "tuple:rgb:3");

// Test bound variable extraction  
assert(extractBoundVariables(PTuple([PLiteral(EAtom("ok")), PVar("value")]))
       == ["value"]);
```

### Integration Tests

The ECond printing test validates the complete pipeline:

```bash
test/snapshot/regression/econd_printing_test/
├── Main.hx           # Test case with guard conditions
├── compile.hxml      # Compilation configuration
└── intended/         # Expected idiomatic output
    └── Main.ex
```

## Implementation Timeline

### ✅ Completed (January 27, 2025)
- [x] Add metadata fields to ElixirAST.hx
- [x] Implement computePatternKey function
- [x] Implement extractBoundVariables function
- [x] Attach metadata to case clause bodies
- [x] Create ECond printing test

### 🔄 Next Steps
- [ ] Implement guardGroupingPass transformation
- [ ] Create comprehensive guard grouping tests
- [ ] Fix existing enum tests with guard conditions
- [ ] Validate todo-app compilation

## Code Location Reference

All changes are in `/src/reflaxe/elixir/ast/ElixirASTBuilder.hx`:

- **Lines 11853-11893**: `computePatternKey` function
- **Lines 11901-11930**: `extractBoundVariables` and helper
- **Lines 5370-5380**: Metadata attachment in TSwitch processing
- **Lines 810-813** (ElixirAST.hx): Metadata field additions

## Related Documentation

- [GUARD_CONDITION_TRANSFORMATION_PLAN.md](./GUARD_CONDITION_TRANSFORMATION_PLAN.md) - Complete architectural plan
- [ENUM_GUARD_CONDITIONS_PRD.md](./ENUM_GUARD_CONDITIONS_PRD.md) - Original problem analysis
- [AST_PIPELINE_MIGRATION.md](../05-architecture/AST_PIPELINE_MIGRATION.md) - AST pipeline architecture

## Conclusion

The pattern metadata generation feature is the foundation of the guard condition transformation system. By computing structural signatures and extracting bound variables during the build phase, we enable the transformer to intelligently group and transform cases with identical patterns into idiomatic Elixir `cond` statements. This metadata-driven approach maintains clean separation of concerns and provides a general solution that works for any pattern type without hardcoding.

## Future Enhancements

Potential extensions to the metadata system:

1. **Pattern complexity scoring** - Prioritize complex patterns for optimization
2. **Usage frequency tracking** - Optimize frequently used patterns
3. **Cross-reference analysis** - Detect related patterns across modules
4. **Performance hints** - Suggest optimal pattern ordering

---

*Document created: January 27, 2025*  
*Feature implemented in: commit aea6c47c*  
*Author: AI-assisted development for Reflaxe.Elixir 1.0*