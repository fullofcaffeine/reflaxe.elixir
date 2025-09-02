# Async/Await Specification for Haxe→JavaScript

## Overview

This document specifies the async/await implementation for Haxe when targeting JavaScript via the genes generator. The implementation achieves near-perfect parity with JavaScript/TypeScript async/await while maintaining Haxe's type safety and ergonomics.

## Comparison with JavaScript/TypeScript

### Feature Parity Table

| Feature | JavaScript/TypeScript | Haxe with genes | Notes |
|---------|----------------------|-----------------|-------|
| Async function declaration | `async function foo()` | `@:async function foo()` | Metadata instead of keyword |
| Await expression | `await promise` | `@:await promise` | Metadata instead of keyword |
| Automatic Promise wrapping | ✅ `return 42` → `Promise<number>` | ✅ `return 42` → `Promise<Int>` | Identical behavior |
| Try/catch with await | ✅ Catches rejections | ✅ Catches rejections | Works identically |
| Type inference | ✅ `await Promise<T>` → `T` | ✅ `@:await Promise<T>` → `T` | Full type safety |
| Promise.all/race | ✅ Supported | ✅ Supported | Standard Promise API |
| Async arrow functions | `async () => {}` | `@:async () -> {}` | Haxe arrow syntax |
| Async class methods | ✅ Supported | ✅ Supported | With @:async metadata |
| Error propagation | ✅ Automatic | ✅ Automatic | Uncaught rejections propagate |
| Finally blocks | ✅ `finally {}` | ❌ Simulate with dual assignment | Haxe lacks finally |

## Syntax Specification

### 1. Async Function Declaration

**JavaScript/TypeScript:**
```javascript
async function fetchUser(id: number): Promise<User> {
    const user = await api.getUser(id);
    return user;  // Automatically wrapped in Promise
}
```

**Haxe:**
```haxe
@:async
function fetchUser(id: Int): Promise<User> {
    var user = @:await api.getUser(id);
    return user;  // Automatically wrapped in Promise
}
```

### 2. Async Class Methods

**JavaScript/TypeScript:**
```javascript
class UserService {
    async getUser(id: number): Promise<User> {
        return await db.findUser(id);
    }
}
```

**Haxe:**
```haxe
@:build(genes.AsyncMacro.build())
class UserService {
    @:async
    public function getUser(id: Int): Promise<User> {
        return @:await db.findUser(id);
    }
}
```

### 3. Inline Async Functions

**JavaScript/TypeScript:**
```javascript
const processData = async (data: string) => {
    const result = await transform(data);
    return result.toUpperCase();
};
```

**Haxe:**
```haxe
var processData = @:async (data: String) -> {
    var result = @:await transform(data);
    return result.toUpperCase();
};
```

### 4. Error Handling

**JavaScript/TypeScript:**
```javascript
async function riskyOperation() {
    try {
        const result = await dangerousCall();
        return result;
    } catch (error) {
        console.error('Failed:', error);
        return defaultValue;
    }
}
```

**Haxe:**
```haxe
@:async
function riskyOperation() {
    try {
        var result = @:await dangerousCall();
        return result;
    } catch (error: Dynamic) {
        trace('Failed: $error');
        return defaultValue;
    }
}
```

## Type System Integration

### Promise Type Enforcement

**JavaScript/TypeScript:**
- Async functions must return `Promise<T>` or `Promise<void>`
- TypeScript enforces this at compile time

**Haxe:**
- Async functions must return `Promise<T>` or `Promise<Void>`
- Haxe compiler enforces this at compile time
- Attempting to return non-Promise type causes compilation error

### Type Unwrapping

**JavaScript/TypeScript:**
```typescript
async function example() {
    const str: string = await Promise.resolve("hello");  // Promise<string> → string
    const num: number = await Promise.resolve(42);       // Promise<number> → number
}
```

**Haxe:**
```haxe
@:async
function example() {
    var str: String = @:await Promise.resolve("hello");  // Promise<String> → String
    var num: Int = @:await Promise.resolve(42);          // Promise<Int> → Int
}
```

## Implementation Details

### Build Macro Requirement

Unlike JavaScript/TypeScript which have native async/await, Haxe requires a build macro:

```haxe
@:build(genes.AsyncMacro.build())
class MyAsyncClass {
    // Async methods here
}
```

This macro:
1. Processes @:async metadata on methods
2. Transforms @:await expressions to proper await syntax
3. Automatically wraps return values in Promise.resolve()
4. Injects markers for the genes generator

### Generated JavaScript

**Haxe Input:**
```haxe
@:async
public static function getData(): Promise<String> {
    var result = @:await fetch("/api/data");
    return result.text();  // Automatically wrapped
}
```

**JavaScript Output:**
```javascript
static async getData() {
    let result = await fetch("/api/data");
    return Promise.resolve(result.text());
}
```

## Differences from JavaScript/TypeScript

### 1. Metadata vs Keywords
- **JS/TS**: Uses `async` and `await` keywords
- **Haxe**: Uses `@:async` and `@:await` metadata
- **Reason**: Haxe doesn't have native async/await keywords

### 2. Build Macro Requirement
- **JS/TS**: No preprocessing needed
- **Haxe**: Requires `@:build(genes.AsyncMacro.build())`
- **Reason**: Transforms metadata to proper async/await

### 3. Explicit Promise Import
- **JS/TS**: Promise is global
- **Haxe**: Must import `js.lib.Promise`
- **Reason**: Haxe's modular standard library

### 4. No Finally Blocks
- **JS/TS**: Has `finally` blocks
- **Haxe**: Must simulate with dual assignment in try/catch
- **Reason**: Haxe language limitation

## Best Practices

### 1. Always Use Build Macro
```haxe
@:build(genes.AsyncMacro.build())  // Required for async/await
class MyClass {
    // ...
}
```

### 2. Don't Double-Wrap Promises
```haxe
// ❌ Bad - unnecessary wrapping
@:async
function bad(): Promise<Int> {
    return Promise.resolve(42);  // Double-wrapped!
}

// ✅ Good - automatic wrapping
@:async
function good(): Promise<Int> {
    return 42;  // Automatically wrapped
}
```

### 3. Use Try/Catch for Error Handling
```haxe
// ✅ Idiomatic - matches JavaScript patterns
@:async
function handleErrors(): Promise<Result> {
    try {
        return @:await riskyOperation();
    } catch (e: Dynamic) {
        trace('Error: $e');
        return defaultResult;
    }
}
```

### 4. Type Your Promises
```haxe
// ✅ Good - explicit types
@:async
function typedAsync(): Promise<Array<User>> {
    return @:await fetchUsers();
}

// ❌ Avoid - loses type safety
@:async
function untypedAsync(): Promise<Dynamic> {
    return @:await fetchSomething();
}
```

## Testing Async Code

### Example Test Pattern
```haxe
@:build(genes.AsyncMacro.build())
class AsyncTest {
    @:async
    static function runTests(): Promise<Void> {
        // Test 1: Basic async/await
        var result = @:await someAsyncOperation();
        assert(result == expected, "Test 1 passed");
        
        // Test 2: Error handling
        try {
            @:await failingOperation();
            assert(false, "Should have thrown");
        } catch (e: Dynamic) {
            assert(true, "Error caught correctly");
        }
        
        return;  // Automatically returns Promise.resolve()
    }
    
    static function main() {
        runTests().then(
            _ -> trace("All tests passed"),
            error -> trace('Tests failed: $error')
        );
    }
}
```

## Migration Guide

### From JavaScript/TypeScript to Haxe

1. Add `@:build(genes.AsyncMacro.build())` to classes
2. Replace `async` with `@:async`
3. Replace `await` with `@:await`
4. Import `js.lib.Promise`
5. Remove explicit `Promise.resolve()` from returns
6. Change `finally` blocks to try/catch patterns

### From Haxe Callbacks to Async/Await

**Before (Callbacks):**
```haxe
function loadUser(id: Int, callback: User -> Void, error: String -> Void) {
    api.getUser(id, callback, error);
}
```

**After (Async/Await):**
```haxe
@:async
function loadUser(id: Int): Promise<User> {
    return @:await api.getUser(id);
}
```

## Performance Characteristics

- **Zero Runtime Overhead**: Compiles to native JavaScript async/await
- **No Polyfills Required**: Targets modern ES6+ environments
- **Clean Output**: No wrapper functions or helper libraries
- **Tree-Shaking Friendly**: Unused async functions eliminated by bundlers

## Limitations

1. **No Async Generators**: `async function*` not supported yet
2. **No Top-Level Await**: Must be within async function
3. **No Async Constructors**: Constructors cannot be async
4. **Finally Block Workaround**: Must simulate with try/catch

## Future Enhancements

1. **Automatic Build Macro**: Consider compiler flag to auto-apply
2. **Async Generators**: Support for `async function*` syntax
3. **Top-Level Await**: Support for module-level await
4. **Finally Support**: Potential Haxe language enhancement

## Conclusion

The Haxe async/await implementation via genes provides near-perfect parity with JavaScript/TypeScript while maintaining Haxe's superior type safety. The metadata-based syntax (`@:async`/`@:await`) is the primary difference, but the runtime behavior is identical, making it easy for JavaScript developers to adopt Haxe for full-stack development.