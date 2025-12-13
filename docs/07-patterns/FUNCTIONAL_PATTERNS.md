# Functional Programming Patterns in Reflaxe.Elixir

This document describes how Reflaxe.Elixir transforms Haxe's imperative programming constructs into Elixir's functional paradigm.

**See Also**: [Paradigm Bridge](paradigms/PARADIGM_BRIDGE.md) - Comprehensive guide to the imperative→functional paradigm bridge, including cross-platform development patterns and Result types.

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
# Elixir - immutable map update (auto-generated by compiler)
user = %{user | name: "New Name"}
user = %{user | age: user.age + 1}
```

✅ **Compiler Support**: As of v1.0, the Reflaxe.Elixir compiler automatically generates proper Elixir struct update syntax for field assignments. You can write natural Haxe field assignment code and the compiler will produce idiomatic functional Elixir patterns.

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

## Array/List Operations

### Design Rationale

Haxe uses object-oriented array methods, while Elixir uses functional programming with the `Enum` module. Our translations preserve the intent while producing idiomatic Elixir that looks hand-written.

### Translation Patterns

#### `array.length` → `length(array)`
**Why**: `length/1` is a Kernel function in Elixir, making it the most idiomatic and performant way to get list length.
```haxe
// Haxe
var count = todos.length;
```
```elixir
# Elixir (generated)
count = length(todos)
```

#### `array.concat(other)` → `array ++ other`
**Why**: The `++` operator is Elixir's idiomatic list concatenation operator. It's more readable and performant than `Enum.concat/2`.
```haxe
// Haxe
var allItems = todos.concat(newTodos);
```
```elixir
# Elixir (generated)
all_items = todos ++ new_todos
```

#### `array.filter(fn)` → `Enum.filter(array, fn)`
**Why**: `Enum.filter/2` is the standard functional approach in Elixir.
```haxe
// Haxe
var completed = todos.filter(t -> t.completed);
```
```elixir
# Elixir (generated)
completed = Enum.filter(todos, fn t -> t.completed end)
```

#### `array.map(fn)` → `Enum.map(array, fn)`
**Why**: `Enum.map/2` is the functional transformation pattern in Elixir.
```haxe
// Haxe
var titles = todos.map(t -> t.title);
```
```elixir
# Elixir (generated)
titles = Enum.map(todos, fn t -> t.title end)
```

#### `array.contains(elem)` → `Enum.member?(array, elem)`
**Why**: `Enum.member?/2` follows Elixir's convention of using `?` suffix for boolean functions.
```haxe
// Haxe
if (tags.contains("urgent")) { ... }
```
```elixir
# Elixir (generated)
if Enum.member?(tags, "urgent"), do: ...
```

#### `array.indexOf(elem)` → `Enum.find_index(array, &(&1 == elem))`
**Why**: `Enum.find_index/2` with a comparison function is the Elixir way to find element position.
```haxe
// Haxe
var position = items.indexOf(target);
```
```elixir
# Elixir (generated)
position = Enum.find_index(items, &(&1 == target))
```

## Future Enhancements

Potential improvements to the transformation system:

1. **Stream Integration**: Detect patterns that could use Stream module
2. **Enum Optimization**: Use Enum functions for better performance
3. **Pattern Matching**: Transform switch statements to pattern matching
4. **Pipeline Operator**: Detect chainable operations for |> usage
5. **With Expressions**: Transform nested error handling to `with` expressions
6. **More Array Methods**: Support slice, take, drop, reverse, sort operations

## Dynamic Type Handling

### Overview
When working with Dynamic types (common in LiveView socket assigns, JSON parsing, etc.), the compiler provides intelligent transformations to ensure idiomatic Elixir output.

### Dynamic Array Operations

```haxe
// Haxe - Dynamic typed socket assigns
var socket: Dynamic = getSocket();
var todos = socket.assigns.todos;
var completed = todos.filter(t -> t.completed);
var titles = todos.map(t -> t.title);
var count = todos.length;
```

```elixir
# Generated Elixir - Proper Enum functions
socket = get_socket()
todos = socket.assigns.todos
completed = Enum.filter(todos, fn t -> t.completed end)
titles = Enum.map(todos, fn t -> t.title end)  
count = length(todos)
```

### How It Works
The compiler uses `isArrayMethod()` to detect common array operations regardless of type:
- Typed Arrays get optimal transformations
- Dynamic values with array-like methods get Enum transformations
- Property access like `.length` becomes function calls

### Best Practice: Progressive Typing

```haxe
// Phase 1: Prototype with Dynamic
function processItems(data: Dynamic): Dynamic {
    return data.items.filter(item -> item.active);
}

// Phase 2: Add types as API stabilizes
typedef Data = {
    items: Array<Item>
}

function processItems(data: Data): Array<Item> {
    return data.items.filter(item -> item.active);
}
```

**See**: [`/docs/05-architecture/DYNAMIC_HANDLING.md`](/docs/05-architecture/DYNAMIC_HANDLING.md) for comprehensive Dynamic type handling guide.

## Type-Safe Null Handling with Option<T>

The `Option<T>` type provides type-safe null handling as an alternative to nullable types, compiling to idiomatic patterns per target following Gleam's approach to explicit over implicit.

### The Option Type Pattern

```haxe
// Import the Option type and tools
import haxe.ds.Option;
using haxe.ds.OptionTools;

// Define functions that may return nothing
function findUser(id: Int): Option<User> {
    var user = database.query("SELECT * FROM users WHERE id = ?", [id]);
    return user != null ? Some(user) : None;
}
```

### Compilation to Idiomatic Elixir

**Haxe Input**:
```haxe
function getUserEmail(id: Int): Option<String> {
    return switch (findUser(id)) {
        case Some(user): 
            if (user.email != null) Some(user.email) else None;
        case None: 
            None;
    }
}
```

**Generated Elixir**:
```elixir
def get_user_email(id) do
  case find_user(id) do
    {:some, user} -> 
      if user.email != nil do 
        {:some, user.email} 
      else 
        :none 
      end
    :none -> 
      :none
  end
end
```

### Functional Operations

Option types support comprehensive functional operations inspired by Gleam's approach:

```haxe
// Chain operations with flatMap/then
function getUserProfile(id: Int): Option<UserProfile> {
    return findUser(id).then(user -> 
        findProfile(user.profileId).map(profile ->
            new UserProfile(user.name, profile.bio)
        )
    );
}

// Transform values with map
function getUserDisplayName(id: Int): Option<String> {
    return findUser(id).map(user -> 
        user.displayName != null ? user.displayName : user.username
    );
}

// Extract values safely with unwrap
function getNameOrDefault(id: Int): String {
    return findUser(id)
        .map(user -> user.name)
        .unwrap("Anonymous User");
}

// Filter based on conditions
function getActiveUser(id: Int): Option<User> {
    return findUser(id).filter(user -> user.isActive);
}
```

### Collection Operations

Working with collections of Option values:

```haxe
// Process all options - fail if any is None
function getUserProfiles(ids: Array<Int>): Option<Array<UserProfile>> {
    var options = ids.map(id -> findUser(id));
    return OptionTools.all(options).map(users ->
        users.map(user -> createProfile(user))
    );
}

// Extract all Some values, discard None values
function getExistingUsers(ids: Array<Int>): Array<User> {
    var options = ids.map(id -> findUser(id));
    return OptionTools.values(options);
}
```

### BEAM/OTP Integration

Option types provide seamless integration with Elixir/OTP patterns:

```haxe
// Convert to Result for error handling chains
function getUser(id: Int): Result<User, String> {
    return findUser(id).toResult('User not found with id: ${id}');
}

// Use in GenServer replies
function handleGetUser(id: Int): Dynamic {
    return findUser(id).toReply(); // Generates proper {:reply, response, state}
}

// Bridge with nullable APIs
function fromNullableAPI(data: Null<String>): Option<String> {
    return OptionTools.fromNullable(data);
}
```

### Pattern vs Nullable Comparison

**Nullable-Based Approach**:
```haxe
// Traditional null checking
function getUserEmail(id: Int): Null<String> {
    var user = findUser(id); // Returns Null<User>
    if (user != null) {
        if (user.email != null) {
            return user.email;
        }
    }
    return null; // Information about why it failed is lost
}
```

**Option-Based Approach**:
```haxe
// Type-safe Option handling
function getUserEmail(id: Int): Option<String> {
    return findUser(id)
        .flatMap(user -> OptionTools.fromNullable(user.email));
}

// Caller must handle both cases explicitly
switch (getUserEmail(123)) {
    case Some(email): sendNotification(email);
    case None: logError("Could not get email for user 123");
}
```

### Cross-Platform Compilation

Option types generate optimal patterns for each target:

- **Elixir**: `{:some, value}` and `:none` atoms for pattern matching
- **JavaScript**: Tagged objects `{tag: "some", value: v}` / `{tag: "none"}`
- **Python**: Dataclasses with proper type hints
- **Other targets**: Standard enum with type safety

### Advanced Patterns

**Chaining with Early Returns**:
```haxe
function getNestedProperty(userId: Int): Option<String> {
    return findUser(userId)
        .flatMap(user -> findProfile(user.profileId))
        .flatMap(profile -> OptionTools.fromNullable(profile.website))
        .filter(website -> website.startsWith("https://"));
}
```

**Combining Multiple Options**:
```haxe
function createFullName(userId: Int): Option<String> {
    var firstName = findUser(userId).map(u -> u.firstName);
    var lastName = findUser(userId).map(u -> u.lastName);
    
    return switch ([firstName, lastName]) {
        case [Some(first), Some(last)]: Some('${first} ${last}');
        case [Some(first), None]: Some(first);
        case [None, Some(last)]: Some(last);
        case [None, None]: None;
    }
}
```

**Lazy Evaluation**:
```haxe
function getUserOrFallback(primaryId: Int, fallbackId: Int): Option<User> {
    return findUser(primaryId).lazyOr(() -> findUser(fallbackId));
}
```

### Benefits

1. **Type Safety**: Compile-time guarantee of null safety
2. **Explicit Intent**: Clear indication when values may be absent
3. **Composability**: Chain operations without nested null checks
4. **Cross-Platform**: Works consistently across all Haxe targets  
5. **Performance**: Zero-cost abstractions with optimal code generation
6. **BEAM Integration**: Seamless integration with Elixir/OTP patterns

**See**: [`std/haxe/ds/Option.hx`](../std/haxe/ds/Option.hx) and [`std/haxe/ds/OptionTools.hx`](../std/haxe/ds/OptionTools.hx) for complete API documentation.

## Error Handling with Result<T,E>

The `Result<T,E>` type provides functional error handling as an alternative to exceptions, compiling to idiomatic patterns per target.

### The Result Type Pattern

```haxe
// Import the Result type
using haxe.functional.Result;
using haxe.functional.ResultTools;

// Define functions that can fail
function parseNumber(input: String): Result<Int, String> {
    var parsed = Std.parseInt(input);
    if (parsed != null) {
        return Ok(parsed);
    } else {
        return Error('Invalid number: ${input}');
    }
}
```

### Compilation to Idiomatic Elixir

**Haxe Input**:
```haxe
function processInput(input: String): Result<Int, String> {
    return switch (parseNumber(input)) {
        case Ok(value): 
            if (value > 0) Ok(value * 2) else Error("Must be positive");
        case Error(msg): 
            Error("Parse failed: " + msg);
    }
}
```

**Generated Elixir**:
```elixir
def process_input(input) do
  case parse_number(input) do
    {:ok, value} -> 
      if value > 0 do 
        {:ok, value * 2} 
      else 
        {:error, "Must be positive"} 
      end
    {:error, msg} -> 
      {:error, "Parse failed: " <> msg}
  end
end
```

### Functional Operations

Result types support comprehensive functional operations:

```haxe
// Chain operations with flatMap
function divideNumbers(a: String, b: String): Result<Float, String> {
    return parseNumber(a).flatMap(numA -> 
        parseNumber(b).flatMap(numB -> 
            numB == 0 ? Error("Division by zero") : Ok(numA / numB)
        )
    );
}

// Transform values with map
function doubleIfValid(input: String): Result<Int, String> {
    return parseNumber(input).map(x -> x * 2);
}

// Extract values safely with fold
function getValueOrDefault(result: Result<Int, String>): Int {
    return result.fold(
        value -> value,    // Success case
        error -> -1        // Error case - return default
    );
}
```

### Pattern vs Exception Comparison

**Exception-Based Approach**:
```haxe
// Traditional exception handling
function processData(input: String): Int {
    try {
        var value = parseOrThrow(input);
        if (value <= 0) throw "Must be positive";
        return value * 2;
    } catch (e: String) {
        return -1; // Silent failure, information lost
    }
}
```

**Result-Based Approach**:
```haxe
// Functional error handling with Result
function processData(input: String): Result<Int, String> {
    return parseNumber(input)
        .flatMap(value -> value > 0 ? Ok(value * 2) : Error("Must be positive"));
}

// Error information preserved, composable, type-safe
```

### Cross-Platform Compilation

Result types generate optimal patterns for each target:

- **Elixir**: `{:ok, value}` and `{:error, reason}` tuples
- **JavaScript**: Tagged objects with discriminated unions
- **Python**: Dataclasses with proper type hints
- **Other targets**: Standard enum with type safety

### Advanced Patterns

**Collecting Results**:
```haxe
// Process multiple inputs, fail fast on first error
function processMultiple(inputs: Array<String>): Result<Array<Int>, String> {
    return ResultTools.traverse(inputs, parseNumber);
}

// Process all inputs, collect all errors
function processAllWithErrors(inputs: Array<String>): {
    successes: Array<Int>,
    errors: Array<String>
} {
    var results = inputs.map(parseNumber);
    return {
        successes: results.map(r -> r.fold(v -> v, _ -> null))
                          .filter(v -> v != null),
        errors: results.map(r -> r.fold(_ -> null, e -> e))
                       .filter(e -> e != null)
    };
}
```

**Chaining with Early Returns**:
```haxe
function complexValidation(data: UserData): Result<User, ValidationError> {
    return validateEmail(data.email)
        .flatMap(_ -> validateAge(data.age))
        .flatMap(_ -> validatePassword(data.password))
        .map(_ -> new User(data.email, data.age));
}
```

### Benefits

1. **Type Safety**: Compile-time guarantee of error handling
2. **Composability**: Chain operations without nested try/catch
3. **Information Preservation**: Error details maintained through pipeline
4. **Cross-Platform**: Works consistently across all Haxe targets
5. **Performance**: Zero-cost abstractions with optimal code generation
6. **Readability**: Clear success/failure paths in code

**See**: [`std/haxe/functional/Result.hx`](../std/haxe/functional/Result.hx) for complete API documentation.

## Future Improvements

1. **Accumulator Pattern**: Detect and transform loops to use accumulators
2. **Recursive Pattern Detection**: Identify recursive patterns for optimization
3. **Pattern Matching**: Transform switch statements to pattern matching
4. **Pipeline Operator**: Detect chainable operations for |> usage
5. **With Expressions**: Transform nested error handling to `with` expressions
6. **More Array Methods**: Support slice, take, drop, reverse, sort operations

## See Also

- [BEAM Type Abstractions](BEAM_TYPE_ABSTRACTIONS.md) - Comprehensive guide to Option<T> and Result<T,E> types for type-safe null handling and error management
- [ExUnit Testing Guide](EXUNIT_TESTING_GUIDE.md) - Testing Option and Result types with type-safe assertions
- [Paradigm Bridge](paradigms/PARADIGM_BRIDGE.md) - Cross-platform development patterns and functional transformations
- [Developer Patterns](guides/DEVELOPER_PATTERNS.md) - Best practices for writing effective Haxe→Elixir code including Option/Result migration patterns
- [Standard Library Handling](STANDARD_LIBRARY_HANDLING.md) - How standard library types including Option and Result compile to Elixir
- [Cookbook](COOKBOOK.md) - Practical recipes for common Option and Result patterns

## References

- [Elixir Recursion Guide](https://elixir-lang.org/getting-started/recursion.html)
- [Tail Call Optimization in Elixir](https://blog.appsignal.com/2019/03/19/elixir-alchemy-recursion.html)
- [Functional Programming Patterns](https://pragprog.com/titles/elixir16/programming-elixir-1-6/)
- [BEAM VM Optimizations](https://blog.stenmans.org/theBeamBook/)
