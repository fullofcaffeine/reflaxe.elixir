# Haxe Fundamentals for LLM Agents

**Purpose**: Essential Haxe knowledge for writing idiomatic code that compiles well to Elixir.

**Target**: LLM agents (Claude, GPT, etc.) working with Reflaxe.Elixir projects.

## Quick Reference Card

### Basic Syntax
```haxe
// Classes and functions
class MyClass {
    public static function main() {
        trace("Hello World");
    }
    
    public function new() {} // Constructor
    
    public var name:String; // Instance variable
    public static var count:Int = 0; // Static variable
    
    public function method(param:String):Int {
        return param.length;
    }
}

// Package declaration (always first line)
package com.example.myproject;

// Imports
import haxe.Json;
import sys.FileSystem;
```

### Essential Types
```haxe
// Primitives
var number:Int = 42;
var decimal:Float = 3.14;
var text:String = "Hello";
var flag:Bool = true;

// Collections
var items:Array<String> = ["a", "b", "c"];
var mapping:Map<String, Int> = new Map();

// Nullable types
var optional:Null<String> = null;
var required:String = optional ?? "default";

// Dynamic (avoid when possible)
var anything:Dynamic = {name: "test", value: 123};
```

### Control Flow
```haxe
// If statements
if (condition) {
    // do something
} else if (other) {
    // do other
} else {
    // default
}

// Switch expressions (preferred over if-else chains)
var result = switch(value) {
    case 1: "one";
    case 2: "two";
    case _: "other"; // Default case
};

// Loops
for (item in array) {
    trace(item);
}

for (i in 0...10) {
    trace(i); // 0 to 9
}

while (condition) {
    // loop body
}
```

## Core Concepts for Elixir Compilation

### 1. **Static vs Instance Methods**
```haxe
// ✅ Good: Static methods become Elixir module functions
class UserService {
    public static function create(params:Dynamic):User {
        return new User(params);
    }
}
// Compiles to: UserService.create(params)

// ⚠️ Careful: Instance methods need careful handling
class User {
    public function getName():String {
        return this.name;
    }
}
```

### 2. **Annotations Drive Compilation**
```haxe
// Essential annotations for Elixir
@:module        // Marks as Elixir module
@:liveview      // Phoenix LiveView component
@:schema        // Ecto schema
@:genserver     // GenServer behavior
@:changeset     // Ecto changeset function
```

### 3. **Type System Best Practices**
```haxe
// ✅ Good: Explicit types help compilation
function processUser(user:User):UserResult {
    return {ok: user.validate()};
}

// ❌ Avoid: Dynamic types when possible
function processAnything(data:Dynamic):Dynamic {
    return data; // Hard to optimize
}

// ✅ Good: Use abstracts for type safety
abstract UserId(Int) {
    public function new(id:Int) {
        this = id;
    }
}
```

### 4. **Error Handling Patterns**
```haxe
// Elixir-style error tuples
typedef Result<T> = {
    success:Bool,
    data:Null<T>,
    error:Null<String>
};

function safeOperation():Result<User> {
    try {
        var user = createUser();
        return {success: true, data: user, error: null};
    } catch(e:Dynamic) {
        return {success: false, data: null, error: Std.string(e)};
    }
}
```

## Common Haxe Patterns

### 1. **String Interpolation**
```haxe
var name = "World";
var message = 'Hello $name!'; // Single quotes for interpolation
var literal = "Hello $name"; // Double quotes are literal
```

### 2. **Array Comprehension**
```haxe
var numbers = [1, 2, 3, 4, 5];
var doubled = [for (n in numbers) n * 2];
var filtered = [for (n in numbers) if (n % 2 == 0) n];
```

### 3. **Anonymous Functions**
```haxe
var multiply = function(a:Int, b:Int):Int {
    return a * b;
};

// Arrow function syntax
var add = (a, b) -> a + b;

// Method references
var processor = processUser; // Reference to function
```

### 4. **Pattern Matching with Enums**
```haxe
enum Result<T> {
    Success(value:T);
    Error(message:String);
}

function handleResult<T>(result:Result<T>):Void {
    switch(result) {
        case Success(value):
            trace('Got value: $value');
        case Error(msg):
            trace('Error: $msg');
    }
}
```

### 5. **Interfaces and Implementation**
```haxe
interface Drawable {
    function draw():Void;
}

class Circle implements Drawable {
    public function new() {}
    public function draw():Void {
        trace("Drawing circle");
    }
}
```

## Compilation-Friendly Patterns

### 1. **Module Organization**
```haxe
// ✅ Good: One public class per file
// File: src/UserService.hx
package services;

@:module
class UserService {
    public static function list():Array<User> {
        return Repository.all(User);
    }
}
```

### 2. **Avoiding Problematic Constructs**
```haxe
// ❌ Avoid: Complex inheritance hierarchies
// ❌ Avoid: Excessive use of Dynamic
// ❌ Avoid: Reflection when possible
// ❌ Avoid: Untyped blocks unless necessary

// ✅ Prefer: Composition over inheritance
// ✅ Prefer: Static methods for business logic
// ✅ Prefer: Explicit types and interfaces
// ✅ Prefer: Simple, clear data structures
```

### 3. **Phoenix/Elixir Integration Patterns**
```haxe
// LiveView pattern
@:liveview
class ProductLive {
    public static function mount(params, session, socket) {
        return socket.assign({products: ProductService.list()});
    }
    
    public static function handle_event(event:String, params, socket) {
        return switch(event) {
            case "search": 
                var results = ProductService.search(params.query);
                socket.assign({products: results});
            case _: 
                socket;
        };
    }
}

// Ecto schema pattern
@:schema
class User {
    public var id:Int;
    public var email:String;
    public var name:String;
    
    @:changeset
    public static function changeset(user, attrs) {
        return user
            .cast(attrs, ["email", "name"])
            .validate_required(["email"]);
    }
}
```

## Error Prevention

### 1. **Common Syntax Errors**
```haxe
// ✅ Correct
function getName():String {
    return this.name;
}

// ❌ Wrong - missing return type
function getName() {
    return this.name;
}

// ❌ Wrong - incorrect access modifier syntax
private function getName():String {
    return this.name;
}
```

### 2. **Type Declaration Best Practices**
```haxe
// ✅ Good: Clear, explicit types
var users:Array<User> = [];
var userMap:Map<String, User> = new Map();
var result:Null<User> = findUser(id);

// ❌ Avoid: Implicit typing when unclear
var data = getData(); // What type is this?
```

### 3. **Import Organization**
```haxe
// ✅ Good import order
package com.example;

// Standard library imports first
import haxe.Json;
import sys.FileSystem;

// External library imports
import reflaxe.elixir.*;

// Local project imports
import models.User;
import services.UserService;
```

## Performance Considerations

### 1. **Efficient Data Structures**
```haxe
// ✅ Use appropriate collections
var lookup:Map<String, User> = new Map(); // For key-value pairs
var items:Array<User> = []; // For ordered lists
var unique:Set<String> = new Set(); // For unique values (when available)
```

### 2. **Minimal Dynamic Usage**
```haxe
// ✅ Prefer typed structures
typedef UserData = {
    name:String,
    email:String,
    age:Int
};

// ❌ Avoid when possible
var userData:Dynamic = {
    name: "John",
    email: "john@example.com",
    age: 30
};
```

## External Resources

### Official Haxe Documentation
- **Haxe Manual**: https://haxe.org/manual/
- **API Documentation**: https://api.haxe.org/
- **Language Reference**: https://haxe.org/manual/language-introduction.html

### Essential Reading for Elixir Compilation
- **Type System**: https://haxe.org/manual/types.html
- **Classes**: https://haxe.org/manual/types-class-instance.html
- **Enums**: https://haxe.org/manual/types-enum-instance.html
- **Abstracts**: https://haxe.org/manual/types-abstract.html

### Learning Resources
- **Try Haxe**: https://try.haxe.org/ (online Haxe playground)
- **Code Cookbook**: https://code.haxe.org/ (practical examples)

## Source Code References (Available Locally)

### Haxe Standard Library Source
When working with Reflaxe.Elixir, you have access to Haxe source code:

```bash
# Haxe standard library source (available in most setups)
/opt/homebrew/Cellar/haxe/*/share/haxe/std/
# Or check with: haxe -v (shows std path)

# Also available in reference directory
$HAXE_ELIXIR_REFERENCE_PATH/haxe/std/ (optional local checkout)
```

**Essential Standard Library Files to Reference**:
- `std/haxe/` - Core Haxe APIs (Json, Http, Timer, etc.)
- `std/sys/` - System APIs (FileSystem, io, etc.)  
- `std/StringTools.hx` - String manipulation utilities
- `std/Lambda.hx` - Functional programming utilities
- `std/Type.hx` - Runtime type utilities
- `std/Std.hx` - Standard conversion functions

### Reflaxe Base Classes Source
```bash
# Reflaxe base implementation (for understanding compiler architecture)
$HAXE_ELIXIR_REFERENCE_PATH/reflaxe/src/ (optional local checkout)
```

**Key Reflaxe Files**:
- `BaseCompiler.hx` - Core compiler interface
- `ClassVarData.hx` - Variable compilation data
- `ClassFuncData.hx` - Function compilation data  
- `EnumOptionData.hx` - Enum option data structures

### Reference Examples and Patterns
```bash
# Working example projects (great for pattern learning)
$HAXE_ELIXIR_REFERENCE_PATH/ (optional local checkout)

# Key directories:
# - Phoenix projects showing real-world usage
# - Reflaxe projects demonstrating DirectToStringCompiler patterns
# - Haxe macro projects for compile-time transformation examples
```

### When to Reference Source Code

1. **Understanding Standard Library APIs**:
   ```haxe
   // Need to understand how StringTools.trim() works?
   // Check: std/StringTools.hx source
   var result = StringTools.trim("  hello  ");
   ```

2. **Implementing Complex Type Mappings**:
   ```haxe
   // Understanding how Haxe handles Map<K,V>?
   // Check: std/haxe/ds/Map.hx source
   var map:Map<String, Int> = new Map();
   ```

3. **Learning Reflaxe Patterns**:
   ```haxe
   // Want to understand how BaseCompiler works?
   // Check: reference/reflaxe/src/BaseCompiler.hx
   ```

4. **Debugging Compilation Issues**:
   ```haxe
   // Strange behavior with abstract types?
   // Check how similar abstracts are implemented in std/
   ```

### Quick Source Lookup Commands

```bash
# Find standard library file
find /opt/homebrew/Cellar/haxe/*/share/haxe/std/ -name "StringTools.hx"

# Or in reference directory  
find "$HAXE_ELIXIR_REFERENCE_PATH" -name "*.hx" | grep StringTools

# Search for specific function in std lib
grep -r "function trim" /opt/homebrew/Cellar/haxe/*/share/haxe/std/

# Find Reflaxe base classes
ls "$HAXE_ELIXIR_REFERENCE_PATH/reflaxe/src/"
```

## Quick Debugging Tips

### 1. **Compilation Issues**
```bash
# Check Haxe version
haxe --version

# Verbose compilation
haxe -v build.hxml

# Check specific types
haxe --display MyClass.hx@0@diagnostic
```

### 2. **Common Error Messages**
- `Type not found: ClassName` → Check imports and classpath
- `Cannot access private field` → Use public fields or getters
- `Abstract type cannot be instantiated` → Use factory methods or @:from/@:to
- `Field ... has different type` → Check type compatibility

## Module System and Static Extensions

### Module Sub-Types
Multiple types can be defined in a single `.hx` file:

```haxe
// File: Result.hx
package haxe.functional;

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class ResultTools {
    public static function isOk<T, E>(result: Result<T, E>): Bool {
        return switch (result) {
            case Ok(_): true;
            case Error(_): false;
        }
    }
}
```

**Import patterns:**
```haxe
// Import main type
import haxe.functional.Result;

// Import sub-type explicitly  
import haxe.functional.Result.ResultTools;

// Import both with qualified name
import haxe.functional.Result;
// ResultTools available as Result.ResultTools
```

### Static Extensions: `using` vs `@:using`

#### Manual Extensions with `using`
Apply static extensions per-file where needed:

```haxe
import haxe.functional.Result;
import haxe.functional.Result.ResultTools;
using haxe.functional.Result.ResultTools;

class Example {
    static function main() {
        var result = Ok(42);
        var isValid = result.isOk(); // Extension method
    }
}
```

#### Automatic Extensions with `@:using`
Apply static extensions globally to a type:

```haxe
// In Result.hx
@:using(haxe.functional.Result.ResultTools)
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class ResultTools {
    public static function isOk<T, E>(result: Result<T, E>): Bool {
        return switch (result) {
            case Ok(_): true;
            case Error(_): false;
        }
    }
}
```

```haxe
// In any other file
import haxe.functional.Result;

class Example {
    static function main() {
        var result = Ok(42);
        var isValid = result.isOk(); // Automatically available!
    }
}
```

### When to Use Which Pattern

| Pattern | Use When | Benefits |
|---------|----------|----------|
| **Same file** | Related types (Result + ResultTools) | Cohesion, single import |
| **Separate files** | Large classes, different responsibilities | Modularity, clarity |
| **`using` keyword** | Explicit control over extensions | Clear scope, selective usage |
| **`@:using` metadata** | Extensions always needed with type | Convenience, global availability |

### Examples from Our Codebase

**Separate Files (Current)**:
```haxe
// std/haxe/functional/Result.hx - Just the enum
// std/haxe/functional/ResultTools.hx - Just the tools

// Usage:
import haxe.functional.Result;
import haxe.functional.ResultTools;
using haxe.functional.ResultTools;
```

**Same File Alternative**:
```haxe
// std/haxe/functional/Result.hx - Both enum and tools
@:using(haxe.functional.Result.ResultTools)
enum Result<T, E> { ... }
class ResultTools { ... }

// Usage:
import haxe.functional.Result;
// Extensions automatically available
```

Both patterns are valid! The choice depends on project organization preferences.

## Summary for LLM Agents

When writing Haxe code for Reflaxe.Elixir:

1. **Always use explicit types** - helps compilation and readability
2. **Prefer static methods** - compile better to Elixir modules
3. **Use appropriate annotations** - drive correct Elixir code generation
4. **Follow Elixir conventions** - snake_case for generated code
5. **Handle errors explicitly** - use proper error types
6. **Keep classes focused** - one responsibility per class
7. **Leverage pattern matching** - more idiomatic than if-else chains
8. **Choose module organization** - same file for related types, separate files for clarity
9. **Use static extensions wisely** - `using` for explicit control, `@:using` for convenience

This foundation ensures you can write effective Haxe code that compiles to clean, idiomatic Elixir.
