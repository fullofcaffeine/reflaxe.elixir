# Functional Programming Patterns in Reflaxe.Elixir

This document describes how Reflaxe.Elixir transforms Haxe's imperative programming constructs into Elixir's functional paradigm.

## Overview

Haxe is a multi-paradigm language with imperative features like loops and mutable variables. Elixir is a functional language with immutable data and recursion. Reflaxe.Elixir bridges this gap by transforming imperative patterns into functional equivalents at compile time.

## Core Transformations

### 1. While Loops → Recursive Functions

Elixir doesn't have `while` loops. We transform them into tail-recursive anonymous functions.

#### Pattern
```haxe
// Haxe input
while (condition) {
    body;
}
```

```elixir
# Generated Elixir
(fn loop_fn ->
  if (condition) do
    body
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
```

#### How It Works
1. Create an anonymous function `loop_fn` that takes itself as an argument
2. Check the condition in an `if` expression
3. Execute the body and recursively call itself if condition is true
4. Use the Y-combinator pattern to initiate the recursion
5. Elixir's tail-call optimization ensures no stack overflow

#### Example
```haxe
// Haxe: Count spaces at start of string
var i = 0;
while (i < str.length && isSpace(str, i)) {
    i++;
}
```

```elixir
# Elixir: Recursive function with accumulator
i = 0
(fn loop_fn ->
  if (i < String.length(str) && is_space(str, i)) do
    i = i + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
```

### 2. Do-While Loops → Recursive Functions

Do-while loops always execute at least once before checking the condition.

#### Pattern
```haxe
// Haxe input
do {
    body;
} while (condition);
```

```elixir
# Generated Elixir
(fn loop_fn ->
  body
  if (condition) do
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
```

### 3. String Concatenation

Elixir uses `<>` for string concatenation, not `+`.

#### Type Detection
The compiler detects string types to select the correct operator:

```haxe
// Haxe
var result = "Hello " + name;
var sum = x + y;  // numeric
```

```elixir
# Elixir
result = "Hello " <> name
sum = x + y  # numeric addition
```

### 4. Compound Assignment Operators

Elixir variables are immutable, so compound assignments become rebinding.

#### Transformations
| Haxe | Elixir |
|------|--------|
| `x += y` | `x = x + y` |
| `x -= y` | `x = x - y` |
| `x *= y` | `x = x * y` |
| `x /= y` | `x = x / y` |
| `x %= y` | `x = rem(x, y)` |
| `x &= y` | `x = x &&& y` |
| `x \|= y` | `x = x \|\|\| y` |
| `x ^= y` | `x = x ^^^ y` |
| `x <<= y` | `x = Bitwise.<<<(x, y)` |
| `x >>= y` | `x = Bitwise.>>>(x, y)` |

### 5. Bitwise Operations

Elixir requires the Bitwise module for certain operations.

#### Module Import
All generated modules include `use Bitwise` when bitwise operations are detected.

#### Operator Mappings
| Haxe | Elixir | Description |
|------|--------|-------------|
| `&` | `&&&` | Bitwise AND |
| `\|` | `\|\|\|` | Bitwise OR |
| `^` | `^^^` | Bitwise XOR |
| `~` | `~~~` | Bitwise NOT |
| `<<` | `Bitwise.<<<` | Left shift |
| `>>` | `Bitwise.>>>` | Arithmetic right shift |
| `>>>` | `Bitwise.>>>` | Logical right shift |

### 6. For Loops → Comprehensions/Recursion

Traditional for loops are transformed based on their usage pattern.

#### Simple Iteration
```haxe
// Haxe
for (i in 0...10) {
    trace(i);
}
```

```elixir
# Elixir
for i <- 0..9 do
  IO.inspect(i)
end
```

#### Complex For Loop
```haxe
// Haxe
for (i in 0...array.length) {
    if (array[i] > max) max = array[i];
}
```

```elixir
# Elixir - using Enum.reduce
max = Enum.reduce(array, max, fn item, acc ->
  if item > acc, do: item, else: acc
end)
```

## Parameter Mapping

Haxe allows arbitrary parameter names, but we standardize them for consistency.

### Mapping Rules
1. Function parameters are renamed to `arg0`, `arg1`, etc. in signatures
2. A mapping table tracks original names for use in function bodies
3. TLocal references are translated using the mapping

### Example
```haxe
// Haxe
public function substring(str: String, start: Int, ?end: Int): String {
    return str.substr(start, end);
}
```

```elixir
# Elixir
@spec substring(String.t(), integer(), integer() | nil) :: String.t()
def substring(arg0, arg1, arg2 \\ nil) do
  # Internal mapping: str->arg0, start->arg1, end->arg2
  String.slice(arg0, arg1, arg2)
end
```

## Type-Driven Compilation

The compiler uses type information to make correct transformation decisions.

### String Detection
```haxe
// Compiler checks if operands are strings
case TBinop(OpAdd, e1, e2, _):
    var isString = checkStringType(e1) || checkStringType(e2);
    if (isString) {
        return compileExpression(e1) + " <> " + compileExpression(e2);
    } else {
        return compileExpression(e1) + " + " + compileExpression(e2);
    }
```

### Numeric Operations
Modulo operations require special handling:
- Haxe: `x % y`
- Elixir: `rem(x, y)`

## Immutability Patterns

Elixir's immutability requires different patterns for data manipulation.

### Variable Updates
```haxe
// Haxe - mutable
var count = 0;
count = count + 1;
count++;
```

```elixir
# Elixir - rebinding
count = 0
count = count + 1
count = count + 1  # No ++ operator
```

### Structure Updates
```haxe
// Haxe - mutable object
user.name = "New Name";
user.age = user.age + 1;
```

```elixir
# Elixir - immutable map update
user = %{user | name: "New Name"}
user = %{user | age: user.age + 1}
```

## Best Practices

### 1. Favor Functional Patterns
When writing Haxe code for Elixir compilation, prefer functional patterns:
- Use `map`, `filter`, `reduce` over loops when possible
- Return new data instead of modifying existing
- Use pattern matching for control flow

### 2. Explicit Type Annotations
Help the compiler with type annotations:
```haxe
var name: String = "Alice";  // Compiler knows to use <>
var count: Int = 0;          // Compiler knows to use +
```

### 3. Avoid Complex Mutations
Complex mutation patterns may not translate efficiently:
```haxe
// Avoid
while (condition) {
    array[i] = transform(array[i]);
    i++;
}

// Prefer
array = array.map(item -> transform(item));
```

## Implementation Details

### Recursion Safety
All generated recursive functions use tail-call position to ensure stack safety:
- The recursive call is the last operation
- No additional computation after recursion
- Elixir's VM optimizes tail calls

### Performance Considerations
- Recursive functions are optimized by the BEAM VM
- Comprehensions are often faster than manual recursion
- Use Stream module for lazy evaluation with large datasets

## Testing Patterns

When testing compiler output:

1. **Verify Semantic Equivalence**: The generated Elixir should have the same behavior as the Haxe input
2. **Check Idiomatic Output**: Generated code should follow Elixir conventions
3. **Test Edge Cases**: Empty collections, single elements, boundary conditions
4. **Validate Performance**: Ensure tail-call optimization is preserved

## Future Enhancements

Potential improvements to the transformation system:

1. **Stream Integration**: Detect patterns that could use Stream module
2. **Enum Optimization**: Use Enum functions for better performance
3. **Pattern Matching**: Transform switch statements to pattern matching
4. **Pipeline Operator**: Detect chainable operations for |> usage
5. **With Expressions**: Transform nested error handling to `with` expressions

## References

- [Elixir Recursion Guide](https://elixir-lang.org/getting-started/recursion.html)
- [Tail Call Optimization in Elixir](https://blog.appsignal.com/2019/03/19/elixir-alchemy-recursion.html)
- [Functional Programming Patterns](https://pragprog.com/titles/elixir16/programming-elixir-1-6/)
- [BEAM VM Optimizations](https://blog.stenmans.org/theBeamBook/)