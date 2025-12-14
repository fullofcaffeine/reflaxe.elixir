# Dead Code Elimination and Abstract Type Operators

## Discovery: DCE Solves Unused Function Warnings (September 2025)

### The Problem

When compiling abstract types with operator overloads (like `Date`), ALL operator methods were being generated as helper functions in the `_Impl_` module, causing Elixir compiler warnings:

```
warning: function neq/2 is unused
warning: function lte/2 is unused  
warning: function lt/2 is unused
warning: function gte/2 is unused
```

### Root Cause Analysis

Abstract types with `@:op` metadata compile their operators to static helper functions:

```haxe
// In Date.cross.hx
abstract Date(DateTime) {
    @:op(A > B) static inline function gt(a: Date, b: Date): Bool
    @:op(A < B) static inline function lt(a: Date, b: Date): Bool
    @:op(A >= B) static inline function gte(a: Date, b: Date): Bool
    @:op(A <= B) static inline function lte(a: Date, b: Date): Bool
    @:op(A == B) static inline function eq(a: Date, b: Date): Bool
    @:op(A != B) static inline function neq(a: Date, b: Date): Bool
}
```

Without DCE, these ALL compile to:

```elixir
defmodule Date_Impl_ do
  defp gt(a, b), do: DateTime.compare(a, b) == :gt
  defp lt(a, b), do: DateTime.compare(a, b) == :lt
  defp gte(a, b), do: # ... etc
  defp lte(a, b), do: # ... etc
  defp eq(a, b), do: # ... etc
  defp neq(a, b), do: # ... etc
end
```

Even if the code only uses `>` operator, ALL six functions are generated.

### The Solution: Enable DCE

Dead Code Elimination (`-dce full`) analyzes usage and removes unreachable code BEFORE Reflaxe transpilation:

```hxml
# In build-server.hxml
-dce full  # Remove all unreachable code
```

### DCE Options Explained

| Option | Effect | Use Case |
|--------|--------|----------|
| `-dce no` | Disable DCE entirely | Development/debugging only |
| `-dce std` | Remove only unused std lib classes | Conservative optimization |
| `-dce full` | Remove ALL unreachable code | **RECOMMENDED for production** |

### Impact of DCE on Abstract Types

#### Before (DCE disabled or `-dce no`)
```elixir
# Date_Impl_.ex - 140 lines
defmodule Date_Impl_ do
  def from_time(t), do: # ...
  def from_string(s), do: # ...
  defp gt(a, b), do: # ... ❌ Unused
  defp lt(a, b), do: # ... ❌ Unused  
  defp gte(a, b), do: # ... ❌ Unused
  defp lte(a, b), do: # ... ❌ Unused
  defp eq(a, b), do: # ... ❌ Unused
  defp neq(a, b), do: # ... ❌ Unused
end
```

#### After (DCE enabled with `-dce full`)
```elixir
# Date_Impl_.ex - 2 lines only!
defmodule Date_Impl_ do
end
```

Only actually used methods are kept. If code uses `date1 > date2`, only `gt/2` would be generated.

### Why This Matters

1. **Clean Compilation**: No unused function warnings in Elixir
2. **Smaller Output**: ~98% reduction in generated code for unused abstracts
3. **Better Performance**: Less code to compile and load
4. **Standard Practice**: DCE is standard for production Haxe builds

### Reflaxe.Elixir and DCE

**Important**: Reflaxe.Elixir correctly respects Haxe's DCE:
- DCE runs BEFORE Reflaxe transpilation
- Eliminated code never reaches the Elixir compiler
- No special handling needed in Reflaxe.Elixir

### Best Practices

1. **Always use `-dce full` for production builds**
2. **Use `-dce no` only when debugging compilation issues**
3. **Abstract types with operators especially benefit from DCE**
4. **Test with DCE enabled to catch actual usage patterns**

### Common Issues Without DCE

- Unused function warnings for abstract operator methods
- Larger generated code size
- Helper functions for Array operations that aren't used
- StringBuf/StringTools helpers when only subset is needed
- Map implementation functions for unused map types

### Verification

To verify DCE is working:

```bash
# Compile with DCE
npx haxe build-server.hxml  # with -dce full

# Check generated module size
wc -l lib/_date/date_impl_.ex  # Should be minimal

# Verify no warnings
mix compile --force 2>&1 | grep "unused"  # Should be empty
```

### Historical Context

This issue was discovered when investigating unused function warnings in the todo-app. The initial assumption was that the compiler needed to track usage and conditionally generate operator functions. However, the solution was much simpler - Haxe already provides DCE for exactly this purpose. The todo-app simply had DCE disabled, causing all abstract operators to be generated regardless of usage.

### Related Documentation

- [Haxe Manual: Dead Code Elimination](https://haxe.org/manual/cr-dce.html)
- [Abstract Types Documentation](https://haxe.org/manual/types-abstract.html)
- [Operator Overloading in Abstracts](https://haxe.org/manual/types-abstract-operator-overloading.html)