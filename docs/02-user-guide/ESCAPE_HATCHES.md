# Escape Hatches: Using Elixir Code from Haxe

This guide covers how to interoperate with existing Elixir code, call Elixir functions directly, use Elixir libraries, and handle scenarios where you need to drop down to raw Elixir.

**See Also**: 
- [Annotations](../04-api-reference/ANNOTATIONS.md) - `@:native` and other target metadata
- [Functional Patterns](../07-patterns/FUNCTIONAL_PATTERNS.md) - Portable functional patterns (Result/Option)
- [Haxe→Elixir Mappings](HAXE_ELIXIR_MAPPINGS.md) - How common Haxe constructs map to Elixir

## Table of Contents
- [The @:native Annotation](#the-native-annotation)
- [Untyped Code Blocks](#untyped-code-blocks)
- [Raw Elixir Expressions](#raw-elixir-expressions)
- [Calling Elixir Modules](#calling-elixir-modules)
- [Using Elixir Libraries](#using-elixir-libraries)
- [Inline Elixir with @:elixir](#inline-elixir-with-elixir)
- [Extern Definitions](#extern-definitions)
- [Dynamic Types](#dynamic-types)
- [Macro Integration](#macro-integration)
- [Best Practices](#best-practices)

## The @:native Annotation

The `@:native` annotation allows you to map Haxe code to existing Elixir modules and functions.

### Basic Usage

```haxe
// Map to an existing Elixir module
@:native("Enum")
extern class ElixirEnum {
    // Map to Elixir functions
    @:native("map")
    public static function map<T, R>(enumerable: Array<T>, fn: T -> R): Array<R>;
    
    @:native("filter")
    public static function filter<T>(enumerable: Array<T>, fn: T -> Bool): Array<T>;
    
    @:native("reduce")
    public static function reduce<T, R>(enumerable: Array<T>, acc: R, fn: (R, T) -> R): R;
}

// Usage
var numbers = [1, 2, 3, 4, 5];
var doubled = ElixirEnum.map(numbers, x -> x * 2);
var evens = ElixirEnum.filter(numbers, x -> x % 2 == 0);
```

### Mapping to Erlang Modules

```haxe
@:native(":crypto")
extern class Crypto {
    @:native("strong_rand_bytes")
    public static function strongRandBytes(size: Int): Dynamic;
    
    @:native("hash")
    public static function hash(type: Dynamic, data: String): Dynamic;
}

// Usage
var randomBytes = Crypto.strongRandBytes(32);
var hash = Crypto.hash(untyped :sha256, "my data");
```

## Untyped Code Blocks

When you need to write raw Elixir code without type checking:

```haxe
class MyModule {
    public function complexElixirOperation(): Dynamic {
        // Escape to untyped code
        return untyped {
            // Raw Elixir code here
            __elixir__('
                case :ets.lookup(:my_table, :my_key) do
                  [{_, value}] -> value
                  [] -> nil
                end
            ');
        };
    }
    
    public function useElixirMacro(): Void {
        untyped {
            // Use Elixir macros directly
            __elixir__('
                require Logger
                Logger.debug("Debug message from Haxe")
            ');
        };
    }
}
```

## Raw Elixir Expressions

### Using __elixir__ Magic Function

```haxe
class ElixirInterop {
    public function callElixirDirectly(): Dynamic {
        // Inline Elixir expression
        var result = untyped __elixir__('DateTime.utc_now()');
        
        // Multi-line Elixir
        var complex = untyped __elixir__('
            with {:ok, file} <- File.read("config.json"),
                 {:ok, json} <- Jason.decode(file) do
              json
            else
              _ -> %{}
            end
        ');
        
        return complex;
    }
    
    public function useElixirOperators(): Bool {
        var a = [1, 2, 3];
        var b = [1, 2, 3];
        
        // Use Elixir's pattern matching operator
        return untyped __elixir__('$a === $b');
    }
}
```

### Embedding Variables

```haxe
class VariableEmbedding {
    public function embedHaxeInElixir(name: String, age: Int): String {
        // Embed Haxe variables in Elixir code
        return untyped __elixir__('
            "Hello #{$name}, you are #{$age} years old"
        ');
    }
    
    public function processWithElixir(data: Array<Int>): Dynamic {
        // Pass Haxe data to Elixir pipeline
        return untyped __elixir__('
            $data
            |> Enum.map(&(&1 * 2))
            |> Enum.filter(&(&1 > 5))
            |> Enum.sum()
        ');
    }
}
```

## Calling Elixir Modules

### Direct Module Calls

```haxe
// Define extern for existing Elixir module
@:native("MyApp.LegacyModule")
extern class LegacyModule {
    public static function processData(data: Dynamic): Dynamic;
    public static function validateInput(input: String): Bool;
}

// Use in Haxe code
class BusinessLogic {
    public function handleRequest(input: String): Dynamic {
        if (LegacyModule.validateInput(input)) {
            return LegacyModule.processData(input);
        }
        return null;
    }
}
```

### Calling Third-Party Libraries

```haxe
// HTTPoison library
@:native("HTTPoison")
extern class HTTPoison {
    public static function get(url: String, ?headers: Dynamic, ?options: Dynamic): Dynamic;
    public static function post(url: String, body: String, ?headers: Dynamic, ?options: Dynamic): Dynamic;
}

// Timex library
@:native("Timex")
extern class Timex {
    public static function now(): Dynamic;
    public static function shift(datetime: Dynamic, options: Dynamic): Dynamic;
    public static function format(datetime: Dynamic, format: String): String;
}

// Usage
class ApiClient {
    public function fetchData(): Dynamic {
        var response = HTTPoison.get("https://api.example.com/data");
        
        return switch (untyped response) {
            case {:ok, %{status_code: 200, body: body}}:
                parseResponse(body);
            case {:error, reason}:
                handleError(reason);
            default:
                null;
        };
    }
    
    public function getCurrentTime(): String {
        var now = Timex.now();
        return Timex.format(now, "{ISO:Extended}");
    }
}
```

## Using Elixir Libraries

### Defining Externs for Libraries

```haxe
// Phoenix.PubSub
@:native("Phoenix.PubSub")
extern class PubSub {
    public static function subscribe(pubsub: Dynamic, topic: String): Void;
    public static function broadcast(pubsub: Dynamic, topic: String, message: Dynamic): Dynamic;
}

// Ecto.Query
@:native("Ecto.Query")
extern class EctoQuery {
    public static function from(query: Dynamic): Dynamic;
    public static function where(query: Dynamic, conditions: Dynamic): Dynamic;
    public static function select(query: Dynamic, fields: Dynamic): Dynamic;
}

// Jason
@:native("Jason")
extern class Jason {
    public static function encode(term: Dynamic, ?opts: Dynamic): Dynamic;
    public static function decode(string: String, ?opts: Dynamic): Dynamic;
}
```

### Complex Library Integration

```haxe
// Absinthe GraphQL
@:native("Absinthe")
extern class Absinthe {
    @:native("run")
    public static function run(query: String, schema: Dynamic, ?options: Dynamic): Dynamic;
}

class GraphQLHandler {
    public function executeQuery(query: String, variables: Dynamic): Dynamic {
        var options = untyped __elixir__('
            [
              variables: $variables,
              context: %{current_user: nil}
            ]
        ');
        
        return Absinthe.run(query, MyAppGraphQL.Schema, options);
    }
}
```

## Inline Elixir with @:elixir

Custom annotation for embedding Elixir code:

```haxe
class MixedCode {
    @:elixir('
        def special_function(data) do
          data
          |> Enum.chunk_every(3)
          |> Enum.map(&Enum.sum/1)
        end
    ')
    public function specialFunction(data: Array<Int>): Array<Int> {
        // This will be replaced by the Elixir code above
        return [];
    }
    
    @:elixir('
        defp private_helper(x) do
          x * x + 2 * x + 1
        end
    ')
    private function privateHelper(x: Int): Int {
        return 0; // Placeholder
    }
}
```

## Extern Definitions

### Complete Extern Example

```haxe
// Complete extern for an Elixir GenServer
@:native("MyApp.Cache")
extern class CacheServer {
    // Client API
    public static function start_link(opts: Dynamic): Dynamic;
    public static function get(key: String): Dynamic;
    public static function put(key: String, value: Dynamic, ?ttl: Int): Dynamic;
    public static function delete(key: String): Bool;
    public static function clear(): Dynamic;
    
    // GenServer callbacks (if needed)
    public static function init(args: Dynamic): Dynamic;
    public static function handle_call(request: Dynamic, from: Dynamic, state: Dynamic): Dynamic;
    public static function handle_cast(msg: Dynamic, state: Dynamic): Dynamic;
}

// Usage
class DataService {
    public function getCachedData(key: String): Dynamic {
        var cached = CacheServer.get(key);
        
        return switch (untyped cached) {
            case {:ok, value}:
                value;
            case {:error, :not_found}:
                var fresh = fetchFreshData(key);
                CacheServer.put(key, fresh, 3600); // 1 hour TTL
                fresh;
            default:
                null;
        };
    }
}
```

### Extern with Type Parameters

```haxe
@:native("GenServer")
extern class GenServer<State> {
    @:native("start_link")
    public static function startLink<T>(module: Dynamic, args: T, ?options: Dynamic): Dynamic;
    
    @:native("call")
    public static function call<Request, Reply>(server: Dynamic, request: Request, ?timeout: Int): Reply;
    
    @:native("cast")
    public static function cast<Msg>(server: Dynamic, msg: Msg): Dynamic;
}
```

## Dynamic Types

When type safety isn't possible or needed:

```haxe
class DynamicInterop {
    public function workWithDynamic(): Void {
        // Everything is Dynamic
        var data: Dynamic = getElixirData();
        
        // Access fields dynamically
        var name = data.name;
        var age = data.age;
        
        // Call methods dynamically
        var result = data.process();
        
        // Pattern match on Dynamic
        switch (data) {
            case {type: "user", id: id}:
                handleUser(id);
            case {type: "admin", permissions: perms}:
                handleAdmin(perms);
            default:
                handleUnknown();
        }
    }
    
    public function convertDynamic(data: Dynamic): User {
        // Convert dynamic Elixir data to typed Haxe
        return {
            id: data.id,
            name: data.name,
            email: data.email,
            createdAt: Date.fromString(data.inserted_at)
        };
    }
}
```

## Macro Integration

### Calling Elixir Macros

```haxe
class MacroUser {
    public function useLogger(): Void {
        // Use Logger macros
        untyped __elixir__('
            require Logger
            Logger.info("Info message")
            Logger.debug("Debug message")
            Logger.error("Error message")
        ');
    }
    
    public function useEctoQuery(): Dynamic {
        // Use Ecto query macros
        return untyped __elixir__('
            import Ecto.Query
            
            from u in User,
              where: u.age > 18,
              select: u
        ');
    }
    
    public function usePhoenixHTML(): String {
        // Use Phoenix HTML helpers
        return untyped __elixir__('
            import Phoenix.HTML
            import Phoenix.HTML.Link
            
            link("Click me", to: "/path") |> safe_to_string()
        ');
    }
}
```

### Creating Wrapper Functions

```haxe
class MacroWrapper {
    public static function logInfo(message: String): Void {
        untyped __elixir__('
            require Logger
            Logger.info($message)
        ');
    }
    
    public static function logError(message: String, ?metadata: Dynamic): Void {
        if (metadata != null) {
            untyped __elixir__('
                require Logger
                Logger.error($message, $metadata)
            ');
        } else {
            untyped __elixir__('
                require Logger
                Logger.error($message)
            ');
        }
    }
}
```

## Best Practices

### 1. Prefer Type-Safe Wrappers

Instead of using `untyped` everywhere, create typed wrappers:

```haxe
// Bad
class Service {
    public function getData(): Dynamic {
        return untyped __elixir__('MyElixirModule.get_data()');
    }
}

// Good
@:native("MyElixirModule")
extern class MyElixirModule {
    @:native("get_data")
    public static function getData(): Array<UserData>;
}

class Service {
    public function getData(): Array<UserData> {
        return MyElixirModule.getData();
    }
}
```

### 2. Isolate Interop Code

Keep Elixir interop in separate modules:

```haxe
// interop/ElixirBridge.hx
class ElixirBridge {
    public static function callComplexElixir(data: Dynamic): Dynamic {
        return untyped __elixir__('
            # Complex Elixir code here
            ComplexModule.process($data)
        ');
    }
}

// BusinessLogic.hx
class BusinessLogic {
    public function process(input: String): Result {
        // Clean typed code
        var data = prepareData(input);
        var result = ElixirBridge.callComplexElixir(data);
        return parseResult(result);
    }
}
```

### 3. Document Escape Hatches

Always document why you're using escape hatches:

```haxe
class DataProcessor {
    /**
     * Uses raw Elixir for performance-critical ETS operations
     * that aren't available in typed API yet.
     */
    public function fastLookup(key: String): Dynamic {
        // TODO: Replace with typed API when available
        return untyped __elixir__('
            :ets.lookup(:cache, $key)
        ');
    }
}
```

### 4. Progressive Migration

When migrating existing Elixir code:

```haxe
// Step 1: Wrap existing Elixir module
@:native("LegacyModule")
extern class LegacyModule {
    public static function process(data: Dynamic): Dynamic;
}

// Step 2: Create typed wrapper
class TypedLegacyModule {
    public static function process(data: InputData): OutputData {
        var raw = LegacyModule.process(data);
        return parseOutput(raw);
    }
}

// Step 3: Gradually reimplement in Haxe
class ModernModule {
    public static function process(data: InputData): OutputData {
        // New Haxe implementation
        return processWithTypes(data);
    }
}
```

### 5. Testing Interop Code

```haxe
class InteropTest {
    public function testElixirCall(): Void {
        // Test the typed wrapper
        var result = MyElixirModule.getData();
        Assert.notNull(result);
        
        // Test error handling
        try {
            var bad = MyElixirModule.callWithBadData(null);
            Assert.fail("Should have thrown");
        } catch (e: Dynamic) {
            Assert.isTrue(true);
        }
    }
}
```

## Common Patterns

### Pattern 1: Elixir Tuple Handling

```haxe
class TupleHandler {
    public function handleElixirResult(result: Dynamic): String {
        return switch (untyped result) {
            case {:ok, value}:
                'Success: $value';
            case {:error, reason}:
                'Error: $reason';
            case _:
                "Unknown result";
        };
    }
}
```

### Pattern 2: Pipeline Operations

**Note**: Reflaxe.Elixir has native pipe operator support. The older standalone pipe-operators guide was archived here: [Pipe Operators Guide](../09-history/archive/docs/06-guides/pipe-operators.md).

```haxe
// Preferred: Native pipe support (type-safe)
class TypedPipeline {
    public function processData(data: Array<Int>): Int {
        return data
            .filter(x -> x > 0)
            .map(x -> x * 2)
            .reduce((a, b) -> a + b, 0);
        // Compiles to Elixir pipes automatically!
    }
}

// Escape hatch: For Elixir-specific patterns
class Pipeline {
    public function processPipeline(data: Array<Int>): Int {
        return untyped __elixir__('
            $data
            |> Enum.map(&(&1 * 2))
            |> Enum.filter(&(&1 > 10))
            |> Enum.reduce(0, &+/2)
        ');
    }
}
```

### Pattern 3: With Expressions

```haxe
class WithExpression {
    public function complexOperation(input: String): Dynamic {
        return untyped __elixir__('
            with {:ok, parsed} <- parse_input($input),
                 {:ok, validated} <- validate(parsed),
                 {:ok, result} <- process(validated) do
              {:success, result}
            else
              {:error, reason} -> {:failure, reason}
            end
        ');
    }
}
```

## Limitations and Gotchas

1. **Type Information Lost**: When using `untyped` or `Dynamic`, you lose compile-time type checking
2. **Macro Timing**: Elixir macros execute at Elixir compile time, not Haxe compile time
3. **Pattern Matching**: Haxe pattern matching is more limited than Elixir's
4. **Atoms**: Use `untyped :atom_name` or create an enum abstraction
5. **Processes**: Process spawning and message passing needs `untyped` blocks

## Summary

Escape hatches in Reflaxe.Elixir provide:
- ✅ Direct access to any Elixir code
- ✅ Integration with existing Elixir modules
- ✅ Use of Elixir-specific features
- ✅ Progressive migration paths
- ✅ Performance optimizations when needed

Use them wisely to maintain the benefits of type safety while leveraging the full power of the Elixir ecosystem!
