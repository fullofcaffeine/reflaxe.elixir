# Result vs Option: Choosing the Right Pattern for Elixir

## Quick Decision Guide

**For Elixir/Phoenix applications, prefer `Result<T,E>` over `Option<T>`** to generate idiomatic Elixir code.

## Pattern Comparison

### Result<T,E> - Idiomatic Elixir Pattern ✅

```haxe
// Haxe code
function parseUser(data: String): Result<User, String> {
    return data.length > 0 
        ? Ok(User.parse(data))
        : Error("Empty input");
}
```

```elixir
# Generated idiomatic Elixir (with @:elixirIdiomatic)
def parse_user(data) do
  if String.length(data) > 0 do
    {:ok, User.parse(data)}    # Standard Elixir pattern
  else
    {:error, "Empty input"}     # Standard Elixir pattern
  end
end
```

### Option<T> - Cross-Platform Pattern ⚠️

```haxe
// Haxe code
function findUser(id: Int): Option<User> {
    return userExists(id)
        ? Some(getUser(id))
        : None;
}
```

```elixir
# Generated Elixir (NOT idiomatic)
def find_user(id) do
  if user_exists(id) do
    {:some, get_user(id)}    # Non-standard in Elixir
  else
    :none                    # Non-standard in Elixir
  end
end
```

## When to Use Each

### Use Result<T,E> for:
- **All Elixir/Phoenix applications** - Generates idiomatic `{:ok, value}` / `{:error, reason}`
- **Error handling** - When you need to communicate why something failed
- **API responses** - Standard pattern in Phoenix controllers
- **Database operations** - Ecto returns `{:ok, record}` / `{:error, changeset}`
- **GenServer responses** - OTP expects `{:ok, state}` / `{:error, reason}`

### Use Option<T> for:
- **Cross-platform Haxe libraries** - When the same code must work on JS, Python, etc.
- **Internal logic** - When the generated Elixir pattern doesn't matter
- **Simple presence/absence** - When there's no error information to convey

## Idiomatic Alternatives

### For Simple Optional Values in Elixir

Instead of `Option<T>`, consider:

```haxe
// Using nullable types (compiles to value or nil)
function findUserName(id: Int): Null<String> {
    return userExists(id) ? getUser(id).name : null;
}
```

```elixir
# Generated idiomatic Elixir
def find_user_name(id) do
  if user_exists(id) do
    get_user(id).name
  else
    nil                      # Idiomatic for simple absence
  end
end
```

### For Success Without Data

When you only need to indicate success/failure without data:

```haxe
// Use Result<Void, String> or Result<{}, String>
function validateEmail(email: String): Result<{}, String> {
    return isValid(email)
        ? Ok({})
        : Error("Invalid email format");
}
```

```elixir
# Generated idiomatic Elixir
def validate_email(email) do
  if is_valid(email) do
    {:ok, %{}}               # Or just :ok if using Result<Void, String>
  else
    {:error, "Invalid email format"}
  end
end
```

## Migration Guide

### Converting Option<T> to Result<T,E>

```haxe
// Before: Using Option
function findUser(id: Int): Option<User> {
    return Some(user);  // or None
}

// After: Using Result for idiomatic Elixir
function findUser(id: Int): Result<User, String> {
    return Ok(user);    // or Error("User not found")
}
```

### Working with Phoenix

```haxe
// Phoenix controller with idiomatic responses
@:controller
class UserController {
    function show(conn: Conn, params: {id: String}): Conn {
        return switch(UserRepo.find(params.id)) {
            case Ok(user): 
                conn.json(%{user: user});
            case Error(reason): 
                conn
                    .putStatus(404)
                    .json(%{error: reason});
        }
    }
}
```

## Type Aliases for Common Patterns

```haxe
// Define semantic type aliases
typedef Found<T> = Result<T, String>;
typedef Validated<T> = Result<T, ValidationErrors>;
typedef Saved<T> = Result<T, ChangesetErrors>;

// Use them for clearer APIs
function findUser(id: Int): Found<User> {
    return Ok(user);  // Generates {:ok, user}
}
```

## Summary

- **Result<T,E> with @:elixirIdiomatic**: Use for all Elixir/Phoenix code to generate idiomatic `{:ok, value}` / `{:error, reason}` patterns
- **Option<T>**: Reserve for cross-platform Haxe libraries where Elixir idioms don't matter
- **Null<T>**: Consider for simple optional values that compile to `value` or `nil`
- **Result<{}, E>**: Use for success/failure without data

The key principle: **Write Haxe code that generates Elixir code an Elixir developer would write by hand.**