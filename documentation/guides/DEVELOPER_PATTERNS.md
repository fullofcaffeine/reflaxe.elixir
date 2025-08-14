# Developer Patterns: Writing Effective Haxe for Elixir

## Table of Contents
- [Core Principles](#core-principles)
- [Pattern Library](#pattern-library)
- [Compiler-Supported Abstractions](#compiler-supported-abstractions)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
- [Migration Patterns](#migration-patterns)
- [Performance Patterns](#performance-patterns)
- [Testing Patterns](#testing-patterns)

## Core Principles

### 1. Think in Transformations, Not Mutations
```haxe
// ❌ Imperative mutation mindset
var result = [];
for (item in items) {
    if (item.active) {
        result.push(transform(item));
    }
}

// ✅ Functional transformation mindset
final result = items
    .filter(item -> item.active)
    .map(transform);
```

### 2. Embrace Immutability with `final`
```haxe
// ✅ Use final for data that shouldn't change
final config = loadConfig();
final user = authenticate(request);
final result = process(user, config);

// The compiler ensures these can't be reassigned
```

### 3. Let the Compiler Handle the Paradigm Shift
Write idiomatic Haxe and trust the compiler to generate idiomatic Elixir. Don't try to write Elixir in Haxe syntax.

## Pattern Library

### Data Pipeline Pattern

**Use Case**: Transform data through multiple stages

```haxe
// Compiler provides @:pipeline annotation for optimization
@:pipeline
class DataProcessor {
    public static function processOrders(orders: Array<Order>): Report {
        return orders
            |> filterValid           // Compiler converts to Elixir pipe
            |> enrichWithCustomer
            |> calculateTotals
            |> groupByCategory
            |> generateReport;
    }
    
    // Each function is pure and testable
    static function filterValid(orders: Array<Order>): Array<Order> {
        return orders.filter(o -> o.isValid());
    }
    
    static function enrichWithCustomer(orders: Array<Order>): Array<EnrichedOrder> {
        return orders.map(o -> {
            order: o,
            customer: CustomerRepo.get(o.customerId)
        });
    }
}
```

**Compiler Support**: The `@:pipeline` annotation tells the compiler to optimize this as Elixir pipe operators.

### Option/Maybe Pattern

**Use Case**: Handle nullable values functionally

```haxe
// Compiler provides Option<T> abstraction
import reflaxe.elixir.Option;

class UserService {
    public static function findUser(id: Int): Option<User> {
        final user = Database.find(User, id);
        return user != null ? Some(user) : None;
    }
    
    public static function getUserEmail(id: Int): String {
        return findUser(id)
            .map(u -> u.email)
            .filter(e -> e != "")
            .getOrElse("no-email@example.com");
    }
}
```

**Compiler Generated Elixir**:
```elixir
def get_user_email(id) do
  case find_user(id) do
    {:some, user} -> user.email
    :none -> "no-email@example.com"
  end
end
```

### Result/Either Pattern

**Use Case**: Explicit error handling without exceptions

```haxe
// Compiler provides Result<T, E> type
import reflaxe.elixir.Result;

class PaymentService {
    public static function processPayment(amount: Float, card: Card): Result<Transaction, PaymentError> {
        return validateCard(card)
            .andThen(c -> checkBalance(c, amount))
            .andThen(c -> chargeCard(c, amount))
            .map(t -> logTransaction(t));
    }
    
    // Chain operations that might fail
    static function validateCard(card: Card): Result<Card, PaymentError> {
        if (!card.isValid()) {
            return Error(InvalidCard("Card validation failed"));
        }
        return Ok(card);
    }
}
```

**Usage**:
```haxe
switch(processPayment(99.99, card)) {
    case Ok(transaction): 
        sendReceipt(transaction);
    case Error(InvalidCard(msg)): 
        showError("Invalid card: " + msg);
    case Error(InsufficientFunds): 
        showError("Not enough funds");
}
```

### State Machine Pattern

**Use Case**: Model complex state transitions

```haxe
// Compiler provides @:state_machine for GenServer integration
@:state_machine
enum OrderState {
    Pending;
    Processing(startedAt: DateTime);
    Shipped(trackingNumber: String);
    Delivered(deliveredAt: DateTime);
    Cancelled(reason: String);
}

@:genserver
class OrderStateMachine {
    @:state var currentState: OrderState = Pending;
    
    // Compiler generates proper state transition validation
    @:transition(from: Pending, to: Processing)
    public function startProcessing(): Result<Void, String> {
        currentState = Processing(DateTime.now());
        return Ok();
    }
    
    @:transition(from: Processing, to: Shipped)
    public function ship(trackingNumber: String): Result<Void, String> {
        currentState = Shipped(trackingNumber);
        notifyCustomer(trackingNumber);
        return Ok();
    }
    
    // Invalid transitions caught at compile time!
    // @:transition(from: Delivered, to: Pending) // ❌ Compiler error
}
```

### Actor Pattern (OTP GenServer)

**Use Case**: Manage state in concurrent systems

```haxe
// Compiler provides clean GenServer abstraction
@:genserver
class ShoppingCart {
    @:state var items: Map<ProductId, Int> = new Map();
    @:state var userId: UserId;
    
    // Synchronous calls (GenServer.call)
    @:call
    public function addItem(productId: ProductId, quantity: Int = 1): Result<Void, String> {
        final current = items.get(productId) ?? 0;
        items.set(productId, current + quantity);
        return Ok();
    }
    
    @:call
    public function getTotal(): Float {
        return items.keys()
            .map(id -> {
                final product = ProductRepo.get(id);
                final quantity = items.get(id);
                return product.price * quantity;
            })
            .fold((sum, price) -> sum + price, 0.0);
    }
    
    // Asynchronous casts (GenServer.cast)
    @:cast
    public function clear(): Void {
        items.clear();
        Logger.info('Cart cleared for user ${userId}');
    }
    
    // Handle system messages
    @:info
    public function handleInfo(msg: Dynamic): Void {
        switch(msg) {
            case SessionExpired:
                clear();
                terminate();
        }
    }
}
```

### Supervisor Pattern

**Use Case**: Build fault-tolerant systems

```haxe
// Compiler provides supervisor abstractions
@:supervisor
class AppSupervisor {
    @:children([
        {id: "cache", start: CacheServer.new(), restart: Permanent},
        {id: "sessions", start: SessionManager.new(), restart: Temporary},
        {id: "workers", start: WorkerPool.new(10), restart: Transient}
    ])
    public static var children: Array<ChildSpec>;
    
    @:strategy(OneForOne)  // or OneForAll, RestForOne
    @:max_restarts(3)
    @:max_seconds(5)
    public static var config: SupervisorConfig;
}
```

### Event Sourcing Pattern

**Use Case**: Build audit trails and event-driven systems

```haxe
// Compiler provides event sourcing abstractions
@:event_sourced
class BankAccount {
    @:state var balance: Float = 0;
    @:state var transactions: Array<Transaction> = [];
    
    // Commands produce events
    @:command
    public function deposit(amount: Float): Result<Void, String> {
        if (amount <= 0) return Error("Invalid amount");
        
        // Emit event (compiler handles persistence)
        emit(MoneyDeposited(amount, DateTime.now()));
        return Ok();
    }
    
    // Events update state
    @:apply(MoneyDeposited)
    function applyDeposit(event: MoneyDeposited): Void {
        balance += event.amount;
        transactions.push(event);
    }
    
    // Replay events to rebuild state
    @:replay
    public static function fromEvents(events: Array<Event>): BankAccount {
        final account = new BankAccount();
        for (event in events) {
            account.apply(event);
        }
        return account;
    }
}
```

## Compiler-Supported Abstractions

### 1. Pipe Operator Support

```haxe
// Use |> in Haxe (compiler transforms to Elixir pipes)
@:elixir.pipes
class PipeExample {
    public function process(data: String): Result {
        return data
            |> trim
            |> toLowerCase
            |> validate
            |> parse
            |> transform
            |> save;
    }
}
```

### 2. With Statement Support

```haxe
// Compiler provides @:with for Elixir's with statement
@:with
public function complexOperation(): Result<Data, Error> {
    // Compiler transforms to Elixir's with statement
    return with(
        user <- authenticate(),
        profile <- loadProfile(user),
        permissions <- checkPermissions(profile),
        data <- fetchData(permissions)
    ) {
        Ok(processData(data));
    } else {
        case Error(e): Error(e);
        case None: Error("Not found");
    }
}
```

### 3. Comprehension Support

```haxe
// Compiler provides comprehension syntax
@:comprehension
public function generateCombinations(): Array<Combination> {
    return for {
        x <- range(1, 10);
        y <- range(1, 10);
        if (x + y == 10);
    } yield {
        Combination(x, y, x * y);
    }
}
```

### 4. Pattern Guards

```haxe
// Compiler supports pattern guards in switch
function processValue(value: Dynamic): String {
    return switch(value) {
        case n: Int if n > 0: "positive";
        case n: Int if n < 0: "negative";
        case 0: "zero";
        case s: String if s.length > 10: "long string";
        case s: String: "short string";
        case _: "unknown";
    }
}
```

## Anti-Patterns to Avoid

### 1. ❌ Simulating Mutation with Recursion

```haxe
// Don't manually implement mutation patterns
class Counter {
    private var count: Int = 0;
    
    public function increment(): Int {
        // Don't try to mutate and return
        count = count + 1;  // This won't work as expected in Elixir
        return count;
    }
}
```

**✅ Instead**: Use GenServer or Agent abstractions:
```haxe
@:agent
class Counter {
    @:state var count: Int = 0;
    
    public function increment(): Int {
        count++;  // Compiler handles state updates properly
        return count;
    }
}
```

### 2. ❌ Overusing Dynamic Types

```haxe
// Avoid losing type safety
function process(data: Dynamic): Dynamic {
    // No compile-time checking!
    return data.someField.someMethod();
}
```

**✅ Instead**: Use proper types or generics:
```haxe
function process<T: HasSomeField>(data: T): ProcessResult {
    return data.someField.someMethod();
}
```

### 3. ❌ Fighting the Functional Paradigm

```haxe
// Don't write deeply nested imperative code
function complexLogic(data: Array<Item>): Result {
    var result = new Result();
    for (item in data) {
        if (item.type == "A") {
            for (subItem in item.children) {
                if (subItem.active) {
                    result.values.push(subItem.value);
                }
            }
        }
    }
    return result;
}
```

**✅ Instead**: Embrace functional composition:
```haxe
function complexLogic(data: Array<Item>): Result {
    final values = data
        .filter(item -> item.type == "A")
        .flatMap(item -> item.children)
        .filter(subItem -> subItem.active)
        .map(subItem -> subItem.value);
    
    return new Result(values);
}
```

## Migration Patterns

### Wrapping Existing Elixir Code

```haxe
// Create type-safe wrappers for Elixir modules
@:native("LegacyApp.ComplexModule")
extern class ComplexModule {
    // Start with Dynamic, add types gradually
    static function oldFunction(params: Dynamic): Dynamic;
    
    // As you learn the API, add proper types
    static function processUser(user: {id: Int, name: String}): ProcessResult;
}

// Now use with type safety
class NewFeature {
    public function process(userId: Int): Result<User, Error> {
        try {
            final result = ComplexModule.processUser({id: userId, name: "unknown"});
            return Ok(User.fromLegacy(result));
        } catch (e: Dynamic) {
            return Error(e.toString());
        }
    }
}
```

### Gradual Type Introduction

```haxe
// Phase 1: Dynamic typing for exploration
function processData_v1(data: Dynamic): Dynamic {
    return ElixirModule.transform(data);
}

// Phase 2: Input typing
function processData_v2(data: Array<Dynamic>): Dynamic {
    return ElixirModule.transform(data);
}

// Phase 3: Output typing
function processData_v3(data: Array<Dynamic>): TransformResult {
    return ElixirModule.transform(data);
}

// Phase 4: Full typing
function processData_v4(data: Array<InputItem>): TransformResult {
    return ElixirModule.transform(data.map(i -> i.toLegacy()));
}
```

## Performance Patterns

### Stream Processing

```haxe
// Compiler optimizes to Elixir Stream operations
@:stream
class LargeDataProcessor {
    public static function processLargeFile(path: String): Result<Stats, Error> {
        return File.stream(path)
            |> Stream.map(parseLine)
            |> Stream.filter(isValid)
            |> Stream.map(transform)
            |> Stream.chunk(1000)
            |> Stream.each(processBatch)
            |> Stream.run();
    }
}
```

### Parallel Processing

```haxe
// Compiler generates Task.async/await
@:parallel
class ParallelProcessor {
    public static function processItems(items: Array<Item>): Array<Result> {
        return items
            |> Task.asyncAll(processItem)  // Parallel execution
            |> Task.awaitAll(timeout: 5000);
    }
}
```

### ETS for Caching

```haxe
// Compiler provides ETS abstractions
@:ets_cache(table: "app_cache", ttl: 3600)
class CacheService {
    @:cached
    public static function expensiveOperation(key: String): Data {
        // Automatically cached in ETS
        return Database.complexQuery(key);
    }
    
    @:cache_invalidate
    public static function clearCache(pattern: String): Void {
        // Compiler generates ETS cleanup code
    }
}
```

## Testing Patterns

### Property-Based Testing

```haxe
@:property_test
class PropertyTests {
    // Compiler generates property tests
    @:property(runs: 100)
    function testSortingIdempotent(list: Array<Int>): Bool {
        final once = list.sort();
        final twice = once.sort();
        return once.equals(twice);
    }
    
    // Custom generators
    @:generator
    static function genValidEmail(): String {
        final user = Gen.alphaNum(5, 20);
        final domain = Gen.alpha(3, 10);
        final tld = Gen.oneOf(["com", "org", "net"]);
        return '${user}@${domain}.${tld}';
    }
}
```

### Behavior Testing

```haxe
@:behavior_test
class UserFlowTest {
    @:scenario("User can register and login")
    function testRegistrationFlow(): Void {
        given("a new user registration form")
            .when("valid data is submitted")
            .then("user should be created")
            .and("welcome email should be sent")
            .and("user can login with credentials");
    }
}
```

## Summary

These patterns show how to:
1. **Write idiomatic Haxe** that compiles to idiomatic Elixir
2. **Use compiler abstractions** to handle paradigm differences
3. **Avoid anti-patterns** that fight the functional paradigm
4. **Migrate gradually** from existing Elixir code
5. **Optimize performance** with Stream and parallel patterns
6. **Test effectively** with property-based and behavior testing

The key is to leverage Haxe's type system and the compiler's intelligence to write safe, maintainable code that performs well in the Elixir runtime.