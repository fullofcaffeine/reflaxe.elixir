# ExUnit Testing with Reflaxe.Elixir

Reflaxe.Elixir provides comprehensive support for writing ExUnit tests in Haxe that compile to idiomatic Elixir test modules. This guide covers all supported ExUnit features and how to use them effectively.

## Overview

ExUnit is Elixir's built-in testing framework. With Reflaxe.Elixir, you can write type-safe tests in Haxe that compile to proper ExUnit test modules, complete with all the features you'd expect:

- Test functions with descriptive names
- Setup and teardown callbacks
- Describe blocks for grouping related tests
- Async tests for concurrent execution
- Test tagging for selective execution
- All ExUnit assertions with type safety

## Getting Started

### Basic Test Class

To create an ExUnit test module, extend `TestCase` and mark your class with `@:exunit`:

```haxe
import exunit.TestCase;
import exunit.Assert.*;

@:exunit
class UserTest extends TestCase {
    @:test
    function testUserCreation(): Void {
        var user = new User("Alice", 30);
        assertEqual("Alice", user.name);
        assertEqual(30, user.age);
    }
}
```

This compiles to:

```elixir
defmodule UserTest do
  use ExUnit.Case
  
  test "user creation" do
    user = User.new("Alice", 30)
    assert user.name == "Alice"
    assert user.age == 30
  end
end
```

## Available Annotations

### `@:exunit` - Mark Test Module

**Purpose**: Identifies a class as an ExUnit test module.

**Why**: Tells the compiler to generate `use ExUnit.Case` and transform test methods into ExUnit test blocks.

**How to use**:
```haxe
@:exunit
class MyTest extends TestCase {
    // Test methods here
}
```

### `@:test` - Mark Test Method

**Purpose**: Identifies a method as a test case.

**Why**: These methods become `test` blocks in the generated ExUnit module.

**How to use**:
```haxe
@:test
function testSomething(): Void {
    assertTrue(true);
}
```

**Name transformation**: The compiler automatically removes "test" prefix and converts to readable names:
- `testUserLogin` → `test "user login"`
- `testCreateOrder` → `test "create order"`
- `validateEmail` → `test "validate email"`

### `@:describe` - Group Related Tests

**Purpose**: Groups related tests in a describe block for better organization.

**Why**: Improves test readability and allows running specific groups of tests.

**How to use**:
```haxe
@:describe("User validation")
@:test
function testEmailValidation(): Void {
    assertTrue(User.isValidEmail("test@example.com"));
}

@:describe("User validation")
@:test
function testAgeValidation(): Void {
    assertTrue(User.isValidAge(25));
}
```

Compiles to:
```elixir
describe "User validation" do
  test "email validation" do
    assert User.is_valid_email("test@example.com")
  end
  
  test "age validation" do
    assert User.is_valid_age(25)
  end
end
```

### `@:async` - Run Tests Asynchronously

**Purpose**: Marks tests to run concurrently with other async tests.

**Why**: Speeds up test suite execution for tests that don't share state.

**How to use**:
```haxe
@:async
@:test
function testIndependentOperation(): Void {
    // This test can run in parallel with other async tests
    var result = performOperation();
    assertNotNull(result);
}
```

**Note**: When any test in a module is marked `@:async`, the entire module uses `use ExUnit.Case, async: true`.

### `@:tag` - Tag Tests for Selective Execution

**Purpose**: Tags tests for conditional execution or filtering.

**Why**: Allows running specific subsets of tests (e.g., skip slow tests in CI).

**How to use**:
```haxe
@:tag("slow")
@:test
function testDatabaseMigration(): Void {
    // This test might take a while
    Database.runMigrations();
    assertTrue(Database.isReady());
}

@:tag("integration")
@:tag("external")
@:test
function testExternalAPI(): Void {
    // Test that requires external service
    var response = API.fetchData();
    assertNotNull(response);
}
```

Run tagged tests with:
```bash
mix test --only slow
mix test --exclude integration
```

### `@:setup` - Run Before Each Test

**Purpose**: Executes code before each test in the module.

**Why**: Prepares test fixtures and ensures clean state for each test.

**How to use**:
```haxe
@:setup
function setupDatabase(): Void {
    Database.beginTransaction();
    insertTestData();
}
```

### `@:setupAll` - Run Once Before All Tests

**Purpose**: Executes code once before any tests in the module run.

**Why**: Performs expensive one-time setup like starting external services.

**How to use**:
```haxe
@:setupAll
function startServices(): Void {
    TestServer.start();
    Database.createTestDatabase();
}
```

### `@:teardown` - Run After Each Test

**Purpose**: Executes cleanup code after each test.

**Why**: Ensures tests don't affect each other by cleaning up state.

**How to use**:
```haxe
@:teardown
function cleanupDatabase(): Void {
    Database.rollbackTransaction();
    clearTempFiles();
}
```

### `@:teardownAll` - Run Once After All Tests

**Purpose**: Executes cleanup code once after all tests complete.

**Why**: Cleans up expensive resources created in setupAll.

**How to use**:
```haxe
@:teardownAll
function stopServices(): Void {
    TestServer.stop();
    Database.dropTestDatabase();
}
```

## Complete Example

Here's a comprehensive example using all features:

```haxe
import exunit.TestCase;
import exunit.Assert.*;

@:exunit
class TodoAppTest extends TestCase {
    
    // One-time setup for all tests
    @:setupAll
    function startApp(): Void {
        TodoApp.start();
        Database.migrate();
    }
    
    // Setup before each test
    @:setup
    function beginTransaction(): Void {
        Database.beginTransaction();
        insertSampleTodos();
    }
    
    // Tests for Todo CRUD operations
    @:describe("Todo CRUD")
    @:test
    function testCreateTodo(): Void {
        var todo = Todo.create("Buy milk", false);
        assertNotNull(todo.id);
        assertEqual("Buy milk", todo.title);
        assertFalse(todo.completed);
    }
    
    @:describe("Todo CRUD")
    @:test
    function testUpdateTodo(): Void {
        var todo = Todo.create("Buy milk", false);
        todo.complete();
        assertTrue(todo.completed);
    }
    
    @:describe("Todo CRUD")
    @:test
    function testDeleteTodo(): Void {
        var todo = Todo.create("Buy milk", false);
        var id = todo.id;
        todo.delete();
        assertNull(Todo.find(id));
    }
    
    // Tests for Todo filtering
    @:describe("Todo filtering")
    @:test
    function testFilterCompleted(): Void {
        createMixedTodos();
        var completed = Todo.filterCompleted();
        assertEqual(3, completed.length);
    }
    
    @:describe("Todo filtering")
    @:async
    @:test
    function testFilterByUser(): Void {
        var userTodos = Todo.filterByUser("alice");
        assertTrue(userTodos.length > 0);
    }
    
    // Integration tests (can be excluded)
    @:tag("integration")
    @:test
    function testSyncWithServer(): Void {
        var todos = Todo.all();
        var result = TodoSync.uploadToServer(todos);
        assertTrue(result.success);
    }
    
    // Slow tests (can be excluded in CI)
    @:tag("slow")
    @:tag("database")
    @:test
    function testLargeBatchInsert(): Void {
        var todos = generateLargeBatch(10000);
        Todo.batchInsert(todos);
        assertEqual(10000, Todo.count());
    }
    
    // Cleanup after each test
    @:teardown
    function rollbackTransaction(): Void {
        Database.rollbackTransaction();
    }
    
    // Final cleanup
    @:teardownAll
    function stopApp(): Void {
        TodoApp.stop();
        Database.cleanupTestData();
    }
    
    // Helper methods (not tests)
    function insertSampleTodos(): Void {
        Todo.create("Sample 1", false);
        Todo.create("Sample 2", true);
    }
    
    function createMixedTodos(): Void {
        for (i in 0...5) {
            Todo.create('Todo $i', i < 3);
        }
    }
    
    function generateLargeBatch(count: Int): Array<Todo> {
        return [for (i in 0...count) new Todo('Batch todo $i', false)];
    }
}
```

## Assertions Reference

The `exunit.Assert` class provides type-safe assertion methods:

| Method | Purpose | Example |
|--------|---------|---------|
| `assertEqual(expected, actual)` | Assert two values are equal | `assertEqual(5, 2 + 3)` |
| `assertNotEqual(expected, actual)` | Assert two values are not equal | `assertNotEqual(5, 2 + 2)` |
| `assertTrue(condition)` | Assert condition is true | `assertTrue(user.isActive)` |
| `assertFalse(condition)` | Assert condition is false | `assertFalse(list.isEmpty())` |
| `assertNull(value)` | Assert value is null/nil | `assertNull(user.deletedAt)` |
| `assertNotNull(value)` | Assert value is not null/nil | `assertNotNull(user.id)` |
| `assertRaises(fn)` | Assert function raises exception | `assertRaises(() -> divide(1, 0))` |

## Running Tests

### Run all tests:
```bash
mix test
```

### Run specific test file:
```bash
mix test test/user_test.exs
```

### Run tests matching pattern:
```bash
mix test --only describe:"User validation"
```

### Run async tests only:
```bash
mix test --only async
```

### Exclude slow tests:
```bash
mix test --exclude slow
```

### Run with coverage:
```bash
mix test --cover
```

## Best Practices

1. **Use describe blocks** to group related tests for better organization
2. **Mark independent tests as @:async** to speed up test execution
3. **Use tags** to categorize tests (unit, integration, slow, etc.)
4. **Keep setup/teardown focused** - only set up what's needed
5. **Use descriptive test names** that explain what's being tested
6. **One assertion per test** when possible for clearer failure messages
7. **Use helper methods** to reduce duplication in test setup

## Troubleshooting

### Tests not being recognized
- Ensure class extends `TestCase`
- Verify `@:exunit` annotation is present on the class
- Check that test methods have `@:test` annotation

### Async tests failing
- Verify tests don't share mutable state
- Ensure database tests use separate connections/transactions
- Check for race conditions in shared resources

### Setup/teardown not running
- Verify annotations are spelled correctly (`@:setup`, not `@:setUp`)
- Ensure methods are not static
- Check that methods don't have parameters

## Advanced Features (Coming Soon)

- Property-based testing with StreamData
- Test.describe with nested contexts
- Parameterized tests
- Custom assertions
- Mocking and stubbing support

## Summary

Reflaxe.Elixir's ExUnit support provides a complete, type-safe testing experience that compiles to idiomatic ExUnit tests. All the power of ExUnit with the safety and tooling of Haxe!