# The Paradigm Bridge: From Imperative Haxe to Functional Elixir

## Table of Contents
- [Philosophy](#philosophy)
- [Core Concept: Mutability vs Immutability](#core-concept-mutability-vs-immutability)
- [Transformation Patterns](#transformation-patterns)
- [Performance Implications](#performance-implications)
- [Decision Matrix](#decision-matrix)
- [Practical Examples](#practical-examples)
- [Haxe Language Features That Promote Functional Programming](#haxe-language-features-that-promote-functional-programming)
- [Universal Result<T,E> Type - Error Handling Paradigm Bridge](#universal-resultte-type---error-handling-paradigm-bridge)
- [Escape Hatches and Conditional Compilation](#escape-hatches-and-conditional-compilation)
- [Best Practices](#best-practices)

## Related Documentation

This guide is part of a comprehensive documentation ecosystem. See also:

- **[BEAM Type Abstractions](../BEAM_TYPE_ABSTRACTIONS.md)** - Comprehensive guide to Option<T> and Result<T,E> types with BEAM/OTP integration patterns and real-world examples
- **[Functional Patterns](../FUNCTIONAL_PATTERNS.md)** - Detailed examples of imperative→functional transformations including Option/Result compilation patterns and functional operations
- **[ExUnit Testing Guide](../EXUNIT_TESTING_GUIDE.md)** - Testing Option and Result types with type-safe assertions and comprehensive examples
- **[Developer Patterns](../guides/DEVELOPER_PATTERNS.md)** - Practical patterns for effective Haxe→Elixir development including Option/Result migration strategies
- **[Cookbook](../COOKBOOK.md)** - Practical recipes for common Option and Result patterns across different platforms
- **[Escape Hatches](../ESCAPE_HATCHES.md)** - Complete guide to Elixir interop, untyped code, and extern definitions  
- **[Dual-Target Compilation](../DUAL_TARGET_COMPILATION.md)** - Setting up projects that compile to multiple targets simultaneously
- **[Standard Library Handling](../STANDARD_LIBRARY_HANDLING.md)** - Architectural decisions for cross-platform standard libraries including Option and Result
- **[Haxe Best Practices](../HAXE_BEST_PRACTICES.md)** - Modern Haxe patterns and conditional compilation guidelines
- **[Architecture Guide](../ARCHITECTURE.md)** - Understanding the Reflaxe.Elixir compilation system

## Philosophy

### "Write Idiomatic Haxe, Generate Idiomatic Elixir"

Reflaxe.Elixir bridges two different programming paradigms:
- **Haxe**: Multi-paradigm with strong imperative features, mutable state, and traditional OOP
- **Elixir**: Purely functional with immutable data, pattern matching, and actor-based concurrency

Our compiler doesn't force you to write functional Haxe. Instead, it **intelligently transforms** your natural Haxe code into idiomatic Elixir, handling the paradigm shift at compile-time.

### Why This Matters

Many developers come to Elixir from imperative backgrounds. Haxe provides a familiar syntax while still generating efficient, idiomatic Elixir code. This means:
- Lower learning curve for Elixir/Phoenix development
- Ability to think imperatively for complex algorithms
- Type safety without sacrificing Elixir's functional benefits
- Gradual adoption of functional patterns

## Core Concept: Mutability vs Immutability

### The Fundamental Difference

**Haxe (Imperative)**:
```haxe
var count = 0;
for (item in items) {
    if (item.active) {
        count++;  // Mutating the variable
    }
}
```

**Generated Elixir (Functional)**:
```elixir
count = Enum.reduce(items, 0, fn item, acc ->
  if item.active do
    acc + 1  # Creating new value, not mutating
  else
    acc
  end
end)
```

### Key Transformations

| Haxe Pattern | Elixir Equivalent | Notes |
|-------------|-------------------|-------|
| `var x = 1; x++;` | Rebinding: `x = x + 1` | No true mutation |
| `array.push(item)` | `array ++ [item]` | Creates new list |
| `array[0] = value` | List.replace_at(array, 0, value) | Inefficient for large lists |
| `while (condition)` | Recursive function | Tail-call optimized |
| `obj.field = value` | Map.put(obj, :field, value) | Returns new map |

## Transformation Patterns

### 1. Loop Transformations

#### While Loops → Tail Recursion

**Haxe Input**:
```haxe
var sum = 0;
var i = 0;
while (i < array.length) {
    sum += array[i];
    i++;
}
```

**Transformation Process**:
1. Identify loop variables (sum, i)
2. Create recursive function with accumulator
3. Ensure tail-call optimization

**Generated Elixir**:
```elixir
{sum, _} = Enum.reduce_while(
  0..length(array)-1,
  {0, 0},
  fn i, {sum, _} ->
    {:cont, {sum + Enum.at(array, i), i + 1}}
  end
)
```

#### For Loops → Enum Operations

**Haxe Input**:
```haxe
var doubled = [];
for (num in numbers) {
    doubled.push(num * 2);
}
```

**Smart Detection**: Compiler recognizes map pattern

**Generated Elixir**:
```elixir
doubled = Enum.map(numbers, fn num -> num * 2 end)
```

### 2. State Management Transformations

#### Mutable Objects → Immutable Maps

**Haxe Input**:
```haxe
class User {
    public var name: String;
    public var age: Int;
    
    public function birthday() {
        age++;  // Mutation
    }
}
```

**Generated Elixir**:
```elixir
defmodule User do
  defstruct [:name, :age]
  
  def birthday(user) do
    %{user | age: user.age + 1}  # Returns new struct
  end
end
```

#### Complex State → Process State

**Haxe Input**:
```haxe
@:genserver
class Counter {
    private var count: Int = 0;
    
    public function increment(): Int {
        count++;
        return count;
    }
}
```

**Generated Elixir**:
```elixir
defmodule Counter do
  use GenServer
  
  def increment(pid) do
    GenServer.call(pid, :increment)
  end
  
  def handle_call(:increment, _from, count) do
    new_count = count + 1
    {:reply, new_count, new_count}
  end
end
```

### 3. Collection Transformations

#### Array Operations

| Haxe Operation | Elixir Generation | Performance |
|---------------|------------------|-------------|
| `arr.push(x)` | `arr ++ [x]` | O(n) - consider alternatives |
| `arr.pop()` | `List.last(arr)` | O(n) - doesn't modify |
| `arr.shift()` | `hd(arr)` | O(1) - efficient |
| `arr.unshift(x)` | `[x | arr]` | O(1) - efficient |
| `arr.reverse()` | `Enum.reverse(arr)` | O(n) - creates new list |
| `arr.sort()` | `Enum.sort(arr)` | O(n log n) - creates new list |

**Important**: Array methods in Haxe that mutate are transformed to operations that return new collections in Elixir.

## Performance Implications

### When Transformations Affect Performance

1. **Large Array Mutations**
   - **Problem**: `array.push()` in a loop generates `++` operations (O(n) each)
   - **Solution**: Use list comprehensions or `Enum.map`
   
2. **Nested Loops**
   - **Problem**: Can generate deeply nested recursive functions
   - **Solution**: Consider using `for` comprehensions or Stream operations

3. **Frequent State Updates**
   - **Problem**: Creating new maps/structs repeatedly
   - **Solution**: Use GenServer or Agent for stateful components

### Performance Patterns

**Inefficient Haxe**:
```haxe
var result = [];
for (i in 0...1000000) {
    result.push(i * 2);  // O(n²) in Elixir!
}
```

**Efficient Haxe for Elixir**:
```haxe
var result = [for (i in 0...1000000) i * 2];  // O(n) - uses comprehension
```

## Decision Matrix

### When to Use Imperative Style

✅ **Good for**:
- Complex algorithms (sorting, searching, graph traversal)
- Stateful UI components (LiveView)
- Game logic with many state changes
- Mathematical computations
- Procedural initialization sequences

**Example**:
```haxe
// Imperative style makes sense for complex algorithms
public function dijkstra(graph: Graph, start: Node): Map<Node, Int> {
    var distances = new Map<Node, Int>();
    var visited = new Set<Node>();
    var queue = new PriorityQueue<Node>();
    
    distances[start] = 0;
    queue.push(start, 0);
    
    while (!queue.isEmpty()) {
        var current = queue.pop();
        if (visited.has(current)) continue;
        
        visited.add(current);
        // ... complex logic
    }
    
    return distances;
}
```

### When to Use Functional Style

✅ **Good for**:
- Data transformations and pipelines
- Concurrent/parallel operations
- Stream processing
- API request/response handling
- Database query building

**Example**:
```haxe
// Functional style for data pipelines
public function processOrders(orders: Array<Order>): Stats {
    return orders
        .filter(o -> o.status == "completed")
        .map(o -> o.total)
        .reduce((sum, total) -> sum + total, 0);
}
```

### Mixed Approach (Recommended)

Most real-world applications benefit from a mixed approach:

```haxe
@:liveview
class DashboardLive {
    // Imperative for UI state management
    private var selectedTab: Int = 0;
    private var filters: FilterState = new FilterState();
    
    // Functional for data processing
    public function getFilteredData(): Array<Item> {
        return items
            .filter(filters.apply)
            .map(transform)
            .sort(byDate);
    }
    
    // Imperative for event handling
    public function handleTabClick(index: Int): Void {
        selectedTab = index;
        updateView();
    }
}
```

## Practical Examples

### Example 1: User Input Validation

**Imperative Approach** (familiar to most developers):
```haxe
public function validateForm(data: FormData): ValidationResult {
    var errors = [];
    
    if (data.email == null || data.email == "") {
        errors.push("Email is required");
    } else if (!isValidEmail(data.email)) {
        errors.push("Invalid email format");
    }
    
    if (data.password.length < 8) {
        errors.push("Password must be at least 8 characters");
    }
    
    return {
        valid: errors.length == 0,
        errors: errors
    };
}
```

**Generated Elixir** (still idiomatic):
```elixir
def validate_form(data) do
  errors = []
  
  errors = cond do
    is_nil(data.email) or data.email == "" ->
      errors ++ ["Email is required"]
    not is_valid_email(data.email) ->
      errors ++ ["Invalid email format"]
    true ->
      errors
  end
  
  errors = if String.length(data.password) < 8 do
    errors ++ ["Password must be at least 8 characters"]
  else
    errors
  end
  
  %{valid: length(errors) == 0, errors: errors}
end
```

### Example 2: Real-time Counter

**Haxe with State Abstraction**:
```haxe
@:genserver
class RealtimeCounter {
    private var count: Int = 0;
    private var clients: Array<ClientId> = [];
    
    public function increment(): Int {
        count++;
        broadcastToClients();
        return count;
    }
    
    public function subscribe(client: ClientId): Void {
        clients.push(client);
    }
    
    private function broadcastToClients(): Void {
        for (client in clients) {
            Phoenix.Channel.push(client, "count_updated", {count: count});
        }
    }
}
```

**Generated Elixir** (proper GenServer):
```elixir
defmodule RealtimeCounter do
  use GenServer
  
  def init(_) do
    {:ok, %{count: 0, clients: []}}
  end
  
  def handle_call(:increment, _from, state) do
    new_count = state.count + 1
    new_state = %{state | count: new_count}
    broadcast_to_clients(new_state)
    {:reply, new_count, new_state}
  end
  
  def handle_call({:subscribe, client}, _from, state) do
    new_state = %{state | clients: [client | state.clients]}
    {:reply, :ok, new_state}
  end
  
  defp broadcast_to_clients(%{clients: clients, count: count}) do
    Enum.each(clients, fn client ->
      Phoenix.Channel.push(client, "count_updated", %{count: count})
    end)
  end
end
```

## Haxe Language Features That Promote Functional Programming

Haxe provides several language features that naturally guide developers toward functional programming patterns, making the transition to Elixir's paradigm smoother.

### The `final` Keyword - Immutability by Default

The `final` keyword creates immutable bindings, encouraging functional patterns:

**Haxe Code**:
```haxe
// Immutable local variables
final config = {
    host: "localhost",
    port: 4000,
    timeout: 30
};
// config.port = 5000; // ❌ Compile error! Cannot reassign

// Immutable function parameters
function processUser(final user: User): ProcessedUser {
    // user = newUser; // ❌ Compile error! Cannot reassign parameter
    // Note: object fields may still be mutable unless also marked final
    return transformUser(user);
}

// Immutable class fields
class Config {
    public final host: String;
    public final port: Int;
    
    public function new(host: String, port: Int) {
        this.host = host;  // Can only assign in constructor
        this.port = port;
    }
}
```

**Generated Elixir** (already immutable by default):
```elixir
config = %{
  host: "localhost",
  port: 4000,
  timeout: 30
}
# All bindings are immutable in Elixir!

defmodule Config do
  defstruct [:host, :port]
  # Struct fields are immutable
end
```

### Pattern Matching - Functional Control Flow

Haxe's enhanced pattern matching replaces imperative if/else chains:

```haxe
// Algebraic data types with enums
enum Result<T> {
    Ok(value: T);
    Error(message: String);
}

// Pattern matching with exhaustiveness checking
function handleResult(result: Result<User>): String {
    return switch(result) {
        case Ok(user): 'Welcome ${user.name}';
        case Error(msg): 'Error: $msg';
        // Compiler ensures all cases handled!
    }
}

// Array destructuring patterns
function processArray(arr: Array<Int>): Int {
    return switch(arr) {
        case []: 0;                           // Empty array
        case [x]: x;                          // Single element
        case [x, y]: x + y;                   // Two elements
        case [x, y, ...rest]: x + y + sum(rest); // Rest pattern
    }
}

// Guard clauses in patterns
function classifyNumber(n: Int): String {
    return switch(n) {
        case 0: "zero";
        case x if x > 0: "positive";
        case x if x < 0: "negative";
    }
}
```

**Generated Elixir**:
```elixir
def handle_result(result) do
  case result do
    {:ok, user} -> "Welcome #{user.name}"
    {:error, msg} -> "Error: #{msg}"
  end
end

def process_array(arr) do
  case arr do
    [] -> 0
    [x] -> x
    [x, y] -> x + y
    [x, y | rest] -> x + y + sum(rest)
  end
end
```

### Abstract Types - Type-Safe Functional Abstractions

Abstract types provide zero-cost abstractions with functional methods:

```haxe
// Type-safe wrapper with validation
abstract Email(String) to String {
    public function new(s: String) {
        if (!~/^[^@]+@[^@]+\.[^@]+$/.match(s)) {
            throw 'Invalid email: $s';
        }
        this = s;
    }
    
    // Functional transformations
    @:to public function toString(): String return this;
    
    public function domain(): String {
        return this.split("@")[1];
    }
    
    public function localPart(): String {
        return this.split("@")[0];
    }
    
    public function anonymize(): Email {
        return new Email('anonymous@${domain()}');
    }
}

// Usage enforces constraints at compile-time
final email: Email = "user@example.com";     // ✅ Valid
final domain = email.domain();               // "example.com"
final anon = email.anonymize();              // Email type preserved

// Abstract enums for type-safe constants
abstract HttpStatus(Int) to Int {
    var Ok = 200;
    var NotFound = 404;
    var ServerError = 500;
    
    public function isSuccess(): Bool {
        return this >= 200 && this < 300;
    }
}
```

### Everything is an Expression

In Haxe, almost everything is an expression that returns a value, promoting functional style:

```haxe
// If expressions return values
final message = if (user.isActive) "Welcome back!" else "Please activate account";

// Switch expressions return values
final discount = switch(customer.tier) {
    case Gold: 0.20;
    case Silver: 0.10;
    case Bronze: 0.05;
    case Regular: 0.00;
};

// Try expressions return values
final result = try {
    parseJson(data);
} catch(e: Dynamic) {
    defaultValue();
};

// Block expressions return last value
final calculated = {
    var temp = computeStep1();
    var adjusted = adjustValue(temp);
    adjusted * factor;  // This is returned
};
```

### Static Extension Methods - Functional Composition

Static extensions enable pipeline-style functional programming:

```haxe
// Define functional helpers
class FunctionalExtensions {
    // Pipe operator simulation
    public static function pipe<T, R>(value: T, fn: T -> R): R {
        return fn(value);
    }
    
    // Tap for debugging pipelines
    public static function tap<T>(value: T, fn: T -> Void): T {
        fn(value);
        return value;
    }
    
    // Conditional application
    public static function when<T>(value: T, condition: Bool, fn: T -> T): T {
        return condition ? fn(value) : value;
    }
    
    // Safe navigation
    public static function andThen<T, R>(value: Null<T>, fn: T -> Null<R>): Null<R> {
        return value != null ? fn(value) : null;
    }
}

// Import extensions
using FunctionalExtensions;

// Use in functional pipelines
final result = getData()
    .pipe(validate)
    .tap(x -> trace('Validated: $x'))
    .when(shouldTransform, transform)
    .pipe(save);

// Safe chaining with null values
final name = getUser()
    .andThen(u -> u.profile)
    .andThen(p -> p.displayName);
```

### Inline and Const - Compile-Time Functional Programming

```haxe
class MathConstants {
    // Compile-time constants (truly immutable)
    inline static final PI = 3.14159265359;
    inline static final E = 2.71828182846;
    
    // Compile-time function evaluation
    inline static function square(x: Float): Float {
        return x * x;
    }
    
    inline static function cube(x: Float): Float {
        return x * x * x;
    }
    
    // These calculations happen at compile time!
    static final CIRCLE_AREA_R5 = square(5) * PI;
    static final SPHERE_VOLUME_R3 = (4/3) * PI * cube(3);
}

// Inline functions for zero-cost abstractions
inline function compose<A, B, C>(f: B -> C, g: A -> B): A -> C {
    return x -> f(g(x));
}

// Usage - completely optimized away at compile time
final transform = compose(stringify, double);
final result = transform(21);  // Compiles to: stringify(double(21))
```

### Type Classes via Interfaces

Haxe interfaces can simulate type classes for functional programming:

```haxe
// Functor-like interface
interface Mappable<T> {
    function map<R>(fn: T -> R): Mappable<R>;
}

// Monad-like interface
interface Chainable<T> {
    function flatMap<R>(fn: T -> Chainable<R>): Chainable<R>;
    function map<R>(fn: T -> R): Chainable<R>;
}

// Option type implementation
enum Option<T> {
    Some(value: T);
    None;
}

class OptionOps {
    public static function map<T, R>(opt: Option<T>, fn: T -> R): Option<R> {
        return switch(opt) {
            case Some(v): Some(fn(v));
            case None: None;
        };
    }
    
    public static function flatMap<T, R>(opt: Option<T>, fn: T -> Option<R>): Option<R> {
        return switch(opt) {
            case Some(v): fn(v);
            case None: None;
        };
    }
    
    public static function getOrElse<T>(opt: Option<T>, defaultValue: T): T {
        return switch(opt) {
            case Some(v): v;
            case None: defaultValue;
        };
    }
}

using OptionOps;

// Functional option handling
final result = getData()
    .map(x -> x * 2)
    .flatMap(validatePositive)
    .map(formatNumber)
    .getOrElse("N/A");
```

### Arrow Functions and Closures

Haxe's arrow functions make functional programming concise:

```haxe
// Simple arrow functions
final double = (x: Int) -> x * 2;
final add = (x: Int, y: Int) -> x + y;

// Implicit return for single expressions
final users = people.filter(p -> p.age >= 18);

// Closures capture immutable values
function makeCounter(final initial: Int): () -> Int {
    var count = initial;  // Captured in closure
    return () -> ++count;
}

// Currying with arrow functions
function curry<A, B, C>(fn: (A, B) -> C): A -> B -> C {
    return a -> b -> fn(a, b);
}

final curriedAdd = curry((x: Int, y: Int) -> x + y);
final add5 = curriedAdd(5);
final result = add5(3);  // 8
```

### Read-Only Properties and Collections

```haxe
// Read-only properties
class User {
    public final id: Int;                    // Immutable after construction
    public var name(default, null): String;  // Read-only from outside
    public var age(default, never): Int;     // Never writable after init
    
    public function new(id: Int, name: String, age: Int) {
        this.id = id;
        this.name = name;
        this.age = age;
    }
}

// Immutable collections
import haxe.ds.ReadOnlyArray;

class DataService {
    private var _data: Array<Item>;
    
    // Return read-only view
    public function getData(): ReadOnlyArray<Item> {
        return _data;
    }
    
    // Functional update - returns new array
    public function addItem(item: Item): ReadOnlyArray<Item> {
        return _data.concat([item]);
    }
}
```

### Type-Safe Cross-Platform Patterns

One of Reflaxe.Elixir's greatest strengths is enabling type-safe patterns that work consistently across all Haxe targets while generating idiomatic code for each platform.

#### Option<T> - Universal Null Safety

The `Option<T>` type bridges the gap between nullable types and type-safe null handling across platforms:

**Universal Haxe Code**:
```haxe
import haxe.ds.Option;
using haxe.ds.OptionTools;

class UserService {
    // Same code works on all platforms
    public function findUser(id: Int): Option<User> {
        var user = database.query("SELECT * FROM users WHERE id = ?", [id]);
        return user != null ? Some(user) : None;
    }
    
    public function getUserDisplayName(id: Int): String {
        return findUser(id)
            .map(user -> user.displayName != null ? user.displayName : user.username)
            .unwrap("Anonymous User");
    }
    
    public function getActiveUsers(ids: Array<Int>): Array<User> {
        return ids
            .map(id -> findUser(id))
            .map(opt -> opt.filter(user -> user.isActive))
            .values(); // Extract all Some values, discard None
    }
}
```

**Cross-Platform Compilation**:

**Elixir Output** (idiomatic atoms and pattern matching):
```elixir
def find_user(id) do
  case Database.query("SELECT * FROM users WHERE id = ?", [id]) do
    nil -> :none
    user -> {:some, user}
  end
end

def get_user_display_name(id) do
  case find_user(id) do
    {:some, user} ->
      if user.display_name != nil do
        user.display_name
      else
        user.username
      end
    :none -> "Anonymous User"
  end
end

def get_active_users(ids) do
  ids
  |> Enum.map(&find_user/1)
  |> Enum.filter(fn
    {:some, user} -> user.is_active
    :none -> false
  end)
  |> Enum.map(fn {:some, user} -> user end)
end
```

**JavaScript Output** (discriminated unions):
```javascript
function findUser(id) {
    const user = database.query("SELECT * FROM users WHERE id = ?", [id]);
    return user != null ? {tag: "some", value: user} : {tag: "none"};
}

function getUserDisplayName(id) {
    const userOpt = findUser(id);
    if (userOpt.tag === "some") {
        const user = userOpt.value;
        return user.displayName != null ? user.displayName : user.username;
    }
    return "Anonymous User";
}
```

#### Cross-Platform Error Handling Architecture

Combine Option and Result types for comprehensive error handling that works everywhere:

```haxe
// Universal error handling architecture
enum DatabaseError {
    NotFound;
    ConnectionFailed(reason: String);
    QueryError(sql: String, error: String);
}

class Repository {
    // Option for simple presence/absence
    public function exists(id: Int): Option<Bool> {
        return try {
            var count = database.query("SELECT COUNT(*) FROM users WHERE id = ?", [id]);
            Some(count > 0);
        } catch (e) {
            None;
        }
    }
    
    // Result for detailed error information
    public function findById(id: Int): Result<User, DatabaseError> {
        return try {
            var user = database.query("SELECT * FROM users WHERE id = ?", [id]);
            user != null ? Ok(user) : Error(NotFound);
        } catch (e: Dynamic) {
            Error(ConnectionFailed(Std.string(e)));
        }
    }
    
    // Combine both for complex workflows
    public function updateIfExists(id: Int, data: UserData): Result<Option<User>, DatabaseError> {
        return findById(id).map(user -> {
            // Update logic here
            Some(updatedUser);
        });
    }
}
```

**Benefits Across All Platforms**:
1. **Type Safety**: Compile-time guarantees prevent null pointer exceptions
2. **Explicit Intent**: Clear API contracts about what may fail or be absent
3. **Composability**: Functional operations work consistently everywhere
4. **Performance**: Zero-cost abstractions with optimal platform-specific code generation
5. **Migration Path**: Gradual adoption from nullable types to Option/Result

#### Universal Data Transformation Patterns

Type-safe patterns for data transformation that generate optimal code per platform:

```haxe
// Universal data pipeline
class DataProcessor {
    public function processUserData(rawData: Array<Dynamic>): Result<Array<User>, ValidationError> {
        return rawData
            .map(item -> validateUserData(item))       // Array<Result<UserData, ValidationError>>
            .traverse(data -> createUser(data))        // Result<Array<User>, ValidationError>
            .map(users -> users.filter(user -> user.isActive))  // Filter active users
            .map(users -> users.sort((a, b) -> a.name.localeCompare(b.name))); // Sort by name
    }
    
    private function validateUserData(raw: Dynamic): Result<UserData, ValidationError> {
        return validateEmail(raw.email)
            .flatMap(_ -> validateAge(raw.age))
            .map(age -> new UserData(raw.email, age, raw.name));
    }
}
```

This pattern generates:
- **Elixir**: Efficient `Enum.map/2`, `Enum.filter/2`, `Enum.sort_by/2` with `{:ok, _}` / `{:error, _}` tuples
- **JavaScript**: Array methods with proper error handling and type guards
- **Other targets**: Optimal iteration patterns with consistent error semantics

### Universal Result<T,E> Type - Error Handling Paradigm Bridge

The `Result<T,E>` type demonstrates perfect paradigm bridging - familiar imperative-style error handling in Haxe that compiles to idiomatic functional patterns in each target.

#### The Problem: Exception vs Functional Error Handling

**Traditional Exception Approach** (imperative):
```haxe
// Problematic: Error information lost, side effects unclear
function processUser(data: UserData): User {
    try {
        var email = validateEmail(data.email);
        var age = validateAge(data.age);
        return new User(email, age);
    } catch (e: String) {
        throw "Validation failed"; // Details lost!
    }
}
```

**Result Type Approach** (functional bridge):
```haxe
using haxe.functional.Result;
using haxe.functional.ResultTools;

// Clear, composable, information-preserving
function processUser(data: UserData): Result<User, ValidationError> {
    return validateEmail(data.email)
        .flatMap(_ -> validateAge(data.age))
        .map(age -> new User(data.email, age));
}
```

#### Cross-Platform Compilation Magic

The same Haxe Result code compiles to optimal patterns per target:

**Haxe Source**:
```haxe
function parseNumber(input: String): Result<Int, String> {
    var parsed = Std.parseInt(input);
    if (parsed != null) {
        return Ok(parsed);
    } else {
        return Error('Invalid number: ${input}');
    }
}

function processData(input: String): Result<Int, String> {
    return switch (parseNumber(input)) {
        case Ok(value): 
            if (value > 0) Ok(value * 2) else Error("Must be positive");
        case Error(msg): 
            Error("Parse failed: " + msg);
    }
}
```

**Generated Elixir** (idiomatic tuples):
```elixir
def parse_number(input) do
  case Integer.parse(input) do
    {parsed, ""} -> {:ok, parsed}
    _ -> {:error, "Invalid number: #{input}"}
  end
end

def process_data(input) do
  case parse_number(input) do
    {:ok, value} -> 
      if value > 0 do 
        {:ok, value * 2} 
      else 
        {:error, "Must be positive"} 
      end
    {:error, msg} -> 
      {:error, "Parse failed: " <> msg}
  end
end
```

**JavaScript Target** (discriminated unions):
```javascript
function parseNumber(input) {
    const parsed = parseInt(input);
    if (!isNaN(parsed)) {
        return {tag: "Ok", value: parsed};
    } else {
        return {tag: "Error", error: `Invalid number: ${input}`};
    }
}
```

#### Functional Programming Features

Result types support comprehensive functional operations while maintaining imperative familiarity:

```haxe
// Chain operations with flatMap
function validateUser(data: UserData): Result<User, String> {
    return validateEmail(data.email)
        .flatMap(email -> validateAge(data.age)
        .flatMap(age -> validatePassword(data.password)
        .map(password -> new User(email, age, password))));
}

// Transform success values with map
function doubleIfValid(input: String): Result<Int, String> {
    return parseNumber(input).map(x -> x * 2);
}

// Extract values safely with fold
function getValueOrDefault(result: Result<Int, String>): Int {
    return result.fold(
        value -> value,    // Success case
        error -> -1        // Error case with default
    );
}

// Sequence operations - fail fast on first error
function processMultiple(inputs: Array<String>): Result<Array<Int>, String> {
    return ResultTools.traverse(inputs, parseNumber);
}
```

#### Benefits of the Paradigm Bridge

1. **Familiar Syntax**: Write error handling that looks like imperative style
2. **Type Safety**: Compile-time guarantee that errors are handled
3. **Composability**: Chain operations without nested try/catch
4. **Information Preservation**: Error details maintained through pipeline
5. **Cross-Platform**: Works consistently across all Haxe targets
6. **Zero Runtime Cost**: Compiles to optimal target patterns
7. **Migration Path**: Easy to refactor from exception-based code

#### Progressive Adoption Pattern

Start with Dynamic types for rapid prototyping, then add Result types for safety:

```haxe
// Phase 1: Prototype with exceptions
function processData(input: String): Int {
    var value = Std.parseInt(input);
    if (value == null) throw "Invalid input";
    if (value <= 0) throw "Must be positive";
    return value * 2;
}

// Phase 2: Add Result type for safety
function processData(input: String): Result<Int, String> {
    return parseNumber(input)
        .flatMap(value -> value > 0 ? Ok(value * 2) : Error("Must be positive"));
}

// Phase 3: Compose with other Result-returning functions
function processDataChain(input: String): Result<User, ValidationError> {
    return processData(input)
        .flatMap(validateUserId)
        .flatMap(loadUser)
        .map(enhanceUserData);
}
```

This demonstrates the core philosophy: **write intuitive Haxe once that compiles to idiomatic patterns** in each target language, enabling productivity, performance, and **true cross-platform code reuse**.

## Escape Hatches and Conditional Compilation

While the paradigm bridge enables most code to be truly cross-platform, there are scenarios where platform-specific code becomes necessary. Haxe provides escape hatches for these situations.

### The Universal Code Philosophy

**95% Universal Code**: The majority of your application should compile identically across all targets:
- Business logic and validation (Result types, data transformations)
- Data structures and algorithms
- Mathematical computations
- Functional programming patterns

**5% Platform-Specific Code**: Only when dealing with fundamentally different platform APIs:
- Communication protocols (WebSockets vs Phoenix Channels)
- File system operations (Browser vs Server)
- Platform-specific services (Push notifications, native APIs)

**0% Manual Optimization**: Never use conditional compilation for performance - let the compiler generate optimal target-specific code.

*These are guidelines reflecting Haxe best practices - the exact ratios will vary by project needs. The key principle is: maximize universal code, minimize platform-specific code, and trust the compiler for optimization.*

### When to Use Platform-Specific Code

#### ✅ Justified Use Cases

**Communication Patterns**:
```haxe
// Platform-specific communication APIs
#if elixir
  Phoenix.PubSub.broadcast(pubsub, topic, message)
#elseif js
  websocket.send(JSON.stringify({topic: topic, data: message}))
#else
  // Generic fallback for other targets
  EventBus.publish(topic, message)
#end
```

**File System Operations**:
```haxe
// Different file APIs per platform
#if elixir
  var content = File.read("config.json")
#elseif js
  var content = await fetch("/api/config").then(r => r.text())
#else
  var content = sys.io.File.getContent("config.json")
#end
```

**Native Platform Features**:
```haxe
// Leverage unique platform strengths
#if elixir
  // Use OTP supervision for fault tolerance
  Supervisor.startLink(children, strategy: :one_for_one)
#elseif js
  // Use Web Workers for parallelism
  worker.postMessage({type: "process", data: data})
#end
```

#### ❌ Avoid Conditional Compilation For

**Performance Optimizations** (Compiler handles this):
```haxe
// ❌ DON'T DO THIS - Let compiler optimize
#if elixir
  // Manual Elixir list optimization
  Enum.reduce(items, [], fn item, acc -> [transform(item) | acc] end)
#else
  items.map(transform)
#end

// ✅ DO THIS - Universal code with smart compilation
var result = items.map(transform);
// Compiler generates optimal code per target automatically
```

**String Operations** (Use functional patterns):
```haxe
// ❌ DON'T DO THIS - Platform-specific string handling
#if elixir
  String.slice(text, 0, 10)
#elseif js
  text.substring(0, 10)
#end

// ✅ DO THIS - Universal string operations
var trimmed = text.substr(0, 10);
// Compiles to idiomatic patterns per target
```

### Progressive Cross-Platform Development

#### Phase 1: Single Target Implementation
Start with your primary target (typically Elixir for server-side):

```haxe
// Focus on business logic without conditional compilation
class UserService {
    public function validateUser(data: UserData): Result<User, ValidationError> {
        return validateEmail(data.email)
            .flatMap(_ -> validateAge(data.age))
            .map(age -> new User(data.email, age));
    }
}
```

#### Phase 2: Identify Platform Boundaries
When adding new targets, identify what actually needs platform-specific code:

```haxe
// Universal business logic (no changes needed)
class UserService {
    // Same validation logic works everywhere
    public function validateUser(data: UserData): Result<User, ValidationError> {
        return validateEmail(data.email)
            .flatMap(_ -> validateAge(data.age))
            .map(age -> new User(data.email, age));
    }
    
    // Platform-specific persistence
    public function saveUser(user: User): Result<UserId, PersistenceError> {
        #if elixir
        return EctoRepository.insert(user);
        #elseif js
        return IndexedDBRepository.save(user);
        #else
        return FileRepository.writeUser(user);
        #end
    }
}
```

#### Phase 3: Abstract Common Patterns
Create cross-platform abstractions for repeated platform-specific patterns:

```haxe
// Cross-platform notification abstraction
interface NotificationService {
    function send(message: String, recipient: UserId): Result<Void, NotificationError>;
}

// Platform-specific implementations
#if elixir
class PhoenixNotificationService implements NotificationService {
    public function send(message: String, recipient: UserId): Result<Void, NotificationError> {
        return Phoenix.PubSub.broadcast(pubsub, "user:${recipient}", {
            type: "notification",
            message: message
        });
    }
}
#elseif js
class WebSocketNotificationService implements NotificationService {
    public function send(message: String, recipient: UserId): Result<Void, NotificationError> {
        websocket.send(JSON.stringify({
            type: "notification",
            recipient: recipient,
            message: message
        }));
        return Ok(null);
    }
}
#end

// Universal business logic uses interface
class NotificationManager {
    private var service: NotificationService;
    
    public function sendWelcome(user: User): Result<Void, NotificationError> {
        return service.send('Welcome ${user.name}!', user.id);
    }
}
```

### Escape Hatch Patterns

#### Direct Platform Code Integration
For complex platform-specific operations, use escape hatches:

```haxe
#if elixir
// Access Elixir-specific features directly
class ElixirSpecific {
    public function complexETS(): Dynamic {
        return untyped __elixir__('
            :ets.new(:cache, [:set, :public, :named_table])
        ');
    }
    
    public function useElixirMacros(): Void {
        untyped __elixir__('
            require Logger
            Logger.info("Processing started")
        ');
    }
}
#end
```

#### Extern Definitions for Platform Libraries
Type-safe access to platform-specific libraries:

```haxe
#if elixir
@:native("HTTPoison")
extern class HTTPoison {
    public static function get(url: String): Dynamic;
    public static function post(url: String, body: String): Dynamic;
}
#elseif js
@:native("fetch")
extern function fetch(url: String, ?options: Dynamic): js.lib.Promise<Dynamic>;
#end
```

### Best Practices for Platform-Specific Code

#### 1. Minimize Platform Differences
Keep platform-specific code at the boundaries:

```haxe
// Good: Platform differences isolated to data layer
class UserRepository {
    #if elixir
    public function findByEmail(email: String): Result<User, RepositoryError> {
        return EctoQueries.findUserByEmail(email);
    }
    #elseif js
    public function findByEmail(email: String): Result<User, RepositoryError> {
        return IndexedDB.findUserByEmail(email);
    }
    #end
}

// Business logic stays universal
class UserService {
    public function authenticate(email: String, password: String): Result<Session, AuthError> {
        return repository.findByEmail(email)
            .flatMap(user -> validatePassword(user, password))
            .map(user -> createSession(user));
    }
}
```

#### 2. Document Platform Choices
Always explain why platform-specific code is necessary:

```haxe
/**
 * Platform-specific storage implementation.
 * 
 * Elixir: Uses Ecto for database persistence with ACID guarantees
 * JavaScript: Uses IndexedDB for offline-capable browser storage
 * Other: Falls back to file-based storage for development/testing
 */
#if elixir
// Ecto implementation for production reliability
#elseif js  
// IndexedDB for offline browser apps
#else
// File storage for testing and development
#end
```

#### 3. Maintain Interface Consistency
Ensure platform implementations have identical interfaces:

```haxe
// Same interface across all platforms
interface StorageService {
    function save(key: String, data: Dynamic): Result<Void, StorageError>;
    function load(key: String): Result<Dynamic, StorageError>;
    function delete(key: String): Result<Void, StorageError>;
}

// Platform implementations match interface exactly
#if elixir
class EctoStorageService implements StorageService { /* ... */ }
#elseif js
class IndexedDBStorageService implements StorageService { /* ... */ }
#end
```

### Reference Documentation

For detailed platform-specific integration guides:

- **[Escape Hatches Guide](../ESCAPE_HATCHES.md)** - Complete guide to Elixir interop, untyped code, and extern definitions
- **[Dual-Target Compilation](../DUAL_TARGET_COMPILATION.md)** - Setting up projects that compile to multiple targets simultaneously
- **[Standard Library Handling](../STANDARD_LIBRARY_HANDLING.md)** - When to use extern patterns vs pure Haxe implementations
- **[Haxe Best Practices](../HAXE_BEST_PRACTICES.md)** - Conditional compilation patterns and modern Haxe features

### The Strategic Balance

The key to successful cross-platform development with Reflaxe.Elixir:

1. **Default to Universal**: Write business logic that works everywhere
2. **Abstract Platform Differences**: Use interfaces for platform-specific operations  
3. **Leverage Smart Compilation**: Trust the compiler to generate optimal target code
4. **Use Escape Hatches Sparingly**: Only for fundamentally platform-specific APIs
5. **Maintain Type Safety**: Even platform-specific code should be as typed as possible

This approach maximizes code reuse while maintaining the ability to leverage unique platform capabilities when truly necessary.

## Best Practices

### 1. Understand the Generated Code
Always check what Elixir code your Haxe generates, especially for performance-critical sections.

### 2. Use Type Annotations
Help the compiler make better decisions:
```haxe
// Explicit type helps compiler optimize
var numbers: Array<Int> = getData();
var sum = numbers.reduce((a, b) -> a + b, 0);
```

### 3. Leverage Compiler Hints
Use annotations to guide transformations:
```haxe
@:tail_recursive
private function factorial(n: Int, acc: Int = 1): Int {
    return n <= 1 ? acc : factorial(n - 1, n * acc);
}
```

### 4. Think in Pipelines
When possible, structure code as data pipelines:
```haxe
// This generates efficient Elixir pipe operators
public function processData(input: String): Result {
    return input
        .trim()
        .toLowerCase()
        .split(",")
        .map(parseItem)
        .filter(isValid)
        .reduce(aggregate, initialValue());
}
```

### 5. State Management Strategy

Choose the right approach for your use case:

| Use Case | Recommended Pattern | Annotation |
|----------|-------------------|------------|
| UI Component State | GenServer | `@:genserver` |
| Shared Cache | ETS Tables | `@:ets` |
| Simple Counter | Agent | `@:agent` |
| Complex Business Logic | GenServer with state machine | `@:genserver @:fsm` |

### 6. Embrace Immutability Where Natural

Some patterns are naturally functional:
```haxe
// Configuration objects - naturally immutable
final config = {
    host: "localhost",
    port: 4000,
    ssl: true
};

// Data transformations - functional is clearer
var report = sales
    .groupBy(s -> s.category)
    .map(group -> {
        category: group.key,
        total: group.values.sum(s -> s.amount)
    });
```

## Summary

The paradigm bridge in Reflaxe.Elixir allows you to:
1. **Write familiar code** - Use imperative patterns when they make sense
2. **Get functional benefits** - Automatic transformation to idiomatic Elixir
3. **Maintain performance** - Compiler optimizations for common patterns
4. **Learn gradually** - Adopt functional patterns at your own pace

Remember: The goal isn't to write functional Haxe, but to write **good Haxe** that compiles to **good Elixir**. The compiler handles the paradigm translation, letting you focus on solving problems.