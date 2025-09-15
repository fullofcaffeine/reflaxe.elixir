# Test Output Patterns Documentation

## Non-Idiomatic Patterns to Fix

### 1. Loop Patterns
**Current (Non-idiomatic)**:
```elixir
# reduce_while for simple iteration
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, g, :ok}, fn _, {acc_fruits, acc_g, acc_state} ->
  if (acc_g < length(acc_fruits)) do
    fruit = acc_fruits[acc_g]
    # ...
  end
end)
```

**Target (Idiomatic)**:
```elixir
# For comprehension
for fruit <- fruits do
  IO.puts("Fruit: #{fruit}")
end

# With index
for {fruit, i} <- Enum.with_index(fruits) do
  IO.puts("#{i}: #{fruit}")
end
```

### 2. Logging/Output
**Current (Non-idiomatic)**:
```elixir
Log.trace(value, %{:file_name => "Main.hx", :line_number => 14, ...})
```

**Target (Idiomatic)**:
```elixir
IO.inspect(value)
IO.puts("Message: #{value}")
```

### 3. Enum Pattern Matching
**Current (Non-idiomatic)**:
```elixir
case (_color) do
  {:rgb, r, g, b} ->
    g = elem(_color, 1)
    g1 = elem(_color, 2)
    g2 = elem(_color, 3)
    r = g
    g = g1
    b = g2
    # use variables
end
```

**Target (Idiomatic)**:
```elixir
case color do
  {:rgb, r, g, b} ->
    # directly use r, g, b - they're already bound!
    "rgb(#{r}, #{g}, #{b})"
end
```

### 4. Variable Naming
**Current (Non-idiomatic)**:
- Generated names: `g`, `g1`, `g2`, `acc_g`, `acc_g1`
- Underscore prefixes when not needed: `_color`, `_opt`
- Redundant reassignments: `value = g`

**Target (Idiomatic)**:
- Meaningful names from pattern matches
- No underscore prefix unless intentionally unused
- Direct pattern extraction without intermediate variables

### 5. Array/List Access
**Current (Non-idiomatic)**:
```elixir
numbers[0]  # Direct bracket access
acc_fruits[acc_i]
```

**Target (Idiomatic)**:
```elixir
Enum.at(numbers, 0)  # Explicit Enum function
List.first(numbers)  # Or List functions
hd(numbers)  # Or kernel functions for head
```

### 6. String Concatenation
**Current (Non-idiomatic)**:
```elixir
"Popped: " <> Kernel.to_string(popped) <> ", Shifted: " <> Kernel.to_string(shifted)
```

**Target (Idiomatic)**:
```elixir
"Popped: #{popped}, Shifted: #{shifted}"  # String interpolation
```

## Categories Needing Updates

### High Priority (Core functionality)
1. **enums** - Has elem() calls and generated variables in intended output
2. **loops** - Likely has reduce_while patterns
3. **pattern_matching** - May have elem() instead of pattern extraction
4. **arrays** - Output has issues, but intended is already idiomatic

### Medium Priority (Framework features)
5. **classes** - Check for proper module structure
6. **functions** - Verify function definitions are idiomatic
7. **generics** - Ensure type parameters handled correctly

### Lower Priority (Already idiomatic or specialized)
- Tests that already have correct intended outputs
- Tests for specific compiler features that intentionally show non-idiomatic intermediate states

## Test Update Strategy

1. **Preserve test intent** - Don't change what the test is validating
2. **Fix only output format** - Make generated code look hand-written
3. **Keep minimal examples** - Don't add complexity to make it "more idiomatic"
4. **Document special cases** - Some tests may intentionally show compiler internals

## Baseline Metrics (Phase 0A - September 15, 2025)
- Total core tests: 66
- Tests updated to idiomatic patterns: 4
  - enums: Fixed elem() calls, pattern extraction, variable naming
  - loop_patterns: Replaced reduce_while with comprehensions
  - while_loops: Converted to proper Enum functions and recursion
  - pattern_matching: Fixed pattern extraction and guards
- Tests with non-idiomatic intended output: ~62 (estimated)
- Tests already idiomatic: arrays test (intended already correct)

## Updated Tests Summary

### enums Test
- **Before**: elem() calls, generated variables (g, g1, g2), complex reassignments
- **After**: Direct pattern matching, clean variable extraction

### loop_patterns Test
- **Before**: reduce_while with Stream.iterate for simple loops
- **After**: For comprehensions for filtering and mapping

### while_loops Test
- **Before**: reduce_while patterns simulating while loops
- **After**: Proper Enum functions, ranges, and reduce_while only when needed

### pattern_matching Test
- **Before**: elem() calls, redundant variable assignments
- **After**: Guards, proper pattern matching, idiomatic list patterns