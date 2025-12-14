# Compiler Resolution Issues

**Known issues with method resolution and code generation in Reflaxe.Elixir**

## Result.filter() vs Enum.filter() Compilation Issue

### Problem Description

When using `ResultTools.filter()` extension method in Haxe code, the compiler sometimes generates incorrect Elixir code that calls `Enum.filter(ResultTools, ...)` instead of `ResultTools.filter(...)`.

### Example Manifestation

**Haxe Code:**
```haxe
import haxe.functional.Result;
import haxe.functional.ResultTools;
using haxe.functional.ResultTools;

class Main {
    static function main() {
        var result = Ok(42);
        var filtered = result.filter(x -> x > 0, "Value not positive");
    }
}
```

**Expected Elixir Output:**
```elixir
filtered = ResultTools.filter(result, fn x -> x > 0 end, "Value not positive")
```

**Actual Generated Output:**
```elixir
filtered = Enum.filter(ResultTools, fn x -> x > 0 end, "Value not positive")
```

### Root Cause Analysis

The issue appears to be in the method resolution phase of the compiler where:

1. **Static Extension Resolution**: The compiler correctly identifies that `filter()` is a static extension method
2. **Method Call Generation**: During code generation, the compiler incorrectly resolves the call to `Enum.filter()` instead of `ResultTools.filter()`
3. **Parameter Order**: The resolution places `ResultTools` as the first parameter to `Enum.filter()` instead of treating it as the module qualifier

### Impact Assessment

**Severity**: High - Generates invalid Elixir code that won't compile
**Frequency**: Occurs specifically with static extension methods in functional chains
**Workaround**: None available - requires compiler fix

### Evidence from Test Suite

From `test/tests/domain_abstractions/out/Main.ex`, line 355:
```elixir
user_id_chain = ResultTools.unwrapOr(Enum.filter(ResultTools, ResultTools.map(UserId_Impl_.parse("TestUser123"), fn user_id -> UserId_Impl_.normalize(user_id) end)), ResultTools.unwrap(UserId_Impl_.parse("defaultuser")))
```

This shows the issue in a real compilation scenario where:
- `ResultTools.map()` generates correctly as `ResultTools.map(...)`
- `ResultTools.filter()` generates incorrectly as `Enum.filter(ResultTools, ...)`

### Technical Context

**File**: `test/tests/domain_abstractions/Main.hx`
**Haxe Code Causing Issue**:
```haxe
var userId_chain = UserId.parse("TestUser123")
    .map(userId -> userId.normalize()) 
    .filter(userId -> userId.startsWith("test"), "UserId does not start with 'test'")
    .unwrapOr(UserId.parse("defaultuser").unwrap());
```

**Current Status: FIXED ✅**: 
- ✅ **Bug fixed** - compiler now correctly generates `ResultTools.filter(...)` 
- ✅ **Test passes** - domain_abstractions test now validates correct behavior
- ✅ **Issue resolved** - proper static extension method resolution working

**Evidence from updated output** (`test/tests/domain_abstractions/intended/Main.ex:355`):
```elixir
user_id_chain = ResultTools.unwrapOr(ResultTools.filter(ResultTools.map(...), ...), ...)
```

This is **correct Elixir code** that properly calls the ResultTools.filter/3 function.

### Fix Details
**Date Fixed**: 2025-01-16
**Solution**: Added "filter" to the `isResultMethod()` function in `ElixirCompiler.hx` (line 3942)
**Changed**: 
```haxe
case "map", "flatMap", "bind", "fold", "isOk", "isError", // Missing "filter"
```
To:
```haxe
case "map", "flatMap", "bind", "fold", "filter", "isOk", "isError", // Added "filter"
```

**Impact**: This simple one-word addition fixed the static extension method resolution for Result.filter() calls.

### Root Cause
The issue was in the `isResultMethod()` function in `ElixirCompiler.hx` which defines which methods are recognized as Result static extension methods. The "filter" method was missing from this list, causing it to fall through to array method handling and generate incorrect `Enum.filter()` calls.

### Lesson Learned
When adding new static extension methods to types like Result or Option, always remember to:
1. Add the method implementation to the Tools class (e.g., ResultTools.hx)
2. Add the method name to the corresponding `isResultMethod()` or `isOptionMethod()` function in ElixirCompiler.hx
3. Test that the method call compiles correctly to the expected static extension syntax

### Priority

**RESOLVED** - Issue was high priority and has been successfully fixed with minimal code change.

## Other Known Issues

*Add other compiler resolution issues here as they are discovered*

---

**Last Updated**: 2025-01-16
**Status**: FIXED ✅ - Issue resolved, correct code generation working
**Tests Affected**: domain_abstractions (test passes and generates correct code)