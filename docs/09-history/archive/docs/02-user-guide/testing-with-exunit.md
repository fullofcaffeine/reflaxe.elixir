# Testing with ExUnit

`★ Insight ─────────────────────────────────────`
Write type-safe tests in Haxe that compile to idiomatic ExUnit tests. Get compile-time safety for your test assertions while generating standard Elixir test code.
`─────────────────────────────────────────────────`

## Overview

Reflaxe.Elixir provides comprehensive ExUnit testing support through the `haxe.test` package. Write your tests in Haxe with full type safety and IDE support, and they'll compile to clean, idiomatic ExUnit test modules.

## Quick Start

### Basic Test Module

```haxe
package;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;

@:exunit
class UserTest extends TestCase {
    
    @:test
    function testUserCreation() {
        var user = new User("Alice", 30);
        Assert.equals("Alice", user.name);
        Assert.equals(30, user.age);
    }
    
    @:test
    function testUserValidation() {
        var validUser = User.create("Bob", 25);
        Assert.isOk(validUser, "Valid user should be created");
        
        var invalidUser = User.create("", -5);
        Assert.isError(invalidUser, "Invalid user should fail validation");
    }
}
```

This compiles to:

```elixir
defmodule UserTest do
  use ExUnit.Case
  
  test "user creation" do
    user = User.new("Alice", 30)
    assert "Alice" == user.name
    assert 30 == user.age
  end
  
  test "user validation" do
    valid_user = User.create("Bob", 25)
    assert match?({:ok, _}, valid_user) do
      "Valid user should be created"
    end
    
    invalid_user = User.create("", -5)
    assert match?({:error, _}, invalid_user) do
      "Invalid user should fail validation"
    end
  end
end
```

## Available Assertions

### Basic Assertions

```haxe
// Boolean assertions
Assert.isTrue(condition, "Message");   // → assert condition, "Message"
Assert.isFalse(condition, "Message");  // → refute condition, "Message"

// Equality
Assert.equals(expected, actual, "Message");     // → assert expected == actual, "Message"
Assert.notEquals(expected, actual, "Message");  // → assert expected != actual, "Message"

// Null checks
Assert.isNull(value, "Message");     // → assert value == nil, "Message"
Assert.isNotNull(value, "Message");  // → assert value != nil, "Message"
```

### Option Type Assertions

```haxe
var maybeUser = findUser("alice");

Assert.isSome(maybeUser, "User should exist");  // → assert match?({:some, _}, maybe_user)
Assert.isNone(maybeUser, "User should not exist");  // → assert maybe_user == :none
```

### Result Type Assertions

```haxe
var result = validateEmail("user@example.com");

Assert.isOk(result, "Email should be valid");     // → assert match?({:ok, _}, result)
Assert.isError(result, "Email should be invalid"); // → assert match?({:error, _}, result)
```

### Collection Assertions

```haxe
var list = [1, 2, 3];
var empty = [];

Assert.contains(list, 2, "List should contain 2");  // → assert Enum.member?(list, 2)
Assert.isEmpty(empty, "List should be empty");      // → assert Enum.empty?(empty)
Assert.isNotEmpty(list, "List should not be empty"); // → refute Enum.empty?(list)
```

### String Assertions

```haxe
var text = "Hello, World!";

Assert.containsString(text, "World", "Should contain World");
// → assert String.contains?(text, "World"), "Should contain World"

Assert.doesNotContainString(text, "Goodbye", "Should not contain Goodbye");
// → refute String.contains?(text, "Goodbye"), "Should not contain Goodbye"
```

### Advanced Assertions

```haxe
// Exception handling
Assert.raises(() -> {
    throw new Error("Expected error");
}, "Should raise an error");
// → assert_raise Error, fn -> ... end

// Pattern matching
Assert.matches({ok: "value"}, result, "Result should match pattern");
// → assert match?({:ok, "value"}, result)

// Floating point comparison
Assert.inDelta(3.14, Math.PI, 0.01, "Should be approximately PI");
// → assert_in_delta 3.14, Math.PI, 0.01

// Failure assertion (for unreachable code)
Assert.fail("This should never happen");
// → flunk("This should never happen")
```

## Test Organization

### Test Naming Conventions

Test methods are automatically processed for readability:
- `testUserCreation` becomes `test "user creation"`
- `testEmailValidation` becomes `test "email validation"`
- Method must start with `test` or have `@:test` metadata

### Setup and Teardown (Coming Soon)

```haxe
@:exunit
class DatabaseTest extends TestCase {
    
    @:setup
    function setup() {
        // Run before each test
        Database.beginTransaction();
    }
    
    @:teardown
    function teardown() {
        // Run after each test
        Database.rollback();
    }
    
    @:test
    function testDatabaseOperation() {
        // Test runs in transaction
    }
}
```

## Testing with Domain Abstractions

### Testing Email Validation

```haxe
import haxe.validation.Email;
import haxe.test.Assert;

@:test
function testEmailValidation() {
    var validEmail = Email.parse("user@example.com");
    Assert.isOk(validEmail, "Valid email should parse");
    
    switch (validEmail) {
        case Ok(email):
            Assert.equals("example.com", email.getDomain());
            Assert.isTrue(email.hasDomain("example.com"));
        case Error(reason):
            Assert.fail("Should not fail: " + reason);
    }
    
    var invalidEmail = Email.parse("not-an-email");
    Assert.isError(invalidEmail, "Invalid email should be rejected");
}
```

### Testing with Result Types

```haxe
import haxe.functional.Result;
using haxe.functional.ResultTools;

@:test
function testResultChaining() {
    var result = parseUser("Alice,30")
        .map(user -> user.age)
        .filter(age -> age >= 18, "Must be adult");
    
    Assert.isOk(result, "Adult user should pass validation");
    
    switch (result) {
        case Ok(age):
            Assert.equals(30, age);
        case Error(msg):
            Assert.fail("Unexpected error: " + msg);
    }
}
```

## Running Tests

### With Mix

```bash
# Run all tests
mix test

# Run specific test file
mix test test/user_test.exs

# Run with coverage
mix test --cover
```

### Compilation

```bash
# Compile Haxe tests to Elixir
npx haxe test-build.hxml

# test-build.hxml content:
-cp src
-cp test
-lib reflaxe
-lib reflaxe-elixir
-D elixir_output=test
--macro reflaxe.elixir.CompilerInit.Start()
UserTest
DatabaseTest
```

## Best Practices

### 1. Use Descriptive Test Names

```haxe
// Good
@:test
function testEmailRejectsInvalidFormat() { }

// Less clear
@:test
function testEmail() { }
```

### 2. One Assertion Focus Per Test

```haxe
// Good - focused test
@:test
function testUserAgeMustBePositive() {
    var result = User.create("Alice", -5);
    Assert.isError(result);
}

// Less focused - testing multiple things
@:test
function testUser() {
    // Tests age, name, email all in one
}
```

### 3. Use Appropriate Assertions

```haxe
// Good - specific assertion
Assert.isOk(result, "Should succeed");

// Less specific
Assert.isTrue(result.isOk(), "Should succeed");
```

### 4. Provide Meaningful Messages

```haxe
// Good - explains expectation
Assert.equals(18, user.age, "New user should have default age of 18");

// Less helpful
Assert.equals(18, user.age);
```

## Integration with Phoenix

### Testing LiveView Components

```haxe
import phoenix.LiveViewTest;
import haxe.test.Assert;

@:exunit
class TodoLiveTest extends TestCase {
    
    @:test
    function testTodoCreation() {
        var {:ok, view, _html} = LiveViewTest.liveView(conn, "/todos");
        
        view.element("#new-todo")
            .renderSubmit(%{title: "Buy milk"});
        
        Assert.containsString(view.render(), "Buy milk");
    }
}
```

### Testing Controllers

```haxe
@:exunit
class UserControllerTest extends TestCase {
    
    @:test
    function testUserIndex() {
        var conn = get(conn, "/users");
        Assert.equals(200, conn.status);
        Assert.containsString(conn.respBody, "Users");
    }
}
```

## Troubleshooting

### Common Issues

1. **"Unknown identifier: Assert"**
   - Make sure to import `haxe.test.Assert`

2. **Tests not being recognized**
   - Ensure class has `@:exunit` metadata
   - Test methods need `@:test` metadata or `test` prefix

3. **Compilation errors in generated tests**
   - Check that all assertion arguments are provided
   - Ensure proper types for Option/Result assertions

## Advanced Features

### Custom Assertions

You can create custom assertion helpers:

```haxe
class CustomAssert {
    public static function assertValidEmail(email: String, ?msg: String) {
        var result = Email.parse(email);
        Assert.isOk(result, msg ?? "Email should be valid: " + email);
    }
}
```

### Property-Based Testing (Future)

```haxe
@:property
function propReverseTwiceIsOriginal(list: Array<Int>) {
    var reversed = list.reverse().reverse();
    Assert.equals(list, reversed);
}
```

## Summary

The ExUnit integration provides:
- Type-safe test writing in Haxe
- Clean, idiomatic ExUnit output
- Full assertion library support
- Integration with Phoenix testing utilities
- Compile-time test validation

Write your tests once in Haxe, get professional ExUnit tests in Elixir!