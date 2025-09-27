# Enum Guard Conditions and Idiomatic Transformation PRD

## Executive Summary

This PRD documents the remaining enum compilation issues after fixing simple constructor and variable name problems. The primary challenges are transforming pattern matching with guard conditions into idiomatic Elixir `cond` statements, implementing string interpolation, and fixing naming conventions.

## Problem Statement

### Current State (January 2025)
After fixing simple enum constructors and variable name mismatches, three critical issues remain:

1. **Guard Conditions Generate Undefined Variables**
2. **String Concatenation Instead of Interpolation**
3. **Incorrect Snake Case Conversion for Acronyms**

### Impact
- Guard conditions generate code with undefined variables (g2, r2, b2, etc.)
- String operations are verbose and non-idiomatic
- Function/pattern names are incorrect (describe_r_g_b instead of describe_rgb)

## Detailed Issues Analysis

### Issue 1: Guard Conditions with Undefined Variables

**Current Generated Code:**
```elixir
def describe_rgb(color) do
  case color do
    {:r_g_b, r, g, b} ->
      if (r > 200 and g < 50 and b < 50) do
        "mostly red"
      else
        r2 = nil  # Undefined!
        b2 = nil  # Undefined!
        if (g2 > 200 and r2 < 50 and b2 < 50) do  # g2 undefined!
          "mostly green"
        else
          # More undefined variables...
        end
      end
  end
end
```

**Expected Idiomatic Code:**
```elixir
def describe_rgb(color) do
  case color do
    {:rgb, r, g, b} ->
      cond do
        r > 200 && g < 50 && b < 50 ->
          "mostly red"
        g > 200 && r < 50 && b < 50 ->
          "mostly green"  
        b > 200 && r < 50 && g < 50 ->
          "mostly blue"
        true ->
          "mixed color"
      end
    _ ->
      "not RGB"
  end
end
```

**Root Cause:**
The compiler treats each `case Pattern if guard:` as a separate case, generating nested if-else statements. It doesn't recognize that multiple cases with the same pattern but different guards should be combined into a single case with a `cond` statement.

### Issue 2: String Concatenation vs Interpolation

**Current Generated Code:**
```elixir
"rgb(" <> r.to_string() <> ", " <> g.to_string() <> ", " <> b.to_string() <> ")"
```

**Expected Idiomatic Code:**
```elixir
"rgb(#{r}, #{g}, #{b})"
```

**Root Cause (RESOLVED January 2025):**
The StringInterpolation transformation pass wasn't handling EParen (parentheses) nodes. When case clause bodies were wrapped in parentheses (which happens when they're used as return values), the transformer would return the EParen node unchanged without recursing into its contents. This blocked the detection and transformation of string concatenation patterns inside.

### Issue 3: Acronym Snake Case Conversion

**Current Naming:**
- Function: `describe_r_g_b` (from `describeRGB`)
- Atom: `:r_g_b` (from `RGB`)

**Expected Naming:**
- Function: `describe_rgb`
- Atom: `:rgb`

**Root Cause:**
The snake_case converter treats each uppercase letter as a word boundary, converting "RGB" to "r_g_b" instead of keeping it as "rgb".

## Proposed Solution Architecture

### Phase 1: Guard Condition Transformation

**New Transformation Pass: `GuardConditionCollapse`**

1. **Detection Phase:**
   - Identify switch statements with multiple cases having same pattern but different guards
   - Group these cases together

2. **Transformation Phase:**
   - Extract the common pattern once
   - Convert guards to `cond` branches
   - Handle the default case (pattern without guard)

3. **Implementation Location:**
   - Add to `ElixirASTTransformer.hx` as a new transformation pass
   - Run after pattern matching transformation

**Algorithm:**
```haxe
function collapseGuardConditions(caseNode: ElixirAST): ElixirAST {
    // Group cases by pattern (ignoring guards)
    var patternGroups = new Map<Pattern, Array<Case>>();
    
    for (case in cases) {
        var patternKey = normalizePattern(case.pattern);
        if (!patternGroups.exists(patternKey)) {
            patternGroups.set(patternKey, []);
        }
        patternGroups.get(patternKey).push(case);
    }
    
    // Transform groups with multiple guards into cond
    var newCases = [];
    for (pattern => group in patternGroups) {
        if (group.length > 1 && hasGuards(group)) {
            newCases.push(createCondCase(pattern, group));
        } else {
            newCases.push(group[0]);
        }
    }
    
    return ECase(target, newCases);
}
```

### Phase 2: String Interpolation Enhancement

**Enhance Existing `StringInterpolation` Pass:**

1. **Pattern Detection:**
   - Detect: `string <> expr.to_string() <> string`
   - Detect: `string <> Std.string(expr) <> string`
   - Detect: Multiple concatenations in sequence

2. **Transformation:**
   - Build interpolation string with `#{}` placeholders
   - Extract expressions for interpolation
   - Generate `ERaw` node with interpolation syntax

### Phase 3: Acronym-Aware Snake Case Conversion

**Fix `ElixirNaming.toSnakeCase()`:**

1. **Acronym Detection:**
   - Identify sequences of uppercase letters
   - Common acronyms: RGB, HTML, XML, JSON, UUID, etc.

2. **Conversion Rules:**
   - "RGB" → "rgb" (not "r_g_b")
   - "HTMLParser" → "html_parser" (not "h_t_m_l_parser")
   - "parseJSON" → "parse_json" (not "parse_j_s_o_n")

3. **Implementation:**
```haxe
static function toSnakeCase(name: String): String {
    // Handle acronyms first
    name = ~/([A-Z]{2,})([A-Z][a-z]|$)/.map(name, function(r) {
        var acronym = r.matched(1).toLowerCase();
        var next = r.matched(2);
        return acronym + (next.length > 0 ? "_" + next.toLowerCase() : "");
    });
    
    // Then handle regular camelCase
    return ~/([a-z])([A-Z])/.map(name, function(r) {
        return r.matched(1) + "_" + r.matched(2).toLowerCase();
    });
}
```

## Implementation Plan

### Priority 1: Guard Condition Transformation (High Complexity)
- **Effort**: 2-3 days
- **Risk**: High - requires significant AST manipulation
- **Testing**: Create comprehensive test suite for guard patterns

### Priority 2: Acronym Snake Case (Low Complexity)
- **Effort**: 2-3 hours
- **Risk**: Low - localized change to naming utility
- **Testing**: Unit tests for conversion function

### Priority 3: String Interpolation (Medium Complexity)
- **Effort**: 1 day
- **Risk**: Medium - needs to detect various patterns
- **Testing**: Snapshot tests for string operations

## Success Criteria

1. **Guard Conditions:**
   - Generate single case with `cond` for multiple guards
   - No undefined variables in generated code
   - All enum tests pass

2. **String Interpolation:**
   - Concatenation patterns converted to interpolation
   - Maintains correctness of string building
   - Idiomatic Elixir output

3. **Naming:**
   - Acronyms converted correctly
   - Function and pattern names match Elixir conventions
   - Backward compatibility maintained

## Alternative Approaches Considered

### For Guard Conditions:
1. **Generate separate functions** - Rejected: Too complex, non-idiomatic
2. **Nested case statements** - Rejected: Already causing the problem
3. **With statements** - Rejected: Not appropriate for this use case

### For String Operations:
1. **IO lists** - Considered: More efficient but less readable
2. **String.Chars protocol** - Rejected: Overkill for simple cases

## Migration Strategy

1. **Feature Flag Protection:**
   - Add `use_guard_condition_collapse` feature flag
   - Enable incrementally as tests pass

2. **Backward Compatibility:**
   - Old generated code continues to work
   - New code generation behind flag

3. **Testing Strategy:**
   - Run parallel tests with flag on/off
   - Compare outputs for correctness

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Complex AST manipulation breaks other patterns | High | Comprehensive test suite, feature flag |
| Performance regression from cond | Low | Cond is idiomatic, BEAM optimizes |
| Naming changes break existing code | Medium | Provide migration guide, deprecation period |

## Conclusion

These remaining issues represent the final barriers to idiomatic enum compilation. The guard condition transformation is the most complex but also most critical for correctness. The naming and string interpolation fixes will significantly improve code readability and maintainability.

## References

- [Elixir Case/Cond/If](https://elixir-lang.org/getting-started/case-cond-and-if.html)
- [Elixir String Interpolation](https://hexdocs.pm/elixir/String.html#module-interpolation)
- [Elixir Naming Conventions](https://hexdocs.pm/elixir/naming-conventions.html)