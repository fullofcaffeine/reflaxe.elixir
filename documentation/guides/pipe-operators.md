# Pipe Operators in Haxe.Elixir

The pipe operator (`|>`) is one of Elixir's most distinctive features, enabling clean data transformation pipelines. Haxe.Elixir provides comprehensive support for pipe operators, allowing you to write idiomatic Elixir-style code with type safety.

## Table of Contents
- [Overview](#overview)
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
import reflaxe.elixir.macro.PipeOperator;

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