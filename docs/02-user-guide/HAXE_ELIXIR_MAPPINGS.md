# Haxe→Elixir Language Mappings Reference

**Complete guide to how Haxe constructs map to Elixir code**

## Table of Contents

- [Overview](#overview)
- [Core Language Mappings](#core-language-mappings)
- [Type System Mappings](#type-system-mappings)
- [Annotation-Driven Transformations](#annotation-driven-transformations)
- [Function and Method Mappings](#function-and-method-mappings)
- [Control Flow Mappings](#control-flow-mappings)
- [Pattern Matching](#pattern-matching)
- [Cross-Platform Type Safety](#cross-platform-type-safety)
- [Ergonomic Features](#ergonomic-features)
- [Migration Patterns](#migration-patterns)

## Overview

Reflaxe.Elixir transforms idiomatic Haxe code into idiomatic Elixir code. This document provides a comprehensive reference for how each Haxe construct maps to its Elixir equivalent.

### Design Philosophy

- **Predictable Mappings**: Similar Haxe constructs produce similar Elixir patterns
- **Idiomatic Output**: Generated Elixir follows BEAM/OTP conventions
- **Type Safety Preservation**: Compile-time safety translates to runtime correctness
- **Annotation-Driven Specialization**: Use annotations to override defaults for specialized patterns

## Core Language Mappings

### Classes → Modules

**Default Behavior**: All Haxe classes become Elixir modules.

**Haxe Input**:
```haxe
class UserService {
    public static function create(name: String): User {
        return new User(name);
    }
    
    public function greet(user: User): String {
        return 'Hello, ${user.name}!';
    }
}
```

**Generated Elixir**:
```elixir
defmodule UserService do
  @doc """
  UserService module generated from Haxe
  """
  
  @spec create(String.t()) :: User.t()
  def create(name) do
    User.new(name)
  end
  
  @spec greet(User.t()) :: String.t()
  def greet(user) do
    "Hello, #{user.name}!"
  end
end
```

**Key Transformations**:
- Class name → Module name
- Static methods → `def` functions  
- Instance methods → `def` functions (with implied context)
- Public visibility → Public functions
- Private visibility → `defp` functions

### Enums → Tagged Tuples/Atoms

**Simple Enums** (no data) → **Atoms**:

**Haxe Input**:
```haxe
enum Color {
    Red;
    Green;
    Blue;
}
```

**Generated Elixir**:
```elixir
# Usage generates atoms: :red, :green, :blue
```

**Enums with Data** → **Tagged Tuples**:

**Haxe Input**:
```haxe
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}
```

**Generated Elixir**:
```elixir
# Usage generates: {:ok, value}, {:error, error}
```

**Complex Enums** → **Tagged Tuples with Multiple Fields**:

**Haxe Input**:
```haxe
enum Shape {
    Circle(radius: Float);
    Rectangle(width: Float, height: Float);
    Triangle(a: Float, b: Float, c: Float);
}
```

**Generated Elixir**:
```elixir
# Usage generates:
# {:circle, radius}
# {:rectangle, width, height}  
# {:triangle, a, b, c}
```

### Interfaces → Protocols/Behaviours

**Default**: Interfaces become Elixir Protocols for polymorphic behavior.

**Haxe Input**:
```haxe
interface Drawable {
    function draw(): String;
    function area(): Float;
}
```

**Generated Elixir**:
```elixir
defprotocol Drawable do
  @doc "Draw the shape"
  @spec draw(t()) :: String.t()
  def draw(shape)
  
  @doc "Calculate the area"
  @spec area(t()) :: float()
  def area(shape)
end
```

### Typedefs → Type Specifications

**Type Aliases**:

**Haxe Input**:
```haxe
typedef UserId = Int;
typedef UserName = String;
```

**Generated Elixir**:
```elixir
@type user_id :: integer()
@type user_name :: String.t()
```

**Structural Types**:

**Haxe Input**:
```haxe
typedef User = {
    id: Int,
    name: String,
    ?email: String,
    active: Bool
}
```

**Generated Elixir**:
```elixir
@type user :: %{
  id: integer(),
  name: String.t(),
  email: String.t() | nil,
  active: boolean()
}
```

## Type System Mappings

| Haxe Type | Elixir Type | Notes |
|-----------|-------------|-------|
| `Int` | `integer()` | Arbitrary precision integers |
| `Float` | `float()` | IEEE 754 double precision |
| `String` | `String.t()` | UTF-8 binary strings |
| `Bool` | `boolean()` | `true` or `false` atoms |
| `Array<T>` | `list(T)` | Immutable linked lists |
| `Map<K,V>` | `map(K, V)` | Immutable hash maps |
| `Dynamic` | `term()` | Any Elixir term |
| `Void` | `:ok` or `nil` | Context dependent |
| `Null<T>` | `T \| nil` | Nullable types |
| `Option<T>` | `{:some, T} \| :none` | Type-safe null handling |
| `Result<T,E>` | `{:ok, T} \| {:error, E}` | Explicit error handling |

### Special Type Compilations

**Option<T> Pattern**:
```haxe
// Haxe
var user: Option<User> = findUser(123);
switch (user) {
    case Some(u): processUser(u);
    case None: handleNotFound();
}
```

```elixir
# Generated Elixir
user = find_user(123)
case user do
  {:some, u} -> process_user(u)
  :none -> handle_not_found()
end
```

**Result<T,E> Pattern**:
```haxe
// Haxe
var result: Result<User, String> = validateUser(data);
switch (result) {
    case Ok(user): createUser(user);
    case Error(msg): logError(msg);
}
```

```elixir
# Generated Elixir
result = validate_user(data)
case result do
  {:ok, user} -> create_user(user)
  {:error, msg} -> log_error(msg)
end
```

## Annotation-Driven Transformations

Annotations override default class→module mapping for specialized Elixir patterns:

| Annotation | Generated Module Type | Primary Use Case |
|------------|----------------------|------------------|
| `@:module` | Plain module with functions | Utility functions, stateless services |
| `@:struct` | Module with `defstruct` | Data containers, DTOs |
| `@:genserver` | OTP GenServer | Stateful processes, caches |
| `@:liveview` | Phoenix LiveView | Real-time UI components |
| `@:controller` | Phoenix Controller | HTTP request handlers |
| `@:router` | Phoenix Router | Request routing logic |
| `@:channel` | Phoenix Channel | WebSocket handling |
| `@:schema` | Ecto Schema | Database models |
| `@:changeset` | Ecto Changeset | Data validation |
| `@:protocol` | Elixir Protocol | Polymorphic behavior |
| `@:behaviour` | Elixir Behaviour | Callback contracts |
| `@:supervisor` | OTP Supervisor | Process supervision |
| `@:application` | OTP Application | Application entry point |

### Example: GenServer Transformation

**Haxe Input**:
```haxe
@:genserver
class Counter {
    private var count: Int = 0;
    
    @:call
    public function get(): Int {
        return count;
    }
    
    @:cast
    public function increment(): Void {
        count++;
    }
}
```

**Generated Elixir**:
```elixir
defmodule Counter do
  use GenServer
  
  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end
  
  def get(pid) do
    GenServer.call(pid, :get)
  end
  
  def increment(pid) do
    GenServer.cast(pid, :increment)
  end
  
  # Server Callbacks
  @impl true
  def init(:ok) do
    {:ok, %{count: 0}}
  end
  
  @impl true
  def handle_call(:get, _from, %{count: count} = state) do
    {:reply, count, state}
  end
  
  @impl true
  def handle_cast(:increment, %{count: count} = state) do
    {:noreply, %{state | count: count + 1}}
  end
end
```

## Function and Method Mappings

### Static Methods → Module Functions

**Haxe Input**:
```haxe
class MathUtils {
    public static function add(a: Int, b: Int): Int {
        return a + b;
    }
    
    private static function multiply(a: Int, b: Int): Int {
        return a * b;
    }
}
```

**Generated Elixir**:
```elixir
defmodule MathUtils do
  @spec add(integer(), integer()) :: integer()
  def add(a, b) do
    a + b
  end
  
  @spec multiply(integer(), integer()) :: integer()
  defp multiply(a, b) do
    a * b
  end
end
```

### Instance Methods → Functions with Context

**Haxe Input**:
```haxe
class Calculator {
    private var memory: Float = 0;
    
    public function add(value: Float): Float {
        memory += value;
        return memory;
    }
    
    public function getMemory(): Float {
        return memory;
    }
}
```

**Generated Elixir**:
```elixir
defmodule Calculator do
  defstruct [:memory]
  
  def new() do
    %Calculator{memory: 0}
  end
  
  def add(%Calculator{memory: memory} = calc, value) do
    new_memory = memory + value
    {new_memory, %{calc | memory: new_memory}}
  end
  
  def get_memory(%Calculator{memory: memory}) do
    memory
  end
end
```

### Anonymous Functions

**Haxe Input**:
```haxe
var numbers = [1, 2, 3, 4, 5];
var doubled = numbers.map(x -> x * 2);
var filtered = numbers.filter(function(x) return x > 3);
```

**Generated Elixir**:
```elixir
numbers = [1, 2, 3, 4, 5]
doubled = Enum.map(numbers, fn x -> x * 2 end)
filtered = Enum.filter(numbers, fn x -> x > 3 end)
```

## Control Flow Mappings

### Switch Statements → Case Expressions

**Haxe Input**:
```haxe
function processStatus(status: Status): String {
    return switch (status) {
        case Pending: "Waiting";
        case Processing(progress): 'In progress: ${progress}%';
        case Completed(result): 'Done: ${result}';
        case Failed(error): 'Error: ${error}';
    }
}
```

**Generated Elixir**:
```elixir
def process_status(status) do
  case status do
    :pending -> "Waiting"
    {:processing, progress} -> "In progress: #{progress}%"
    {:completed, result} -> "Done: #{result}"
    {:failed, error} -> "Error: #{error}"
  end
end
```

### Loops → Functional Operations

**For Loops → Enum Operations**:

**Haxe Input**:
```haxe
var total = 0;
for (item in items) {
    total += item.value;
}
```

**Generated Elixir**:
```elixir
total = Enum.reduce(items, 0, fn item, acc -> acc + item.value end)
```

**While Loops → Recursive Functions**:

**Haxe Input**:
```haxe
var count = 0;
while (count < 10) {
    trace(count);
    count++;
}
```

**Generated Elixir**:
```elixir
(fn loop_fn ->
  count = 0
  if count < 10 do
    IO.inspect(count)
    count = count + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
```

### Conditional Expressions

**Haxe Input**:
```haxe
var message = if (user.isActive) {
    "Welcome back!";
} else {
    "Please activate your account";
}
```

**Generated Elixir**:
```elixir
message = if user.is_active do
  "Welcome back!"
else
  "Please activate your account"
end
```

## Pattern Matching

### Destructuring Assignments

**Haxe Input**:
```haxe
var {name, age} = user;
var [first, second, ...rest] = items;
```

**Generated Elixir**:
```elixir
%{name: name, age: age} = user
[first, second | rest] = items
```

### Complex Pattern Matching

**Haxe Input**:
```haxe
function handleResponse(response: Response): String {
    return switch (response) {
        case Success({data: userData, status: 200}): 
            'User: ${userData.name}';
        case Success({status: code}) if (code >= 200 && code < 300): 
            "Success with code " + code;
        case Error({message: msg, code: 404}): 
            "Not found: " + msg;
        case Error({message: msg}): 
            "Error: " + msg;
        case _: 
            "Unknown response";
    }
}
```

**Generated Elixir**:
```elixir
def handle_response(response) do
  case response do
    {:success, %{data: user_data, status: 200}} ->
      "User: #{user_data.name}"
    {:success, %{status: code}} when code >= 200 and code < 300 ->
      "Success with code #{code}"
    {:error, %{message: msg, code: 404}} ->
      "Not found: #{msg}"
    {:error, %{message: msg}} ->
      "Error: #{msg}"
    _ ->
      "Unknown response"
  end
end
```

## Cross-Platform Type Safety

### Option<T> - Universal Null Safety

Works consistently across all Haxe targets while generating platform-optimal code:

**Haxe Source**:
```haxe
import haxe.ds.Option;
using haxe.ds.OptionTools;

function findUser(id: Int): Option<User> {
    var user = database.query("users", {id: id});
    return user != null ? Some(user) : None;
}

function processUser(id: Int): String {
    return findUser(id)
        .map(user -> user.name)
        .filter(name -> name.length > 0)
        .unwrap("Anonymous");
}
```

**Elixir Compilation**:
```elixir
def find_user(id) do
  user = Database.query("users", %{id: id})
  if user != nil do
    {:some, user}
  else
    :none
  end
end

def process_user(id) do
  case find_user(id) do
    {:some, user} when byte_size(user.name) > 0 -> user.name
    _ -> "Anonymous"
  end
end
```

### Result<T,E> - Universal Error Handling

**Haxe Source**:
```haxe
import haxe.functional.Result;
using haxe.functional.ResultTools;

function validateUser(data: UserData): Result<User, ValidationError> {
    return validateEmail(data.email)
        .flatMap(_ -> validateAge(data.age))
        .map(age -> new User(data.email, age));
}

function processUsers(dataList: Array<UserData>): Result<Array<User>, ValidationError> {
    return ResultTools.traverse(dataList, validateUser);
}
```

**Elixir Compilation**:
```elixir
def validate_user(data) do
  case validate_email(data.email) do
    {:ok, _} ->
      case validate_age(data.age) do
        {:ok, age} -> {:ok, User.new(data.email, age)}
        {:error, reason} -> {:error, reason}
      end
    {:error, reason} -> {:error, reason}
  end
end

def process_users(data_list) do
  Enum.reduce_while(data_list, {:ok, []}, fn data, {:ok, acc} ->
    case validate_user(data) do
      {:ok, user} -> {:cont, {:ok, [user | acc]}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end)
  |> case do
    {:ok, users} -> {:ok, Enum.reverse(users)}
    {:error, reason} -> {:error, reason}
  end
end
```

## Ergonomic Features

### Intelligent Pattern Detection

The compiler can detect common patterns and optimize accordingly:

**Method Chaining → Pipe Operators**:
```haxe
// Haxe input
var result = data
    .filter(x -> x > 0)
    .map(x -> x * 2)
    .reduce((a, b) -> a + b);
```

```elixir
# Generated Elixir (optimized)
result = data
|> Enum.filter(&(&1 > 0))
|> Enum.map(&(&1 * 2))
|> Enum.reduce(&+/2)
```

**Data-Only Classes → Structs**:
```haxe
// Haxe input (detected as data-only)
class Point {
    public var x: Float;
    public var y: Float;
    
    public function new(x: Float, y: Float) {
        this.x = x;
        this.y = y;
    }
}
```

```elixir
# Generated Elixir
defmodule Point do
  defstruct [:x, :y]
  
  def new(x, y) do
    %Point{x: x, y: y}
  end
end
```

### Smart Array/List Operations

The compiler optimizes array operations to use appropriate Elixir functions:

**Haxe Input**:
```haxe
var numbers = [1, 2, 3, 4, 5];
var doubled = numbers.map(x -> x * 2);
var filtered = numbers.filter(x -> x > 3);
var total = numbers.reduce((a, b) -> a + b);
var length = numbers.length;
var contains = numbers.contains(3);
```

**Generated Elixir**:
```elixir
numbers = [1, 2, 3, 4, 5]
doubled = Enum.map(numbers, fn x -> x * 2 end)
filtered = Enum.filter(numbers, fn x -> x > 3 end)
total = Enum.reduce(numbers, fn a, b -> a + b end)
length = length(numbers)
contains = Enum.member?(numbers, 3)
```

## Migration Patterns

### From Nullable Types to Option<T>

**Phase 1: Identify Nullable APIs**
```haxe
// Current nullable approach
function findUser(id: Int): Null<User> {
    // Implementation
}

// Usage requires null checks
var user = findUser(123);
if (user != null) {
    processUser(user);
}
```

**Phase 2: Migrate to Option<T>**
```haxe
// Migrated to Option
function findUser(id: Int): Option<User> {
    var user = database.find(id);
    return user != null ? Some(user) : None;
}

// Type-safe usage
switch (findUser(123)) {
    case Some(user): processUser(user);
    case None: handleNotFound();
}
```

**Phase 3: Leverage Functional Operations**
```haxe
// Functional style
function getUserEmail(id: Int): String {
    return findUser(id)
        .map(user -> user.email)
        .filter(email -> email != "")
        .unwrap("no-email@example.com");
}
```

### From Exception-Based to Result<T,E>

**Phase 1: Exception-Based Approach**
```haxe
function processPayment(amount: Float): Transaction {
    try {
        var validation = validateAmount(amount);
        var payment = chargeCard(amount);
        return createTransaction(payment);
    } catch (e: PaymentError) {
        throw e; // Error information can be lost
    }
}
```

**Phase 2: Result-Based Approach**
```haxe
function processPayment(amount: Float): Result<Transaction, PaymentError> {
    return validateAmount(amount)
        .flatMap(validAmount -> chargeCard(validAmount))
        .map(payment -> createTransaction(payment));
}

// Caller must handle both cases
switch (processPayment(100.0)) {
    case Ok(transaction): completeOrder(transaction);
    case Error(error): handlePaymentError(error);
}
```

## See Also

- [Functional Patterns](../07-patterns/FUNCTIONAL_PATTERNS.md) - Examples of imperative→functional transformations
- [Annotations Reference](../04-api-reference/ANNOTATIONS.md) - Complete annotation documentation
- [Compiler Best Practices](../03-compiler-development/COMPILER_BEST_PRACTICES.md) - Patterns and conventions for compiler/std development
- [ExUnit Testing Guide](exunit-testing.md) - Testing patterns for mapped constructs

## References

- [Elixir Language Reference](https://hexdocs.pm/elixir/)
- [OTP Design Principles](https://erlang.org/doc/design_principles/users_guide.html)
- [Gleam Language](https://gleam.run/) - Inspiration for type-safe BEAM patterns
- [Phoenix Framework](https://hexdocs.pm/phoenix/) - Web framework patterns
