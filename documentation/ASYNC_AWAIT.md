# Async/Await Support in Reflaxe.Elixir

## Overview

Reflaxe.Elixir now provides **full async/await support** for Haxe→JavaScript compilation, enabling clean, modern asynchronous programming patterns that compile to native JavaScript `async function` declarations and `await` expressions.

## Features

✅ **Native JavaScript Generation** - Compiles to actual `async function` and `await` keywords  
✅ **Type-Safe Promise Handling** - Full type inference with `Promise<T>` unwrapping  
✅ **Build Macro Integration** - Automatic function transformation with `@:async`  
✅ **Custom JS Generator** - Uses AsyncJSGenerator for proper code generation  
✅ **Zero Runtime Overhead** - Pure compile-time transformation  
✅ **100% Promise Compatibility** - Works with all JavaScript Promise libraries  
✅ **Error Handling** - Full try/catch support with async/await  
✅ **Snapshot Testing** - Included in test suite for reliability  

## Quick Start

### 1. Basic Usage

```haxe
import reflaxe.js.Async;

@:build(reflaxe.js.Async.build())
class MyApp {
    
    @:async
    public static function loadData(): js.lib.Promise<String> {
        var config = Async.await(loadConfig());
        var result = Async.await(fetchData(config.url));
        return js.lib.Promise.resolve(result.toUpperCase());
    }
    
    static function loadConfig(): js.lib.Promise<{url: String}> {
        return js.lib.Promise.resolve({url: "https://api.example.com"});
    }
    
    static function fetchData(url: String): js.lib.Promise<String> {
        return new js.lib.Promise(function(resolve, reject) {
            // Fetch implementation
            resolve("data from " + url);
        });
    }
}
```

### 2. Build Configuration

Add to your `.hxml` file:

```hxml
# Enable AsyncJSGenerator for native async/await support
--macro reflaxe.js.AsyncJSGenerator.use()

# Modern JavaScript target
-D js-es=6
```

### 3. Generated JavaScript

The above Haxe code compiles to clean JavaScript:

```javascript
MyApp.loadData = async function() {
    let config = await loadConfig();
    let result = await fetchData(config.url);
    return Promise.resolve(result.toUpperCase());
};
```

## Detailed Usage

### Function Declaration

Mark functions with `@:async` to enable async/await:

```haxe
@:async
public static function processData(): js.lib.Promise<Array<String>> {
    var items = Async.await(loadItems());
    var processed = [];
    
    for (item in items) {
        var result = Async.await(processItem(item));
        processed.push(result);
    }
    
    return js.lib.Promise.resolve(processed);
}
```

**Generates:**
```javascript
MyApp.processData = async function() {
    let items = await loadItems();
    let processed = [];
    
    for (let item of items) {
        let result = await processItem(item);
        processed.push(result);
    }
    
    return Promise.resolve(processed);
};
```

### Error Handling

Full try/catch support with async/await:

```haxe
@:async
public static function safeOperation(): js.lib.Promise<String> {
    try {
        var data = Async.await(riskyOperation());
        var processed = Async.await(processData(data));
        return js.lib.Promise.resolve("Success: " + processed);
    } catch (error: Dynamic) {
        trace("Error occurred:", error);
        return js.lib.Promise.resolve("Error handled");
    }
}
```

**Generates:**
```javascript
MyApp.safeOperation = async function() {
    try {
        let data = await riskyOperation();
        let processed = await processData(data);
        return Promise.resolve("Success: " + processed);
    } catch (error) {
        console.log("Error occurred:", error);
        return Promise.resolve("Error handled");
    }
};
```

### Conditional Async Operations

```haxe
@:async
public static function conditionalLoad(useCache: Bool): js.lib.Promise<String> {
    if (useCache) {
        var cached = Async.await(loadFromCache());
        return js.lib.Promise.resolve(cached);
    } else {
        var fresh = Async.await(loadFromAPI());
        return js.lib.Promise.resolve(fresh);
    }
}
```

### Integration with Promise Utilities

Works with existing Promise libraries and utilities:

```haxe
@:async
public static function parallelOperations(): js.lib.Promise<Array<String>> {
    // Sequential awaits
    var result1 = Async.await(operation1());
    var result2 = Async.await(operation2());
    
    // Or use Promise.all for parallel execution
    var promises = [operation3(), operation4()];
    var parallelResults = Async.await(js.lib.Promise.all(promises));
    
    var combined = [result1, result2].concat(parallelResults);
    return js.lib.Promise.resolve(combined);
}
```

## Architecture

### Components

1. **`reflaxe.js.Async`** - Core macro library with `@:async` build macro and `await()` expression macro
2. **`reflaxe.js.AsyncJSGenerator`** - Custom JavaScript generator that extends ExampleJSGenerator
3. **`reflaxe.js.Promise`** - Static extension utilities for Promise manipulation
4. **Test Infrastructure** - Snapshot tests ensure reliable code generation

### How It Works

1. **Build Macro Processing**: `@:async` functions are processed by `Async.build()`
2. **Metadata Marking**: Processed functions get `:jsAsync` metadata for generator detection
3. **Return Type Transformation**: `T` → `Promise<T>` transformation
4. **JavaScript Generation**: AsyncJSGenerator detects `:jsAsync` and adds `async` keyword
5. **Await Expression**: `Async.await()` macro generates native `await` expressions

## Phoenix LiveView Integration

Perfect for Phoenix LiveView applications:

```haxe
@:build(reflaxe.js.Async.build())
class LiveViewHooks {
    
    @:async
    public static function initializeHook(): js.lib.Promise<Dynamic> {
        var config = Async.await(loadConfiguration());
        var connection = Async.await(establishConnection(config));
        
        return js.lib.Promise.resolve({
            mounted: function() {
                trace("Hook mounted with async initialization");
            },
            destroyed: function() {
                connection.close();
            }
        });
    }
}
```

## Best Practices

### 1. Type Safety
- Always specify Promise return types: `js.lib.Promise<T>`
- Use typed parameters for better inference
- Avoid `Dynamic` unless necessary

### 2. Error Handling
- Wrap await calls in try/catch for proper error handling
- Return meaningful error messages
- Consider using Result<T,E> types for structured error handling

### 3. Performance
- Use `Promise.all()` for parallel operations
- Avoid unnecessary sequential awaits
- Consider using `Promise.race()` for timeout scenarios

### 4. Testing
- Test async functions with proper Promise assertions
- Use the snapshot testing approach for code generation validation
- Verify both success and error paths

## Comparison with Other Approaches

### vs. Promise Chains
```haxe
// Promise chains (verbose)
loadData()
    .then(function(data) return processData(data))
    .then(function(result) return saveResult(result))
    .then(function(_) trace("Complete"))
    .catchError(function(error) trace("Error:", error));

// Async/await (clean)
@:async
public static function handleData(): js.lib.Promise<Void> {
    try {
        var data = Async.await(loadData());
        var result = Async.await(processData(data));
        Async.await(saveResult(result));
        trace("Complete");
    } catch (error: Dynamic) {
        trace("Error:", error);
    }
    return js.lib.Promise.resolve(cast null);
}
```

### vs. Callback Hell
```haxe
// Callback hell (hard to read)
loadData(function(data) {
    processData(data, function(result) {
        saveResult(result, function() {
            trace("Complete");
        }, function(error) {
            trace("Save error:", error);
        });
    }, function(error) {
        trace("Process error:", error);
    });
}, function(error) {
    trace("Load error:", error);
});

// Async/await (linear and clear)
@:async
public static function handleDataClean(): js.lib.Promise<Void> {
    var data = Async.await(loadData());
    var result = Async.await(processData(data));
    Async.await(saveResult(result));
    trace("Complete");
    return js.lib.Promise.resolve(cast null);
}
```

## Testing

The async/await implementation includes comprehensive tests:

### Snapshot Test
Location: `test/tests/js_async_await/`

Validates that:
- `@:async` functions generate `async function` declarations
- `await()` expressions generate native `await` 
- Regular functions don't get `async` keyword
- Error handling works correctly

Run with:
```bash
haxe test/Test.hxml test=js_async_await
```

### Example Test Output
```javascript
Main.simpleAsync = async function() {
    let greeting = await Promise.resolve("Hello");
    return Promise.resolve(greeting + " World");
};

Main.regularFunction = function() {
    return "Not async";
};
```

## Limitations

### Current Limitations
- `Promise<Void>` types may require special handling in some contexts
- Macro processing adds slight compilation overhead
- Requires modern JavaScript target (ES6+)

### Known Issues
- None currently - all snapshot tests pass

## Examples

See working examples in:
- `test/tests/js_async_await/Main.hx` - Complete test cases
- `std/reflaxe/js/Async.hx` - Implementation reference
- `examples/todo-app/` - Real-world Phoenix LiveView usage

## Future Enhancements

Planned improvements:
- [ ] Generator function support (`async function*`)
- [ ] Top-level await support
- [ ] Integration with Haxe's Result<T,E> types
- [ ] Performance optimizations for large codebases
- [ ] Improved error messages and debugging

## Support

For issues or questions:
1. Check the snapshot tests for working examples
2. Review this documentation for patterns
3. File issues on the Reflaxe.Elixir repository
4. See the main project documentation for general guidance

---

**The async/await implementation is production-ready and fully tested. Use it to build modern, clean asynchronous applications with Haxe and Phoenix LiveView!**