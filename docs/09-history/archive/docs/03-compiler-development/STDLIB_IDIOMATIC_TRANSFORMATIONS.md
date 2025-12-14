# Standard Library Idiomatic Transformation Guide

## Overview

This document captures the specific transformations needed to make Haxe standard library implementations generate idiomatic Elixir code. These patterns were identified during Phase 0A of the AST refactoring and serve as targets for Phase 0B compiler improvements.

## Key Transformation Patterns

### 1. Loop Transformations

#### Pattern: reduce_while(Stream.iterate(...)) → Native Elixir Functions

**Non-idiomatic (Current):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, r, :ok}, fn _, {acc_s, acc_l, acc_r, acc_state} ->
  if (acc_r < acc_l && is_space(acc_s, acc_r)) do
    acc_r = acc_r + 1
    {:cont, {acc_s, acc_l, acc_r, acc_state}}
  else
    {:halt, {acc_s, acc_l, acc_r, acc_state}}
  end
end)
```

**Idiomatic (Target):**
```elixir
# For simple string operations
String.trim_leading(s)  # Instead of complex ltrim loop

# For iterating with index
Enum.with_index(list) |> Enum.each(fn {item, index} -> ... end)

# For building results
for item <- items, validate(item), do: transform(item)
```

**Compiler Implementation:**
- Detect Stream.iterate(0, ...) patterns in AST
- Analyze loop body to determine intent (side effects, accumulation, transformation)
- Replace with appropriate Elixir idiom

### 2. String Operations

#### Pattern: String Concatenation → Interpolation

**Non-idiomatic (Current):**
```elixir
pstr = infos.file_name <> ":" <> Kernel.to_string(infos.line_number)
result = "Hello " <> name <> ", age: " <> Std.string(age)
```

**Idiomatic (Target):**
```elixir
pstr = "#{infos.file_name}:#{infos.line_number}"
result = "Hello #{name}, age: #{age}"
```

**Compiler Implementation:**
- In StringInterpolationPass, detect consecutive `<>` operations
- Convert to single interpolated string with `#{}` placeholders
- Handle type conversions automatically within interpolation

### 3. Recursive Tree Operations

#### Pattern: reduce_while for Trees → Recursive Functions

**Non-idiomatic (Current):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {node, :ok}, fn _, {acc_node, acc_state} ->
  if (acc_node != nil) do
    c = compare(key, acc_node.key)
    if (c == 0), do: acc_node.value
    # ... complex navigation logic
  end
end)
```

**Idiomatic (Target):**
```elixir
defp find_node(nil, _key, _compare_fn), do: nil
defp find_node(node, key, compare_fn) do
  case compare_fn.(key, node.key) do
    0 -> node.value
    x when x < 0 -> find_node(node.left, key, compare_fn)
    _ -> find_node(node.right, key, compare_fn)
  end
end
```

**Compiler Implementation:**
- Detect tree/graph traversal patterns (recursive data structures)
- Convert iterative loops to recursive helper functions
- Use pattern matching for nil checks

### 4. URL Encoding/Decoding

#### Pattern: Character Processing Loops → Pipeline Operations

**Non-idiomatic (Current):**
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, result, g, :ok}, fn _, acc ->
  # Complex character-by-character processing
end)
```

**Idiomatic (Target):**
```elixir
s
|> String.to_charlist()
|> Enum.map(fn c ->
  if c in ?A..?Z or c in ?a..?z or c in ?0..?9 or c in [?-, ?_, ?., ?~] do
    <<c>>
  else
    "%#{Integer.to_string(c, 16) |> String.upcase()}"
  end
end)
|> IO.iodata_to_binary()
```

**Compiler Implementation:**
- Detect string character iteration patterns
- Convert to String.to_charlist() + Enum operations
- Use IO.iodata_to_binary() for efficient string building

### 5. Padding Operations

#### Pattern: Loops for Padding → String.duplicate/pad_leading/pad_trailing

**Non-idiomatic (Current):**
```elixir
buf = ""
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {l, buf, s, :ok}, fn _, acc ->
  # Loop to build padding
end)
```

**Idiomatic (Target):**
```elixir
def lpad(s, c, l) do
  current_length = String.length(s)
  if current_length >= l or String.length(c) == 0 do
    s
  else
    padding_needed = l - current_length
    padding = String.duplicate(c, div(padding_needed, String.length(c)) + 1)
    String.slice(padding, 0, padding_needed) <> s
  end
end

# Or even simpler for single-char padding:
String.pad_leading(s, l, c)
```

### 6. Parsing Operations

#### Pattern: Manual Parsing Loops → Built-in Parse Functions

**Non-idiomatic (Current):**
```elixir
# Complex manual hex parsing with reduce_while
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g, g1, :ok}, fn _, acc ->
  # Manual character-by-character parsing
end)
```

**Idiomatic (Target):**
```elixir
def parse_int(str) do
  cond do
    String.starts_with?(str, "0x") or String.starts_with?(str, "0X") ->
      hex_part = String.slice(str, 2..-1)
      case Integer.parse(hex_part, 16) do
        {value, ""} -> value
        _ -> nil
      end
    true ->
      case Integer.parse(str) do
        {value, ""} -> value
        _ -> nil
      end
  end
end
```

### 7. Collection Building

#### Pattern: Accumulator Loops → List Building with Recursion

**Non-idiomatic (Current):**
```elixir
acc = []
Enum.reduce_while(..., {acc, ...}, fn _, {acc, ...} ->
  acc = acc ++ [item]
  ...
end)
```

**Idiomatic (Target):**
```elixir
defp collect_items([], acc), do: Enum.reverse(acc)
defp collect_items([head | tail], acc) do
  collect_items(tail, [process(head) | acc])
end

# Or use comprehension:
for item <- items, do: process(item)
```

## AST Transformation Implementation Strategy

### Phase 1: Pattern Detection in ElixirASTBuilder

Add metadata to identify transformation opportunities:

```haxe
case TWhile(cond, body, doWhile):
    var node = buildWhileNode(cond, body, doWhile);

    // Detect patterns
    if (isStreamIteratePattern(cond)) {
        node.metadata.loopPattern = "stream_iterate";
        node.metadata.loopIntent = analyzeLoopIntent(body);
    }

    return node;
```

### Phase 2: Transformation Passes in ElixirASTTransformer

Create specialized passes for each pattern:

1. **LoopIdiomPass**: Transform reduce_while patterns
2. **StringInterpolationPass**: Convert concatenation to interpolation
3. **RecursionPass**: Convert iterative tree operations to recursion
4. **CollectionPass**: Optimize collection building patterns
5. **ParsingPass**: Use built-in parse functions

### Phase 3: Testing Against Idiomatic Output

For each stdlib file, create tests that verify:
1. Compilation succeeds
2. Generated code matches idiomatic patterns
3. Functionality is preserved

## Priority Order for Implementation

1. **High Priority** (Most common, biggest impact):
   - String interpolation (appears everywhere)
   - Simple loop transformations (Enum.each, ranges)
   - Basic collection operations

2. **Medium Priority** (Common in stdlib):
   - Tree/recursive operations
   - Parsing functions
   - String manipulation (trim, pad)

3. **Lower Priority** (Specialized):
   - URL encoding/decoding
   - Complex accumulator patterns
   - Advanced tree balancing

## Success Metrics

- **Before**: 100% of stdlib files use reduce_while(Stream.iterate(...))
- **After**: 0% use this pattern, replaced with idiomatic alternatives
- **Before**: String concatenation with `<>` throughout
- **After**: String interpolation with `#{}` where appropriate
- **Before**: Generated variable names (g, g1, g2)
- **After**: Meaningful names or underscores for unused variables

## Next Steps

1. Implement pattern detection in ElixirASTBuilder
2. Create transformation passes in order of priority
3. Test each transformation against the idiomatic examples
4. Update snapshot tests to expect idiomatic output
5. Document any edge cases or limitations discovered

---

This guide serves as the blueprint for making the Reflaxe.Elixir compiler generate truly idiomatic Elixir code for standard library implementations.