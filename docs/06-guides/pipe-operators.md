# Pipe Operators in Haxe.Elixir

The pipe operator (`|>`) is one of Elixir's most distinctive features, enabling clean data transformation pipelines. Haxe.Elixir provides comprehensive support for pipe operators, allowing you to write idiomatic Elixir-style code with type safety.

## Table of Contents
- [Overview](#overview)
- [Why No `|>` Syntax in Haxe?](#why-no--syntax-in-haxe)
- [Basic Usage](#basic-usage)
- [Method Chaining to Pipes](#method-chaining-to-pipes)
- [Anonymous Functions in Pipes](#anonymous-functions-in-pipes)
- [Enum Operations](#enum-operations)
- [Map Operations](#map-operations)
- [Phoenix Patterns](#phoenix-patterns)
- [Custom Pipe Functions](#custom-pipe-functions)
- [Macro Support](#macro-support)
- [Best Practices](#best-practices)
- [Implementation Details](#implementation-details)

## Overview

Haxe.Elixir automatically transforms Haxe method chaining into Elixir pipe operators during compilation. This provides:

- ✅ **Natural Syntax**: Write familiar method chains in Haxe
- ✅ **Idiomatic Output**: Generate clean Elixir pipe operators
- ✅ **Type Safety**: Maintain compile-time type checking
- ✅ **Zero Runtime Cost**: Transformation happens at compile time

## Why No `|>` Syntax in Haxe?

### The Architectural Decision

You might wonder: **"Why doesn't Haxe.Elixir support `|>` syntax directly in Haxe code?"**

This is a **deliberate design choice** based on the principle: **"Write idiomatic Haxe, generate idiomatic Elixir"**

### Method Chaining vs Direct Pipe Operator

#### What We Could Have Done (But Didn't)

We *could* have added `|>` syntax via macros:

```haxe
// Hypothetical direct pipe operator in Haxe (NOT IMPLEMENTED)
var result = data 
    |> filter(_, x -> x > 0)
    |> map(_, x -> x * 2)
    |> reduce(_, (a, b) -> a + b, 0);
```

#### Why This Would Be Problematic

1. **Non-Standard Haxe Syntax**
   - Breaks compatibility with existing Haxe code
   - Other Haxe targets wouldn't understand it
   - Fragments the Haxe ecosystem

2. **IDE and Tooling Issues**
   - Most Haxe IDEs wouldn't recognize `|>`
   - No autocomplete after pipe operators
   - Formatters and linters would fail
   - Syntax highlighting would break

3. **Type Inference Challenges**
   - Harder for the compiler to track types through pipes
   - Less helpful error messages
   - Reduced compile-time safety

4. **Learning Curve**
   - Haxe developers need to learn non-standard syntax
   - Documentation becomes more complex
   - Onboarding is harder

### The Better Approach: Method Chaining

Instead, Haxe.Elixir uses **standard method chaining** that transforms to pipes:

```haxe
// Idiomatic Haxe (what you write)
var result = data
    .filter(x -> x > 0)      // ← IDE shows available methods
    .map(x -> x * 2)          // ← Full type inference
    .reduce((a, b) -> a + b, 0); // ← Compile-time validation
```

```elixir
# Idiomatic Elixir (what gets generated)
result = data
  |> Enum.filter(&(&1 > 0))
  |> Enum.map(&(&1 * 2))
  |> Enum.reduce(0, &(&1 + &2))
```

### Benefits of This Design

| Aspect | Direct `\|>` in Haxe | Method Chaining (Current) |
|--------|---------------------|---------------------------|
| **Haxe Compatibility** | ❌ Non-standard | ✅ Standard Haxe |
| **IDE Support** | ❌ Limited | ✅ Full autocomplete |
| **Type Safety** | ⚠️ Partial | ✅ Complete |
| **Learning Curve** | ❌ New syntax | ✅ Familiar |
| **Tooling** | ❌ Breaks tools | ✅ All tools work |
| **Code Sharing** | ❌ Target-specific | ✅ Cross-target |
| **Elixir Output** | ✅ Pipes | ✅ Pipes |

### The Philosophy

```
┌─────────────┐          ┌──────────────┐          ┌─────────────┐
│   Haxe      │          │  Compiler    │          │   Elixir    │
│ Developers  │  write   │ Transforms   │  read    │ Developers  │
│             │ ──────►  │              │ ──────►  │             │
│  Natural    │          │  Method      │          │  Natural    │
│   Haxe      │          │  Chains →    │          │   Elixir    │
│   Code      │          │  Pipes       │          │    Code     │
└─────────────┘          └──────────────┘          └─────────────┘
```

### Best of Both Worlds

This design gives you:

1. **For Haxe Developers**:
   - Write normal Haxe code
   - Use familiar patterns
   - Get full IDE support
   - Maintain type safety

2. **For Elixir Developers**:
   - Read idiomatic Elixir
   - See familiar pipe operators
   - Maintain code normally
   - Use standard tools

3. **For Teams**:
   - No learning curve
   - Easy onboarding
   - Standard tooling works
   - Clean separation of concerns

### When You Need Direct Pipes

For complex Elixir-specific patterns, use escape hatches:

```haxe
// When you need specific Elixir pipe patterns
var result = untyped __elixir__('
    data
    |> Stream.map(&process/1)
    |> Task.async_stream(&heavy_work/1)
    |> Enum.to_list()
');
```

But for 99% of cases, method chaining gives you everything you need with better developer experience!

### Custom Constructs for Elixir Idioms

While the philosophy is "idiomatic Haxe → idiomatic Elixir", some Elixir patterns have no natural Haxe equivalent. For these, Haxe.Elixir provides **custom constructs** that feel natural in Haxe while generating idiomatic Elixir:

#### Example 1: Pattern Matching with Guards

```haxe
// Custom @:guard annotation (Haxe doesn't have guards natively)
@:guard("is_binary(input) and byte_size(input) > 0")
public function processString(input: String): String {
    return input.toUpperCase();
}
```

```elixir
# Generates idiomatic Elixir guards
def process_string(input) when is_binary(input) and byte_size(input) > 0 do
  String.upcase(input)
end
```

#### Example 2: With Expressions

```haxe
// Custom with() construct (Haxe doesn't have with-expressions)
public function processFile(path: String): Result<Data> {
    return with(
        file <- File.read(path),
        json <- Json.decode(file),
        validated <- validate(json)
    ) {
        return {:ok, validated};
    } else {
        {:error, reason} -> logError(reason);
    };
}
```

```elixir
# Generates idiomatic Elixir with-expression
def process_file(path) do
  with {:ok, file} <- File.read(path),
       {:ok, json} <- Jason.decode(file),
       {:ok, validated} <- validate(json) do
    {:ok, validated}
  else
    {:error, reason} -> log_error(reason)
  end
end
```

#### Example 3: Comprehensions with Filters

```haxe
// Custom for-comprehension syntax extensions
var result = for (x in list, x > 0, y in x.items, y.active) {
    yield {x: x.id, y: y.value};
} into %{};
```

```elixir
# Generates idiomatic Elixir comprehension
result = for x <- list, x > 0, y <- x.items, y.active, into: %{} do
  {x.id, y.value}
end
```

#### Example 4: Process Communication

```haxe
// Custom receive construct (Haxe doesn't have actor model)
public function handleMessages(): Void {
    receive {
        {:data, payload} -> processData(payload);
        {:stop} -> shutdown();
        after 5000 -> handleTimeout();
    };
}
```

```elixir
# Generates idiomatic Elixir receive
def handle_messages do
  receive do
    {:data, payload} -> process_data(payload)
    {:stop} -> shutdown()
  after
    5000 -> handle_timeout()
  end
end
```

### The Complete Picture

```
┌──────────────────────────────────────────────────────────┐
│                   Haxe.Elixir Strategy                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. Natural Mapping (90% of cases)                       │
│     Haxe method chaining → Elixir pipes                  │
│     Haxe classes → Elixir modules                        │
│     Haxe switch → Elixir case                           │
│                                                           │
│  2. Custom Constructs (9% of cases)                      │
│     @:guard → when guards                                │
│     with() → with expressions                            │
│     receive → receive blocks                             │
│     @:genserver → GenServer callbacks                    │
│                                                           │
│  3. Escape Hatches (1% of cases)                         │
│     untyped __elixir__() → Raw Elixir                   │
│     @:native → Direct module mapping                     │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

The key insight: **Custom constructs are still idiomatic Haxe** - they use familiar Haxe patterns (annotations, method calls) rather than introducing foreign syntax like `|>`.

## Basic Usage

### Method Chaining Transformation

In Haxe, you write method chains:

```haxe
// Haxe code
var result = "  HELLO WORLD  "
    .toLowerCase()
    .trim()
    .split(" ");
```

This compiles to Elixir pipes:

```elixir
# Generated Elixir
result = "  HELLO WORLD  "
  |> String.downcase()
  |> String.trim()
  |> String.split(" ")
```

### Direct Pipe Syntax

You can also use pipe operators directly in untyped blocks:

```haxe
var result = untyped __elixir__('
    data
    |> process()
    |> validate()
    |> transform()
');
```

## Method Chaining to Pipes

### String Operations

```haxe
class StringProcessor {
    public function processText(input: String): String {
        return input
            .trim()
            .toLowerCase()
            .replace(" ", "_")
            .substring(0, 10);
    }
}
```

Compiles to:

```elixir
def process_text(input) do
  input
  |> String.trim()
  |> String.downcase()
  |> String.replace(" ", "_")
  |> String.slice(0, 10)
end
```

### Array/List Operations

```haxe
class DataProcessor {
    public function processNumbers(numbers: Array<Int>): Int {
        return numbers
            .filter(n -> n > 0)
            .map(n -> n * 2)
            .reduce((a, b) -> a + b, 0);
    }
}
```

Compiles to:

```elixir
def process_numbers(numbers) do
  numbers
  |> Enum.filter(&(&1 > 0))
  |> Enum.map(&(&1 * 2))
  |> Enum.reduce(0, &(&1 + &2))
end
```

## Anonymous Functions in Pipes

### Using Lambda Expressions

```haxe
class LambdaPipes {
    public function transformData(data: Array<Int>): Array<Int> {
        return data
            .map(x -> x + 1)
            .filter(x -> x % 2 == 0)
            .map(x -> x * x);
    }
}
```

Compiles to:

```elixir
def transform_data(data) do
  data
  |> Enum.map(&(&1 + 1))
  |> Enum.filter(&(rem(&1, 2) == 0))
  |> Enum.map(&(&1 * &1))
end
```

### Complex Anonymous Functions

```haxe
class ComplexPipes {
    public function processUsers(users: Array<User>): Array<String> {
        return users
            .filter(u -> u.age >= 18)
            .map(u -> {
                var name = u.firstName + " " + u.lastName;
                return name.toUpperCase();
            })
            .sort((a, b) -> a.compareTo(b));
    }
}
```

## Enum Operations

### Common Enum Patterns

```haxe
class EnumPipes {
    public function analyzeData(data: Array<Float>): Statistics {
        var sum = data.reduce((acc, val) -> acc + val, 0.0);
        var count = data.length;
        var mean = sum / count;
        
        var sortedData = data.sort((a, b) -> a - b);
        var median = sortedData[Math.floor(count / 2)];
        
        var variance = data
            .map(x -> Math.pow(x - mean, 2))
            .reduce((acc, val) -> acc + val, 0.0) / count;
            
        return {
            mean: mean,
            median: median,
            variance: variance,
            stdDev: Math.sqrt(variance)
        };
    }
}
```

Compiles to clean Elixir pipelines:

```elixir
def analyze_data(data) do
  sum = data |> Enum.reduce(0.0, &(&1 + &2))
  count = length(data)
  mean = sum / count
  
  sorted_data = data |> Enum.sort()
  median = Enum.at(sorted_data, div(count, 2))
  
  variance = data
    |> Enum.map(&(:math.pow(&1 - mean, 2)))
    |> Enum.reduce(0.0, &(&1 + &2))
    |> Kernel./(count)
    
  %{
    mean: mean,
    median: median,
    variance: variance,
    std_dev: :math.sqrt(variance)
  }
end
```

### Advanced Enum Operations

```haxe
class AdvancedEnum {
    public function groupAndAggregate(items: Array<Item>): Map<String, Float> {
        return items
            .groupBy(item -> item.category)
            .map((category, items) -> {
                var total = items
                    .map(item -> item.value)
                    .reduce((a, b) -> a + b, 0.0);
                return {key: category, value: total};
            });
    }
}
```

## Map Operations

### Map Transformations

```haxe
class MapPipes {
    public function transformMap(data: Map<String, Int>): Map<String, String> {
        return data
            .filter((k, v) -> v > 0)
            .map((k, v) -> {key: k, value: 'Value: $v'})
            .merge(getDefaults());
    }
    
    public function chainMapOps(initial: Map<String, Dynamic>): Map<String, Dynamic> {
        return initial
            .put("timestamp", Date.now())
            .put("version", "1.0.0")
            .update("counter", old -> (old ?? 0) + 1)
            .delete("temp_field");
    }
}
```

Compiles to:

```elixir
def transform_map(data) do
  data
  |> Enum.filter(fn {_k, v} -> v > 0 end)
  |> Enum.map(fn {k, v} -> {k, "Value: #{v}"} end)
  |> Map.merge(get_defaults())
end

def chain_map_ops(initial) do
  initial
  |> Map.put(:timestamp, DateTime.utc_now())
  |> Map.put(:version, "1.0.0")
  |> Map.update(:counter, 0, &(&1 + 1))
  |> Map.delete(:temp_field)
end
```

## Phoenix Patterns

### Controller Pipelines

```haxe
@:controller
class UserController {
    public function create(conn: Conn, params: Params): Conn {
        return conn
            .validateParams(params)
            .createUser()
            .putStatus(201)
            .putView(UserView)
            .render("show.json");
    }
    
    public function update(conn: Conn, params: Params): Conn {
        return conn
            .fetchUser(params.id)
            .authorizeUser()
            .updateUser(params)
            .putFlash("info", "User updated successfully")
            .redirect(to: userPath(conn, "show", params.id));
    }
}
```

Compiles to idiomatic Phoenix controllers:

```elixir
def create(conn, params) do
  conn
  |> validate_params(params)
  |> create_user()
  |> put_status(201)
  |> put_view(UserView)
  |> render("show.json")
end

def update(conn, params) do
  conn
  |> fetch_user(params["id"])
  |> authorize_user()
  |> update_user(params)
  |> put_flash(:info, "User updated successfully")
  |> redirect(to: user_path(conn, :show, params["id"]))
end
```

### LiveView Pipelines

```haxe
@:liveview
class DashboardLive {
    public function handle_event("filter", params, socket): Socket {
        return socket
            .assignFilters(params)
            .loadData()
            .updateChart()
            .pushEvent("chart-updated", getChartData(socket));
    }
    
    public function handle_info({:data_updated, data}, socket): Socket {
        return socket
            .assign("data", data)
            .calculateStats()
            .broadcastUpdate()
            .putFlash("info", "Data refreshed");
    }
}
```

## Custom Pipe Functions

### Creating Pipeable Functions

```haxe
class PipeableFunctions {
    // Functions that work well in pipes
    public static function validate<T>(data: T, rules: Array<Rule>): Result<T> {
        // First parameter receives piped value
        return ValidationEngine.validate(data, rules);
    }
    
    public static function transform<T, R>(data: T, transformer: T -> R): R {
        return transformer(data);
    }
    
    public static function tap<T>(data: T, sideEffect: T -> Void): T {
        // Useful for debugging or side effects
        sideEffect(data);
        return data;
    }
}

// Usage
class DataFlow {
    public function processRequest(input: String): Response {
        return input
            .parseJson()
            .validate(getValidationRules())
            .transform(data -> enrichData(data))
            .tap(data -> logData(data))
            .createResponse();
    }
}
```

### Pipeline Helpers

```haxe
class PipelineHelpers {
    // Conditional pipes
    public static function when<T>(data: T, condition: Bool, fn: T -> T): T {
        return condition ? fn(data) : data;
    }
    
    // Error handling in pipes
    public static function tryPipe<T>(data: T, fn: T -> T): Result<T> {
        try {
            return Ok(fn(data));
        } catch (e: Dynamic) {
            return Error(e);
        }
    }
    
    // Debugging pipes
    public static function debug<T>(data: T, label: String = ""): T {
        trace('${label}: ${data}');
        return data;
    }
}

// Usage
var result = data
    .when(shouldValidate, d -> d.validate())
    .debug("After validation")
    .tryPipe(d -> d.process())
    .when(shouldCache, d -> d.cache());
```

## Macro Support

### Using PipeOperator Macros

```haxe
import reflaxe.elixir.macros.PipeOperator;

class MacroPipes {
    public function usePipeMacro(): String {
        // Use the pipe macro for compile-time transformation
        return PipeOperator.pipe(
            getData()
                .process()
                .format()
        );
    }
    
    public function useAutoPipe(): Dynamic {
        // Automatic pipe transformation
        return PipeOperator.autoPipe(
            "input"
                .toLowerCase()
                .trim()
                .split(",")
        );
    }
    
    public function usePipeCall(): Dynamic {
        // Explicit pipe call syntax
        return PipeOperator.pipeCall([
            getData(),
            process,
            validate,
            transform
        ]);
    }
}
```

## Best Practices

### 1. Keep Pipes Readable

```haxe
// Good: Clear, logical flow
var result = input
    .validate()
    .normalize()
    .transform()
    .save();

// Bad: Too many operations in one pipe
var result = input
    .trim()
    .toLowerCase()
    .replace(" ", "_")
    .substring(0, 10)
    .split("_")
    .filter(s -> s.length > 0)
    .map(s -> s.charAt(0))
    .join("")
    .toUpperCase();

// Better: Break into logical groups
var normalized = input
    .trim()
    .toLowerCase()
    .replace(" ", "_");

var result = normalized
    .substring(0, 10)
    .split("_")
    .processTokens()
    .formatOutput();
```

### 2. Use Helper Functions

```haxe
class PipelinePatterns {
    // Extract complex operations into named functions
    private function validateAndEnrich(data: Data): EnrichedData {
        return data
            .validate()
            .addMetadata()
            .enrichWithContext();
    }
    
    private function transformAndFormat(data: EnrichedData): String {
        return data
            .transform()
            .applyTemplate()
            .format();
    }
    
    public function process(input: Data): String {
        return input
            .pipe(validateAndEnrich)
            .pipe(transformAndFormat);
    }
}
```

### 3. Error Handling in Pipes

```haxe
class SafePipes {
    public function safeProcess(input: String): Result<String> {
        return Result.ok(input)
            .flatMap(parseInput)
            .flatMap(validate)
            .flatMap(process)
            .map(format)
            .mapError(handleError);
    }
    
    // With pattern matching
    public function processWithMatch(input: Dynamic): Dynamic {
        return switch (parseInput(input)) {
            case {:ok, parsed}:
                parsed
                    .validate()
                    .transform()
                    .format();
            case {:error, reason}:
                handleError(reason);
        };
    }
}
```

### 4. Type-Safe Pipes

```haxe
// Define pipe-friendly types
abstract Pipeline<T>(T) {
    public inline function new(value: T) {
        this = value;
    }
    
    public inline function pipe<R>(fn: T -> R): Pipeline<R> {
        return new Pipeline(fn(this));
    }
    
    public inline function value(): T {
        return this;
    }
}

// Usage
var result = new Pipeline(data)
    .pipe(validate)
    .pipe(transform)
    .pipe(format)
    .value();
```

## Implementation Details

### How It Works

The Haxe.Elixir compiler includes a `PipeOperator` macro that:

1. **Detects Method Chains**: Identifies chained method calls during compilation
2. **Transforms to Pipes**: Converts chains to Elixir pipe operator syntax
3. **Maps Functions**: Translates Haxe methods to appropriate Elixir functions
4. **Preserves Types**: Maintains type information through the transformation

### Supported Transformations

| Haxe Pattern | Elixir Output |
|-------------|---------------|
| `str.toLowerCase()` | `String.downcase(str)` |
| `str.trim()` | `String.trim(str)` |
| `arr.map(fn)` | `Enum.map(arr, fn)` |
| `arr.filter(fn)` | `Enum.filter(arr, fn)` |
| `arr.reduce(fn, init)` | `Enum.reduce(arr, init, fn)` |
| `map.put(k, v)` | `Map.put(map, k, v)` |
| `map.get(k)` | `Map.get(map, k)` |

### Custom Module Mappings

You can configure custom mappings for your modules:

```haxe
@:pipeModule("MyApp.Utils")
class CustomUtils {
    @:pipe("process_data")
    public static function processData(data: Dynamic): Dynamic;
    
    @:pipe("validate_input")
    public static function validateInput(input: String): Bool;
}

// Usage generates:
// data |> MyApp.Utils.process_data() |> MyApp.Utils.validate_input()
```

## Advanced Examples

### Complex Data Pipeline

```haxe
class AnalyticsPipeline {
    public function processEvents(events: Array<Event>): Report {
        return events
            .filter(e -> e.timestamp > yesterdayTimestamp())
            .groupBy(e -> e.userId)
            .map((userId, userEvents) -> {
                return {
                    userId: userId,
                    eventCount: userEvents.length,
                    totalValue: userEvents
                        .map(e -> e.value)
                        .reduce((a, b) -> a + b, 0),
                    avgEngagement: calculateEngagement(userEvents)
                };
            })
            .filter(stat -> stat.eventCount > 5)
            .sortBy(stat -> -stat.totalValue)
            .take(100)
            .generateReport();
    }
}
```

### Database Query Pipeline

```haxe
@:query
class UserQuery {
    public function activeUsers(): Query<User> {
        return from(User)
            .where(u -> u.active == true)
            .where(u -> u.lastLogin > daysAgo(30))
            .preload([:profile, :subscriptions])
            .orderBy(u -> u.createdAt, :desc)
            .limit(50);
    }
}
```

### Web Request Pipeline

```haxe
class ApiClient {
    public function fetchAndProcess(endpoint: String): Promise<Result> {
        return request(endpoint)
            .addHeaders(getAuthHeaders())
            .setTimeout(5000)
            .send()
            .then(response -> response.json())
            .then(data -> validate(data))
            .then(valid -> transform(valid))
            .catch(error -> handleError(error));
    }
}
```

## Performance Considerations

Pipe operators in Haxe.Elixir:

- ✅ **Zero Runtime Overhead**: Transformation happens at compile time
- ✅ **Optimized Output**: Generates idiomatic Elixir code
- ✅ **Tail Call Optimization**: Preserves Elixir's TCO where applicable
- ✅ **Memory Efficient**: No intermediate collections in streaming operations

## Troubleshooting

### Common Issues

1. **Method Not Found**: Ensure the method exists and is properly typed
2. **Type Mismatch**: Check that piped types match expected function parameters
3. **Import Missing**: Verify required modules are imported
4. **Macro Conflicts**: Avoid naming conflicts with Elixir built-in macros

## Summary

Pipe operators in Haxe.Elixir provide:

- 🚀 Clean, readable data transformation pipelines
- 🎯 Type-safe method chaining
- ⚡ Zero-cost compile-time transformation
- 🔧 Seamless Phoenix and Elixir ecosystem integration
- 📝 Idiomatic Elixir code generation

Use pipes to write expressive, maintainable code that leverages the best of both Haxe's type system and Elixir's functional programming paradigms!
