# Option<T> Patterns with ExUnit Testing

This example demonstrates real-world usage of Option<T> for type-safe null handling in Elixir applications, with comprehensive ExUnit tests written in Haxe.

## What This Example Shows

### 1. **Type-Safe Repository Pattern**
- `UserRepository.hx` - Database operations that return `Option<User>` instead of null
- Demonstrates safe database lookups with explicit handling of missing records

### 2. **Configuration Management**
- `ConfigManager.hx` - Safe configuration access with defaults and validation
- Shows how to chain Option operations for complex configuration logic

### 3. **Service Layer Integration**
- `NotificationService.hx` - Option types in business logic
- Demonstrates how to compose Option and Result types for robust error handling

### 4. **ExUnit Testing in Haxe**
- Tests written in Haxe that compile to ExUnit test modules
- Type-safe assertions that work with Option and Result types
- Real test scenarios that verify the example code actually works

## Key Benefits Demonstrated

1. **No Null Pointer Exceptions** - Option<T> makes null handling explicit
2. **Composable Operations** - Chain map/flatMap/filter operations safely
3. **BEAM Integration** - Option compiles to `{:some, value}` / `:none` patterns
4. **Type-Safe Testing** - Tests are type-checked at compile time
5. **Real Working Code** - All examples have passing tests

## Files Overview

### Source Code (`src_haxe/`)
- `models/User.hx` - User data model
- `repositories/UserRepository.hx` - Database access with Option returns
- `services/ConfigManager.hx` - Configuration management with Option
- `services/NotificationService.hx` - Business logic with Option/Result
- `Main.hx` - Example usage

### Tests (`test_haxe/`)
- `repositories/UserRepositoryTest.hx` - Repository testing with ExUnit
- `services/ConfigManagerTest.hx` - Configuration testing
- `services/NotificationServiceTest.hx` - Service layer testing

### Generated Output (`lib/`)
- All `.ex` files are generated from Haxe source
- Includes both application code and ExUnit test modules

## Running the Example

```bash
# Compile Haxe to Elixir
haxe build.hxml

# Run tests
mix test

# Run the example
mix run -e "Main.main()"
```

## Key Patterns Demonstrated

### 1. Safe Database Access
```haxe
// Returns Option instead of null
var user: Option<User> = UserRepository.find(123);

// Safe chaining with map
var email = user
    .map(u -> u.email)
    .unwrap("no-email@example.com");
```

### 2. Configuration with Defaults
```haxe
// Get config with fallback
var timeout = ConfigManager.getInt("timeout").unwrap(30);

// Chain validation
var result = ConfigManager.getRequired("database_url")
    .toResult("Missing database URL")
    .flatMap(url -> validateUrl(url));
```

### 3. Type-Safe Testing
```haxe
@:exunit
class UserRepositoryTest extends TestCase {
    @:test
    function findReturnsOptionForValidId() {
        var user = UserRepository.find(1);
        Assert.isSome(user);
        
        switch(user) {
            case Some(u): Assert.equals("Alice", u.name);
            case None: Assert.fail("Expected user");
        }
    }
}
```

## Learning Points

1. **Option vs Null** - Explicit absence handling prevents runtime errors
2. **Functional Composition** - Chain operations safely without nested null checks
3. **BEAM Patterns** - Generated code follows Elixir conventions
4. **Test Coverage** - All code paths are tested and verified
5. **Type Safety** - Compile-time guarantees prevent common mistakes

This example serves as both documentation and verification that Option<T> patterns work correctly in real Elixir applications.