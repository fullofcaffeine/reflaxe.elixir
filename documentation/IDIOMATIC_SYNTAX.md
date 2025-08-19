# Idiomatic Haxe.Elixir Syntax Guide

This guide covers the idiomatic syntax patterns and transformations that Haxe.Elixir provides to write type-safe code that compiles to clean, idiomatic Elixir.

## Core Philosophy

**"Write idiomatic Haxe → Get idiomatic Elixir"**

### Translation Principles

1. **Look Hand-Written**: Generated code should be indistinguishable from manual Elixir
2. **Performance**: Use efficient Elixir patterns (++ for concat, not Enum.concat)
3. **Predictability**: Developers can reason about the output
4. **Interoperability**: Seamless integration with Phoenix/Ecto/OTP

This is achieved through three strategies:
1. **Natural Mappings** (90%): Direct transformations (method chains → pipes)
2. **Custom Constructs** (9%): Haxe-friendly syntax for Elixir-specific patterns
3. **Escape Hatches** (1%): Direct Elixir when needed

### Why These Design Decisions?

Every translation decision prioritizes **idiomatic output**. For example:
- We use `++` for list concatenation because that's what Elixir developers write
- We use `length/1` not `Enum.count/1` for lists because it's more idiomatic
- We generate `Enum.member?/2` with the `?` suffix to follow Elixir conventions

## Table of Contents
- [Pipe Operators](#pipe-operators)
- [Pattern Matching](#pattern-matching)
- [Tuples and Atoms](#tuples-and-atoms)
- [Module Attributes](#module-attributes)
- [Function Heads and Guards](#function-heads-and-guards)
- [With Expressions](#with-expressions)
- [Comprehensions](#comprehensions)
- [Process and Message Passing](#process-and-message-passing)
- [Structs and Records](#structs-and-records)
- [Protocols and Behaviours](#protocols-and-behaviours)

## Pipe Operators

Haxe.Elixir features **intelligent pipeline optimization** that automatically detects sequential operations and transforms them into idiomatic Elixir pipeline operators (`|>`).

### Automatic Pipeline Detection ✨ **NEW**

The compiler analyzes your Haxe code and automatically detects these patterns:

**Pattern 1: Sequential Variable Operations**
```haxe
// Haxe code - Sequential operations on same variable
socket = assign(socket, :name, "Alice");
socket = assign(socket, :age, 30);
socket = assign(socket, :status, :active);
```

```elixir
# Generated Elixir - Automatic pipeline transformation
socket
  |> assign(:name, "Alice")
  |> assign(:age, 30)
  |> assign(:status, :active)
```

**Pattern 2: Method Chaining**
```haxe
// Haxe code - Method chaining
var result = input
    .trim()
    .toLowerCase()
    .split(" ")
    .filter(word -> word.length > 3)
    .map(word -> word.capitalize());
```

```elixir
# Generated Elixir - Method chains become pipelines
result = input
  |> String.trim()
  |> String.downcase()
  |> String.split(" ")
  |> Enum.filter(&(String.length(&1) > 3))
  |> Enum.map(&String.capitalize/1)
```

### Pipeline Pattern Recognition ⚡ **NEW**

The compiler intelligently recognizes these patterns and automatically optimizes them:

**Phoenix LiveView Assign Chains:**
```haxe
// Traditional sequential assignments
socket = assign(socket, :current_user, user);
socket = assign(socket, :todos, todos);
socket = assign(socket, :loading, false);
```

Becomes:
```elixir
# Idiomatic pipeline
socket
  |> assign(:current_user, user)
  |> assign(:todos, todos)
  |> assign(:loading, false)
```

**Enum Operations:**
```haxe
// Sequential transformations
data = Enum.filter(data, x -> x.active);
data = Enum.map(data, x -> x.name);
data = Enum.sort(data);
```

Becomes:
```elixir
# Functional pipeline
data
  |> Enum.filter(&(&1.active))
  |> Enum.map(&(&1.name))
  |> Enum.sort()
```

### When Pipeline Optimization Triggers

The optimization automatically activates when:
- **2+ sequential operations** on the same variable
- **Variable reassignment pattern**: `var = func(var, args)`
- **Recognized pipeline functions**: `assign`, `push_event`, `map`, `filter`, etc.
- **Non-conflicting statements**: No complex control flow between operations

### Complex Pipelines

```haxe
// Phoenix controller pipeline
@:controller
class UserController {
    public function update(conn: Conn, params: Params): Conn {
        return conn
            .fetchUser(params.id)
            .authorize(:update)
            .updateAttributes(params.user)
            .putFlash(:info, "Updated successfully")
            .redirect(to: userPath(conn, :show, params.id));
    }
}
```

See [Pipe Operators Guide](guides/pipe-operators.md) for comprehensive documentation.

## Pattern Matching

### Switch Expressions

```haxe
// Haxe pattern matching
var result = switch (response) {
    case {status: 200, body: data}:
        processData(data);
    case {status: 404}:
        notFound();
    case {status: code} if (code >= 500):
        serverError(code);
    case _:
        unknownResponse();
};
```

```elixir
# Generated Elixir
result = case response do
  %{status: 200, body: data} ->
    process_data(data)
  %{status: 404} ->
    not_found()
  %{status: code} when code >= 500 ->
    server_error(code)
  _ ->
    unknown_response()
end
```

### Destructuring

```haxe
// Destructuring in function parameters
public function processUser({name, email, age}: User): String {
    return 'User $name ($email) is $age years old';
}

// Array destructuring
var [first, second, ...rest] = myArray;

// Tuple destructuring
var {ok: value} = fetchData();
```

## Tuples and Atoms

### Tuple Syntax

```haxe
// Creating tuples
var success = {:ok, value};
var error = {:error, "Not found"};
var triple = {1, "two", 3.0};

// Pattern matching tuples
switch (result) {
    case {:ok, data}:
        handleSuccess(data);
    case {:error, reason}:
        handleError(reason);
}
```

### Atom Literals

```haxe
// Atom literals using : prefix
var atom = :my_atom;
var status = :active;

// In annotations
@:genserver(name: :my_server)
class MyServer {
    // ...
}
```

## Module Attributes

### Compile-Time Attributes

```haxe
@:module_attribute("vsn", "1.0.0")
@:module_attribute("author", "Your Name")
@:moduledoc("
  This module handles user authentication.
  
  ## Examples
  
      iex> Auth.login(\"user\", \"pass\")
      {:ok, %User{}}
")
class Auth {
    @:doc("Authenticates a user with credentials")
    public function login(username: String, password: String): Result<User> {
        // ...
    }
}
```

```elixir
# Generated Elixir
defmodule Auth do
  @vsn "1.0.0"
  @author "Your Name"
  @moduledoc """
  This module handles user authentication.
  
  ## Examples
  
      iex> Auth.login("user", "pass")
      {:ok, %User{}}
  """
  
  @doc "Authenticates a user with credentials"
  def login(username, password) do
    # ...
  end
end
```

## Function Heads and Guards

### Multiple Function Heads

```haxe
class Calculator {
    // Function overloading becomes multiple heads
    public function factorial(0): Int {
        return 1;
    }
    
    public function factorial(n: Int) when (n > 0): Int {
        return n * factorial(n - 1);
    }
    
    public function factorial(n: Int): Never {
        throw "Negative numbers not supported";
    }
}
```

```elixir
# Generated Elixir
defmodule Calculator do
  def factorial(0), do: 1
  
  def factorial(n) when n > 0 do
    n * factorial(n - 1)
  end
  
  def factorial(n) do
    raise "Negative numbers not supported"
  end
end
```

### Guard Clauses

```haxe
// Using @:guard annotation
class Validator {
    @:guard("is_binary(input) and byte_size(input) > 0")
    public function validateString(input: String): Bool {
        return true;
    }
    
    @:guard("is_number(value) and value >= min and value <= max")
    public function inRange(value: Float, min: Float, max: Float): Bool {
        return true;
    }
}
```

## With Expressions

### Type-Safe With

```haxe
// Using Result type for with expressions
class FileProcessor {
    public function processFile(path: String): Result<ProcessedData> {
        return with(
            file <- File.read(path),
            json <- Json.decode(file),
            validated <- validate(json),
            processed <- process(validated)
        ) {
            return {:ok, processed};
        } else {
            {:error, reason} -> {:error, 'Failed: $reason'};
        };
    }
}
```

```elixir
# Generated Elixir
def process_file(path) do
  with {:ok, file} <- File.read(path),
       {:ok, json} <- Jason.decode(file),
       {:ok, validated} <- validate(json),
       {:ok, processed} <- process(validated) do
    {:ok, processed}
  else
    {:error, reason} -> {:error, "Failed: #{reason}"}
  end
end
```

## Comprehensions

### List Comprehensions

```haxe
// For comprehensions
class DataProcessor {
    public function processItems(items: Array<Item>): Array<Result> {
        return for (item in items) {
            if (item.active) {
                for (tag in item.tags) {
                    if (tag.priority > 5) {
                        yield processTag(item, tag);
                    }
                }
            }
        };
    }
}
```

```elixir
# Generated Elixir
def process_items(items) do
  for item <- items,
      item.active,
      tag <- item.tags,
      tag.priority > 5 do
    process_tag(item, tag)
  end
end
```

### Generator Expressions

```haxe
// Generating maps and binaries
class Generator {
    public function generateMap(pairs: Array<Pair>): Map<String, Int> {
        return for ({key, value} in pairs) into %{} {
            {key, value * 2}
        };
    }
    
    public function generateBinary(bytes: Array<Int>): Binary {
        return for (byte in bytes) into <<>> {
            <<byte>>
        };
    }
}
```

## Process and Message Passing

### Spawning Processes

```haxe
class ProcessManager {
    public function startWorker(task: Task): Pid {
        return spawn(() -> {
            performTask(task);
        });
    }
    
    public function startLinkedWorker(task: Task): Pid {
        return spawn_link(() -> {
            performTask(task);
        });
    }
    
    public function sendMessage(pid: Pid, message: Message): Void {
        send(pid, message);
    }
}
```

### Receiving Messages

```haxe
@:genserver
class MessageHandler {
    public function handleInfo(message: Dynamic, state: State): {Symbol, State} {
        return receive {
            {:data, payload} -> 
                processData(payload);
                {:noreply, updateState(state, payload)};
            {:shutdown} ->
                cleanup();
                {:stop, :normal, state};
            after 5000 ->
                {:noreply, state};
        };
    }
}
```

## Structs and Records

### Defining Structs

```haxe
@:struct
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var active: Bool = true;  // Default value
    
    // Constructor becomes struct creation
    public function new(id: Int, name: String, email: String) {
        this.id = id;
        this.name = name;
        this.email = email;
    }
}

// Usage
var user = new User(1, "Alice", "alice@example.com");
var updated = {...user, active: false};  // Struct update syntax
```

```elixir
# Generated Elixir
defmodule User do
  defstruct [:id, :name, :email, active: true]
  
  def new(id, name, email) do
    %User{
      id: id,
      name: name,
      email: email
    }
  end
end

# Usage
user = User.new(1, "Alice", "alice@example.com")
updated = %{user | active: false}
```

## Protocols and Behaviours

### Protocol Definition

```haxe
@:protocol
interface Serializable {
    function serialize(): String;
    function deserialize(data: String): Self;
}

// Implementation for specific type
@:impl(Serializable)
class UserSerializer {
    public static function serialize(user: User): String {
        return Json.encode(user);
    }
    
    public static function deserialize(data: String): User {
        return Json.decode(data, User);
    }
}
```

### Behaviour Contracts

```haxe
@:behaviour
interface Storage {
    function get(key: String): Result<Dynamic>;
    function put(key: String, value: Dynamic): Result<Void>;
    function delete(key: String): Result<Void>;
}

@:implements(Storage)
class RedisStorage {
    public function get(key: String): Result<Dynamic> {
        // Redis implementation
    }
    
    public function put(key: String, value: Dynamic): Result<Void> {
        // Redis implementation
    }
    
    public function delete(key: String): Result<Void> {
        // Redis implementation
    }
}
```

## Special Syntax Features

### Capture Operator (&)

```haxe
// Function capture
var addOne = &(add(1, &1));
var result = list.map(addOne);

// Module function capture
var trimmer = &String.trim/1;
var trimmed = list.map(trimmer);
```

### Pin Operator (^)

```haxe
// Pinning in pattern matching
var expected = 42;
switch (getValue()) {
    case ^expected:  // Pin operator - must match expected value
        trace("Got expected value");
    case other:
        trace('Got $other instead');
}
```

### Range Syntax

```haxe
// Range literals
var range1 = 1..10;     // Inclusive: 1 to 10
var range2 = 1...10;    // Exclusive: 1 to 9

for (i in 1..100) {
    process(i);
}
```

### Binary Pattern Matching

```haxe
// Binary matching
public function parseBinary(data: Binary): Result<Header> {
    return switch (data) {
        case <<version:8, flags:16, rest:binary>>:
            {:ok, {version: version, flags: flags, data: rest}};
        case _:
            {:error, "Invalid format"};
    };
}
```

## Async/Await Pattern (Task)

```haxe
class AsyncOperations {
    public async function fetchData(): Task<Data> {
        var user = await fetchUser();
        var profile = await fetchProfile(user.id);
        var posts = await fetchPosts(user.id);
        
        return {
            user: user,
            profile: profile,
            posts: posts
        };
    }
}
```

```elixir
# Generated Elixir
def fetch_data do
  Task.async(fn ->
    user = fetch_user() |> Task.await()
    profile = fetch_profile(user.id) |> Task.await()
    posts = fetch_posts(user.id) |> Task.await()
    
    %{
      user: user,
      profile: profile,
      posts: posts
    }
  end)
end
```

## String Interpolation

```haxe
// Haxe string interpolation
var name = "Alice";
var age = 30;
var message = 'Hello $name, you are ${age} years old';
var multiline = '
    Welcome $name!
    Your account has been active for ${calculateDays()} days.
';
```

```elixir
# Generated Elixir
name = "Alice"
age = 30
message = "Hello #{name}, you are #{age} years old"
multiline = """
    Welcome #{name}!
    Your account has been active for #{calculate_days()} days.
"""
```

## Sigils

```haxe
// Regular expressions
var regex = ~r/[a-z]+/i;

// Word lists
var words = ~w(apple banana cherry);

// Charlist
var charlist = ~c"hello world";

// Custom sigils
@:sigil("Z")
class CustomSigil {
    public static function sigil_Z(content: String, modifiers: String): Dynamic {
        // Custom sigil implementation
    }
}
```

## Dynamic Type Considerations

### When to Use Dynamic

While Haxe's type system is a core strength, Dynamic types are sometimes necessary:

```haxe
// Acceptable Dynamic usage - External API integration
var apiResponse: Dynamic = Json.parse(responseText);
var items = apiResponse.data.items;

// Better - Progressive typing as API stabilizes
typedef ApiResponse = {
    data: {
        items: Array<Item>
    }
}
var apiResponse: ApiResponse = Json.parse(responseText);
```

### Dynamic Transformations

The compiler intelligently handles Dynamic types:

```haxe
// Haxe with Dynamic
var data: Dynamic = getData();
var filtered = data.items.filter(x -> x.active);
var count = data.items.length;
```

```elixir
# Generated Elixir - Still idiomatic!
data = get_data()
filtered = Enum.filter(data.items, fn x -> x.active end)
count = length(data.items)
```

**Key Point**: Even with Dynamic types, generated code remains idiomatic through intelligent method detection.

**See**: [`documentation/DYNAMIC_HANDLING.md`](DYNAMIC_HANDLING.md) for detailed Dynamic handling patterns.

## Best Practices

1. **Use Native Syntax**: Prefer Haxe.Elixir's idiomatic transformations over escape hatches
2. **Type Safety First**: Leverage Haxe's type system for compile-time guarantees
3. **Pattern Consistency**: Use consistent patterns throughout your codebase
4. **Documentation**: Document any non-obvious syntax transformations
5. **Gradual Adoption**: Mix idiomatic Haxe.Elixir with escape hatches during migration
6. **Progressive Typing**: Start with Dynamic for prototypes, add types as APIs stabilize

## Summary

Haxe.Elixir provides comprehensive syntax transformations that allow you to write type-safe Haxe code that compiles to idiomatic Elixir. Key features include:

- ✅ Automatic pipe operator transformation
- ✅ Pattern matching with exhaustiveness checking
- ✅ Native tuple and atom support
- ✅ Module attributes and documentation
- ✅ Guards and multiple function heads
- ✅ Comprehensions and generators
- ✅ Process and message passing primitives
- ✅ Protocol and behaviour support

This enables you to leverage Elixir's expressive syntax while maintaining Haxe's compile-time type safety!