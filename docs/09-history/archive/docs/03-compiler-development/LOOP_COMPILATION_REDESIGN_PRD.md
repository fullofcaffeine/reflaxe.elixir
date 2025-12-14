# Loop Compilation Redesign PRD
## Pattern-Based Intent Recognition for Idiomatic Elixir Generation

**Version**: 1.0  
**Date**: 2024-12-25  
**Status**: Draft  
**Author**: Compiler Team

---

## Executive Summary

This PRD outlines a fundamental redesign of the Reflaxe.Elixir loop compilation strategy. Instead of mechanically translating loop syntax using complex recursive patterns (Y-combinators, self-passing functions), we will implement a pattern-based approach that recognizes loop **intent** and generates the appropriate idiomatic Elixir construct.

**Key Principle**: Don't translate the STRUCTURE, translate the BEHAVIOR.

---

## Problem Statement

### Current Issues

1. **Non-Idiomatic Code Generation**
   - Current approach generates complex Y-combinator patterns
   - Anonymous recursive functions with scope issues
   - Generated code doesn't look like what Elixir developers write

2. **Technical Debt**
   - Complex helper functions for variable dependency tracking
   - Brittle variable initialization logic
   - Difficult to maintain and debug

3. **Performance Concerns**
   - Custom recursion instead of optimized BEAM built-ins
   - Unnecessary overhead from generic abstractions

4. **Scope Errors**
   - Anonymous functions can't self-reference in Elixir
   - Led to increasingly complex workarounds

### Root Cause

We've been trying to create generic loop constructs in a language that intentionally doesn't have them. Elixir provides specific, optimized constructs for different iteration patterns instead.

---

## Proposed Solution

### Core Architecture: Pattern-Based Translation

Instead of generic loop compilation, implement a pattern recognition system that:

1. **Analyzes loop intent** - What is this loop trying to accomplish?
2. **Matches to patterns** - Which Elixir construct best fits this intent?
3. **Generates idiomatic code** - Produce what an Elixir expert would write

### Pattern Catalog

#### 1. Indexed Array Iteration
**Detection**: Counter variable, array access by index, increment pattern  
**Translation**: `Enum.with_index/1`

```haxe
// Input (Haxe)
for (i in 0...array.length) {
    process(array[i], i);
}
```

```elixir
# Output (Elixir)
array
|> Enum.with_index()
|> Enum.each(fn {item, index} ->
    process(item, index)
end)
```

#### 2. Character Iteration
**Detection**: String length check, charAt/cca calls  
**Translation**: Binary pattern matching

```haxe
// Input (Haxe)
for (i in 0...s.length) {
    var char = s.charAt(i);
    processChar(char);
}
```

```elixir
# Output (Elixir)
for <<char <- s>> do
    process_char(char)
end
```

#### 3. Collection Filtering & Mapping
**Detection**: Conditional push to new array  
**Translation**: `Enum.filter/2` + `Enum.map/2`

```haxe
// Input (Haxe)
var result = [];
for (item in items) {
    if (check(item)) {
        result.push(transform(item));
    }
}
```

```elixir
# Output (Elixir)
items
|> Enum.filter(&check/1)
|> Enum.map(&transform/1)
```

#### 4. Accumulation/Reduction
**Detection**: Variable mutation with loop values  
**Translation**: `Enum.reduce/3`

```haxe
// Input (Haxe)
var sum = 0;
for (n in numbers) {
    sum += n;
}
```

```elixir
# Output (Elixir)
Enum.reduce(numbers, 0, fn n, sum -> sum + n end)
```

#### 5. Early Termination Search
**Detection**: Loop with return/break on condition  
**Translation**: `Enum.find/2` or `Enum.find_value/2`

```haxe
// Input (Haxe)
for (item in items) {
    if (matches(item)) {
        return item;
    }
}
```

```elixir
# Output (Elixir)
Enum.find(items, &matches/1)
```

#### 6. Range Iteration
**Detection**: Counter from A to B  
**Translation**: Range with `Enum.each/2`

```haxe
// Input (Haxe)
for (i in start...end) {
    doSomething(i);
}
```

```elixir
# Output (Elixir)
Enum.each(start..(end-1), &do_something/1)
```

#### 7. State Machine Loops
**Detection**: Complex state mutations, no clear pattern  
**Translation**: `Stream.unfold/2` or `Enum.reduce_while/3`

```haxe
// Input (Haxe)
while (state.active) {
    state = updateState(state);
}
```

```elixir
# Output (Elixir)
Stream.unfold(initial_state, fn state ->
    if state.active do
        new_state = update_state(state)
        {new_state, new_state}
    else
        nil
    end
end)
|> Enum.to_list()
|> List.last()
```

#### 8. Complex/Unknown Pattern (Fallback)
**Detection**: Doesn't match any known pattern  
**Translation**: Simple module-level recursive function

```elixir
# Output (Elixir)
# Generated at module level:
@doc false
defp loop_helper_XXX(state) do
    if condition(state) do
        new_state = process(state)
        loop_helper_XXX(new_state)
    else
        state
    end
end
```

---

## Implementation Plan

### Phase 1: Pattern Detection Engine
Create `LoopPatternDetector` class with methods:
- `detectIndexedIteration()`
- `detectCharacterIteration()`
- `detectCollectionBuilding()`
- `detectAccumulation()`
- `detectEarlyTermination()`
- `detectRangeIteration()`
- `detectStateMachine()`

### Phase 2: Pattern-Specific Generators
Create generator methods for each pattern:
- `generateEnumWithIndex()`
- `generateBinaryComprehension()`
- `generateFilterMap()`
- `generateReduce()`
- `generateFind()`
- `generateRangeEach()`
- `generateStreamUnfold()`
- `generateModuleHelper()`

### Phase 3: Integration
1. Update `LoopCompiler.compileFor()` to use pattern detection
2. Update `LoopCompiler.compileWhile()` to use pattern detection
3. Remove Y-combinator and complex recursive helpers
4. Remove variable dependency tracking (no longer needed)

### Phase 4: Testing
1. Verify JsonPrinter compiles correctly
2. Test all pattern types with unit tests
3. Performance benchmarks vs. current implementation
4. Full todo-app integration test

---

## Success Metrics

1. **Code Quality**
   - Generated code matches idiomatic Elixir patterns
   - No Y-combinator or self-passing functions
   - Readable without comments

2. **Performance**
   - Uses BEAM-optimized built-ins
   - Reduced compilation time
   - Smaller generated code size

3. **Maintainability**
   - Simpler compiler codebase
   - Clear pattern → translation mapping
   - Easier to add new patterns

4. **Correctness**
   - All existing tests pass
   - No scope errors
   - Proper tail-call optimization where needed

---

## Migration Strategy

1. **Parallel Implementation**
   - Build new pattern-based system alongside existing
   - Feature flag to switch between old/new

2. **Incremental Rollout**
   - Start with most common patterns (indexed iteration)
   - Fall back to module helpers for complex cases
   - Gradually expand pattern recognition

3. **Compatibility**
   - Ensure generated code behavior remains identical
   - Maintain API compatibility

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Pattern misidentification | Wrong code generation | Comprehensive pattern tests, conservative fallback |
| Missing edge cases | Compilation errors | Extensive test suite, gradual rollout |
| Performance regression | Slower code | Benchmark before/after, use BEAM built-ins |
| Breaking changes | User code fails | Feature flag, compatibility mode |

---

## Design Decisions

### Why Not Generic Loop Constructs?

Elixir intentionally lacks generic loops because:
1. Specific constructs are more expressive
2. Pattern matching enables optimization
3. Functional approach prevents common bugs
4. BEAM VM optimizes known patterns

### Why Pattern-Based?

1. **Natural fit**: Each Haxe loop pattern has a natural Elixir equivalent
2. **Performance**: Leverages optimized BEAM functions
3. **Readability**: Generated code looks hand-written
4. **Maintainability**: Clear, isolated transformations

### Module Helpers vs. Anonymous Functions

For complex patterns, module-level helpers are preferred because:
1. No scope issues with self-reference
2. Easier to debug (named functions in stack traces)
3. Can be marked with `@doc false` to hide from docs
4. Natural tail-call optimization

---

## Examples

### Before (Current Y-Combinator Approach)
```elixir
(
  while_loop = fn condition_fn, body_fn ->
    if condition_fn.() do
      body_fn.()
      while_loop.(condition_fn, body_fn)  # ERROR: undefined
    else
      nil
    end
  end
  
  while_loop.(fn -> i < length end, fn ->
    process(array[i])
    i = i + 1
  end)
)
```

### After (Pattern-Based Approach)
```elixir
array
|> Enum.with_index()
|> Enum.each(fn {item, i} ->
  process(item)
end)
```

---

## Appendix

### A. Elixir Iteration Constructs Reference

- `Enum.each/2` - Side effects, no return value
- `Enum.map/2` - Transform each element
- `Enum.filter/2` - Select elements by predicate
- `Enum.reduce/3` - Accumulate a value
- `Enum.reduce_while/3` - Reduce with early termination
- `Enum.find/2` - Find first matching element
- `Enum.with_index/1` - Add indices to elements
- `Stream.unfold/2` - Generate values from state
- `Stream.iterate/2` - Infinite iteration from initial value
- `for` comprehensions - Multiple generators and filters

### B. Pattern Detection Heuristics

1. **Index increment**: `i++`, `i = i + 1`, `i += 1`
2. **Array access**: `array[i]`, `array.get(i)`
3. **String character**: `s.charAt(i)`, `s.cca(i)`
4. **Collection building**: `result.push()`, `result.add()`
5. **Early exit**: `return`, `break`
6. **State mutation**: Multiple variable assignments

### C. References

- [Elixir Recursion Guide](https://hexdocs.pm/elixir/recursion.html)
- [Enum Module Documentation](https://hexdocs.pm/elixir/Enum.html)
- [Stream Module Documentation](https://hexdocs.pm/elixir/Stream.html)
- [Elixir Forum: Recursive Anonymous Functions](https://elixirforum.com/t/recursive-anonymous-functions/18421)

---

## Approval

This PRD requires approval from:
- [ ] Compiler Team Lead
- [ ] Architecture Review Board
- [ ] QA Team

**Next Steps**: Upon approval, create detailed technical design document and implementation tickets.