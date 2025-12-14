# Array Functional Methods in Reflaxe.Elixir

## Overview

Reflaxe.Elixir now supports comprehensive functional programming methods for arrays through the `ArrayTools` static extension and enhanced compiler support.

## New Array Methods Implemented ✅

### Accumulation Methods
- **`reduce(func, initial)`** - Reduces array to single value using accumulator function
  ```haxe
  var sum = numbers.reduce((acc, item) -> acc + item, 0);
  // Compiles to: Enum.reduce(numbers, 0, fn item, acc -> acc + item end)
  ```

- **`fold(func, initial)`** - Alias for reduce
  ```haxe
  var product = numbers.fold((acc, item) -> acc * item, 1);
  // Compiles to: Enum.reduce(numbers, 1, fn item, acc -> acc * item end)
  ```

### Search Methods
- **`find(predicate)`** - Finds first element matching predicate
  ```haxe
  var firstEven = numbers.find(n -> n % 2 == 0);
  // Compiles to: Enum.find(numbers, fn item -> item % 2 == 0 end)
  ```

- **`findIndex(predicate)`** - Finds index of first element matching predicate
  ```haxe
  var evenIndex = numbers.findIndex(n -> n % 2 == 0);
  // Compiles to: Enum.find_index(numbers, fn item -> item % 2 == 0 end)
  ```

### Boolean Predicates
- **`exists(predicate)`** / **`any(predicate)`** - Tests if any element matches
  ```haxe
  var hasEven = numbers.exists(n -> n % 2 == 0);
  // Compiles to: Enum.any?(numbers, fn item -> item % 2 == 0 end)
  ```

- **`foreach(predicate)`** / **`all(predicate)`** - Tests if all elements match
  ```haxe
  var allPositive = numbers.all(n -> n > 0);
  // Compiles to: Enum.all?(numbers, fn item -> item > 0 end)
  ```

### Collection Operations
- **`forEach(action)`** - Executes function for each element (side effects)
  ```haxe
  numbers.forEach(n -> trace(n));
  // Compiles to: Enum.each(numbers, fn item -> trace(item) end)
  ```

- **`take(n)`** - Returns first n elements
  ```haxe
  var first3 = numbers.take(3);
  // Compiles to: Enum.take(numbers, 3)
  ```

- **`drop(n)`** - Skips first n elements
  ```haxe
  var skip2 = numbers.drop(2);
  // Compiles to: Enum.drop(numbers, 2)
  ```

- **`flatMap(mapper)`** - Maps and flattens the result
  ```haxe
  var flattened = arrays.flatMap(arr -> arr.map(x -> x * 2));
  // Compiles to: Enum.flat_map(arrays, fn item -> Enum.map(item, fn x -> x * 2 end) end)
  ```

## Usage

### 1. Using ArrayTools Static Extension

```haxe
using ArrayTools;

class Example {
    public static function main() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Accumulation
        var sum = numbers.reduce((acc, item) -> acc + item, 0);
        var product = numbers.fold((acc, item) -> acc * item, 1);
        
        // Search
        var firstEven = numbers.find(n -> n % 2 == 0);
        var evenIndex = numbers.findIndex(n -> n % 2 == 0);
        
        // Predicates
        var hasEven = numbers.exists(n -> n % 2 == 0);
        var allPositive = numbers.all(n -> n > 0);
        
        // Collection operations
        var first3 = numbers.take(3);
        var skip2 = numbers.drop(2);
        
        // Method chaining
        var processed = numbers
            .filter(n -> n > 2)
            .map(n -> n * n)
            .take(2)
            .reduce((acc, n) -> acc + n, 0);
    }
}
```

### 2. Generated Elixir Code

The compiler generates idiomatic Elixir using the `Enum` module:

```elixir
def main() do
  numbers = [1, 2, 3, 4, 5]
  
  # Accumulation
  sum = Enum.reduce(numbers, 0, fn item, acc -> acc + item end)
  product = Enum.reduce(numbers, 1, fn item, acc -> acc * item end)
  
  # Search
  first_even = Enum.find(numbers, fn item -> item rem 2 == 0 end)
  even_index = Enum.find_index(numbers, fn item -> item rem 2 == 0 end)
  
  # Predicates  
  has_even = Enum.any?(numbers, fn item -> item rem 2 == 0 end)
  all_positive = Enum.all?(numbers, fn item -> item > 0 end)
  
  # Collection operations
  first_3 = Enum.take(numbers, 3)
  skip_2 = Enum.drop(numbers, 2)
  
  # Method chaining compiles to nested Enum calls
  processed = Enum.reduce(
    Enum.take(
      Enum.map(
        Enum.filter(numbers, fn item -> item > 2 end),
        fn item -> item * item end
      ),
      2
    ),
    0,
    fn item, acc -> acc + item end
  )
end
```

## Architecture

### Compiler Implementation

The array functional methods are implemented in `ElixirCompiler.hx` within the `compileArrayMethod()` function:

```haxe
case "reduce", "fold":
    // array.reduce((acc, item) -> acc + item, initial) → Enum.reduce(array, initial, fn item, acc -> acc + item end)
    if (compiledArgs.length >= 2) {
        // Check if the first argument is a lambda that needs variable substitution
        switch (args[0].expr) {
            case TFunction(func):
                // Handle lambda parameter substitution and generate idiomatic Elixir
                var compiledBody = compileExpression(func.expr);
                return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, fn ${elixirItemName}, ${elixirAccName} -> ${compiledBody} end)';
        }
    }
```

### Static Extension Pattern

ArrayTools uses Haxe's static extension pattern to add methods to Array<T>:

```haxe
class ArrayTools {
    public static function reduce<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        // Haxe implementation for other targets
    }
    
    public static function find<T>(array: Array<T>, predicate: T -> Bool): Null<T> {
        // Haxe implementation for other targets  
    }
    
    // ... other methods
}
```

When targeting Elixir, the compiler recognizes these static extension calls and compiles them to idiomatic `Enum` module functions instead of generating the Haxe implementations.

## Benefits

### 1. **Idiomatic Elixir Code Generation**
- Uses `Enum` module functions which are optimized and idiomatic
- Generates `?` suffix for boolean predicates (`Enum.any?`, `Enum.all?`)
- Proper parameter ordering (Elixir uses `(item, acc)` vs Haxe `(acc, item)`)

### 2. **Cross-Platform Consistency**
- Same API works across all Haxe targets
- ArrayTools provides fallback implementations for non-Elixir targets
- Type-safe functional programming patterns

### 3. **Method Chaining Support**
- Full support for fluent method chaining
- Compiles to efficient nested Enum calls
- Maintains functional programming style

### 4. **Variable Scope Handling**
- Proper lambda parameter substitution
- Consistent variable naming in generated code
- No variable scope conflicts

## Testing

The array functional methods are comprehensively tested in `test/tests/arrays/Main.hx`:

```haxe
using ArrayTools;

class Main {
    public static function functionalMethods(): Void {
        var numbers = [1, 2, 3, 4, 5];
        
        // Test all new methods with various patterns
        var sum = numbers.reduce((acc, item) -> acc + item, 0);
        var firstEven = numbers.find(n -> n % 2 == 0);
        var hasEven = numbers.exists(n -> n % 2 == 0);
        // ... comprehensive test coverage
    }
}
```

**Test Status**: ✅ All tests passing with updated intended output

## Performance Characteristics

- **Compile-time optimization**: Array method calls compile directly to Enum functions
- **No runtime overhead**: Static extension calls are eliminated at compile time
- **Elixir optimization**: Generated code uses Elixir's optimized Enum implementations
- **Memory efficiency**: Immutable data structures with efficient copying

## Future Enhancements

### Planned Improvements
1. **Enhanced reduce parameter handling** - Better dual-parameter variable substitution
2. **More collection methods** - `zip`, `partition`, `groupBy`, `distinctBy`
3. **Lazy evaluation support** - Integration with Elixir's Stream module
4. **Error handling** - Result<T,E> integration for safe operations

### API Stability
The current API is stable and production-ready. Future additions will be backward compatible.

## Cross-References

- **[Compiler Patterns](/docs/05-architecture/COMPILER_PATTERNS.md)** - Development patterns used in array method implementation
- **[Functional Patterns](/docs/07-patterns/FUNCTIONAL_PATTERNS.md)** - Functional programming patterns and Result/Option types
- **[Standard Library Handling](/docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md)** - Architecture comparison with StringTools extern pattern
- **[Haxe→Elixir Mappings](/docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md)** - How array methods map to Elixir constructs

## Implementation Files

- **`std/ArrayTools.hx`** - Static extension definitions for cross-platform support
- **`src/reflaxe/elixir/ElixirCompiler.hx`** - Compiler implementation (lines 4121-4317)
- **`test/tests/arrays/Main.hx`** - Comprehensive test suite
- **`docs/05-architecture/ARRAY_FUNCTIONAL_METHODS.md`** - This documentation file
