# Functional Helpers Implementation Plan

## Overview
This document outlines the implementation plan for compiler-supported functional abstractions mentioned in the paradigm documentation.

## Priority 1: Core Functional Abstractions

### 1. Option/Maybe Type
**File**: `src/reflaxe/elixir/abstractions/Option.hx`
```haxe
enum Option<T> {
    Some(value: T);
    None;
}

// Static extension methods for functional operations
class OptionOps {
    public static function map<T, R>(opt: Option<T>, fn: T -> R): Option<R>;
    public static function flatMap<T, R>(opt: Option<T>, fn: T -> Option<R>): Option<R>;
    public static function filter<T>(opt: Option<T>, pred: T -> Bool): Option<T>;
    public static function getOrElse<T>(opt: Option<T>, defaultValue: T): T;
}
```

### 2. Result/Either Type
**File**: `src/reflaxe/elixir/abstractions/Result.hx`
```haxe
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class ResultOps {
    public static function map<T, R, E>(result: Result<T, E>, fn: T -> R): Result<R, E>;
    public static function mapError<T, E, F>(result: Result<T, E>, fn: E -> F): Result<T, F>;
    public static function andThen<T, R, E>(result: Result<T, E>, fn: T -> Result<R, E>): Result<R, E>;
}
```

## Priority 2: Macro-Based Helpers

### 1. Pipeline Operator Macro
**File**: `src/reflaxe/elixir/macro/PipelineMacro.hx`
- Enhance existing PipeOperator.hx to support `|>` syntax in Haxe
- Transform method chains to Elixir pipes automatically
- Add `@:pipeline` annotation for optimization hints

### 2. Functional Extensions Macro
**File**: `src/reflaxe/elixir/macro/FunctionalExtensions.hx`
```haxe
class FunctionalExtensions {
    public static macro function pipe<T, R>(value: ExprOf<T>, fn: ExprOf<T -> R>): ExprOf<R>;
    public static macro function tap<T>(value: ExprOf<T>, fn: ExprOf<T -> Void>): ExprOf<T>;
    public static macro function when<T>(value: ExprOf<T>, condition: ExprOf<Bool>, fn: ExprOf<T -> T>): ExprOf<T>;
}
```

### 3. With Statement Macro
**File**: `src/reflaxe/elixir/macro/WithMacro.hx`
- Support for Elixir's `with` statement pattern
- Type-safe error handling in pipelines

## Priority 3: Compiler Hints

### 1. Paradigm Warnings
**File**: `src/reflaxe/elixir/hints/ParadigmHints.hx`
- Detect inefficient imperative patterns
- Suggest functional alternatives
- Example: "Consider using Enum.map instead of loop+push"

### 2. Immutability Checker
**File**: `src/reflaxe/elixir/hints/ImmutabilityChecker.hx`
- Warn when trying to mutate in ways that won't work in Elixir
- Suggest using `final` for immutable bindings
- Detect array mutation anti-patterns

## Priority 4: GenServer/OTP Abstractions

### 1. Enhanced GenServer Support
**File**: `src/reflaxe/elixir/helpers/GenServerEnhanced.hx`
- Add `@:call`, `@:cast`, `@:info` annotations
- Generate proper handle_call/cast/info functions
- Type-safe message passing

### 2. Agent Abstraction
**File**: `src/reflaxe/elixir/abstractions/Agent.hx`
- Simple state management without full GenServer
- `@:agent` annotation for classes
- Automatic get/update function generation

### 3. Supervisor Abstraction
**File**: `src/reflaxe/elixir/abstractions/Supervisor.hx`
- `@:supervisor` annotation
- Child spec generation
- Strategy configuration

## Implementation Order

1. **Week 1**: Core functional types (Option, Result)
2. **Week 2**: Pipeline and functional extension macros  
3. **Week 3**: Compiler hints and warnings
4. **Week 4**: GenServer/OTP enhancements

## Testing Strategy

### Test Type Matrix for Functional Helpers

| Helper Type | Snapshot Test | Mix Test | Compile-Time Test | Why |
|------------|--------------|----------|------------------|-----|
| **Option/Result Types** | ✅ Primary | ✅ Secondary | ❌ | Test transformation + runtime behavior |
| **Pipeline Macros** | ✅ Primary | ✅ Verify | ✅ Error cases | Macro expansion + runtime correctness |
| **@:genserver** | ✅ Primary | ✅ Critical | ❌ | State management needs runtime validation |
| **Compiler Hints** | ❌ | ❌ | ✅ Primary | Warnings are compile-time only |
| **Static Extensions** | ✅ Primary | ✅ Secondary | ❌ | Method generation + usage |

### Specific Test Implementations

#### 1. Option/Result Types - Snapshot Tests
**Location**: `test/tests/functional_option/`
```haxe
// Main.hx
class Main {
    static function testOption() {
        var opt: Option<Int> = Some(42);
        var result = opt
            .map(x -> x * 2)
            .filter(x -> x > 50)
            .getOrElse(0);
        
        var none: Option<String> = None;
        var fallback = none.getOrElse("default");
    }
    
    static function testResult() {
        var result: Result<Int, String> = Ok(10);
        var processed = result
            .map(x -> x * 2)
            .andThen(validate)
            .mapError(e -> 'Error: $e');
    }
}
```

**Expected Output**: `intended/Main.ex`
```elixir
def test_option() do
  opt = {:some, 42}
  result = opt
    |> Option.map(fn x -> x * 2 end)
    |> Option.filter(fn x -> x > 50 end)
    |> Option.get_or_else(0)
  
  none = :none
  fallback = Option.get_or_else(none, "default")
end
```

#### 2. Pipeline Macros - Compile-Time Tests
**Location**: `test/tests/pipeline_macro/`
```haxe
// Test valid pipelines
@:pipeline
function testValidPipeline() {
    var result = data
        |> validate
        |> transform
        |> save;
}

// Test error detection
// Should produce compile error: "Pipeline requires functions"
@:pipeline
function testInvalidPipeline() {
    var result = data |> 123;  // ❌ Not a function
}
```

#### 3. GenServer Abstractions - Mix Tests
**Location**: `test/mix/genserver_test.exs`
```elixir
defmodule GenServerTest do
  use ExUnit.Case
  
  test "generated GenServer handles calls correctly" do
    {:ok, pid} = TestCounter.start_link(0)
    assert TestCounter.increment(pid) == 1
    assert TestCounter.increment(pid) == 2
    assert TestCounter.get_count(pid) == 2
  end
  
  test "Agent abstraction works" do
    {:ok, agent} = TestAgent.start_link(initial: %{})
    TestAgent.put(agent, :key, "value")
    assert TestAgent.get(agent, :key) == "value"
  end
end
```

#### 4. Compiler Hints - Special Test Runner
**Location**: `test/tests/compiler_hints/`
```haxe
// ExpectedWarnings.hx
class ExpectedWarnings {
    // @:expect_warning("Consider using Enum.map instead of loop+push")
    function inefficientPattern() {
        var result = [];
        for (item in items) {
            result.push(item * 2);
        }
    }
    
    // @:expect_warning("Array mutation doesn't work in Elixir")
    function mutationPattern() {
        var arr = [1, 2, 3];
        arr[0] = 5;  // Should warn
    }
}
```

**Test Runner Enhancement**: Modify TestRunner.hx to capture and validate compiler warnings.

#### 5. Functional Extensions - Snapshot + Mix
**Location**: `test/tests/functional_extensions/`
```haxe
using FunctionalExtensions;

class TestExtensions {
    static function testPipe() {
        var result = getValue()
            .pipe(validate)
            .tap(x -> trace('Debug: $x'))
            .when(shouldTransform, transform)
            .andThen(save);
    }
}
```

### Test Execution Strategy

1. **Snapshot Tests** (test/tests/*)
   - Run via `npm test`
   - Verify AST transformation correctness
   - Check generated Elixir syntax

2. **Mix Tests** (test/mix/*)
   - Run via `MIX_ENV=test mix test`
   - Validate runtime behavior
   - Test GenServer state management
   - Verify Option/Result operations

3. **Compile-Time Tests**
   - Enhanced TestRunner.hx to capture warnings
   - Verify macro expansion errors
   - Check annotation processing

4. **Integration Tests** (examples/functional_patterns/)
   - Complete working example
   - Demonstrates all features together
   - Used for documentation

### Test Coverage Requirements

Each functional helper must have:
- ✅ At least one snapshot test showing transformation
- ✅ Mix test if it has runtime behavior
- ✅ Compile-time test if it's a macro
- ✅ Example in documentation
- ✅ Error case tests (invalid usage)

### Example Test Structure
```
test/
├── tests/
│   ├── functional_option/      # Option type tests
│   ├── functional_result/      # Result type tests
│   ├── pipeline_macro/         # Pipeline operator tests
│   ├── genserver_enhanced/     # GenServer abstractions
│   ├── agent_abstraction/      # Agent pattern tests
│   └── compiler_hints/         # Warning validation
└── mix/
    ├── functional_helpers_test.exs
    ├── genserver_test.exs
    └── agent_test.exs
```

## Integration Points

### ElixirCompiler.hx Changes
- Add hooks for new annotations
- Register functional helpers
- Enable paradigm hints

### ElixirPrinter.hx Changes  
- Support for Option/Result types
- Pipeline operator handling
- With statement generation

### ElixirTyper.hx Changes
- Type mapping for Option<T> → {:ok, T} | :none
- Type mapping for Result<T, E> → {:ok, T} | {:error, E}

## Documentation Requirements

For each feature:
1. Add to ANNOTATIONS.md
2. Create example in examples/
3. Add to DEVELOPER_PATTERNS.md
4. Update FEATURES.md status

## Success Criteria

- Developers can write idiomatic functional code in Haxe
- Generated Elixir is clean and performant
- Type safety is maintained throughout
- Clear migration path from imperative to functional patterns
- Comprehensive documentation and examples