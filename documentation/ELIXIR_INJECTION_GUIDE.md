# Elixir Code Injection - Complete Guide ⚡ UPDATED

## Overview: Two Injection Approaches

Reflaxe.Elixir provides **two ways** to inject raw Elixir code:

1. **✅ RECOMMENDED: `elixir.Syntax.code()`** - Type-safe, modern approach (NEW)
2. **🔄 LEGACY: `untyped __elixir__()`** - Backward compatibility only

**Migration Status**: As of August 2024, the project is migrating from legacy injection to the new type-safe API.

## ✅ NEW: Type-Safe elixir.Syntax API

### Basic Usage
```haxe
import elixir.Syntax;

// Basic injection
var result = Syntax.code("DateTime.utc_now()");

// Parameterized injection  
var formatted = Syntax.code("String.slice({0}, {1}, {2})", str, start, length);

// Specialized methods
var atom = Syntax.atom("ok");
var tuple = Syntax.tuple("ok", result);
```

### Why elixir.Syntax is Better

✅ **Type Safety**: No `untyped` keyword needed  
✅ **IDE Support**: IntelliSense and autocomplete  
✅ **Compile-Time Validation**: Catches errors early  
✅ **Modern Pattern**: Follows js.Syntax from Haxe 4.1+  
✅ **Specialized Methods**: Purpose-built functions for common patterns  
✅ **Future-Proof**: Primary API going forward

## Code Injection Across Targets

### Reflaxe Targets (Consistent Pattern)
All Reflaxe targets use the same `untyped __target__()` pattern:

| Target | Modern Syntax | Legacy Syntax | Example |
|--------|---------------|---------------|---------|
| **Elixir** | `elixir.Syntax.code()` ✅ | `untyped __elixir__()` | `Syntax.code("DateTime.now()")` |
| **JavaScript** | `js.Syntax.code()` ✅ | `untyped __js__()` | `js.Syntax.code("console.log({0})", msg)` |
| **C++** | Not Available | `untyped __cpp__()` | `untyped __cpp__("std::cout << {0}", msg)` |
| **Go** | Not Available | `untyped __go__()` | `untyped __go__("fmt.Println({0})", msg)` |
| **GDScript** | Not Available | `untyped __gdscript__()` | `untyped __gdscript__("print({0})", msg)` |

### Modern Haxe JavaScript (4.1+)
JavaScript evolved to a cleaner approach:

```haxe
// ❌ OLD (deprecated, shows warnings):
untyped __js__("console.log(123)");

// ✅ NEW (modern, type-safe):
js.Syntax.code("console.log({0})", value);
```

**Why js.Syntax is better:**
- No `untyped` needed (it's a real extern class)
- Type-safe and well-documented
- Provides specialized methods (`instanceof`, `typeof`, etc.)
- No deprecation warnings

### Elixir's Modern Evolution ⚡ NEW

**Reflaxe.Elixir now leads the way** by implementing the first modern Syntax API for Reflaxe targets!

**Why Elixir Got Modern Syntax First:**
1. **Type Safety Priority**: Elixir development emphasizes compile-time guarantees
2. **Complex Use Cases**: Phoenix/Ecto integration needs sophisticated injection patterns
3. **Developer Experience**: Standard library needs testable, IDE-friendly APIs
4. **js.Syntax Success**: Proven pattern from Haxe's JavaScript target

**Other targets remain legacy** because:
- Simpler injection needs don't justify the implementation effort
- Community hasn't requested type-safe alternatives yet
- Each target would need custom compiler integration

### ✅ IMPLEMENTED: elixir.Syntax API

The modern type-safe injection API is now available:

```haxe
// ✅ REAL API (fully implemented)
import elixir.Syntax;

class Date {
    public function new(year: Int, month: Int, day: Int) {
        // Type-safe injection with parameter interpolation
        var naiveDateTime = Syntax.code("NaiveDateTime.new!({0}, {1}, {2})", year, month, day);
        this = Syntax.code("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", naiveDateTime);
    }
    
    public static function now(): Date {
        // Simple injection without parameters
        var timestampMs = Syntax.code("DateTime.to_unix(DateTime.utc_now(), :millisecond)");
        return fromTime(timestampMs);
    }
}
```

### Complete API Reference

```haxe
import elixir.Syntax;

// Basic code injection
var result = Syntax.code("DateTime.utc_now()");

// Parameterized injection
var sliced = Syntax.code("String.slice({0}, {1}, {2})", str, start, length);

// Specialized helper methods
var atom = Syntax.atom("ok");                           // → :ok
var tuple = Syntax.tuple("ok", result);                 // → {:ok, result}
var keyword = Syntax.keyword(["name", "John"]);         // → [name: "John"]
var map = Syntax.map(["key", "value"]);                 // → %{"key" => "value"}

// Pattern matching
var matched = Syntax.match(value, "{:ok, result} -> result\n{:error, _} -> nil");

// Pipeline operations
var piped = Syntax.pipe(data, "Enum.map(&transform/1)", "Enum.filter(&valid?/1)");
```

### Migration Examples

```haxe
// ❌ OLD: Legacy approach
var result = untyped __elixir__("DateTime.now()");

// ✅ NEW: Type-safe approach  
var result = Syntax.code("DateTime.now()");

// ❌ OLD: Complex concatenation
var complex = untyped __elixir__("String.slice(" + str + ", " + start + ", " + length + ")");

// ✅ NEW: Clean parameterization
var complex = Syntax.code("String.slice({0}, {1}, {2})", str, start, length);
```

## 🔧 How elixir.Syntax Works

### Compilation Context Requirements

The elixir.Syntax API uses **conditional compilation** to ensure it's only available in appropriate contexts:

```haxe
#if (elixir || reflaxe_runtime)
class Syntax {
    // Only available when:
    // 1. Compiling to Elixir target (elixir flag)
    // 2. Testing with reflaxe_runtime flag
}
#end
```

### The Three Execution Contexts

1. **Macro-Time**: Compiler processes elixir.Syntax calls → generates raw Elixir code
2. **Test-Time**: With `-D reflaxe_runtime`, methods are available for testing
3. **Runtime**: In BEAM VM, no trace of elixir.Syntax exists (replaced with generated code)

**See**: [`documentation/REFLAXE_RUNTIME_EXPLAINED.md`](REFLAXE_RUNTIME_EXPLAINED.md) - Complete explanation

### Compiler Integration

```haxe
// In ElixirCompiler.hx
if (isElixirSyntaxCall(obj, fieldName)) {
    return compileElixirSyntaxCall(fieldName, el);
}
```

The compiler detects `elixir.Syntax` calls and transforms them to `__elixir__` injection at macro-time.

## 🔄 LEGACY: Why `untyped` is REQUIRED (Backward Compatibility)

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

## How to Use `__elixir__()`

### Basic Syntax

```haxe
// Inject simple Elixir expressions
var now = untyped __elixir__("DateTime.utc_now()");
var atom = untyped __elixir__(":ok");
var tuple = untyped __elixir__("{:error, \"reason\"}");
```

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

1. **Idiomatic Code Generation**
   ```haxe
   // Generate idiomatic Elixir DateTime usage
   return untyped __elixir__("DateTime.utc_now()");
   ```

2. **Platform-Specific Features**
   ```haxe
   // Use Elixir's pattern matching
   untyped __elixir__("case {0} do ... end", value);
   ```

3. **When Externs Fail**
   ```haxe
   // If extern method resolution is broken
   untyped __elixir__("NaiveDateTime.new!({0}, {1}, {2})", year, month, day);
   ```

4. **Atoms and Tuples**
   ```haxe
   // Elixir-specific data types
   return untyped __elixir__("{:ok, {0}}", result);
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
var result = untyped __elixir__("DateTime.now()");
// result has type 'Unknown' - no IntelliSense, no type checking

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
/**
 * Uses __elixir__ because:
 * - NaiveDateTime extern methods don't resolve properly
 * - Need to generate idiomatic Elixir code
 */
public function toElixirDate(): Dynamic {
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
- **Use it** to generate idiomatic Elixir code in standard library
- **Avoid it** for business logic that should be in Haxe
- **Document** why you're using it
- **Keep it small** and focused

Remember: The goal is idiomatic Elixir output that leverages the platform's strengths!