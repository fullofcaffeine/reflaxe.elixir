# Idiomatic Pattern Reference Library for Haxe→Elixir Compilation

## Introduction

This document serves as the golden standard for transforming Haxe code into idiomatic Elixir. Each pattern includes the current non-idiomatic output, the target idiomatic form, transformation rules, and AST metadata requirements for compiler implementation.

## Core Principles

1. **Think Like an Elixir Developer**: Generated code should look hand-written by an experienced Elixir programmer
2. **Preserve Semantics**: Maintain Haxe behavior while using Elixir idioms
3. **Optimize for Readability**: Prefer clear, maintainable patterns over clever optimizations
4. **Leverage BEAM**: Use Elixir/Erlang platform strengths (pattern matching, immutability, processes)

## Pattern Categories

### 1. Loop Transformations

#### Pattern 1.1: Simple Range Iteration
**Haxe Input:**
```haxe
for (i in 0...10) {
    trace("Index: " + i);
}
```

**Current Output (Non-idiomatic):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 10) do
    i = acc_i
    acc_i = acc_i + 1
    Log.trace("Index: " <> Std.string(i), ...)
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
Enum.each(0..9, fn i ->
  Log.trace("Index: #{i}", ...)
end)
```

**Transformation Rule:**
- Detect: `for (var in start...end)` with side effects only
- Transform: `Enum.each(start..end-1, fn var -> ... end)`
- AST Metadata: `{loopType: "simple_range", hasSideEffects: true, returnsValue: false}`

#### Pattern 1.2: Array Iteration
**Haxe Input:**
```haxe
for (item in items) {
    process(item);
}
```

**Current Output (Non-idiomatic):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items}, fn _, {items} ->
  if (0 < length(items)) do
    item = hd(items)
    process(item)
    {:cont, {tl(items)}}
  else
    {:halt, {items}}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
Enum.each(items, fn item ->
  process(item)
end)
```

**Transformation Rule:**
- Detect: `for (elem in collection)` with side effects
- Transform: `Enum.each(collection, fn elem -> ... end)`
- AST Metadata: `{loopType: "collection_iteration", hasSideEffects: true}`

#### Pattern 1.3: Array Comprehension with Filter
**Haxe Input:**
```haxe
var evens = [for (n in numbers) if (n % 2 == 0) n];
```

**Current Output (Non-idiomatic):**
```elixir
evens = []
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, evens, 0}, fn _, {numbers, evens, index} ->
  if (index < length(numbers)) do
    n = Enum.at(numbers, index)
    evens = if rem(n, 2) == 0 do
      evens ++ [n]
    else
      evens
    end
    {:cont, {numbers, evens, index + 1}}
  else
    {:halt, {numbers, evens, index}}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
evens = for n <- numbers, rem(n, 2) == 0, do: n
```

**Transformation Rule:**
- Detect: Array comprehension with filter condition
- Transform: Elixir comprehension with guard
- AST Metadata: `{loopType: "comprehension", hasFilter: true, isCollecting: true}`

#### Pattern 1.4: Nested Loops
**Haxe Input:**
```haxe
for (i in 0...rows) {
    for (j in 0...cols) {
        matrix[i][j] = i * cols + j;
    }
}
```

**Current Output (Non-idiomatic):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, matrix}, fn _, {i, matrix} ->
  if (i < rows) do
    {_, matrix} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, matrix}, fn _, {j, matrix} ->
      if (j < cols) do
        matrix = put_in(matrix, [i, j], i * cols + j)
        {:cont, {j + 1, matrix}}
      else
        {:halt, {j, matrix}}
      end
    end)
    {:cont, {i + 1, matrix}}
  else
    {:halt, {i, matrix}}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
matrix = for i <- 0..(rows-1), do:
  for j <- 0..(cols-1), do: i * cols + j
```

**Transformation Rule:**
- Detect: Nested for loops building data structure
- Transform: Nested comprehensions
- AST Metadata: `{loopType: "nested", depth: 2, isBuilding: true}`

#### Pattern 1.5: While Loop
**Haxe Input:**
```haxe
while (condition) {
    doWork();
    updateCondition();
}
```

**Current Output (Non-idiomatic):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if condition do
    do_work()
    update_condition()
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
defp loop_while(state) do
  if condition(state) do
    state = do_work(state)
    state = update_condition(state)
    loop_while(state)
  else
    state
  end
end
```

**Transformation Rule:**
- Detect: While loop pattern
- Transform: Recursive function with state
- AST Metadata: `{loopType: "while", needsRecursion: true}`

### 2. Pattern Matching

#### Pattern 2.1: Enum Destructuring
**Haxe Input:**
```haxe
switch(option) {
    case Some(value): return value * 2;
    case None: return 0;
}
```

**Current Output (Non-idiomatic):**
```elixir
case option do
  g when elem(g, 0) == 0 ->
    value = elem(g, 1)
    value * 2
  g when elem(g, 0) == 1 ->
    0
end
```

**Target Output (Idiomatic):**
```elixir
case option do
  {:some, value} -> value * 2
  :none -> 0
end
```

**Transformation Rule:**
- Detect: Enum pattern matching with elem() calls
- Transform: Direct tuple destructuring with atoms
- AST Metadata: `{patternType: "enum", needsDestructuring: true}`

#### Pattern 2.2: Multiple Pattern Variables
**Haxe Input:**
```haxe
switch(result) {
    case Ok(data): process(data);
    case Error(code, message): log(code, message);
}
```

**Current Output (Non-idiomatic):**
```elixir
case result do
  g when elem(g, 0) == 0 ->
    data = elem(g, 1)
    process(data)
  g when elem(g, 0) == 1 ->
    code = elem(g, 1)
    message = elem(g, 2)
    log(code, message)
end
```

**Target Output (Idiomatic):**
```elixir
case result do
  {:ok, data} -> process(data)
  {:error, code, message} -> log(code, message)
end
```

**Transformation Rule:**
- Detect: Multi-parameter enum patterns
- Transform: Tuple patterns with multiple elements
- AST Metadata: `{patternType: "enum", paramCount: varies}`

#### Pattern 2.3: Nested Pattern Matching
**Haxe Input:**
```haxe
switch(response) {
    case Success(Ok(data)): return data;
    case Success(Error(msg)): throw msg;
    case Failure(reason): throw "Failed: " + reason;
}
```

**Current Output (Non-idiomatic):**
```elixir
case response do
  g when elem(g, 0) == 0 ->
    inner = elem(g, 1)
    case inner do
      g2 when elem(g2, 0) == 0 ->
        data = elem(g2, 1)
        data
      g2 when elem(g2, 0) == 1 ->
        msg = elem(g2, 1)
        throw(msg)
    end
  g when elem(g, 0) == 1 ->
    reason = elem(g, 1)
    throw("Failed: " <> reason)
end
```

**Target Output (Idiomatic):**
```elixir
case response do
  {:success, {:ok, data}} -> data
  {:success, {:error, msg}} -> throw(msg)
  {:failure, reason} -> throw("Failed: #{reason}")
end
```

**Transformation Rule:**
- Detect: Nested enum patterns
- Transform: Nested tuple patterns
- AST Metadata: `{patternType: "nested_enum", depth: 2}`

### 3. String Operations

#### Pattern 3.1: String Concatenation
**Haxe Input:**
```haxe
var greeting = "Hello " + name + ", you are " + age + " years old";
```

**Current Output (Non-idiomatic):**
```elixir
greeting = "Hello " <> name <> ", you are " <> Std.string(age) <> " years old"
```

**Target Output (Idiomatic):**
```elixir
greeting = "Hello #{name}, you are #{age} years old"
```

**Transformation Rule:**
- Detect: String concatenation with `<>` operator
- Transform: String interpolation with `#{}`
- AST Metadata: `{stringOp: "concatenation", canInterpolate: true}`

#### Pattern 3.2: Multi-line String Building
**Haxe Input:**
```haxe
var sql = "SELECT * FROM users\n";
sql += "WHERE age > " + minAge + "\n";
sql += "ORDER BY name";
```

**Current Output (Non-idiomatic):**
```elixir
sql = "SELECT * FROM users\n"
sql = sql <> "WHERE age > " <> Std.string(min_age) <> "\n"
sql = sql <> "ORDER BY name"
```

**Target Output (Idiomatic):**
```elixir
sql = """
SELECT * FROM users
WHERE age > #{min_age}
ORDER BY name
"""
```

**Transformation Rule:**
- Detect: Sequential string concatenation
- Transform: Multi-line string with interpolation
- AST Metadata: `{stringOp: "multiline", isBuilding: true}`

### 4. Variable Naming

#### Pattern 4.1: Infrastructure Variables
**Haxe Input:**
```haxe
// Compiler-generated infrastructure
```

**Current Output (Non-idiomatic):**
```elixir
g = some_value
g1 = another_value
g2 = third_value
```

**Target Output (Idiomatic):**
```elixir
temp_value = some_value
index = another_value
accumulator = third_value
```

**Transformation Rule:**
- Detect: Generated variable names (g, g1, g2, etc.)
- Transform: Meaningful contextual names
- AST Metadata: `{varType: "infrastructure", needsRename: true}`

#### Pattern 4.2: Unused Parameters
**Haxe Input:**
```haxe
function process(data, options) {
    // options not used
    return transform(data);
}
```

**Current Output (Non-idiomatic):**
```elixir
def process(data, options) do
  transform(data)
end
```

**Target Output (Idiomatic):**
```elixir
def process(data, _options) do
  transform(data)
end
```

**Transformation Rule:**
- Detect: Unused function parameters
- Transform: Prefix with underscore
- AST Metadata: `{paramUsage: "unused", needsUnderscore: true}`

#### Pattern 4.3: Loop Index Variables
**Haxe Input:**
```haxe
for (i in 0...length) {
    items[i] = i * 2;
}
```

**Current Output (Non-idiomatic):**
```elixir
{g, _} = Enum.reduce({0, items}, fn _, {g, items} ->
  if g < length do
    items = List.replace_at(items, g, g * 2)
    {g + 1, items}
  else
    {g, items}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
items = Enum.map(0..(length-1), fn index ->
  index * 2
end)
```

**Transformation Rule:**
- Detect: Index-based array modification
- Transform: Appropriate Enum function
- AST Metadata: `{loopType: "indexed", operation: "map"}`

### 5. Conditional Logic

#### Pattern 5.1: Chained If-Else to Cond
**Haxe Input:**
```haxe
if (x < 0) return "negative";
else if (x == 0) return "zero";
else if (x < 10) return "small";
else return "large";
```

**Current Output (Non-idiomatic):**
```elixir
if x < 0 do
  "negative"
else
  if x == 0 do
    "zero"
  else
    if x < 10 do
      "small"
    else
      "large"
    end
  end
end
```

**Target Output (Idiomatic):**
```elixir
cond do
  x < 0 -> "negative"
  x == 0 -> "zero"
  x < 10 -> "small"
  true -> "large"
end
```

**Transformation Rule:**
- Detect: Chained if-else with returns
- Transform: Cond expression
- AST Metadata: `{conditionalType: "chained", canUseCond: true}`

#### Pattern 5.2: Guard Clauses
**Haxe Input:**
```haxe
function divide(a, b) {
    if (b == 0) throw "Division by zero";
    return a / b;
}
```

**Current Output (Non-idiomatic):**
```elixir
def divide(a, b) do
  if b == 0 do
    throw("Division by zero")
  end
  a / b
end
```

**Target Output (Idiomatic):**
```elixir
def divide(a, 0), do: throw("Division by zero")
def divide(a, b), do: a / b
```

**Transformation Rule:**
- Detect: Early return/throw patterns
- Transform: Multiple function clauses with pattern matching
- AST Metadata: `{conditionalType: "guard", useMultiClause: true}`

### 6. Collection Operations

#### Pattern 6.1: Array Building
**Haxe Input:**
```haxe
var result = [];
for (item in items) {
    if (isValid(item)) {
        result.push(transform(item));
    }
}
```

**Current Output (Non-idiomatic):**
```elixir
result = []
result = Enum.reduce(items, result, fn item, result ->
  if is_valid(item) do
    result ++ [transform(item)]
  else
    result
  end
end)
```

**Target Output (Idiomatic):**
```elixir
result = items
  |> Enum.filter(&is_valid/1)
  |> Enum.map(&transform/1)
```

**Transformation Rule:**
- Detect: Array building with filtering and transformation
- Transform: Pipeline of Enum functions
- AST Metadata: `{collectionOp: "filter_map", usePipeline: true}`

#### Pattern 6.2: Find First Match
**Haxe Input:**
```haxe
for (item in items) {
    if (matches(item)) {
        return item;
    }
}
return null;
```

**Current Output (Non-idiomatic):**
```elixir
result = Enum.reduce_while(items, nil, fn item, _ ->
  if matches(item) do
    {:halt, item}
  else
    {:cont, nil}
  end
end)
```

**Target Output (Idiomatic):**
```elixir
Enum.find(items, &matches/1)
```

**Transformation Rule:**
- Detect: Early return in loop (find pattern)
- Transform: Enum.find
- AST Metadata: `{collectionOp: "find", hasEarlyReturn: true}`

### 7. Module and Type Definitions

#### Pattern 7.1: Implementation Module Names
**Haxe Input:**
```haxe
abstract Email(String) { ... }
```

**Current Output (Non-idiomatic):**
```elixir
defmodule Email_Impl_ do
  ...
end
```

**Target Output (Idiomatic):**
```elixir
defmodule Email do
  ...
end
```

**Transformation Rule:**
- Detect: _Impl_ suffix in module names
- Transform: Remove implementation suffix
- AST Metadata: `{moduleType: "abstract", cleanName: true}`

#### Pattern 7.2: Type Conversions
**Haxe Input:**
```haxe
Std.string(value)
Std.int(floatValue)
```

**Current Output (Non-idiomatic):**
```elixir
Std.string(value)
Std.int(float_value)
```

**Target Output (Idiomatic):**
```elixir
"#{value}"
trunc(float_value)
```

**Transformation Rule:**
- Detect: Std type conversion calls
- Transform: Native Elixir conversions
- AST Metadata: `{stdCall: "conversion", useNative: true}`

### 8. Error Handling

#### Pattern 8.1: Try-Catch
**Haxe Input:**
```haxe
try {
    return riskyOperation();
} catch (e: Exception) {
    return defaultValue;
}
```

**Current Output (Non-idiomatic):**
```elixir
try do
  risky_operation()
rescue
  e ->
    default_value
end
```

**Target Output (Idiomatic):**
```elixir
case safe_risky_operation() do
  {:ok, result} -> result
  {:error, _reason} -> default_value
end
```

**Transformation Rule:**
- Detect: Try-catch for expected errors
- Transform: Result tuples with pattern matching
- AST Metadata: `{errorHandling: "expected", useResult: true}`

### 9. Function Definitions

#### Pattern 9.1: Default Parameters
**Haxe Input:**
```haxe
function greet(name = "World") {
    return "Hello " + name;
}
```

**Current Output (Non-idiomatic):**
```elixir
def greet(name \\ "World") do
  "Hello " <> name
end
```

**Target Output (Idiomatic):**
```elixir
def greet(name \\ "World") do
  "Hello #{name}"
end
```

**Transformation Rule:**
- Already handles defaults correctly, just fix string interpolation
- AST Metadata: `{hasDefaults: true}`

### 10. Special Elixir Idioms

#### Pattern 10.1: Pipeline Operations
**Haxe Input:**
```haxe
var result = transform3(transform2(transform1(data)));
```

**Current Output (Non-idiomatic):**
```elixir
result = transform3(transform2(transform1(data)))
```

**Target Output (Idiomatic):**
```elixir
result = data
  |> transform1()
  |> transform2()
  |> transform3()
```

**Transformation Rule:**
- Detect: Nested function calls (3+ levels)
- Transform: Pipeline operator
- AST Metadata: `{callDepth: 3, usePipeline: true}`

#### Pattern 10.2: With Statement for Sequential Operations
**Haxe Input:**
```haxe
var user = getUser(id);
if (user == null) return null;
var profile = getProfile(user);
if (profile == null) return null;
return formatProfile(profile);
```

**Current Output (Non-idiomatic):**
```elixir
user = get_user(id)
if user == nil do
  nil
else
  profile = get_profile(user)
  if profile == nil do
    nil
  else
    format_profile(profile)
  end
end
```

**Target Output (Idiomatic):**
```elixir
with {:ok, user} <- get_user(id),
     {:ok, profile} <- get_profile(user) do
  format_profile(profile)
else
  _ -> nil
end
```

**Transformation Rule:**
- Detect: Sequential nil checks with early returns
- Transform: With statement
- AST Metadata: `{pattern: "sequential_validation", useWith: true}`

## Implementation Priority

1. **Highest Impact** (Fix First):
   - Loop transformations (affects 40% of tests)
   - String interpolation (improves readability everywhere)
   - Pattern matching improvements (core to Elixir)

2. **Medium Impact**:
   - Variable naming (g, g1, g2 removal)
   - Conditional logic improvements
   - Collection operations

3. **Lower Impact** (Polish):
   - Module naming cleanup
   - Pipeline operators
   - With statements

## AST Transformation Pipeline

### Phase 1: Pattern Detection (ElixirASTBuilder)
- Analyze TypedExpr patterns
- Attach metadata to AST nodes
- Flag transformation opportunities

### Phase 2: Transformation (ElixirASTTransformer)
- Read metadata from Phase 1
- Apply transformation passes in order:
  1. LoopTransformationPass
  2. StringInterpolationPass
  3. PatternMatchingPass
  4. ConditionalLogicPass
  5. VariableNamingPass
  6. CollectionOperationPass

### Phase 3: Pretty Printing (ElixirASTPrinter)
- Generate clean Elixir syntax
- Handle indentation and formatting
- Ensure idiomatic spacing and layout

## Validation Checklist

For each pattern transformation:
- [ ] Preserves original semantics
- [ ] Generates valid Elixir syntax
- [ ] Follows Elixir community conventions
- [ ] Improves code readability
- [ ] Handles edge cases correctly
- [ ] Has test coverage

## References

- [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- [Programming Elixir](https://pragprog.com/titles/elixir16/programming-elixir-1-6/)
- [Elixir School](https://elixirschool.com/)
- [Credo - Elixir Code Analysis](https://github.com/rrrene/credo)

---

*Version: 1.0*  
*Last Updated: 2024-09-28*  
*Total Patterns Documented: 25+*