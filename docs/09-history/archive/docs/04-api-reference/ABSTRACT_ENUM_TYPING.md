# Abstract Enum Typing Pattern - String Literal Types in Haxe

## Overview

Haxe provides string literal typing through abstract enums, similar to TypeScript's string literal types. This pattern ensures compile-time validation of string values while maintaining clean syntax.

## The Problem: Untyped Strings

```haxe
// ❌ BAD: No compile-time validation
function setDirection(dir: String) { }

setDirection("asc");     // ✅ Works
setDirection("desc");    // ✅ Works  
setDirection("DeSCo");   // ✅ Works but WRONG! Runtime error later
setDirection("up");      // ✅ Works but WRONG! Runtime error later
```

## The Solution: Abstract Enum Pattern

### Basic Pattern (RECOMMENDED)

```haxe
/**
 * Type-safe string literals using abstract enum
 * Only accepts "asc" or "desc" at compile time
 */
@:enum abstract SortDirection(String) to String {
    var Asc = "asc";
    var Desc = "desc";
}

// Usage:
function setDirection(dir: SortDirection) { }

setDirection(Asc);           // ✅ Using enum value
setDirection("asc");         // ✅ String literal (validated!)
setDirection("desc");        // ✅ String literal (validated!)
setDirection("DeSCo");       // ❌ COMPILE ERROR - not a valid value
setDirection("up");          // ❌ COMPILE ERROR - not a valid value
```

### How It Works

1. **`@:enum`** - Tells Haxe this is a closed set of values
2. **`abstract`** - Creates a compile-time type abstraction
3. **`(String)`** - Underlying runtime type is String
4. **`to String`** - Implicit cast to String when needed
5. **Compile-time validation** - Invalid values caught during compilation

## Comparison with Other Approaches

### 1. Regular Enum (Less Flexible)

```haxe
// Traditional enum - type-safe but not string-based
enum SortDirection {
    Asc;
    Desc;
}

setDirection(Asc);           // ✅ Works
setDirection("asc");         // ❌ Type error - expects enum, not string
```

### 2. Plain String (No Safety)

```haxe
// No compile-time validation
typedef SortDirection = String;

setDirection("asc");         // ✅ Works
setDirection("DeSCo");       // ✅ Compiles but wrong!
```

### 3. Abstract with Runtime Validation (Less Safe)

```haxe
// Validates at runtime, not compile time
abstract SortDirection(String) {
    public function new(s: String) {
        if (s != "asc" && s != "desc") {
            throw 'Invalid: $s';  // Runtime error
        }
        this = s;
    }
}
```

## Advanced Patterns

### With Custom Methods

```haxe
@:enum abstract HttpMethod(String) to String {
    var Get = "GET";
    var Post = "POST";
    var Put = "PUT";
    var Delete = "DELETE";
    
    // Add helper methods
    public function isIdempotent(): Bool {
        return this == Get || this == Put || this == Delete;
    }
    
    public function isSafe(): Bool {
        return this == Get;
    }
}

// Usage:
var method: HttpMethod = "GET";  // ✅ Validated at compile time
if (method.isIdempotent()) {
    // Can safely retry
}
```

### With From Conversion

```haxe
@:enum abstract Status(String) to String {
    var Active = "active";
    var Inactive = "inactive";
    var Pending = "pending";
    
    // Convert from integers (useful for database codes)
    @:from static function fromInt(i: Int): Status {
        return switch(i) {
            case 1: Active;
            case 0: Inactive;
            case _: Pending;
        }
    }
}

var status: Status = 1;        // ✅ Converts to Active
var status2: Status = "active"; // ✅ Direct string literal
```

### For Elixir Atoms

```haxe
/**
 * Compiles to Elixir atoms while maintaining type safety
 */
@:enum abstract FlashType(String) to String {
    var Info = "info";      // Compiles to :info
    var Error = "error";    // Compiles to :error
    var Warning = "warning"; // Compiles to :warning
}

// In Haxe:
socket.putFlash(Info, "Success!");

// Generated Elixir:
Phoenix.LiveView.put_flash(socket, :info, "Success!")
```

## Real-World Examples in Reflaxe.Elixir

### 1. Sort Direction (Ecto Queries)

```haxe
@:enum abstract SortDirection(String) to String {
    var Asc = "asc";
    var Desc = "desc";
}

// Type-safe ordering
query.orderBy(u -> [{field: u.createdAt, direction: "desc"}]); // ✅
query.orderBy(u -> [{field: u.createdAt, direction: "DeSc"}]); // ❌ Compile error
```

### 2. Changeset Actions

```haxe
@:enum abstract ChangesetAction(String) to String {
    var Insert = "insert";
    var Update = "update";
    var Delete = "delete";
    var Replace = "replace";
}
```

### 3. Phoenix Socket Events

```haxe
@:enum abstract SocketEvent(String) to String {
    var Join = "join";
    var Leave = "leave";
    var Close = "close";
    var Error = "error";
    var Reply = "reply";
}
```

## Benefits Over Plain Strings

1. **Compile-time validation** - Typos caught immediately
2. **IDE autocomplete** - Shows valid options
3. **Refactoring safety** - Rename values across entire codebase
4. **Self-documenting** - Valid values are explicit in code
5. **Zero runtime cost** - Compiles to plain strings/atoms

## When to Use Abstract Enum Pattern

### ✅ USE When:
- Fixed set of string values (status codes, directions, types)
- API expects specific string literals
- Compiling to atoms in Elixir
- Want TypeScript-style string literal types

### ❌ DON'T USE When:
- Values are dynamic or user-provided
- Large number of values (100+)
- Values change frequently
- Need complex validation logic

## Comparison with TypeScript

```typescript
// TypeScript string literal types
type SortDirection = "asc" | "desc";

// Haxe equivalent using abstract enum
@:enum abstract SortDirection(String) to String {
    var Asc = "asc";
    var Desc = "desc";
}
```

Both provide:
- Compile-time validation
- IDE support
- String literal acceptance

Haxe advantages:
- Can add methods to the type
- Can define conversions (@:from, @:to)
- Works with pattern matching

## Best Practices

1. **Use for all fixed string sets** - Replace plain String parameters
2. **Name clearly** - `SortDirection` not `SortDir`
3. **Document values** - Explain what each value means
4. **Consider atoms** - For Elixir, these compile nicely to atoms
5. **Add helpers** - Methods for common operations

## Conclusion

The abstract enum pattern is the **PREFERRED WAY** to type string literals in Haxe for Reflaxe.Elixir. It provides:
- TypeScript-style string literal types
- Compile-time safety
- Clean syntax
- Zero runtime overhead

Always use this pattern instead of plain strings when the set of valid values is known at compile time.