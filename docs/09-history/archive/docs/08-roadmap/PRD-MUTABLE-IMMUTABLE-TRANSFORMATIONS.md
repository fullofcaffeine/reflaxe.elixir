# Product Requirements Document: Mutable-to-Immutable Code Transformations

## Executive Summary

This PRD defines the strategic approach for Reflaxe.Elixir to handle mutable code patterns from Haxe's standard library and transform them into idiomatic, immutable Elixir patterns. The goal is to support cross-platform Haxe development while encouraging functional programming paradigms, without relying on workarounds or band-aid fixes.

## Vision & Philosophy

### Dual-Paradigm Support Philosophy

**Core Principle**: Reflaxe.Elixir embraces a dual-paradigm philosophy that balances cross-platform compatibility with idiomatic target code generation.

#### Primary Goal: Encourage Functional Paradigms
- **Haxe developers writing for Elixir** should naturally adopt functional, immutable patterns
- **Generated code** should look like it was written by an Elixir expert
- **Phoenix applications** should use Elixir-native constructs and APIs by default
- **1:1 paradigm translation** when developers write functional Haxe code

#### Secondary Goal: Enable Cross-Platform Development  
- **Support Haxe standard library** for true cross-platform code portability
- **Transform mutable patterns** safely to immutable equivalents
- **Maintain semantic equivalence** while adapting to target platform constraints
- **Zero runtime overhead** through compile-time transformations

### Pragmatic Implementation Strategy: Native Elixir with Type Safety

**NEW APPROACH**: Leverage `__elixir__()` for efficient standard library implementation rather than pure Haxe transformations.

#### The `__elixir__()` Strategy
Instead of complex compile-time transformations, we can implement the Haxe standard library using native Elixir code wrapped in type-safe interfaces:

```haxe
// Type-safe Haxe interface with native Elixir implementation
@:coreApi
class StringBuf {
    var iodata: Dynamic;
    
    public function new() {
        // Direct Elixir IO list initialization
        iodata = untyped __elixir__('[]');
    }
    
    public function add(x: String): Void {
        // Native Elixir list append - efficient and idiomatic
        iodata = untyped __elixir__('$iodata ++ [$x]');
    }
    
    public function toString(): String {
        // Native IO.iodata_to_binary conversion
        return untyped __elixir__('IO.iodata_to_binary($iodata)');
    }
}
```

#### Benefits of Native Implementation
1. **Efficiency**: Direct use of Elixir's optimized data structures (IO lists, ETS, etc.)
2. **Idiomatic Code**: Generated code uses native Elixir patterns
3. **Simplicity**: No complex transformation logic in the compiler
4. **Maintainability**: Clear, readable implementations
5. **Completeness**: Can support ALL Haxe stdlib features through native code
6. **Turing Complete**: Full computational capability guaranteed

#### Implementation Priority
1. **Native First**: Use `__elixir__()` for stdlib implementation
2. **Type Safety Wrapper**: All native code wrapped in typed Haxe interfaces  
3. **Cross-Platform API**: Standard Haxe API remains unchanged
4. **Progressive Enhancement**: Start with critical classes, expand coverage

### The "No Workarounds" Mandate

**Fundamental Rule**: Every transformation must be an industry-standard, well-established pattern. No ad-hoc fixes, no band-aids, no workarounds.

#### What This Means
- ✅ **State threading** - Well-established functional programming pattern
- ✅ **Accumulator patterns** - Standard approach in ML-family languages
- ✅ **IO lists** - Elixir's native efficient string building
- ❌ **String post-processing** - Not a transformation, just a patch
- ❌ **Temporary variables** - Symptom fixes, not solutions
- ❌ **Runtime conversion** - All transformations at compile-time

## Implementation Examples

### Example 1: JsonPrinter with Native Implementation

Instead of complex transformations, implement directly with `__elixir__()`:

```haxe
// Native Elixir implementation for JsonPrinter
package haxe.format;

@:coreApi
class JsonPrinter {
    var replacer: Dynamic;
    var space: String;
    
    public function new(replacer: Dynamic = null, space: String = null) {
        this.replacer = replacer;
        this.space = space;
    }
    
    public static function print(o: Dynamic, ?replacer: Dynamic, ?space: String): String {
        // Use native Jason library for efficient JSON encoding
        if (replacer != null || space != null) {
            // Custom printing with replacer/space
            return untyped __elixir__('
                JsonPrinter.custom_encode($o, $replacer, $space)
            ');
        } else {
            // Direct Jason encoding for performance
            return untyped __elixir__('Jason.encode!($o)');
        }
    }
}
```

### Example 2: Array Operations with Native Lists

```haxe
@:coreApi  
class Array<T> {
    var data: Dynamic;
    
    public function new() {
        data = untyped __elixir__('[]');
    }
    
    public function push(x: T): Int {
        data = untyped __elixir__('$data ++ [$x]');
        return untyped __elixir__('length($data)');
    }
    
    public function reverse(): Void {
        data = untyped __elixir__('Enum.reverse($data)');
    }
    
    public function map<S>(f: T -> S): Array<S> {
        var result = new Array<S>();
        result.data = untyped __elixir__('Enum.map($data, $f)');
        return result;
    }
}
```

## Problem Statement

### Current Challenges

1. **StringBuf Compilation Failures**
   - Mutable string building pattern incompatible with Elixir
   - Direct field mutations (`buf.b = buf.b + str`) cause syntax errors
   - Current approach generates invalid Elixir code

2. **Parameter Reference Mismatches**
   - Underscore-prefixed parameters (`_replacer`) not mapped in function bodies
   - Results in "undefined variable" errors at runtime
   - Breaks JSON printing and formatting utilities

3. **Struct Mutation Patterns**
   - Sequential reassignment + mutation fails in Elixir
   - Pattern: `struct = struct.field; struct.otherField = value`
   - Violates Elixir's immutability guarantees

4. **Testing Efficiency Issues**
   - Tests must complete in reasonable time (not hang or timeout)
   - Transformation overhead must not impact test performance
   - Need clear visibility into transformation behavior during tests

### Impact on Developers

- **Cross-platform developers** cannot use familiar Haxe patterns
- **Phoenix developers** get non-idiomatic generated code
- **Compiler maintainers** face increasing technical debt from workarounds
- **Test suites** become unreliable with hanging or slow transformations

## Requirements

### Functional Requirements

#### FR1: State Threading Transformation
**Priority**: P0 (Critical)

Transform mutable state modifications into functional state threading:

```haxe
// Input: Mutable pattern
var buf = new StringBuf();
buf.add("hello");
buf.add(" ");
buf.add("world");
return buf.toString();

// Output: State threading
buf1 = StringBuf.new()
buf2 = StringBuf.add(buf1, "hello")
buf3 = StringBuf.add(buf2, " ")
buf4 = StringBuf.add(buf3, "world")
StringBuf.to_string(buf4)
```

#### FR2: IO List Pattern for String Building
**Priority**: P0 (Critical)

Use Elixir's native IO lists for efficient string concatenation:

```haxe
// Input: StringBuf pattern
var buf = new StringBuf();
for (item in items) {
    buf.add(item.toString());
}

// Output: IO list accumulation
io_list = Enum.reduce(items, [], fn item, acc ->
  acc ++ [to_string(item)]
end)
IO.iodata_to_binary(io_list)
```

#### FR3: Accumulator Pattern for Collections
**Priority**: P0 (Critical)

Transform imperative collection building to functional accumulation:

```haxe
// Input: Imperative array building
var result = [];
for (item in items) {
    if (item.isValid()) {
        result.push(item.transform());
    }
}

// Output: Functional accumulation
Enum.reduce(items, [], fn item, acc ->
  if item.is_valid() do
    acc ++ [item.transform()]
  else
    acc
  end
end)
```

#### FR4: Parameter Mapping Consistency
**Priority**: P0 (Critical)

Ensure all parameter references are correctly mapped:
- Track parameter renaming (underscore prefixing)
- Maintain mapping throughout function body
- Support nested function contexts

#### FR5: Struct Update Syntax
**Priority**: P1 (High)

Transform struct mutations to Map.put or struct update syntax:

```haxe
// Input: Struct mutation
struct.field = value;

// Output: Functional update
struct = Map.put(struct, :field, value)
// OR for known structs:
struct = %{struct | field: value}
```

### Non-Functional Requirements

#### NFR1: Performance Requirements
**Priority**: P0 (Critical)

- **Compilation overhead**: < 10% increase in compilation time
- **Runtime performance**: No degradation vs hand-written Elixir
- **Memory efficiency**: Use Elixir's structural sharing
- **Test execution**: Tests must complete within normal timeframes
  - Unit tests: < 1 second per test
  - Integration tests: < 5 seconds per test
  - Full test suite: < 2 minutes total
  - No hanging or infinite loops in transformations

#### NFR2: Code Quality
**Priority**: P0 (Critical)

- **Idiomatic output**: Generated code indistinguishable from hand-written
- **Readability**: Clear variable naming and structure
- **Maintainability**: No temporary variables or complex nesting
- **Debugging**: Preserve source mapping for error tracking

#### NFR3: Developer Experience
**Priority**: P1 (High)

- **Transparent transformation**: Clear documentation of patterns
- **Predictable behavior**: Consistent transformation rules
- **Error messages**: Clear guidance when patterns cannot be transformed
- **Migration path**: Gradual adoption without breaking changes

#### NFR4: Testing Visibility
**Priority**: P0 (Critical)

- **Transformation tracing**: Debug mode to show transformations applied
- **Performance metrics**: Report transformation time per module
- **Test timeout detection**: Fail fast on hanging transformations
- **Progress indicators**: Show which transformations are running

## Technical Architecture

### Transformation Pipeline

```
AST Analysis → Pattern Detection → Transformation Selection → Code Generation
      ↓              ↓                     ↓                      ↓
   Identify      Match Against        Choose Best           Apply Transform
   Mutations     Pattern Library      Transformation          & Generate
```

### Pattern Detection Framework

#### Detection Components
1. **AST Pattern Matcher**: Identifies mutable patterns in typed AST
2. **Context Analyzer**: Determines scope and dependencies  
3. **Transformation Selector**: Chooses appropriate immutable pattern
4. **Code Generator**: Produces idiomatic Elixir output

#### Pattern Library

| Pattern | Detection | Transformation | Priority |
|---------|-----------|----------------|----------|
| StringBuf.add() | Sequential calls on same var | IO list accumulation | P0 |
| Array.push() | Mutation on local array | List prepend + reverse | P0 |
| field assignment | struct.field = value | Map.put or struct update | P0 |
| Loop accumulation | for + push/add | Enum.reduce | P1 |
| Conditional mutation | if + mutation | Pattern matching | P1 |

### Implementation Strategy

#### Phase 1: Core Transformations (Week 1-2)
- [ ] Implement state threading for StringBuf
- [ ] Add IO list transformation for string building
- [ ] Fix parameter mapping for underscore prefixes
- [ ] Add comprehensive test timeout detection

#### Phase 2: Collection Patterns (Week 2-3)
- [ ] Array mutation to list accumulation
- [ ] Map building patterns
- [ ] Set operations

#### Phase 3: Advanced Patterns (Week 3-4)
- [ ] Complex struct updates
- [ ] Nested transformations
- [ ] Performance optimizations
- [ ] Test performance benchmarking

#### Phase 4: Developer Experience (Week 4-5)
- [ ] Documentation generator
- [ ] Migration guide
- [ ] Error message improvements
- [ ] Performance profiling tools

## Success Metrics

### Objective Metrics
- **Compilation success rate**: 100% of Haxe stdlib patterns compile
- **Test completion rate**: 100% of tests complete without hanging
- **Test performance**: No test takes >5 seconds (excluding network operations)
- **Code quality**: 0 Elixir compiler warnings in generated code
- **Performance**: < 10% compilation overhead
- **Adoption**: Todo-app fully functional with transformations

### Subjective Metrics
- **Developer satisfaction**: Generated code looks hand-written
- **Maintainability**: No accumulation of technical debt
- **Learning curve**: Clear documentation enables quick adoption

## Testing Strategy

### Test Categories

#### Unit Tests
- Pattern detection accuracy
- Transformation correctness
- AST preservation
- Performance benchmarks
- Timeout detection (must fail within 1 second on hanging transform)

#### Integration Tests  
- Todo-app compilation and runtime
- Phoenix framework integration
- Cross-module transformations
- End-to-end scenarios
- Full application test (must complete within 30 seconds)

#### Performance Tests
- Compilation time regression tests
- Memory usage monitoring
- Generated code performance
- Test suite execution time
- Transformation overhead measurement

### Test Monitoring

```elixir
# Test timeout configuration
config :test_timeout,
  unit_test_timeout: 1_000,      # 1 second
  integration_test_timeout: 5_000, # 5 seconds
  suite_timeout: 120_000          # 2 minutes

# Performance tracking
defmodule TransformationProfiler do
  def profile(ast, transformation) do
    start_time = System.monotonic_time()
    
    # Set hard timeout
    task = Task.async(fn -> transformation.apply(ast) end)
    
    case Task.yield(task, 1000) || Task.shutdown(task) do
      {:ok, result} ->
        elapsed = System.monotonic_time() - start_time
        report_metrics(transformation, elapsed)
        result
        
      nil ->
        raise "Transformation timeout: #{transformation.name}"
    end
  end
end
```

## Risks & Mitigations

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Performance regression | High | Medium | Comprehensive benchmarking |
| Pattern detection failures | High | Low | Extensive test coverage |
| Breaking changes | High | Low | Gradual rollout with flags |
| Test timeouts | High | Medium | Timeout detection & fast-fail |
| Transformation loops | Critical | Low | Cycle detection in pipeline |

### Mitigation Strategies

1. **Feature Flags**: Enable gradual rollout of transformations
2. **Fallback Paths**: Emit warnings instead of failing on unknown patterns  
3. **Performance Gates**: Automatic rollback if performance degrades
4. **Test Timeouts**: Hard limits on transformation execution time
5. **Monitoring**: Real-time metrics on transformation behavior

## Documentation Requirements

### Developer Documentation
- **Transformation Patterns Guide**: Complete list of supported transformations
- **Migration Guide**: How to adapt existing code
- **Best Practices**: Writing transformation-friendly Haxe code
- **API Reference**: Transformation configuration options

### Internal Documentation
- **Architecture Overview**: How the transformation pipeline works
- **Pattern Detection**: Adding new pattern detectors
- **Testing Guide**: How to test transformations
- **Performance Guide**: Optimization techniques

## Timeline & Milestones

### Week 1-2: Foundation
- ✅ Complete PRD documentation (this document)
- [ ] Implement state threading for StringBuf
- [ ] Fix parameter mapping issues
- [ ] Add test timeout detection

### Week 2-3: Core Patterns
- [ ] IO list transformations
- [ ] Basic accumulator patterns
- [ ] Struct update transformations
- [ ] Performance benchmarking setup

### Week 3-4: Advanced Features
- [ ] Complex pattern combinations
- [ ] Optimization passes
- [ ] Edge case handling
- [ ] Test suite performance validation

### Week 4-5: Polish & Documentation
- [ ] Developer documentation
- [ ] Migration tooling
- [ ] Performance optimization
- [ ] Release preparation

## Appendix A: Industry-Standard Patterns

### State Threading (Monadic Style)
Used in: Haskell, OCaml, F#, Scala
```haskell
-- Haskell State Monad
modify (\s -> s { field = newValue })
```

### IO Lists (Efficient String Building)
Used in: Erlang, Elixir
```elixir
# Elixir IO List
["Hello", " ", "World"] |> IO.iodata_to_binary()
```

### Accumulator Pattern (Fold/Reduce)
Used in: All functional languages
```ocaml
(* OCaml *)
List.fold_left (fun acc x -> x :: acc) [] items
```

### Structural Sharing (Persistent Data Structures)
Used in: Clojure, Scala, Elixir
```clojure
; Clojure
(assoc map :key value)
```

## Appendix B: Test Performance Requirements

### Critical Test Performance Constraints

To ensure developer productivity and CI/CD pipeline efficiency:

1. **Unit Test Performance**
   - Maximum execution time: 1 second per test
   - Timeout threshold: 2 seconds (automatic failure)
   - Expected average: 100ms per test

2. **Integration Test Performance**  
   - Maximum execution time: 5 seconds per test
   - Timeout threshold: 10 seconds (automatic failure)
   - Expected average: 2 seconds per test

3. **Full Test Suite Performance**
   - Maximum execution time: 2 minutes total
   - Timeout threshold: 5 minutes (automatic failure)
   - Expected completion: < 90 seconds

4. **Transformation-Specific Metrics**
   - Pattern detection: < 10ms per module
   - Transformation application: < 50ms per module
   - Code generation: < 20ms per module
   - Total overhead: < 100ms per module

5. **Failure Modes**
   - Hanging transformation: Fail within 1 second
   - Infinite loop detection: Circuit breaker at 1000 iterations
   - Memory limit: 500MB per transformation
   - Stack depth: Maximum 100 levels

### Performance Monitoring Implementation

```elixir
defmodule TestPerformanceMonitor do
  @unit_test_timeout 1_000
  @integration_test_timeout 5_000
  @suite_timeout 120_000
  
  def run_with_timeout(test_fn, timeout \\ @unit_test_timeout) do
    task = Task.async(test_fn)
    
    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> 
        {:ok, result}
      nil -> 
        {:error, :timeout, "Test exceeded #{timeout}ms limit"}
    end
  end
  
  def monitor_suite(tests) do
    start = System.monotonic_time(:millisecond)
    
    results = Enum.map(tests, fn test ->
      if (System.monotonic_time(:millisecond) - start) > @suite_timeout do
        {:error, :suite_timeout}
      else
        run_with_timeout(test, get_timeout_for(test))
      end
    end)
    
    elapsed = System.monotonic_time(:millisecond) - start
    
    %{
      results: results,
      elapsed: elapsed,
      within_limit: elapsed < @suite_timeout
    }
  end
end
```

## Appendix C: References

- [Purely Functional Data Structures](https://www.cs.cmu.edu/~rwh/theses/okasaki.pdf) - Chris Okasaki
- [Elixir's IO Data](https://hexdocs.pm/elixir/IO.html#module-io-data)
- [State Threading in Functional Programming](https://wiki.haskell.org/State_Monad)
- [Persistent Data Structures](https://en.wikipedia.org/wiki/Persistent_data_structure)
- [The Expression Problem](http://homepages.inf.ed.ac.uk/wadler/papers/expression/expression.txt)

---

**Document Version**: 1.0.0  
**Last Updated**: January 2025  
**Status**: Draft for Review  
**Author**: Reflaxe.Elixir Team