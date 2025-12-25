# Elixir Code Injection Guide

## 📝 Code Injection Method

Reflaxe.Elixir provides direct Elixir code injection using:

**`untyped __elixir__()`** - Direct injection for standard library and special cases

> [!IMPORTANT]
> **Prefer `__elixir__()` in framework/stdlib code, not application code.**
>
> `__elixir__()` remains available in user apps as an escape hatch, but relying on it heavily
> makes it harder for compiler transforms to stay structural/idiomatic.
>
> In this repository, shipped examples **opt in** to a stricter policy by defining
> `-D reflaxe_elixir_strict_examples`. This guard is **examples-only**: it fails compilation
> when `examples/<app>/src_haxe/**` uses `untyped __elixir__()` (or introduces new app-local
> extern bridges), so the examples stay “Haxe-first” and keep compiler transforms structural.
>
> Your own applications are not required to enable this flag. `__elixir__()` and typed
> `extern` definitions remain supported in user apps — just use them intentionally and prefer
> promoting reusable Phoenix/Ecto interop into the framework/stdlib layer when it’s generic.
>
> If you need access to a Phoenix/Ecto/Elixir API from app code, add a typed wrapper in `std/`
> (or a compiler-supported annotation module like `@:repo`) so the surface is reusable and documented.

## How to Use `__elixir__()`

### Basic Syntax

```haxe
// Inject simple Elixir expressions
var now = untyped __elixir__("DateTime.utc_now()");
var atom = untyped __elixir__(":ok");
var tuple = untyped __elixir__("{:error, \"reason\"}");
```

### ⚠️ CRITICAL: Correct Placeholder Syntax Required

The `__elixir__()` function requires specific placeholder syntax to work correctly:

```haxe
// ❌ WRONG: $variable syntax causes Haxe string interpolation at compile-time
untyped __elixir__('Phoenix.Controller.json($conn, $data)');  // FAILS!
// This becomes string concatenation: "" + conn + ", " + data + ")"
// Result: Not a constant string, Reflaxe cannot process it

// ✅ CORRECT: {N} placeholder syntax for variable substitution
untyped __elixir__('Phoenix.Controller.json({0}, {1})', conn, data);  // WORKS!
// Variables are passed as parameters and substituted at placeholder positions
```

**WHY THIS MATTERS**: 
- `$variable` triggers Haxe's compile-time string interpolation
- The result is no longer a constant string literal
- Reflaxe's TargetCodeInjection requires the first parameter to be a constant
- `{N}` placeholders preserve the constant string while allowing substitution

### With Parameters

Use `{0}`, `{1}`, etc. as placeholders for Haxe values:

```haxe
// Pass Haxe values to Elixir code
var name = "Alice";
var age = 30;
var result = untyped __elixir__("User.create(%{name: {0}, age: {1}})", name, age);

// Generated Elixir:
// result = User.create(%{name: "Alice", age: 30})
```

### Complex Expressions

```haxe
// Multi-line Elixir code
var result = untyped __elixir__("
    case File.read({0}) do
      {:ok, content} -> content
      {:error, _} -> \"\"
    end
", filename);
```

## 🔍 Code Injection Across Targets

### Reflaxe Targets Pattern
All Reflaxe targets use the same `untyped __target__()` pattern:

| Target | Method | Example |
|--------|--------|---------|
| **Elixir** | `untyped __elixir__()` | `untyped __elixir__('DateTime.now()')` |
| **JavaScript** | `js.Syntax.code()` | `js.Syntax.code("Date.now()")` |
| **C++** | `untyped __cpp__()` | `untyped __cpp__("std::time(0)")` |
| **Go** | `untyped __go__()` | `untyped __go__("fmt.Println({0})", msg)` |

Note: JavaScript has evolved to use `js.Syntax.code()` as a type-safe alternative to `untyped __js__()`.

## 🔄 Why `untyped` is REQUIRED

### The Problem: `__elixir__` Doesn't Exist

```haxe
// ❌ THIS FAILS:
var result = __elixir__("DateTime.now()");
// Error: Unknown identifier: __elixir__
```

**Why it fails:**
1. Haxe's type checker runs BEFORE Reflaxe
2. Haxe looks for a function called `__elixir__`
3. No such function exists in any scope
4. Compilation stops with "Unknown identifier"

### The Solution: Skip Type Checking with `untyped`

```haxe
// ✅ THIS WORKS:
var result = untyped __elixir__("DateTime.now()");
```

**Why it works:**
1. `untyped` tells Haxe: "Don't type-check this expression"
2. Haxe wraps it in a `TUntyped` AST node without validation
3. Reflaxe receives the AST with `__elixir__` intact
4. Reflaxe recognizes the pattern and injects the Elixir code

## Special Case: Abstract Types Require `extern inline`

When using `__elixir__()` in abstract type methods, you MUST use `extern inline`:

```haxe
abstract LiveSocket<T> {
    // ❌ WRONG: Fails with "Unknown identifier: __elixir__"
    public function clearFlash(): LiveSocket<T> {
        return untyped __elixir__('Phoenix.LiveView.clear_flash({0})', this);
    }
    
    // ✅ CORRECT: Works with extern inline
    extern inline public function clearFlash(): LiveSocket<T> {
        return untyped __elixir__('Phoenix.LiveView.clear_flash({0})', this);
    }
}
```

**Why:** Abstract methods are typed when imported, before Reflaxe initialization. `extern inline` delays typing until usage.

## Common Patterns

### 1. Calling Elixir Functions

```haxe
// When extern definitions don't work
public static function now(): Date {
    var timestamp = untyped __elixir__("DateTime.to_unix(DateTime.utc_now(), :millisecond)");
    return Date.fromTime(timestamp);
}
```

### 2. Using Elixir Atoms

```haxe
// Atoms don't exist in Haxe
var status = untyped __elixir__(":active");
var result = untyped __elixir__("{:ok, {0}}", value);
```

### 3. Pattern Matching

```haxe
// Elixir pattern matching
var extracted = untyped __elixir__("
    case {0} do
      {:ok, value} -> value
      _ -> nil
    end
", maybeValue);
```

### 4. Using Elixir-Specific Syntax

```haxe
// Pipe operator
var result = untyped __elixir__("{0} |> Enum.map(&(&1 * 2)) |> Enum.sum()", list);

// With blocks
var filtered = untyped __elixir__("
    Enum.filter({0}, fn x ->
      x > 10 and rem(x, 2) == 0
    end)
", numbers);
```

## When to Use `__elixir__()`

### ✅ GOOD Use Cases

1. **Standard Library Implementation**
   ```haxe
   // Efficient native implementations
   return untyped __elixir__("DateTime.utc_now()");
   ```

2. **Framework Integration**
   ```haxe
   // Direct access to Phoenix/Ecto APIs
   untyped __elixir__("Phoenix.Controller.json({0}, {1})", conn, data);
   ```

3. **Atoms and Tuples**
   ```haxe
   // Elixir-specific data types
   return untyped __elixir__("{:ok, {0}}", result);
   ```

4. **Performance Critical Code**
   ```haxe
   // Avoid abstraction overhead
   untyped __elixir__("NIF.fast_operation({0})", data);
   ```

### ❌ BAD Use Cases

1. **Business Logic**
   ```haxe
   // ❌ WRONG: Business logic should be in Haxe
   untyped __elixir__("
     defmodule BusinessLogic do
       def calculate(x), do: x * 2
     end
   ");
   ```

2. **When Haxe Has Equivalent Features**
   ```haxe
   // ❌ WRONG: Use Haxe's array methods
   var doubled = untyped __elixir__("Enum.map({0}, &(&1 * 2))", arr);
   
   // ✅ CORRECT: Use Haxe
   var doubled = arr.map(x -> x * 2);
   ```

3. **Type Definitions**
   ```haxe
   // ❌ WRONG: Define types in Haxe
   untyped __elixir__("@type user :: %{name: String.t(), age: integer()}");
   
   // ✅ CORRECT: Use Haxe types
   typedef User = {name: String, age: Int};
   ```

## Important Limitations

### 1. No Type Information

```haxe
// The result is untyped
import elixir.types.Term;

var result: Term = untyped __elixir__("DateTime.now()");
// result is an opaque Elixir term - no structural typing until you wrap/decode it

// Cast if you need types
var date: Date = cast untyped __elixir__("DateTime.now()");
```

### 2. No Compile-Time Validation

```haxe
// This will fail at RUNTIME, not compile-time
var bad = untyped __elixir__("This.Module.DoesNot.Exist()");
```

### 3. Breaks Cross-Platform Compatibility

```haxe
// This only works when targeting Elixir
var result = untyped __elixir__("DateTime.now()");

// For cross-platform, use conditional compilation
#if elixir
var result = untyped __elixir__("DateTime.now()");
#else
var result = Date.now();
#end
```

## Best Practices

### 1. Document Why You're Using It

```haxe
import elixir.types.Term;

/**
 * Uses __elixir__ because:
 * - NaiveDateTime extern methods don't resolve properly
 * - Need to generate idiomatic Elixir code
 */
public function toElixirDate(): Term {
    return untyped __elixir__("Date.from_erl!({0})", erlDate);
}
```

### 2. Minimize Usage in Application Code

- **Standard Library**: Use freely for idiomatic output
- **Application Code**: Prefer Haxe or typed externs
- **Business Logic**: Always use pure Haxe

### 3. Keep Injections Small

```haxe
// ✅ GOOD: Small, focused injection
var atom = untyped __elixir__(":ok");

// ❌ BAD: Large blocks of Elixir code
var result = untyped __elixir__("
    defmodule Helper do
      def process(data) do
        # 50 lines of Elixir...
      end
    end
");
```

### 4. Use Parameters Instead of String Concatenation

```haxe
// ❌ BAD: String concatenation
var code = "DateTime.add(" + date + ", " + days + ", :day)";
var result = untyped __elixir__(code);

// ✅ GOOD: Use parameters
var result = untyped __elixir__("DateTime.add({0}, {1}, :day)", date, days);
```

## Common Errors and Solutions

### Error: "Unknown identifier: __elixir__"
**Solution**: Add `untyped` before `__elixir__()`

### Error: "Invalid Elixir syntax"
**Solution**: Test your Elixir code in IEx first

### Error: "Parameter {0} not replaced"
**Solution**: Ensure you're passing the right number of arguments

### Error: "Type not found" after injection
**Solution**: Use `cast` to restore type information

## The Compilation Process

```
1. Haxe Source:
   untyped __elixir__("DateTime.now()")
   
2. Haxe AST (after parsing):
   TUntyped(TCall(TIdent("__elixir__"), [TConst("DateTime.now()")]))
   
3. Reflaxe Processing:
   - Detects __elixir__ pattern
   - Extracts "DateTime.now()"
   - Replaces placeholders with parameters
   
4. Generated Elixir:
   DateTime.now()
```

## Summary

- **`__elixir__()`** is a compile-time marker, not a real function
- **`untyped`** is REQUIRED because `__elixir__` doesn't exist in Haxe's scope
- **Use `{N}` placeholders** for variable substitution, not `$variable`
- **Abstract types** need `extern inline` for proper timing
- **Use it** for standard library and framework integration
- **Avoid it** for business logic that should be in Haxe
- **Document** why you're using it
- **Keep it small** and focused

Remember: The goal is idiomatic Elixir output that leverages the platform's strengths!
