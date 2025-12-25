# `__elixir__()` Injection System Regression - Root Cause Analysis

**Status**: RESOLVED (September 2025)
**Breaking Commit**: 43615271 (Phoenix.Presence fix, September 2025)
**Fix Commit**: [This commit] (January 2025)

## Executive Summary

The `__elixir__()` code injection system stopped working in commit 43615271, causing the compiler to generate **literal function calls** `__elixir__.("...")` instead of **inline Elixir code** `DateTime.utc_now()`. This affected both user code and standard library implementations.

## The Root Cause

### 1. **Architectural Change in Commit 43615271**

Commit 43615271 added Phoenix.Presence handling to ElixirASTBuilder, which introduced a critical processing order issue:

```haxe
// In ElixirASTBuilder.buildFromTypedExpr()
case TCall(e, el):
    // NEW CODE: Phoenix.Presence handling was added HERE
    // This processes TCall expressions BEFORE injection detection

    // THEN delegates to CallExprBuilder
    CallExprBuilder.buildCall(e, el, currentContext);
```

**The Problem**: The new Phoenix.Presence code path processed TCall expressions **before** they could be checked for `__elixir__()` injection patterns. Since the code was modularized and delegated to CallExprBuilder, but injection detection wasn't added at the start of CallExprBuilder, the injection system was effectively bypassed.

### 2. **The Missing Link: Injection Detection in CallExprBuilder**

When ElixirASTBuilder delegated TCall handling to CallExprBuilder, the injection detection logic needed to be at the **very start** of `CallExprBuilder.buildCall()`:

```haxe
// CallExprBuilder.buildCall() - CRITICAL FIX
public static function buildCall(e: TypedExpr, args: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
    // MUST CHECK FOR INJECTION **FIRST**, before ANY other processing
    if (context.compiler.options.targetCodeInjectionName != null && e != null && args.length > 0) {
        // Check all possible AST patterns for __elixir__
        var isInjectionCall = switch(e.expr) {
            case TIdent(id): id == context.compiler.options.targetCodeInjectionName;
            case TField(_, fa): /* check FieldAccess patterns */;
            case TLocal(v): v.name == context.compiler.options.targetCodeInjectionName;
            case _: false;
        };

        if (isInjectionCall) {
            // Process parameter substitution and return ERaw(finalCode) immediately
            return ERaw(finalCode);
        }
    }

    // Continue with normal call processing (enum constructors, etc.)
}
```

### 3. **Why Reflaxe's Built-in Detection Failed**

Reflaxe provides `TargetCodeInjection.checkTargetCodeInjectionGeneric()`, but it has a critical limitation:

```haxe
// In Reflaxe's TargetCodeInjection.hx (lines 88-105)
final callIdent = switch(expr.expr) {
    case TCall(e, el): {
        switch(e.expr) {
            case TIdent(id): {  // ← ONLY DETECTS TIdent!
                arguments = el;
                id;
            }
            case _: null;  // Returns null for TField, TLocal, etc.
        }
    }
    case _: null;
}
```

**The Problem**: Reflaxe ONLY detects `TIdent("__elixir__")` patterns, but Haxe's typing can produce other patterns:
- `TField(_, FDynamic("__elixir__"))` - When accessed as a field
- `TLocal(v)` where `v.name == "__elixir__"` - When assigned to a variable
- `TField(_, FInstance/FStatic/FAnon)` - Various field access patterns

## The Symptoms

### Before the Fix:
```elixir
# Generated code (WRONG)
defmodule Main do
  defp main() do
    _current_time = __elixir__.("DateTime.utc_now()")  # ❌ Literal call
    _greeting = __elixir__.("\"Hello, {0}!\"", name)   # ❌ Literal call
    _result = __elixir__.("{0} + {1}", x, y)           # ❌ Literal call
  end
end
```

**Error at runtime**:
```
** (UndefinedFunctionError) function __elixir__/1 is undefined
```

### After the Fix:
```elixir
# Generated code (CORRECT)
defmodule Main do
  defp main() do
    _current_time = DateTime.utc_now()     # ✅ Inline Elixir
    _greeting = "Hello, #{name}!"          # ✅ With substitution
    _result = x + y                         # ✅ Inline expression
  end
end
```

## The Fix

### Implementation Location
`src/reflaxe/elixir/ast/builders/CallExprBuilder.hx` (lines 52-112)

### Key Changes:

1. **Injection Detection at Entry Point**:
   - Added comprehensive pattern matching for `__elixir__` detection
   - Handles TIdent, TField (all FieldAccess variants), and TLocal
   - Placed at the **very start** of `buildCall()` method

2. **Parameter Substitution Processing**:
   ```haxe
   // Process {0}, {1}, {2} placeholders
   finalCode = ~/{(\d+)}/g.map(finalCode, function(ereg) {
       final num = Std.parseInt(ereg.matched(1));
       if (num != null && num + 1 < args.length) {
           var argAst = buildExpression(args[num + 1]);
           return reflaxe.elixir.ast.ElixirASTPrinter.printAST(argAst);
       }
       return ereg.matched(0);
   });
   ```

3. **Immediate Return**:
   - Returns `ERaw(finalCode)` directly
   - Bypasses all other TCall processing (enum constructors, method calls, etc.)
   - Ensures injection happens **before** any other transformation

## Why This Architectural Approach Works

### The Pipeline Order:
```
TypedExpr (TCall)
  → ElixirASTBuilder.buildFromTypedExpr()
    → CallExprBuilder.buildCall()
      → [CHECK INJECTION FIRST] ← THE FIX
      → [Then check enum constructors]
      → [Then check Phoenix.Presence]
      → [Then other call types]
```

### Key Principles:
1. **First Detection Wins**: Injection must be checked before any other pattern
2. **Comprehensive Pattern Matching**: Handle all AST variants Haxe might generate
3. **Immediate Return**: Don't continue processing after detecting injection
4. **No String Manipulation**: Work with AST nodes, not strings

## Historical Context

### When It Worked (Commit b2d48bc5):
- Injection detection was in the main compiler flow
- TCall expressions were checked before delegation
- Generated correct inline code:
  ```elixir
  case DateTime.from_iso8601(s) do  # ✅ Inline
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
  end
  ```

### When It Broke (Commit 43615271):
- Phoenix.Presence code added to ElixirASTBuilder
- TCall processing happened before injection detection
- Delegation to CallExprBuilder without injection check at entry
- Result: `__elixir__.("...")` literal calls

### The Researcher Agent Investigation:
The researcher agent (using git bisect and code analysis) identified:
- **Breaking Commit**: 43615271
- **Root Cause**: Call processing order changed
- **Recommended Fix**: "Move injection detection to CallExprBuilder.buildCall() BEFORE any other processing"

## Testing

### Regression Test Created:
`/test/snapshot/regression/ElixirInjectionExpansion/`

**Test Cases**:
1. Simple __elixir__ call (no parameters)
2. Parameter substitution with {0}
3. Multiple parameters {0}, {1}
4. Complex multiline Elixir expressions

### Validation Commands:
```bash
# Compile the test
npx haxe test/snapshot/regression/ElixirInjectionExpansion/compile.hxml

# Check output
cat test/snapshot/regression/ElixirInjectionExpansion/out/main.ex

# Expected: Inline Elixir code, NOT __elixir__.() calls
```

## Lessons Learned

### 1. **Pipeline Architecture is Critical**
- Changes to call processing order can break injection systems
- Detection logic must be at the **entry point** of processing, not mid-pipeline

### 2. **Reflaxe Limitations**
- Built-in `checkTargetCodeInjectionGeneric` only handles TIdent patterns
- Must implement comprehensive pattern matching for production use

### 3. **Git Bisect is Invaluable**
- The researcher agent used git bisect to find the exact breaking commit
- Saved hours of manual debugging by pinpointing the architectural change

### 4. **Test-Driven Fixes**
- Created regression test BEFORE implementing the fix
- Verified the fix works with all injection patterns
- Ensures the bug never returns

## Related Documentation

- [docs/03-compiler-development/TWO_ELIXIR_INJECTION_SYSTEMS.md](TWO_ELIXIR_INJECTION_SYSTEMS.md) - Dual injection system architecture
- [docs/03-compiler-development/COMPREHENSIVE_DOCUMENTATION_STANDARD.md](COMPREHENSIVE_DOCUMENTATION_STANDARD.md) - Documentation standards
- [Reflaxe TargetCodeInjection.hx](https://github.com/SomeRanDev/reflaxe/blob/main/src/reflaxe/compiler/TargetCodeInjection.hx) - Reflaxe's injection implementation

## Conclusion

The `__elixir__()` injection system regression was caused by an architectural change in how TCall expressions were processed. The fix ensures injection detection happens at the **very start** of call processing, before any other transformations. This architectural principle prevents similar issues in the future: **always check for injection patterns first, then process normally**.
