# BEAM Type Abstractions in Reflaxe.Elixir

*Gleam-inspired type-safe patterns for OTP/BEAM development*

## Table of Contents
- [Philosophy](#philosophy)
- [Option<T> Type](#optiont-type)
- [Result<T,E> Type](#resultte-type)
- [Integration with OTP](#integration-with-otp)
- [Real-World Examples](#real-world-examples)
- [Design Principles](#design-principles)

## Philosophy

Reflaxe.Elixir takes inspiration from [Gleam](https://gleam.run/) - a type-safe language for the BEAM that demonstrates how to build robust abstractions over Erlang/OTP primitives while maintaining the platform's fault-tolerance benefits.

### Core Principles (Gleam-Inspired)

1. **Type Safety First** - Sacrifice features that can't be type-safe over untyped flexibility
2. **Explicit Over Implicit** - Make intentions clear in the type system
3. **BEAM Idioms with Type Guarantees** - Generate idiomatic BEAM code while maintaining compile-time safety
4. **Fault Tolerance Through Types** - Use Result/Option for expected failures, supervision for unexpected ones
5. **Functional Composition First** - Design APIs for chaining and transformation

## Option<T> Type

The `Option<T>` type provides type-safe null handling that compiles to idiomatic BEAM patterns.

### Definition

```haxe
// In std/haxe/ds/Option.hx
enum Option<T> {
    Some(v: T);
    None;
}
```

### Compilation Patterns

Option values compile to BEAM-friendly patterns:
- `Some(value)` → `{:some, value}`
- `None` → `:none`

This differs from Elixir's typical use of `nil` but provides better type safety and explicit intent.

### Usage Patterns

```haxe
// Basic construction
var user: Option<User> = findUser(id);

// Pattern matching (idiomatic Haxe)
switch (user) {
    case Some(u): processUser(u);
    case None: handleMissingUser();
}

// Functional composition
var email = user
    .map(u -> u.email)
    .filter(e -> e.length > 0)
    .unwrap("no-email@example.com");

// BEAM/OTP integration
var result = user.toResult("User not found");
```

### Generated Elixir

```elixir
# Pattern matching compiles to:
case user do
  {:some, u} -> process_user(u)
  :none -> handle_missing_user()
end

# Functional operations use proper BEAM patterns
case user do
  {:some, value} -> {:some, String.upcase(value)}
  :none -> :none
end
```

## Result<T,E> Type

The `Result<T,E>` type provides explicit error handling that maps directly to Elixir's `{:ok, value}` / `{:error, reason}` idiom.

### Definition

```haxe
// In std/haxe/functional/Result.hx
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}
```

### Compilation Patterns

Result values compile to standard BEAM tuples:
- `Ok(value)` → `{:ok, value}`
- `Error(reason)` → `{:error, reason}`

This provides seamless integration with existing Elixir/Erlang libraries.

### Usage Patterns

```haxe
// Error handling chains
function updateUser(id: Int, data: Dynamic): Result<User, String> {
    return findUser(id)
        .toResult("User not found")
        .flatMap(user -> validateData(data))
        .map(valid -> user.update(valid))
        .mapError(err -> 'Update failed: ${err}');
}

// Pattern matching
switch (updateUser(123, data)) {
    case Ok(user): sendNotification(user);
    case Error(msg): logError(msg);
}
```

## Integration with OTP

### GenServer Reply Patterns

Option and Result types integrate naturally with GenServer callbacks:

```haxe
@:genserver
class UserCache {
    @:call
    public function getUser(id: Int): Option<User> {
        return cache.get(id);
    }
    
    @:call
    public function updateUser(id: Int, data: Dynamic): Result<User, String> {
        return getUser(id)
            .toResult("User not found")
            .flatMap(user -> user.update(data));
    }
}
```

Compiles to:

```elixir
def handle_call({:get_user, id}, _from, state) do
  reply = case Map.get(state.cache, id) do
    nil -> :none
    user -> {:some, user}
  end
  {:reply, reply, state}
end

def handle_call({:update_user, id, data}, _from, state) do
  reply = case Map.get(state.cache, id) do
    nil -> {:error, "User not found"}
    user -> User.update(user, data)
  end
  {:reply, reply, state}
end
```

### Supervisor Child Specs

Option types work well with optional configuration:

```haxe
function childSpec(name: String, config: Option<Config>): ChildSpec {
    return {
        id: name,
        start: {
            module: WorkerModule,
            function: "start_link",
            args: [config.unwrap(defaultConfig())]
        },
        restart: config.map(c -> c.restart).unwrap(Permanent)
    };
}
```

## Real-World Examples

### Database Repository Pattern

```haxe
class UserRepository {
    /**
     * Find user by ID - returns Option for nullable result
     */
    public static function find(id: Int): Option<User> {
        var result = Database.query("SELECT * FROM users WHERE id = ?", [id]);
        return result.rows.length > 0 
            ? Some(User.fromRow(result.rows[0]))
            : None;
    }
    
    /**
     * Create user - returns Result for error handling
     */
    public static function create(data: UserData): Result<User, ValidationError> {
        return validate(data)
            .flatMap(valid -> {
                try {
                    var id = Database.insert("users", valid);
                    Ok(User.fromData(valid, id));
                } catch (e: Dynamic) {
                    Error(DatabaseError(e.toString()));
                }
            });
    }
    
    /**
     * Update user - combines Option and Result
     */
    public static function update(id: Int, changes: Dynamic): Result<User, String> {
        return find(id)
            .toResult("User not found")
            .flatMap(user -> user.applyChanges(changes))
            .flatMap(updated -> save(updated));
    }
}
```

### API Handler Pattern

```haxe
@:controller
class UserController {
    public function show(conn: Conn, params: Params): Conn {
        var userId = params.get("id").then(id -> parseInt(id));
        
        return userId
            .then(id -> UserRepository.find(id))
            .map(user -> conn.json(user))
            .unwrap(conn.notFound("User not found"));
    }
    
    public function create(conn: Conn, params: Params): Conn {
        var userData = parseUserData(params);
        
        return userData
            .then(data -> UserRepository.create(data))
            .fold(
                user -> conn.created(user),
                error -> conn.badRequest(error.message)
            );
    }
}
```

### Configuration Management

```haxe
class Config {
    static var settings: Map<String, Option<String>> = new Map();
    
    public static function get(key: String): Option<String> {
        return settings.get(key);
    }
    
    public static function getRequired(key: String): Result<String, String> {
        return get(key).toResult('Missing required config: ${key}');
    }
    
    public static function getInt(key: String): Option<Int> {
        return get(key).then(value -> {
            var parsed = Std.parseInt(value);
            return parsed != null ? Some(parsed) : None;
        });
    }
    
    public static function getWithDefault(key: String, defaultValue: String): String {
        return get(key).unwrap(defaultValue);
    }
}
```

## Design Principles

### Why Not Just Use Null?

1. **Explicit Intent** - `Option<String>` clearly indicates the value might be absent
2. **Compile-Time Safety** - Can't accidentally use None as a value
3. **Functional Composition** - Rich set of operations for transformation and chaining
4. **Pattern Matching** - Forces handling both Some and None cases

### Why Tagged Tuples Instead of Nil?

Following Gleam's philosophy:
- **Distinguishable from actual nil** - `:none` is intentionally absent, `nil` might be a bug
- **Pattern matching clarity** - `{:some, value}` vs `:none` is explicit
- **Consistent with Result** - Both Option and Result use similar patterns
- **Type preservation** - Maintains type information through compilation

### When to Use Option vs Result

**Option<T>** - When absence is a normal, expected state:
- Database lookups that might not find a record
- Configuration values that are optional
- First/last element of potentially empty collections

**Result<T,E>** - When you need to know WHY something failed:
- Validation that can fail for multiple reasons
- IO operations that might have various errors
- Business logic with specific failure cases

### Integration Philosophy

Reflaxe.Elixir's type abstractions follow these principles:

1. **Generate idiomatic BEAM code** - Output should look natural to Elixir developers
2. **Preserve type safety** - Compile-time guarantees translate to runtime correctness
3. **Enable gradual adoption** - Can mix with existing untyped code
4. **Respect BEAM philosophy** - Let it crash for unexpected errors, handle expected ones

## See Also

- [Paradigm Bridge](paradigms/PARADIGM_BRIDGE.md) - Cross-platform development patterns
- [Functional Patterns](FUNCTIONAL_PATTERNS.md) - Functional programming in Haxe→Elixir
- [Standard Library Handling](STANDARD_LIBRARY_HANDLING.md) - How standard library types compile
- [Developer Patterns](guides/DEVELOPER_PATTERNS.md) - Best practices for Haxe→Elixir development