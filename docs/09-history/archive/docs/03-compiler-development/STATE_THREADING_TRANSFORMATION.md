# State Threading: Mutable-to-Immutable Transformation

## Executive Summary

The State Threading Transformation system enables Haxe developers to write familiar imperative, mutable code that is automatically transformed into idiomatic, immutable Elixir code at compile time. This bridges the paradigm gap between Haxe's object-oriented mutability and Elixir's functional immutability.

## The Problem: Paradigm Mismatch

### Haxe's Mutable Model
```haxe
class JsonPrinter {
    var buf: StringBuf;
    
    function write(k: String, v: Dynamic): Void {
        buf.add(k);      // Mutates buf in place
        buf.add(":");    // Mutates again
        writeValue(v);   // More mutations internally
    }
}
```

In Haxe, objects are mutable. Methods modify fields directly, and these changes persist in the object instance.

### Elixir's Immutable Model
```elixir
defmodule JsonPrinter do
  defstruct buf: %StringBuf{}
  
  # WRONG: This doesn't work in Elixir!
  def write(%__MODULE__{} = struct, k, v) do
    struct.buf = StringBuf.add(struct.buf, k)  # ❌ Can't mutate!
  end
end
```

In Elixir, all data is immutable. You cannot modify existing structs - you must create new ones with updated values.

## The Solution: State Threading

State threading is a functional programming pattern where state is explicitly passed through a series of transformations, with each function returning the updated state for the next operation.

### Transformation Pattern

**Before (Mutable Haxe):**
```haxe
function process(): Void {
    this.count = this.count + 1;
    this.data = transform(this.data);
    this.status = "processed";
}
```

**After (Immutable Elixir with State Threading):**
```elixir
def process(%__MODULE__{} = struct) do
  struct
  |> Map.put(:count, struct.count + 1)
  |> Map.update!(:data, &transform/1)
  |> Map.put(:status, "processed")
end
```

## Implementation Architecture

### 1. Detection Phase: MutabilityAnalyzer

The `MutabilityAnalyzer` recursively traverses the AST to detect field mutations:

```haxe
class MutabilityAnalyzer {
    function analyzeMethod(expr: TypedExpr): MutabilityInfo {
        // Detects patterns like:
        // - this.field = value         (direct assignment)
        // - this.field += value        (compound assignment)
        // - this.buf.add(value)        (mutating method calls)
        // - this.data.nested = value   (nested mutations)
    }
}
```

**Detection Patterns:**
- `TBinop(OpAssign, TField(this, field), value)` - Direct field assignment
- `TBinop(OpAssignOp(_), TField(this, field), value)` - Compound assignments (+=, -=, etc.)
- `TCall(TField(this.field, method), args)` - Method calls on fields (if method is mutating)

### 2. Transformation Decision

The compiler decides whether to transform based on:
```haxe
shouldTransform = isStructClass && isMutating && returnsVoid
```

**Criteria:**
- **isStructClass**: The class compiles to an Elixir struct
- **isMutating**: The method contains field assignments
- **returnsVoid**: The method doesn't already return a value

### 3. Method Signature Transformation

**ClassCompiler** changes the method signature:

```haxe
// Before: Void return type
@spec write(t(), String.t(), any()) :: nil

// After: Returns updated struct
@spec write(t(), String.t(), any()) :: t()
```

### 4. Field Assignment Transformation

**OperatorCompiler** transforms assignments when state threading is enabled:

```haxe
// Haxe source
this.count = this.count + 1;

// Without state threading (broken)
_this.count = _this.count + 1  // ❌ Can't mutate!

// With state threading (working)
struct = %{struct | count: struct.count + 1}  // ✅ Creates new struct
```

### 5. Return Value Injection

**ClassCompiler** ensures the method returns the updated struct:

```elixir
def process(%__MODULE__{} = struct) do
  struct = %{struct | field1: value1}
  struct = %{struct | field2: value2}
  struct  # Explicitly return the updated struct
end
```

## Transformation Rules

### Rule 1: Simple Field Assignment
```haxe
// Haxe
this.field = value;

// Elixir
struct = %{struct | field: value}
```

### Rule 2: Nested Field Assignment
```haxe
// Haxe
this.data.nested = value;

// Elixir (requires deep update)
struct = %{struct | data: %{struct.data | nested: value}}
```

### Rule 3: Method Calls on Fields
```haxe
// Haxe
this.buf.add(item);

// Elixir (buf.add must return updated buf)
struct = %{struct | buf: StringBuf.add(struct.buf, item)}
```

### Rule 4: Compound Assignments
```haxe
// Haxe
this.count += 5;

// Elixir
struct = %{struct | count: struct.count + 5}
```

### Rule 5: Multiple Sequential Mutations
```haxe
// Haxe
this.a = 1;
this.b = 2;
this.c = 3;

// Elixir (sequential updates)
struct = %{struct | a: 1}
struct = %{struct | b: 2}
struct = %{struct | c: 3}
```

## Call Site Transformation

When a method is transformed to return the struct, call sites must be updated:

### Instance Method Calls
```haxe
// Haxe
obj.mutate();
obj.process();

// Elixir (must capture returned struct)
obj = obj.mutate()
obj = obj.process()
```

### Method Chaining
```haxe
// Haxe
obj.reset().add(item).process();

// Elixir (natural with state threading)
obj
|> reset()
|> add(item)
|> process()
```

## Edge Cases and Limitations

### 1. Conditional Mutations
```haxe
if (condition) {
    this.field = value;
}
// What is the state after the if?
```

**Solution:** Both branches must return consistent state:
```elixir
struct = if condition do
  %{struct | field: value}
else
  struct  # Return unchanged
end
```

### 2. Loop Mutations
```haxe
for (item in items) {
    this.total += item.value;
}
```

**Solution:** Use Enum.reduce for accumulation:
```elixir
struct = Enum.reduce(items, struct, fn item, acc ->
  %{acc | total: acc.total + item.value}
end)
```

### 3. Early Returns
```haxe
function process() {
    if (this.done) return;
    this.value = compute();
}
```

**Solution:** All paths must return the struct:
```elixir
def process(%__MODULE__{} = struct) do
  if struct.done do
    struct  # Return unchanged
  else
    %{struct | value: compute()}
  end
end
```

### 4. External Mutations
```haxe
function process() {
    helper.mutate(this);  // Helper modifies our fields
}
```

**Solution:** Helper must return the modified struct:
```elixir
def process(%__MODULE__{} = struct) do
  Helper.mutate(struct)  # Returns updated struct
end
```

## Benefits of State Threading

### 1. **Maintains Immutability**
- Preserves Elixir's functional programming guarantees
- Thread-safe by default
- No hidden state changes

### 2. **Natural Composition**
- Methods naturally chain with pipe operator
- Clear data flow
- Easy to reason about

### 3. **Developer Friendly**
- Write familiar mutable code in Haxe
- Get idiomatic immutable Elixir
- No manual state management

### 4. **Performance**
- Elixir's runtime optimizes struct updates
- Shared structure for unchanged fields
- Efficient memory usage

## Implementation Status

### ✅ Completed
- MutabilityAnalyzer for detecting mutations
- ClassCompiler integration for method transformation
- ElixirCompiler state threading mode infrastructure
- Comprehensive documentation

### 🚧 In Progress
- OperatorCompiler field assignment transformation
- Method call site updates
- JsonPrinter test case

### 📋 TODO
- Nested field update optimization
- Loop mutation patterns
- Conditional mutation handling
- External mutation coordination

## Configuration and Debugging

### Enable Debug Output
```hxml
# In build.hxml
-D debug_mutability
-D debug_state_threading
-D debug_parameter_mapping
```

### Manual Override
```haxe
@:noStateThreading  // Disable transformation for this class
class MyClass { }

@:forceStateThreading  // Force transformation even if not detected
class MyOtherClass { }
```

## Writing Optimal Haxe for Elixir (1:1 Generation)

### The Functional Pattern: Zero-Overhead Approach

While the state threading transformation enables imperative code, you can write Haxe that generates nearly 1:1 Elixir code by following functional patterns from the start. This avoids transformation overhead and produces the cleanest output.

### Optimal Pattern: Return Updated Structs

**🎯 Optimal Haxe (Functional Style):**
```haxe
class JsonPrinter {
    var buf: StringBuf;
    
    // Return the updated struct explicitly
    function write(k: String, v: Dynamic): JsonPrinter {
        var updated = this;
        updated.buf = StringBuf.add(updated.buf, k);
        updated.buf = StringBuf.add(updated.buf, ":");
        return updated;
    }
    
    // Chain operations naturally
    function writeMultiple(items: Array<Item>): JsonPrinter {
        var result = this;
        for (item in items) {
            result = result.write(item.key, item.value);
        }
        return result;
    }
}
```

**Generated Elixir (Nearly 1:1):**
```elixir
defmodule JsonPrinter do
  defstruct buf: %StringBuf{}
  
  # Direct translation - no transformation needed
  def write(%__MODULE__{} = struct, k, v) do
    struct
    |> Map.put(:buf, StringBuf.add(struct.buf, k))
    |> Map.put(:buf, StringBuf.add(struct.buf, ":"))
  end
  
  def write_multiple(%__MODULE__{} = struct, items) do
    Enum.reduce(items, struct, fn item, acc ->
      write(acc, item.key, item.value)
    end)
  end
end
```

### Comparison: Imperative vs Functional

#### Imperative (Requires Transformation)
```haxe
// ❌ Requires state threading transformation
function process(): Void {
    this.count++;           // Mutation
    this.total += value;    // Mutation
    this.status = "done";   // Mutation
}

// Generated with overhead:
def process(%__MODULE__{} = struct) do
  struct = %{struct | count: struct.count + 1}      # Transformed
  struct = %{struct | total: struct.total + value}  # Transformed
  struct = %{struct | status: "done"}               # Transformed
  struct  # Added return
end
```

#### Functional (Optimal)
```haxe
// ✅ Already functional - minimal transformation
function process(value: Int): Config {
    return {
        count: this.count + 1,
        total: this.total + value,
        status: "done"
    };
}

// Generated 1:1:
def process(%__MODULE__{} = struct, value) do
  %{struct | 
    count: struct.count + 1,
    total: struct.total + value,
    status: "done"
  }
end
```

### Optimal Patterns for Elixir

#### 1. **Builder Pattern with Method Chaining**
```haxe
class QueryBuilder {
    var conditions: Array<Condition>;
    
    // Each method returns updated builder
    public function where(field: String, value: Any): QueryBuilder {
        return new QueryBuilder({
            conditions: conditions.concat([{field: field, value: value}])
        });
    }
    
    public function orderBy(field: String): QueryBuilder {
        return new QueryBuilder({
            conditions: conditions,
            order: field
        });
    }
}

// Usage - already functional
var query = new QueryBuilder()
    .where("status", "active")
    .where("age", 21)
    .orderBy("name");
```

#### 2. **Accumulator Pattern for Collections**
```haxe
// ✅ Optimal: Use reduce/fold patterns
function sumItems(items: Array<Item>): Stats {
    return items.fold(function(item, stats) {
        return {
            count: stats.count + 1,
            total: stats.total + item.value,
            items: stats.items.concat([item.id])
        };
    }, {count: 0, total: 0, items: []});
}

// Generates clean Elixir:
def sum_items(items) do
  Enum.reduce(items, %{count: 0, total: 0, items: []}, fn item, stats ->
    %{
      count: stats.count + 1,
      total: stats.total + item.value,
      items: stats.items ++ [item.id]
    }
  end)
end
```

#### 3. **Pipeline-Friendly Operations**
```haxe
// ✅ Design for pipeline operator
class DataProcessor {
    static function validate(data: Data): Result<Data, Error> {
        return data.isValid() ? Ok(data) : Error("Invalid");
    }
    
    static function transform(data: Data): Data {
        return {...data, processed: true};
    }
    
    static function save(data: Data): Result<Data, Error> {
        // Save logic
        return Ok(data);
    }
}

// Usage aligns with Elixir pipes
var result = data
    |> validate
    |> Result.map(transform)
    |> Result.flatMap(save);
```

### When to Use Each Pattern

#### Use Imperative (State Threading) When:
- Porting existing imperative code
- Complex stateful algorithms
- Team familiarity with OOP patterns
- Gradual migration from other languages

#### Use Functional (Optimal) When:
- Writing new Elixir-first code
- Performance-critical sections
- Building reusable libraries
- Team familiar with functional patterns

### Performance Comparison

| Pattern | Compilation Time | Runtime Performance | Code Size | Readability |
|---------|-----------------|---------------------|-----------|-------------|
| **Imperative + State Threading** | Slower (analysis required) | Same | Larger | Familiar to OOP devs |
| **Functional (Optimal)** | Faster (1:1 mapping) | Same | Smaller | Natural for Elixir |

### Migration Strategy

If you have existing imperative code but want optimal generation:

```haxe
// Step 1: Start with imperative (works with state threading)
class Counter {
    var count: Int = 0;
    
    function increment(): Void {
        count++;
    }
}

// Step 2: Add return type
class Counter {
    var count: Int = 0;
    
    function increment(): Counter {
        count++;
        return this;  // Compiler adds this if missing
    }
}

// Step 3: Make it functional (optimal)
class Counter {
    var count: Int = 0;
    
    function increment(): Counter {
        return new Counter(count + 1);
    }
}
```

### Summary

While state threading enables any Haxe code to work with Elixir's immutability, writing functional Haxe from the start produces the cleanest, most efficient Elixir code. Choose the pattern that best fits your team and project needs.

## Best Practices

### 1. **Design for Immutability**
Even though the compiler handles transformation, design your Haxe code with immutability in mind for better results.

### 2. **Minimize Mutations**
Group related mutations together for cleaner generated code:
```haxe
// Good: Single update point
function updateStats(value: Int) {
    this.count++;
    this.total += value;
    this.average = this.total / this.count;
}

// Less optimal: Scattered mutations
function process() {
    this.count++;
    doSomething();
    this.total += getValue();
    doMore();
    this.average = compute();
}
```

### 3. **Return Early, Return Struct**
Always return the struct, even in early return cases:
```haxe
function process(): JsonPrinter {  // Return type helps!
    if (done) return this;
    // mutations...
    return this;
}
```

### 4. **Use Builder Pattern**
For complex object construction, use builder pattern:
```haxe
class ConfigBuilder {
    function withHost(host: String): ConfigBuilder {
        this.host = host;
        return this;  // Already returns self!
    }
}
```

## Testing State Threading

### Unit Test Pattern
```haxe
class TestMutableStruct {
    var value: Int = 0;
    
    function increment(): Void {
        this.value++;
    }
}

// Test the transformation
var obj = new TestMutableStruct();
obj = obj.increment();  // Must capture return
assert(obj.value == 1);
```

### Integration Test
```bash
# Compile with state threading
haxe build.hxml -D debug_state_threading

# Verify generated Elixir
cat lib/test_mutable_struct.ex | grep "def increment"
# Should see: def increment(%__MODULE__{} = struct) do

# Run Elixir tests
mix test
```

## Troubleshooting

### Problem: "undefined variable struct"
**Cause:** State threading not enabled for the method
**Solution:** Check MutabilityAnalyzer is detecting mutations

### Problem: "undefined variable _this"
**Cause:** Parameter mapping not set correctly
**Solution:** Verify setThisParameterMapping is called

### Problem: Method doesn't return struct
**Cause:** Return type not transformed
**Solution:** Check shouldTransform conditions

### Problem: Nested updates fail
**Cause:** Deep update pattern not implemented
**Solution:** Use helper functions for nested updates

## Related Documentation

- [MutabilityAnalyzer.hx](../../src/reflaxe/elixir/helpers/MutabilityAnalyzer.hx) - Mutation detection implementation
- [ClassCompiler.hx](../../src/reflaxe/elixir/helpers/ClassCompiler.hx) - Method transformation logic
- [OperatorCompiler.hx](../../src/reflaxe/elixir/helpers/OperatorCompiler.hx) - Assignment transformation
- [COMPILER_PRINCIPLES.md](compiler-principles.md) - General compiler architecture

## Future Enhancements

### 1. **Automatic Batching**
Detect multiple sequential mutations and batch them into a single struct update:
```elixir
# Instead of:
struct = %{struct | a: 1}
struct = %{struct | b: 2}

# Generate:
struct = %{struct | a: 1, b: 2}
```

### 2. **Lens Integration**
Use lens libraries for complex nested updates:
```elixir
struct = Lens.set(struct, [:data, :nested, :field], value)
```

### 3. **Compile-Time Verification**
Add compile-time checks to ensure all mutations are properly threaded.

### 4. **Performance Optimization**
Analyze mutation patterns and optimize common cases for better performance.

---

*This transformation system represents a significant achievement in bridging the imperative-functional paradigm gap, allowing developers to write natural Haxe code while producing idiomatic Elixir.*