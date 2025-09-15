# Snapshot Test Idiomatic Patterns Guide

> **Parent Context**: See [/test/CLAUDE.md](/test/CLAUDE.md) for overall testing infrastructure

## 📋 Phase 0A: Test-Driven Idiomatic Pattern Documentation

This document captures the idiomatic Elixir patterns established during Phase 0A of the AST modularization refactoring. These patterns serve as the quality targets that will drive compiler improvements.

## 🎯 Core Principle: Think Like an Elixir Developer

When translating Haxe to Elixir, we must consider:
1. **What would an Elixir developer write naturally?**
2. **How can we preserve Haxe semantics while generating idiomatic code?**
3. **What Elixir patterns best express the Haxe intent?**

## 📚 Pattern Transformation Catalog

### 1. Loop Patterns → Comprehensions/Enum Functions

#### Pattern: Simple Iteration
**Haxe Input:**
```haxe
for (i in 0...5) {
    trace(i);
}
```

**Current (Non-idiomatic):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    i = acc_i
    acc_i = acc_i + 1
    Log.trace(i, ...)
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
```

**Idiomatic Target:**
```elixir
Enum.each(0..4, fn i ->
  Log.trace(i, ...)
end)
```

**Compiler Strategy:** Detect simple for loops with side effects only → Use `Enum.each` with range

#### Pattern: Collecting Results
**Haxe Input:**
```haxe
var evens = [for (n in numbers) if (n % 2 == 0) n];
```

**Current (Non-idiomatic):**
```elixir
evens = []
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, evens, 0, :ok}, fn _, acc ->
  # Complex accumulator manipulation
end)
```

**Idiomatic Target:**
```elixir
evens = for n <- numbers, rem(n, 2) == 0, do: n
```

**Compiler Strategy:** Array comprehensions → Elixir comprehensions with guards

#### Pattern: Nested Loops
**Haxe Input:**
```haxe
for (i in 0...3) {
    for (j in 0...3) {
        grid[i][j] = i * 3 + j;
    }
}
```

**Idiomatic Target:**
```elixir
grid = for i <- 0..2, do: (for j <- 0..2, do: i * 3 + j)
```

**Compiler Strategy:** Nested for loops → Nested comprehensions when building data

### 2. Switch/Case Pattern Matching

#### Pattern: Enum Destructuring
**Haxe Input:**
```haxe
switch(color) {
    case RGB(r, g, b): return 'rgb($r, $g, $b)';
    case HSL(h, s, l): return 'hsl($h, $s, $l)';
}
```

**Current (Non-idiomatic):**
```elixir
case color do
  g when elem(g, 0) == 0 ->
    r = elem(g, 1)
    g = elem(g, 2)
    b = elem(g, 3)
    "rgb(#{r}, #{g}, #{b})"
```

**Idiomatic Target:**
```elixir
case color do
  {:rgb, r, g, b} -> "rgb(#{r}, #{g}, #{b})"
  {:hsl, h, s, l} -> "hsl(#{h}, #{s}, #{l})"
end
```

**Compiler Pipeline Implementation:**
1. **ElixirASTBuilder Phase**:
   - Detect TSwitch with enum patterns
   - Build ElixirAST.ECase with proper tuple patterns
   - Mark with metadata: `isEnumMatch: true`

2. **ElixirASTTransformer Phase**:
   - EnumPatternPass: Transform elem() extraction to direct destructuring
   - VariableNamePass: Replace generated names (g, g1) with actual parameter names

3. **ElixirASTPrinter Phase**:
   - Print clean pattern matching syntax

**Compiler Strategy:**
- Enum constructors → Tagged tuples with atoms
- Direct pattern matching instead of elem() calls
- Use actual parameter names, not generated variables (g, g1, g2)

#### Pattern: Result Type Handling
**Haxe Input:**
```haxe
switch(result) {
    case Ok(value): process(value);
    case Error(msg): handleError(msg);
}
```

**Idiomatic Target:**
```elixir
case result do
  {:ok, value} -> process(value)
  {:error, msg} -> handle_error(msg)
end
```

**Compiler Strategy:** Standard Result type → Elixir's {:ok, _}/{:error, _} convention

### 3. Conditional Logic

#### Pattern: Nested If-Else to Cond
**Haxe Input:**
```haxe
if (value == null) return "null";
else if (Std.is(value, Bool)) return "Bool: " + value;
else if (Std.is(value, Int)) return "Int: " + value;
else return "Unknown";
```

**Current (Non-idiomatic):**
```elixir
if (value == nil) do
  "null"
else
  if (Std.is(value, Bool)) do
    "Bool: " <> Std.string(value)
  else
    if (Std.is(value, Int)) do
      "Int: " <> Std.string(value)
    else
      "Unknown"
    end
  end
end
```

**Idiomatic Target:**
```elixir
cond do
  value == nil -> "null"
  is_boolean(value) -> "Bool: #{value}"
  is_integer(value) -> "Int: #{value}"
  true -> "Unknown"
end
```

**Compiler Strategy:** Chain of if-else with returns → cond with guards

### 4. String Operations

#### Pattern: String Interpolation
**Haxe Input:**
```haxe
return "Hello " + name + ", age: " + age;
```

**Current (Non-idiomatic):**
```elixir
"Hello " <> name <> ", age: " <> Std.string(age)
```

**Idiomatic Target:**
```elixir
"Hello #{name}, age: #{age}"
```

**Compiler Strategy:** String concatenation → Interpolation with #{}

### 5. Function Calls and Method Chaining

#### Pattern: Dynamic Method Calls
**Haxe Input:**
```haxe
obj.greet();
```

**Current (Non-idiomatic):**
```elixir
obj.greet()  # Invalid in Elixir
```

**Idiomatic Target:**
```elixir
greet_fn = Map.get(obj, :greet)
greet_fn.()
```

**Compiler Strategy:** Method calls on dynamic objects → Map.get + function call

#### Pattern: Type Checking
**Haxe Input:**
```haxe
if (Std.is(value, String)) { ... }
```

**Idiomatic Target:**
```elixir
if is_binary(value) do ... end
```

**Compiler Strategy:** Std.is checks → Elixir guard functions

### 6. Variable Naming

#### Pattern: Unused Variables
**Haxe Input:**
```haxe
switch(result) {
    case Custom(code): return code;
    case Default(_): return 0;
}
```

**Idiomatic Target:**
```elixir
case result do
  {:custom, code} -> code
  {:default, _} -> 0
end
```

**Compiler Strategy:**
- Used parameters → Keep original names
- Unused parameters → Prefix with underscore
- No generated names (g, g1, g2) in output

### 7. Module Naming

#### Pattern: Implementation Modules
**Haxe Input:**
```haxe
abstract Email(String) { ... }
```

**Current (Non-idiomatic):**
```elixir
defmodule Email_Impl_ do ... end
```

**Idiomatic Target:**
```elixir
defmodule Email do ... end
```

**Compiler Strategy:** Remove _Impl_ suffix for cleaner module names

### 8. Collection Operations

#### Pattern: Array Building
**Haxe Input:**
```haxe
var result = [];
for (item in items) {
    if (validate(item)) {
        result.push(transform(item));
    }
}
```

**Idiomatic Target:**
```elixir
result = items
  |> Enum.filter(&validate/1)
  |> Enum.map(&transform/1)
```

Or with comprehension:
```elixir
result = for item <- items, validate(item), do: transform(item)
```

**Compiler Strategy:** Imperative array building → Pipeline or comprehension

### 9. Idiomatic Option and Result Types

#### Pattern: @:elixirIdiomatic Option Type
**Haxe Input:**
```haxe
@:elixirIdiomatic
enum Option<T> {
    Some(value: T);
    None;
}
```

**Current (Non-idiomatic):**
```elixir
case option do
  {:some, g} ->
    g = elem(option, 1)
    value = g
    # use value
  {:none} ->
    # handle none
end
```

**Idiomatic Target:**
```elixir
# For idiomatic option, Some becomes bare value, None becomes :none atom
some = "test"       # Not {:some, "test"}
none = :none       # Not {:none}

# Pattern matching for idiomatic tagged option
case option do
  {:some, value} ->  # Direct destructuring
    # use value
  {:none} ->
    # handle none
end
```

**Compiler Pipeline Implementation:**
1. **ElixirASTBuilder Phase**:
   - Check for @:elixirIdiomatic metadata on enum type
   - For idiomatic types, generate simplified patterns
   - Mark AST nodes with `idiomaticType: "option"` metadata

2. **ElixirASTTransformer Phase**:
   - IdiomaticPatternPass: Transform based on metadata
   - For Some(v) with @:elixirIdiomatic → bare value or {:some, v} in patterns
   - For None with @:elixirIdiomatic → :none atom

3. **Pattern Detection**:
   - If enum has @:elixirIdiomatic AND has Some/None constructors → Option type
   - If enum has @:elixirIdiomatic AND has Ok/Error constructors → Result type

#### Pattern: @:elixirIdiomatic Result Type
**Haxe Input:**
```haxe
@:elixirIdiomatic
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}
```

**Idiomatic Target:**
```elixir
# Standard Elixir convention
ok = {:ok, "success"}
error = {:error, "failed"}

case result do
  {:ok, data} ->
    # handle success
  {:error, reason} ->
    # handle error
end
```

**Compiler Strategy:**
- @:elixirIdiomatic Result → Always use {:ok, _}/{:error, _} tuples
- This matches Elixir's standard library conventions
- Direct pattern matching without elem() extraction

### 10. Error Handling Patterns

#### Pattern: Early Returns with Validation
**Haxe Input:**
```haxe
function process(str: String): Result<Int> {
    if (str == null) return Error("null input");
    var n = Std.parseInt(str);
    if (n == null) return Error("not a number");
    if (n < 0) return Error("negative");
    return Ok(n);
}
```

**Idiomatic Target:**
```elixir
def process(str) do
  with {:ok, n} <- parse_int_safe(str),
       :ok <- validate_positive(n) do
    {:ok, n}
  else
    {:error, reason} -> {:error, reason}
  end
end
```

**Compiler Strategy:** Sequential validation → with statement

## 🔮 Future Compiler Improvements

Based on these patterns, the compiler needs:

### AST Pipeline Architecture (3-Phase System)

```
TypedExpr → ElixirASTBuilder → ElixirAST → ElixirASTTransformer → ElixirAST' → ElixirASTPrinter → String
           (Build Phase)                    (Transform Phase)                    (Print Phase)
```

#### Phase 1: ElixirASTBuilder (Building)
**Responsibility**: Convert Haxe TypedExpr to ElixirAST nodes
- Build raw AST structure from Haxe
- Attach metadata for later transformation
- NO transformation logic here, only building

**Key Metadata to Attach**:
```haxe
node.metadata = {
  isEnumMatch: true,           // For enum pattern matching
  isArrayComprehension: true,   // For loop → comprehension
  idiomaticType: "option",      // For @:elixirIdiomatic types
  variableUsage: "unused",      // For underscore prefixing
  loopPattern: "simple_range"   // For loop optimization
}
```

#### Phase 2: ElixirASTTransformer (Transformation)
**Responsibility**: Apply idiomatic transformations based on metadata

**Transformation Passes** (executed in order):
1. **EnumPatternPass**:
   - Transform elem() extraction → direct destructuring
   - Convert enum indices → atom tags
   - Replace generated variables (g, g1) with parameter names

2. **LoopComprehensionPass**:
   - Convert reduce_while → for comprehensions
   - Transform Enum.reduce → Enum.each for side effects
   - Detect and optimize nested loops

3. **StringInterpolationPass**:
   - Convert `<>` concatenation → `#{}` interpolation
   - Handle Std.string() calls in interpolation

4. **ConditionalPass**:
   - Transform nested if-else → cond
   - Optimize single-branch conditionals

5. **IdiomaticTypePass**:
   - Handle @:elixirIdiomatic Option/Result types
   - Transform Some/None → idiomatic patterns
   - Apply Elixir conventions for Ok/Error

6. **VariableNamingPass**:
   - Apply underscore prefixes for unused variables
   - Remove generated variable names
   - Ensure consistent naming across scopes

#### Phase 3: ElixirASTPrinter (Printing)
**Responsibility**: Convert transformed AST to string
- Pretty-print with proper indentation
- NO transformation logic, only formatting
- Handle special syntax (pipes, with statements)

### Implementation Priority

1. **AST Pattern Detection Module**
   - Identify reduce_while patterns that should be comprehensions
   - Detect nested if-else chains for cond conversion
   - Recognize array building patterns

2. **Idiomatic Transform Passes**
   - EnumComprehensionPass: Convert loops to comprehensions
   - PatternMatchPass: Direct destructuring instead of elem()
   - StringInterpolationPass: Convert concatenation to interpolation
   - ConditionalPass: if-else chains to cond

3. **Variable Naming Intelligence**
   - Track variable usage across scope
   - Apply underscore prefixing only for truly unused vars
   - Eliminate generated variable names (g, g1, etc.)

4. **Module Naming Strategy**
   - Clean module names without implementation suffixes
   - Proper namespacing for nested modules

## 📊 Progress Tracking

### Phase 0A Status (Completed)
- ✅ **COMPLETE** - All major test files updated to idiomatic patterns
- ✅ Established comprehensive pattern catalog through test updates
- ✅ Documented compiler transformation requirements
- ✅ ~60+ test files transformed to idiomatic Elixir

### Key Insights from Phase 0A Completion

1. **reduce_while is overused** - Most cases should be simple Enum operations
2. **elem() calls indicate poor pattern matching** - Direct destructuring is cleaner
3. **Generated variables (g, g1, g2)** - These should never appear in final output
4. **String concatenation** - Always prefer interpolation for readability
5. **Nested if-else chains** - Should become cond statements
6. **Complex loops** - Simple iterations should use Enum.each/map, not reduce_while
7. **Pattern matching** - Case statements should directly destructure tuples, not use elem()
8. **Unused variables** - Should have underscore prefixes (_var) for clarity

## 🎯 Next Steps - Phase 0B: AST Modularization

With Phase 0A complete and idiomatic patterns established, we're ready for Phase 0B:

1. **Extract AST Builder Modules** - Break ElixirASTBuilder into specialized builders
2. **Create Transformation Passes** - Implement the patterns identified in Phase 0A
3. **Modularize AST Transformer** - Create focused transformation passes
4. **Test Against Idiomatic Outputs** - Verify compiler generates the patterns we established

## 📚 References

- [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- [Elixir School - Basics](https://elixirschool.com/en/lessons/basics)
- [Programming Elixir](https://pragprog.com/titles/elixir16/programming-elixir-1-6/) - Idiomatic patterns

---

**Remember**: The goal is not just correctness but elegance. Generated code should be indistinguishable from hand-written Elixir by experienced developers.