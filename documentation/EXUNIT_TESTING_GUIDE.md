# ExUnit Testing Guide for Haxe→Elixir

This guide explains how to write and use ExUnit tests with the Haxe→Elixir compiler, enabling type-safe testing that compiles to idiomatic Elixir test code.

## Table of Contents

- [Overview](#overview)
- [Basic Setup](#basic-setup)
- [Writing Tests](#writing-tests)
- [Assertions](#assertions)
- [Test Organization](#test-organization)
- [Phoenix Testing](#phoenix-testing)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## Overview

The Haxe→Elixir compiler provides ExUnit support through:
- `haxe.test.ExUnit` - Main test framework extern
- `haxe.test.Assert` - Type-safe assertion helpers
- `ExUnitCompiler` - Transforms Haxe test code to idiomatic ExUnit

**See Also**:
- **[Haxe→Elixir Mappings](HAXE_ELIXIR_MAPPINGS.md)** - How Haxe constructs compile to testable Elixir code
- **[Functional Patterns](FUNCTIONAL_PATTERNS.md)** - Option<T> and Result<T,E> usage patterns
- **[Standard Library Handling](STANDARD_LIBRARY_HANDLING.md)** - Testing strategy for different standard library patterns

## Basic Setup

### 1. Import Required Modules

```haxe
import haxe.test.ExUnit;
import haxe.test.Assert;

using haxe.test.ExUnit.ExUnitTools;
```

### 2. Create Test Module

```haxe
@:test
class UserTest {
    // Tests go here
}
```

The `@:test` annotation marks this class for ExUnit compilation, generating:
```elixir
defmodule UserTest do
  use ExUnit.Case
  # Compiled tests
end
```

### 3. Project Configuration

In your `build.hxml`:
```hxml
-cp src
-cp test
-lib reflaxe
-D elixir_output=test
-D reflaxe_test  # Enable test compilation mode
--macro reflaxe.elixir.CompilerInit.Start()
```

## Writing Tests

### Basic Test Structure

```haxe
@:test
class MathTest {
    @test
    public function testAddition() {
        Assert.equals(4, Calculator.add(2, 2));
    }
    
    @test("multiplication works correctly")
    public function testMultiplication() {
        var result = Calculator.multiply(3, 4);
        Assert.equals(12, result);
    }
    
    @test
    @tag("slow")
    public function testComplexCalculation() {
        // Test with tags for filtering
        Assert.isTrue(Calculator.isPrime(17));
    }
}
```

Compiles to:
```elixir
defmodule MathTest do
  use ExUnit.Case
  
  test "addition" do
    assert Calculator.add(2, 2) == 4
  end
  
  test "multiplication works correctly" do
    result = Calculator.multiply(3, 4)
    assert result == 12
  end
  
  @tag :slow
  test "complex calculation" do
    assert Calculator.is_prime(17) == true
  end
end
```

## Assertions

### Available Assertions

```haxe
// Equality
Assert.equals(expected, actual);           // assert actual == expected
Assert.notEquals(unwanted, actual);        // assert actual != unwanted

// Boolean
Assert.isTrue(condition);                  // assert condition == true
Assert.isFalse(condition);                 // assert condition == false

// Null/Option checks
Assert.isNull(value);                      // assert is_nil(value)
Assert.isNotNull(value);                   // refute is_nil(value)
Assert.isSome(option);                     // assert {:some, _} = option
Assert.isNone(option);                     // assert :none = option

// Result checks  
Assert.isOk(result);                       // assert {:ok, _} = result
Assert.isError(result);                    // assert {:error, _} = result

// Option/Result value extraction (type-safe)
Assert.optionEquals(Some(42), option);     // assert {:some, 42} = option
Assert.resultEquals(Ok("data"), result);   // assert {:ok, "data"} = result

// Pattern matching
Assert.matches(pattern, value);            // assert ^pattern = value

// Exception testing
Assert.raises(Exception, () -> {           // assert_raise Exception, fn ->
    dangerousOperation();                  //   dangerous_operation()
});                                         // end

// Custom messages
Assert.equals(expected, actual, "Values should match");
```

### Working with Option and Result Types

**Type-safe null handling and error management** with comprehensive testing support:

```haxe
import haxe.ds.Option;
import haxe.functional.Result;
using haxe.ds.OptionTools;
using haxe.functional.ResultTools;

@:test
class OptionResultTest {
    @test
    public function testOptionHandling() {
        var user = UserRepo.find(1);
        Assert.isSome(user);
        
        switch (user) {
            case Some(u):
                Assert.equals("Alice", u.name);
            case None:
                Assert.fail("User should exist");
        }
    }
    
    @test
    public function testOptionChaining() {
        var result = UserRepo.find(1)
            .map(user -> user.email)
            .filter(email -> email.contains("@"))
            .unwrap("no-email@example.com");
            
        Assert.equals("alice@example.com", result);
    }
    
    @test
    public function testResultHandling() {
        var result = UserService.create("Bob", "bob@example.com");
        Assert.isOk(result);
        
        // Extract and test the value
        switch (result) {
            case Ok(user):
                Assert.equals("Bob", user.name);
                Assert.equals("bob@example.com", user.email);
            case Error(msg):
                Assert.fail('Creation failed: $msg');
        }
    }
    
    @test
    public function testResultChaining() {
        var result = UserService.validateEmail("test@example.com")
            .flatMap(email -> UserService.validateAge(25))
            .map(age -> UserService.create("Test", "test@example.com"));
            
        Assert.isOk(result);
    }
    
    @test
    public function testResultTraverse() {
        var emails = ["a@test.com", "b@test.com", "c@test.com"];
        var result = ResultTools.traverse(emails, UserService.validateEmail);
        
        Assert.isOk(result);
        
        switch (result) {
            case Ok(validEmails):
                Assert.equals(3, validEmails.length);
            case Error(msg):
                Assert.fail('Should validate all emails');
        }
    }
}
```

## Test Organization

### Setup and Teardown

```haxe
@:test
class DatabaseTest {
    @setup
    public function setupDatabase() {
        // Runs before each test
        Database.beginTransaction();
    }
    
    @teardown
    public function cleanupDatabase() {
        // Runs after each test
        Database.rollback();
    }
    
    @setupAll
    public static function globalSetup() {
        // Runs once before all tests
        Database.connect();
    }
    
    @teardownAll
    public static function globalCleanup() {
        // Runs once after all tests
        Database.disconnect();
    }
}
```

### Test Contexts (Describe Blocks)

```haxe
@:test
class UserControllerTest {
    @describe("when user is authenticated")
    public function authenticatedTests() {
        @test
        public function canAccessProfile() {
            // Test authenticated access
        }
        
        @test
        public function canUpdateSettings() {
            // Test settings update
        }
    }
    
    @describe("when user is anonymous")
    public function anonymousTests() {
        @test
        public function redirectsToLogin() {
            // Test redirect behavior
        }
    }
}
```

## Phoenix Testing

### Controller Tests

```haxe
@:test
@:useCase("ConnCase")  // Uses Phoenix.ConnTest
class UserControllerTest {
    @test
    public function testIndex(conn: Conn) {
        conn = get(conn, "/users");
        Assert.equals(200, conn.status);
        Assert.contains(conn.resp_body, "Users");
    }
    
    @test
    public function testCreate(conn: Conn) {
        var params = {
            user: {
                name: "Alice",
                email: "alice@example.com"
            }
        };
        
        conn = post(conn, "/users", params);
        Assert.equals(302, conn.status);  // Redirect after creation
    }
}
```

### LiveView Tests

```haxe
@:test
@:useCase("LiveViewTest")
class TodoLiveTest {
    @test
    public function testRendersTodos(conn: Conn) {
        var view = live(conn, "/todos");
        
        Assert.contains(view.html(), "Todo List");
        Assert.matches(~/<li>.*Buy milk.*<\/li>/, view.html());
    }
    
    @test
    public function testAddTodo(conn: Conn) {
        var view = live(conn, "/todos");
        
        // Simulate form submission
        view.submitForm("todo-form", {
            todo: {title: "New Task", completed: false}
        });
        
        Assert.contains(view.html(), "New Task");
    }
}
```

### Database Tests

```haxe
@:test
@:useCase("DataCase")  // Handles Ecto sandbox
class UserRepoTest {
    @test
    public function testCreateUser() {
        var result = UserRepo.create({
            name: "Bob",
            email: "bob@test.com"
        });
        
        Assert.isOk(result);
        
        switch (result) {
            case Ok(user):
                Assert.isNotNull(user.id);
                Assert.equals("Bob", user.name);
            case Error(changeset):
                Assert.fail("Should create user");
        }
    }
}
```

## Best Practices

### 1. Use Descriptive Test Names

```haxe
// ❌ Bad
@test
public function test1() { }

// ✅ Good
@test("returns error when email is invalid")
public function testInvalidEmailError() { }
```

### 2. Test One Thing at a Time

```haxe
// ❌ Bad - Testing multiple behaviors
@test
public function testUser() {
    var user = User.create("Alice", "alice@example.com");
    Assert.equals("Alice", user.name);
    Assert.equals("alice@example.com", user.email);
    Assert.isTrue(user.isActive());
    Assert.equals(0, user.loginCount);
}

// ✅ Good - Focused tests
@test
public function testUserCreation() {
    var user = User.create("Alice", "alice@example.com");
    Assert.equals("Alice", user.name);
    Assert.equals("alice@example.com", user.email);
}

@test
public function testNewUserIsActive() {
    var user = User.create("Alice", "alice@example.com");
    Assert.isTrue(user.isActive());
}
```

### 3. Use Setup for Common Initialization

```haxe
@:test
class OrderTest {
    var user: User;
    var product: Product;
    
    @setup
    public function createTestData() {
        user = User.create("Test User", "test@example.com");
        product = Product.create("Widget", 29.99);
    }
    
    @test
    public function testOrderCreation() {
        var order = Order.create(user, product, 2);
        Assert.equals(59.98, order.total);
    }
}
```

### 4. Test Edge Cases

```haxe
@test
public function testDivisionByZero() {
    Assert.raises(ArithmeticException, () -> {
        Calculator.divide(10, 0);
    });
}

@test
public function testEmptyListHandling() {
    var result = ListProcessor.sum([]);
    Assert.equals(0, result);
}

@test
public function testNullHandling() {
    var result = StringUtils.capitalize(null);
    Assert.isNull(result);
}
```

## Common Patterns

### Testing Async Operations

```haxe
@test
@async
public function testAsyncOperation() {
    var future = AsyncService.fetchData();
    
    future.handle(result -> {
        switch (result) {
            case Success(data):
                Assert.equals("expected", data);
                done();  // Signal test completion
            case Failure(error):
                Assert.fail('Async operation failed: $error');
        }
    });
}
```

### Testing with Mocks

```haxe
@test
public function testEmailService() {
    // Create mock
    var mockMailer = Mock.create(Mailer);
    Mock.expect(mockMailer.send).withArgs("test@example.com", "Welcome").returns(true);
    
    // Inject mock
    var service = new EmailService(mockMailer);
    var result = service.sendWelcome("test@example.com");
    
    Assert.isTrue(result);
    Mock.verify(mockMailer);
}
```

### Property-Based Testing

```haxe
@test
@property
public function testSortingProperty(list: Array<Int>) {
    var sorted = Sorter.sort(list);
    
    // Property 1: Length preserved
    Assert.equals(list.length, sorted.length);
    
    // Property 2: Ordered
    for (i in 0...sorted.length - 1) {
        Assert.isTrue(sorted[i] <= sorted[i + 1]);
    }
    
    // Property 3: Same elements
    for (item in list) {
        Assert.isTrue(sorted.contains(item));
    }
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Tests Not Being Discovered

**Problem**: Tests don't run even though they're defined.

**Solution**: Ensure:
- Class has `@:test` annotation
- Test methods have `@test` annotation
- Test files are included in compilation path

#### 2. Assertion Compilation Errors

**Problem**: Assert statements don't compile correctly.

**Solution**: Import the correct module:
```haxe
import haxe.test.Assert;  // NOT import Assert;
```

#### 3. Async Test Timeouts

**Problem**: Async tests timeout before completion.

**Solution**: Increase timeout or ensure `done()` is called:
```haxe
@test
@timeout(5000)  // 5 seconds
@async
public function testSlowOperation() {
    // Test implementation
}
```

#### 4. Test Isolation Issues

**Problem**: Tests affect each other's state.

**Solution**: Use proper setup/teardown:
```haxe
@setup
public function resetState() {
    Database.clearAll();
    Cache.flush();
}
```

## Running Tests

### Command Line

```bash
# Run all tests
mix test

# Run specific file
mix test test/user_test.exs

# Run with tag
mix test --only slow

# Run with coverage
mix test --cover
```

### Continuous Integration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Compile Haxe tests
        run: haxe test.hxml
      - name: Run ExUnit tests
        run: mix test
```

## Advanced Topics

### Custom Assertions

Create reusable assertion helpers:

```haxe
class CustomAssert {
    public static function assertValidEmail(email: String) {
        Assert.matches(~/^[^@]+@[^@]+\.[^@]+$/, email, 
                      'Invalid email format: $email');
    }
    
    public static function assertBetween(value: Float, min: Float, max: Float) {
        Assert.isTrue(value >= min && value <= max,
                     'Value $value not between $min and $max');
    }
}
```

### Test Factories

Create test data easily:

```haxe
class Factory {
    public static function createUser(?name: String, ?email: String): User {
        return User.create(
            name ?? "Test User",
            email ?? "test@example.com"
        );
    }
    
    public static function createOrder(?user: User, ?items: Int): Order {
        var u = user ?? createUser();
        return Order.create(u, items ?? 1);
    }
}
```

## Type-Safe Testing Patterns

### Testing with Cross-Platform Types

**Option<T> Testing Patterns**:
```haxe
@:test
class OptionTestPatterns {
    @test
    public function testSomeValue() {
        var option = Some(42);
        Assert.isSome(option);
        Assert.equals(42, option.extract());
    }
    
    @test
    public function testNoneValue() {
        var option = None;
        Assert.isNone(option);
        Assert.equals("default", option.unwrap("default"));
    }
    
    @test
    public function testOptionMapping() {
        var doubled = Some(21).map(x -> x * 2);
        Assert.equals(Some(42), doubled);
        
        var noneDoubled = None.map(x -> x * 2);
        Assert.equals(None, noneDoubled);
    }
}
```

**Result<T,E> Testing Patterns**:
```haxe
@:test
class ResultTestPatterns {
    @test
    public function testOkValue() {
        var result = Ok("success");
        Assert.isOk(result);
        Assert.equals("success", result.extract());
    }
    
    @test
    public function testErrorValue() {
        var result = Error("failed");
        Assert.isError(result);
        Assert.equals("default", result.unwrap("default"));
    }
    
    @test
    public function testResultChaining() {
        var result = Ok(5)
            .flatMap(x -> x > 0 ? Ok(x * 2) : Error("negative"))
            .map(x -> x + 1);
            
        Assert.equals(Ok(11), result);
    }
}
```

### Testing Compiled Elixir Patterns

These Haxe tests compile to ExUnit tests that verify the generated Elixir patterns:

```elixir
# Generated from Option tests
test "some value" do
  option = {:some, 42}
  assert match?({:some, _}, option)
  assert {:some, value} = option
  assert value == 42
end

test "none value" do
  option = :none
  assert option == :none
end

# Generated from Result tests
test "ok value" do
  result = {:ok, "success"}
  assert match?({:ok, _}, result)
  assert {:ok, value} = result
  assert value == "success"
end

test "error value" do
  result = {:error, "failed"}
  assert match?({:error, _}, result)
end
```

## Cross-References

- **[Haxe→Elixir Mappings](HAXE_ELIXIR_MAPPINGS.md)** - Complete mapping reference for all testable constructs
- **[Functional Patterns](FUNCTIONAL_PATTERNS.md)** - Option<T> and Result<T,E> usage examples and patterns
- **[Standard Library Handling](STANDARD_LIBRARY_HANDLING.md)** - Testing strategies for different standard library implementations
- **[Developer Patterns](guides/DEVELOPER_PATTERNS.md)** - Best practices for type-safe development and testing
- **[BEAM Type Abstractions](BEAM_TYPE_ABSTRACTIONS.md)** - Deep dive into Option<T> and Result<T,E> design
- **[Paradigm Bridge](paradigms/PARADIGM_BRIDGE.md)** - Cross-platform testing philosophy

## External References

- [ExUnit Documentation](https://hexdocs.pm/ex_unit/ExUnit.html)
- [Phoenix Testing Guide](https://hexdocs.pm/phoenix/testing.html)
- [Ecto Sandbox](https://hexdocs.pm/ecto/Ecto.Adapters.SQL.Sandbox.html)
- [Haxe Testing](https://haxe.org/manual/std-unit-testing.html)
- [Gleam Testing Patterns](https://gleam.run/book/tour/testing.html) - Inspiration for type-safe BEAM testing