# Haxe Module System and Static Extensions

**Understanding Haxe's module organization and static extension patterns for effective Reflaxe.Elixir development.**

## Table of Contents

1. [Module Sub-Types](#module-sub-types)
2. [Static Extensions](#static-extensions)
3. [Import Strategies](#import-strategies)
4. [Best Practices](#best-practices)
5. [Real-World Examples](#real-world-examples)
6. [Common Patterns](#common-patterns)

## Module Sub-Types

### What Are Module Sub-Types?

In Haxe, a **module sub-type** is a type declared in a module with a different name than that module. This allows a single `.hx` file to contain multiple types.

### Basic Example

```haxe
// File: MyModule.hx
package com.example;

// Main type (same name as file)
class MyModule {
    public static function main() {
        trace("Hello from main module");
    }
}

// Sub-type (different name)
class Helper {
    public static function assist() {
        trace("Helper function");
    }
}

// Another sub-type
enum Status {
    Active;
    Inactive;
    Pending;
}
```

### Import Patterns for Sub-Types

```haxe
// Import main type only
import com.example.MyModule;

// Import specific sub-type
import com.example.MyModule.Helper;
import com.example.MyModule.Status;

// Import main type, sub-types available via qualification
import com.example.MyModule;
// Now you can use: MyModule.Helper.assist()
```

### When to Use Module Sub-Types

✅ **Good use cases:**
- Related types that work together (Result + ResultTools)
- Small helper classes for a main type
- Enums and their utility functions
- Types that are always used together

❌ **Avoid when:**
- Sub-types grow large and complex
- Sub-types have different dependencies
- Types serve different architectural layers
- File becomes difficult to navigate (>500 lines)

## Static Extensions

### Overview

Static extensions allow you to add methods to existing types without modifying their source code. In Haxe, this is achieved through static methods where the first parameter is the type being extended.

### Manual Extensions with `using`

The `using` keyword brings static extension classes into the current scope:

```haxe
// StringExtensions.hx
class StringExtensions {
    public static function reverse(str: String): String {
        var chars = str.split("");
        chars.reverse();
        return chars.join("");
    }
    
    public static function isPalindrome(str: String): Bool {
        var cleaned = str.toLowerCase().replace(" ", "");
        return cleaned == cleaned.reverse();
    }
}

// Usage with manual import
import StringExtensions;
using StringExtensions;

class Main {
    static function main() {
        var text = "hello";
        trace(text.reverse()); // "olleh"
        trace("racecar".isPalindrome()); // true
    }
}
```

### Automatic Extensions with `@:using`

The `@:using` metadata automatically applies static extensions to a type:

```haxe
// Option.hx
package haxe.ds;

@:using(haxe.ds.Option.OptionTools)
enum Option<T> {
    Some(value: T);
    None;
}

class OptionTools {
    public static function isSome<T>(option: Option<T>): Bool {
        return switch (option) {
            case Some(_): true;
            case None: false;
        }
    }
    
    public static function map<T, U>(option: Option<T>, transform: T -> U): Option<U> {
        return switch (option) {
            case Some(value): Some(transform(value));
            case None: None;
        }
    }
}

// Usage - extensions automatically available
import haxe.ds.Option;

class Main {
    static function main() {
        var opt = Some(42);
        trace(opt.isSome()); // true
        var doubled = opt.map(x -> x * 2); // Some(84)
    }
}
```

### Comparison: `using` vs `@:using`

| Aspect | `using` Keyword | `@:using` Metadata |
|--------|-----------------|-------------------|
| **Scope** | Current file/module only | Global (wherever type is used) |
| **Control** | Explicit per-file | Automatic with type |
| **Flexibility** | Can choose which files use extensions | Always available |
| **Maintenance** | Must add to each file | Set once on type definition |
| **Discoverability** | Explicit in imports | May be "magical" for newcomers |

## Import Strategies

### Strategy 1: Explicit Imports (Recommended for Libraries)

```haxe
// Clear and explicit
import haxe.functional.Result;
import haxe.functional.ResultTools;
using haxe.functional.ResultTools;

class UserService {
    static function parseUserId(input: String): Result<Int, String> {
        var parsed = Std.parseInt(input);
        return parsed != null ? Ok(parsed) : Error("Invalid ID");
    }
    
    static function validateUser(userId: String): Result<User, String> {
        return parseUserId(userId)
            .flatMap(id -> findUser(id))
            .mapError(err -> 'User validation failed: ${err}');
    }
}
```

### Strategy 2: Metadata-Driven (Recommended for Core Types)

```haxe
// Result.hx with automatic extensions
@:using(haxe.functional.Result.ResultTools)
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class ResultTools {
    // Extension methods automatically available
    public static function flatMap<T, U, E>(result: Result<T, E>, transform: T -> Result<U, E>): Result<U, E> {
        return switch (result) {
            case Ok(value): transform(value);
            case Error(error): Error(error);
        }
    }
}

// Usage is simpler
import haxe.functional.Result;

class UserService {
    static function validateUser(userId: String): Result<User, String> {
        return parseUserId(userId) // Extensions automatically available
            .flatMap(id -> findUser(id))
            .mapError(err -> 'User validation failed: ${err}');
    }
}
```

## Best Practices

### 1. File Organization

**Keep related types together:**
```haxe
// Good: Result.hx
enum Result<T, E> { Ok(value: T); Error(error: E); }
class ResultTools { /* extension methods */ }

// Good: User.hx  
class User { /* user model */ }
enum UserRole { Admin; Member; Guest; }
class UserValidation { /* validation logic */ }
```

**Separate unrelated types:**
```haxe
// Better as separate files
// User.hx - user model and validation
// DatabaseConnection.hx - database logic
// EmailService.hx - email functionality
```

### 2. Static Extension Guidelines

**Use descriptive method names:**
```haxe
// Good
public static function isEmpty<T>(option: Option<T>): Bool
public static function mapError<T, E, F>(result: Result<T, E>, transform: E -> F): Result<T, F>

// Avoid
public static function check<T>(option: Option<T>): Bool
public static function transform<T, E, F>(result: Result<T, E>, transform: E -> F): Result<T, F>
```

**First parameter is the extended type:**
```haxe
// Correct - String is extended
public static function reverse(str: String): String

// Correct - Array<T> is extended  
public static function findFirst<T>(array: Array<T>, predicate: T -> Bool): Option<T>

// Wrong - unclear what's being extended
public static function process(data: String, config: Config): String
```

### 3. Import Organization

**Group imports logically:**
```haxe
// Standard library
import haxe.Json;
import haxe.Http;

// External libraries  
import tink.core.Future;
import tink.core.Error;

// Project modules
import models.User;
import services.UserService;

// Static extensions (at the end)
using haxe.functional.ResultTools;
using utils.StringExtensions;
```

## Real-World Examples

### Example 1: Reflaxe.Elixir Result Type

**Current Implementation (Separate Files):**

```haxe
// std/haxe/functional/Result.hx
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);  
}

// std/haxe/functional/ResultTools.hx
class ResultTools {
    public static function map<T, U, E>(result: Result<T, E>, transform: T -> U): Result<U, E> {
        return switch (result) {
            case Ok(value): Ok(transform(value));
            case Error(error): Error(error);
        }
    }
    
    public static function flatMap<T, U, E>(result: Result<T, E>, transform: T -> Result<U, E>): Result<U, E> {
        return switch (result) {
            case Ok(value): transform(value);
            case Error(error): Error(error);
        }
    }
    
    public static function filter<T, E>(result: Result<T, E>, predicate: T -> Bool, errorValue: E): Result<T, E> {
        return switch (result) {
            case Ok(value): predicate(value) ? Ok(value) : Error(errorValue);
            case Error(error): Error(error);
        }
    }
}

// Usage
import haxe.functional.Result;
import haxe.functional.ResultTools;
using haxe.functional.ResultTools;
```

**Alternative Implementation (Same File with @:using):**

```haxe
// std/haxe/functional/Result.hx
@:using(haxe.functional.Result.ResultTools)
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class ResultTools {
    // Same methods as above
}

// Usage (simpler)
import haxe.functional.Result;
// Extensions automatically available
```

### Example 2: Haxe Standard Library Pattern

Haxe's own standard library uses both patterns:

```haxe
// eval/luv/Result.hx (Same file with @:using)
@:using(eval.luv.Result.ResultTools)
enum Result<T> {
    Ok(value: T);
    Error(e: UVError);
}

class ResultTools {
    static public inline function resolve<T>(result: Result<T>): T {
        switch result {
            case Ok(v): return v;
            case Error(e): throw new LuvException(e);
        }
    }
}

// haxe/EnumTools.hx (Separate file)
extern class EnumTools {
    public static function getName(e: Enum<Dynamic>): String;
    public static function getIndex(e: Enum<Dynamic>): Int;
    // More methods...
}
```

### Example 3: Domain-Driven Design with Haxe

```haxe
// Email.hx - Domain type with validation
@:using(haxe.validation.Email.EmailTools)
abstract Email(String) from String {
    public function new(value: String) {
        if (!isValid(value)) {
            throw 'Invalid email: ${value}';
        }
        this = value;
    }
    
    public static function parse(value: String): Result<Email, String> {
        return isValid(value) ? Ok(new Email(value)) : Error('Invalid email: ${value}');
    }
    
    private static function isValid(email: String): Bool {
        return ~/^[^@]+@[^@]+\.[^@]+$/.match(email);
    }
}

class EmailTools {
    public static function getDomain(email: Email): String {
        return email.toString().split("@")[1];
    }
    
    public static function getLocalPart(email: Email): String {
        return email.toString().split("@")[0];
    }
    
    public static function hasDomain(email: Email, domain: String): Bool {
        return email.getDomain().toLowerCase() == domain.toLowerCase();
    }
}

// Usage
import haxe.validation.Email;

class UserService {
    static function createUser(emailStr: String): Result<User, String> {
        return Email.parse(emailStr)
            .map(email -> new User(email))
            .mapError(err -> 'User creation failed: ${err}');
    }
    
    static function getUsersByDomain(users: Array<User>, domain: String): Array<User> {
        return users.filter(user -> user.email.hasDomain(domain));
    }
}
```

## Common Patterns

### Pattern 1: Functional Data Types

```haxe
// Option type with comprehensive tools
@:using(haxe.ds.Option.OptionTools)
enum Option<T> {
    Some(value: T);
    None;
}

class OptionTools {
    public static function map<T, U>(option: Option<T>, transform: T -> U): Option<U>;
    public static function flatMap<T, U>(option: Option<T>, transform: T -> Option<U>): Option<U>;
    public static function filter<T>(option: Option<T>, predicate: T -> Bool): Option<T>;
    public static function fold<T, R>(option: Option<T>, onSome: T -> R, onNone: () -> R): R;
    public static function toArray<T>(option: Option<T>): Array<T>;
    public static function toResult<T, E>(option: Option<T>, error: E): Result<T, E>;
}
```

### Pattern 2: Domain Validation Types

```haxe
// UserId.hx - Validated domain type
abstract UserId(String) from String {
    public function new(value: String) this = value;
    
    public static function parse(value: String): Result<UserId, String> {
        if (value.length < 3) return Error("UserId too short");
        if (value.length > 50) return Error("UserId too long");
        if (!~/^[a-zA-Z0-9]+$/.match(value)) return Error("UserId contains invalid characters");
        return Ok(new UserId(value));
    }
}

// Extensions for common operations
@:using(haxe.validation.UserId.UserIdTools)
class UserIdTools {
    public static function normalize(userId: UserId): UserId {
        return new UserId(userId.toString().toLowerCase());
    }
    
    public static function startsWith(userId: UserId, prefix: String): Bool {
        return userId.toString().toLowerCase().indexOf(prefix.toLowerCase()) == 0;
    }
}
```

### Pattern 3: Collection Extensions

```haxe
// ArrayExtensions.hx - Utility methods for arrays
class ArrayExtensions {
    public static function findFirst<T>(array: Array<T>, predicate: T -> Bool): Option<T> {
        for (item in array) {
            if (predicate(item)) return Some(item);
        }
        return None;
    }
    
    public static function groupBy<T, K>(array: Array<T>, keySelector: T -> K): Map<K, Array<T>> {
        var groups = new Map<K, Array<T>>();
        for (item in array) {
            var key = keySelector(item);
            if (!groups.exists(key)) groups.set(key, []);
            groups.get(key).push(item);
        }
        return groups;
    }
    
    public static function partitionResults<T, E>(array: Array<Result<T, E>>): {successes: Array<T>, errors: Array<E>} {
        var successes = [];
        var errors = [];
        for (result in array) {
            switch (result) {
                case Ok(value): successes.push(value);
                case Error(error): errors.push(error);
            }
        }
        return {successes: successes, errors: errors};
    }
}

// Usage with explicit import
using ArrayExtensions;

class DataProcessor {
    static function processUsers(rawData: Array<String>): {validUsers: Array<User>, errors: Array<String>} {
        var results = rawData.map(data -> parseUser(data));
        var partitioned = results.partitionResults();
        return {
            validUsers: partitioned.successes,
            errors: partitioned.errors
        };
    }
}
```

## Summary

The Haxe module system provides flexible options for organizing code:

1. **Module sub-types** allow multiple related types in one file
2. **Static extensions** enable adding methods to existing types
3. **`using` keyword** provides explicit, per-file extension control
4. **`@:using` metadata** enables automatic, global extension availability

Choose the pattern that best fits your project's needs:

- **Small, cohesive projects**: Use `@:using` for convenience
- **Large, collaborative projects**: Use explicit `using` for clarity
- **Library development**: Provide both options for maximum flexibility
- **Domain modeling**: Combine abstract types with static extensions for rich, type-safe APIs

Both the current Reflaxe.Elixir approach (separate files) and the alternative (same file with `@:using`) are valid patterns used in the Haxe ecosystem. The choice depends on your team's preferences and project requirements.