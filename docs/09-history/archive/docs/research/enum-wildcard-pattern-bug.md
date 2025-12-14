# Enum Wildcard Pattern Bug Research

## Problem Statement
When a TSwitch expression has a single case with a wildcard default (`_`), the compiler generates an if-else statement with enum index checking (`status == 3`) instead of a proper case statement with pattern matching.

## Example of the Bug

### Haxe Input
```haxe
static function getRedirectInfo(status: HttpStatus): String {
    return switch(status) {
        case Redirect(url, permanent):
            'URL: ${url}, Permanent: ${permanent}';
        case _:
            "Not a redirect";
    };
}
```

### Current (Incorrect) Output
```elixir
defp get_redirect_info(status) do
  if (status == 3) do  # Wrong! Checking enum index
    url = nil
    permanent = nil
    "URL: #{url}, Permanent: #{Std.string(permanent)}"
  else
    "Not a redirect"
  end
end
```

### Expected (Idiomatic) Output
```elixir
defp get_redirect_info(status) do
  case status do
    {:redirect, url, permanent} ->
      "URL: #{url}, Permanent: #{permanent}"
    _ ->
      "Not a redirect"
  end
end
```

## Root Cause Analysis

### Location in Code
The issue is in `ElixirASTBuilder.hx` around line 4588 in the TSwitch handling. The compiler has complex logic for:

1. **Infrastructure Variable Detection** (lines 4762-4791)
   - Detects when Haxe has desugared switch expressions to use `_g` variables
   - Falls back to using `nil` for infrastructure variables

2. **Enum Type Detection** (lines 4695-4735)
   - Tries to extract enum type from various wrapper expressions
   - Handles TEnumIndex optimization that Haxe applies

3. **Case Statement Building** (lines 4889+)
   - Complex logic for building clauses
   - Has special handling for "topic_to_string-style" temp variables

### The Decision Point
The bug occurs when the compiler decides to generate an if-else instead of a case statement. This happens when:

1. There's only one explicit case plus a default
2. The compiler thinks it can optimize to a simpler if-else
3. But it incorrectly uses enum index checking (`status == 3`) instead of pattern matching

## Why This is Wrong

1. **Non-idiomatic**: Elixir developers expect pattern matching, not index checking
2. **Fragile**: Enum index checking breaks if enum constructor order changes
3. **Incorrect Logic**: The generated code sets `url = nil` and `permanent = nil` inside the if branch, which is wrong

## Proposed Solution

### Approach 1: Always Use Case for Enum Switches
Never optimize enum switches to if-else. Always generate case statements when dealing with enums, regardless of the number of cases.

### Approach 2: Fix If-Else Generation
If keeping the if-else optimization, fix it to:
1. Use proper pattern matching in the condition
2. Extract variables correctly
3. Generate idiomatic Elixir

### Recommended: Approach 1
Always use case statements for enum pattern matching because:
- More idiomatic
- Clearer intent
- Easier to maintain and extend
- Avoids the complexity of determining when optimization is safe

## Code Path to Fix

1. In `ElixirASTBuilder.hx` TSwitch handler:
   - Remove or fix the optimization that converts single-case switches to if-else
   - Ensure all enum switches generate case statements
   - Properly handle wildcard patterns

2. Key areas to modify:
   - Line ~4588: TSwitch case handler
   - The clause building logic (around line 4889+)
   - The decision logic for if-else vs case generation

## Test Coverage

The test case in `test/snapshot/regression/EnumUnderscorePattern/` covers this scenario and will validate the fix.

## Related Issues

- Infrastructure variable handling (`_g` variables from Haxe desugaring)
- Enum parameter extraction and naming
- Pattern matching generation in general