# Enum Constructor Patterns in Haxe→Elixir Compilation

## Overview

This document explains the critical distinction between enum constructors and function calls in Haxe→Elixir compilation, which is essential for understanding how Option and other algebraic data types work.

## The Key Distinction

### Enum Constructors Are NOT Function Calls

**Important**: When you write `Some("Hello")` or `None` in Haxe, these are **enum constructor expressions**, not function calls to the generated module functions.

```haxe
// This is an enum constructor expression (TCall/TField)
var some = Some("Hello");  // TCall - constructor with arguments
var none = None;           // TField - constructor without arguments
```

### How They Compile

#### 1. TCall Pattern (Constructor with Arguments)
```haxe
Some("Hello")  // Haxe enum constructor
```
↓ **Compiles directly to:**
```elixir
{:ok, "Hello"}  # Idiomatic Elixir tuple
```

#### 2. TField Pattern (Constructor without Arguments)  
```haxe
None  // Haxe enum constructor
```
↓ **Compiles directly to:**
```elixir
:error  # Idiomatic Elixir atom
```

### Generated Module Functions Are Mostly Unused

The Option module generates these functions:
```elixir
defmodule Option do
  def some(arg0), do: {:ok, arg0}
  def none(), do: :error
end
```

**But**: These functions are rarely called in generated code because enum constructors compile directly to their patterns.

## Why This Matters

### 1. Performance
Direct compilation to patterns is more efficient than function calls:
```elixir
# Direct pattern (what we generate)
{:ok, "Hello"}

# Function call (unnecessary overhead)
Option.some("Hello")
```

### 2. Idiomatic Elixir
The direct patterns follow Elixir conventions:
```elixir
# Idiomatic Elixir
case result do
  {:ok, value} -> value
  :error -> "default"
end
```

### 3. Type Safety
Pattern matching works naturally with the compiled patterns:
```elixir
# Pattern matching expects tuples/atoms, not function calls
case some_value do
  {:ok, data} -> process(data)  # ✅ Works with {:ok, "Hello"}
  :error -> handle_error()      # ✅ Works with :error
end
```

## Implementation Details

### AlgebraicDataTypeCompiler
Handles the mapping from Haxe constructors to Elixir patterns:
```haxe
// Configuration for Option<T>
optionConstructors.set("some", {
    elixirPattern: "{:ok, %s}",  // %s gets replaced with arguments
    arity: 1,
    isAtom: false
});
optionConstructors.set("none", {
    elixirPattern: ":error",     // No substitution needed
    arity: 0,
    isAtom: true
});
```

### Expression Compilation
- **TCall**: `compileADTPattern()` handles `Some(value)`
- **TField**: `compileADTFieldAccess()` handles `None`

Both compile directly to the configured patterns without going through module functions.

## Standard Library vs User-Defined Enums

### Standard Library ADT Types (Always Idiomatic)

Standard library algebraic data types **always** generate idiomatic Elixir patterns regardless of annotation:

```haxe
// Standard library types - ALWAYS idiomatic
import haxe.ds.Option;
import haxe.functional.Result;

var some = Some("Hello");  // → {:ok, "Hello"}
var none = None;           // → :error
var ok = Ok("success");    // → {:ok, "success"}  
var error = Error("fail"); // → {:error, "fail"}
```

**Standard Library Types:**
- `haxe.ds.Option<T>` → Always generates `{:ok, value}` / `:error`
- `haxe.functional.Result<T,E>` → Always generates `{:ok, value}` / `{:error, reason}`

### User-Defined Enums (Explicit Opt-In)

User-defined enums compile to **literal patterns by default**, but can opt into idiomatic patterns with the `@:elixirIdiomatic` annotation:

#### Without @:elixirIdiomatic (Default - Literal Patterns)
```haxe
enum UserOption<T> {
    Some(value: T);
    None;
}

var some = Some("World");  // → {:some, "World"}  
var none = None;           // → :none
```

**Generated Elixir:**
```elixir
@type t() :: {:some, term()} | :none
def some(arg0), do: {:some, arg0}
def none(), do: :none
```

#### With @:elixirIdiomatic (Opt-In - Idiomatic Patterns)
```haxe
@:elixirIdiomatic
enum UserOption<T> {
    Some(value: T);
    None;
}

var some = Some("World");  // → {:ok, "World"}  
var none = None;           // → :error
```

**Generated Elixir:**
```elixir
@type t() :: {:ok, term()} | :error
def some(arg0), do: {:ok, arg0}
def none(), do: :error
```

### Detection Logic (No More "Option-Like" Detection)

The new detection logic is **explicit and predictable**:

1. **Standard Library ADTs**: Detected by module path (`haxe.ds.Option`, `haxe.functional.Result`)
   - Always generate idiomatic patterns
   - No annotation required

2. **User-Defined Enums**: Detected by presence of `@:elixirIdiomatic` annotation
   - Default: Literal patterns (`{:some, value}` / `:none`)
   - With annotation: Idiomatic patterns (`{:ok, value}` / `:error`)

3. **No Magic Name Detection**: Enum names like "Option" or "Result" don't automatically trigger special behavior

### Why This Design?

**Predictable Behavior:**
- No surprises based on enum names
- Clear opt-in mechanism via annotation
- Standard library types always work as expected

**Flexibility:**
- Users can choose literal patterns when appropriate
- Can opt into idiomatic patterns when integrating with Elixir libraries
- No forced conventions for user code

**Examples:**

```haxe
// These generate DIFFERENT patterns:

// Standard library - always idiomatic
import haxe.ds.Option;
var stdOpt = Some("test");     // → {:ok, "test"}

// User enum without annotation - literal  
enum MyOption<T> { Some(v:T); None; }
var myOpt = Some("test");      // → {:some, "test"}

// User enum with annotation - idiomatic
@:elixirIdiomatic
enum ApiOption<T> { Some(v:T); None; }
var apiOpt = Some("test");     // → {:ok, "test"}
```

## Common Misconceptions

### ❌ "Some() is a function call"
```haxe
// This looks like a function call but it's NOT
Some("Hello")  // This is a constructor expression
```

### ❌ "We need to call Option.some()"
```elixir
# Generated code doesn't do this:
Option.some("Hello")  # ❌ Unnecessary function call

# Generated code does this:
{:ok, "Hello"}  # ✅ Direct pattern
```

### ❌ "None becomes :none"
```elixir
# Old (non-idiomatic):
:none  # ❌ Not standard Elixir

# New (idiomatic):
:error  # ✅ Standard Elixir error pattern
```

## Testing Implications

When writing tests, expect the direct patterns:
```elixir
# In generated Main.ex:
some = {:ok, "Hello"}  # Direct pattern, not function call
none = :error          # Direct pattern, not function call

# Pattern matching expects these patterns:
case some do
  {:ok, value} -> value    # ✅ Matches {:ok, "Hello"}
  :error -> "default"      # ✅ Matches :error  
end
```

## Key Takeaways

1. **Enum constructors compile to patterns**, not function calls
2. **Module functions exist but are rarely used** in generated code
3. **Idiomatic patterns** (`{:ok, value}` / `:error`) are preferred over custom patterns
4. **Both TCall and TField** expressions compile directly to their target patterns
5. **Performance and idiomaticity** are achieved through direct pattern compilation

This design ensures that Haxe's type-safe enum constructors generate efficient, idiomatic Elixir code that follows BEAM ecosystem conventions.