# 🔬 Deep Dive: Understanding Externs - What They Really Are and When to Use Them

## The Fundamental Truth About Externs

**An extern class is a CONTRACT, not an IMPLEMENTATION.**

When you write:
```haxe
extern class Foo {
    function bar(): String;
}
```

You're telling Haxe: "I promise that when this compiles to the target, there will be a `Foo` with a `bar()` method that returns a String. Trust me and generate calls to it."

## What Actually Gets Generated?

### Example 1: Basic Extern Usage

**Haxe Code:**
```haxe
// Declaration
@:native("File")
extern class File {
    static function read(path: String): String;
}

// Usage
class Main {
    static function main() {
        var content = File.read("test.txt");
        trace(content);
    }
}
```

**Generated Elixir:**
```elixir
defmodule Main do
  def main() do
    content = File.read("test.txt")  # Just the CALL, no implementation!
    IO.inspect(content)
  end
end
```

**What's Generated:**
- ✅ The CALL to `File.read()`
- ❌ NO implementation of File module
- ❌ NO read function definition

**Runtime Result:**
- If Elixir's File module exists with read/1: Works! ✅
- If not: Runtime error - undefined function File.read/1 ❌

## The Critical Distinction: Extern vs Regular Class

### Regular Class
```haxe
class StringUtils {
    public static function reverse(s: String): String {
        // Implementation here
        return s.split("").reverse().join("");
    }
}
```

**Generates:**
```elixir
defmodule StringUtils do
  def reverse(s) do
    # Full implementation generated
    s |> String.graphemes() |> Enum.reverse() |> Enum.join("")
  end
end
```

### Extern Class
```haxe
@:native("String")
extern class StringUtils {
    @:native("reverse")
    static function reverse(s: String): String;
}
```

**Generates:**
```elixir
# In usage:
reversed = String.reverse(text)  # Just the call!
# NO StringUtils module generated
# NO implementation generated
```

## Handling Different Method Signatures

### Problem: Haxe vs Target Signature Mismatch

Elixir's `Enum.reduce` has signature: `reduce(enumerable, acc, fun)`
Haxe's `Lambda.fold` has signature: `fold(iterable, func, initial)`

### Solution 1: Using @:native with Inline

```haxe
extern class Lambda {
    // This WON'T work - extern can't have bodies!
    @:native("Enum.reduce")
    static function fold<T,R>(it: Array<T>, f: (T,R) -> R, init: R): R {
        // COMPILER ERROR: Extern non-inline function may not have an expression
    }
}
```

### Solution 2: Extern Inline (Forces Inlining)

```haxe
extern class Lambda {
    // This WORKS - inline allows body in extern
    @:extern static inline function fold<T,R>(it: Array<T>, f: (T,R) -> R, init: R): R {
        // Rearrange parameters to match Elixir's order
        return untyped __elixir__("Enum.reduce({0}, {2}, {1})", it, f, init);
    }
}
```

**Usage:**
```haxe
var sum = Lambda.fold([1,2,3], (x, acc) -> acc + x, 0);
```

**Generates:**
```elixir
# The function body is INLINED at call site
sum = Enum.reduce([1, 2, 3], 0, fn x, acc -> acc + x end)
```

### Solution 3: Abstract Over Extern

```haxe
// The actual extern matching Elixir's signature
@:native("Enum")
extern class ElixirEnum {
    static function reduce<T,R>(enum: Array<T>, acc: R, fun: (T,R) -> R): R;
}

// Abstract providing Haxe-friendly interface
abstract Lambda(Dynamic) {
    public static inline function fold<T,R>(it: Array<T>, f: (T,R) -> R, init: R): R {
        // Rearrange to match Elixir
        return ElixirEnum.reduce(it, init, f);
    }
}
```

## Real-World Examples from Our Codebase

### Example 1: Phoenix Socket (Correct Extern Usage)

```haxe
// std/phoenix/Socket.hx
@:native("Phoenix.LiveView.Socket")
extern class LiveViewSocket {
    var assigns: Dynamic;
    var connected: Bool;
    // ... more fields
}
```

**Why this is CORRECT:**
- ✅ Phoenix.LiveView.Socket EXISTS in Elixir
- ✅ We're just declaring its interface
- ✅ No implementation needed - Phoenix provides it

### Example 2: Lambda (INCORRECT Extern Usage)

```haxe
// ❌ WRONG - Lambda doesn't exist in Elixir!
@:native("Lambda")
extern class Lambda {
    static function map<A,B>(it: Iterable<A>, f: A -> B): Array<B>;
}
```

**Why this is WRONG:**
- ❌ No Lambda module in Elixir
- ❌ Runtime error: undefined function Lambda.map/2
- ❌ We need to GENERATE implementation, not reference it

### Example 3: ArrayTools (Why NOT Extern)

```haxe
// std/ArrayTools.hx - Regular class, NOT extern
class ArrayTools {
    public static function reduce<T,U>(array: Array<T>, func: (U,T) -> U, initial: U): U {
        // We GENERATE the Enum.reduce call
        return untyped __elixir__("Enum.reduce({0}, {1}, fn item, acc -> {2}.(acc, item) end)", 
                                  array, initial, func);
    }
}
```

**Why NOT extern:**
- ArrayTools doesn't exist in Elixir
- We want to generate Enum calls with parameter reordering
- We need control over the generated code

## The Decision Tree: Should I Use Extern?

```
Does the module/class exist in the target platform?
├─ NO ────→ DON'T use extern! Use:
│            ├─ Regular class with __elixir__()
│            ├─ Compiler transformation
│            └─ Pure Haxe implementation
│
└─ YES ───→ Does the API match exactly?
             ├─ YES ──→ Use simple extern
             │
             └─ NO ───→ Do you need parameter reordering?
                        ├─ Simple ──→ Use extern inline
                        └─ Complex ─→ Use abstract over extern
```

## Common Extern Pitfalls and Solutions

### Pitfall 1: Expecting Implementation Generation

```haxe
// ❌ WRONG EXPECTATION
extern class MyUtils {
    static function process(x: Int): Int;  // Expects this to generate code
}

// Reality: NO implementation generated!
// Only generates: MyUtils.process(5) calls
```

### Pitfall 2: Misunderstanding @:native

```haxe
// @:native does NOT generate code!
@:native("CompletelyMadeUpModule")
extern class Fake {
    static function doesntExist(): Void;
}

// Generates: CompletelyMadeUpModule.doesntExist()
// Runtime: ERROR - undefined module
```

### Pitfall 3: Trying to Transform with Plain Extern

```haxe
// ❌ Can't transform parameters with plain extern
@:native("Enum.reduce")
extern class Lambda {
    // This maps fold → Enum.reduce but can't reorder parameters!
    static function fold<T,R>(it: Array<T>, f: (T,R) -> R, init: R): R;
}

// Generates: Enum.reduce(it, f, init) - WRONG ORDER!
```

## What About Different Platforms?

### JavaScript Externs
```haxe
// js.html.Window exists in browser
@:native("window")
extern class Window {
    static function alert(msg: String): Void;
}
// Generates: window.alert("Hello")
```

### Python Externs
```haxe
@:pythonImport("os")
extern class Os {
    static function getcwd(): String;
}
// Generates: import os; os.getcwd()
```

### Our Elixir Case
```haxe
@:native("GenServer")
extern class GenServer {
    static function start_link(module: Dynamic, args: Dynamic): Dynamic;
}
// Generates: GenServer.start_link(module, args)
```

## The Final Truth: When to Use Each Approach

### Use Extern When:
1. **Wrapping existing platform libraries**
   - Phoenix, Ecto, Erlang OTP
   - JavaScript DOM, Node.js modules
   - Python standard library

2. **The API matches reasonably well**
   - Same or similar parameter order
   - Compatible types

3. **You want zero overhead**
   - Direct calls to native functions
   - No wrapper overhead

### DON'T Use Extern When:
1. **The target library doesn't exist**
   - Lambda in Elixir (doesn't exist)
   - Custom utility classes

2. **You need to generate implementation**
   - Standard library adaptations
   - Cross-platform compatibility layers

3. **Complex transformations needed**
   - Parameter reordering
   - Type conversions
   - Pattern transformations

## Real Example: Why Lambda Can't Be Extern

### The Lambda Case Study

Lambda is a perfect example of when NOT to use extern. Here's why:

**The Problem:**
- Haxe has a Lambda class with methods like map, filter, fold
- Elixir has NO Lambda module - it uses Enum instead
- The signatures are different (Lambda.fold vs Enum.reduce parameter order)

**Why Extern Fails Here:**

```haxe
// ❌ ATTEMPT 1: Direct extern mapping
@:native("Lambda")  
extern class Lambda {
    static function map<A,B>(it: Iterable<A>, f: A -> B): Array<B>;
}
// FAILS: Lambda module doesn't exist in Elixir!
// Runtime error: undefined function Lambda.map/2

// ❌ ATTEMPT 2: Map to Enum with @:native
@:native("Enum")
extern class Lambda {
    @:native("map")
    static function map<A,B>(it: Iterable<A>, f: A -> B): Array<B>;
    
    @:native("reduce")  
    static function fold<A,B>(it: Iterable<A>, f: (A,B) -> B, init: B): B;
}
// PROBLEM: This generates Enum.reduce(it, f, init) - WRONG PARAMETER ORDER!
// Elixir expects: Enum.reduce(it, init, f)

// ❌ ATTEMPT 3: Extern with body (illegal)
@:native("Enum")
extern class Lambda {
    @:native("reduce")
    static function fold<A,B>(it: Iterable<A>, f: (A,B) -> B, init: B): B {
        // Try to reorder parameters
        return untyped __elixir__("Enum.reduce({0}, {2}, {1})", it, f, init);
    }
}
// FAILS: Extern non-inline function may not have an expression
```

**The Correct Solutions:**

```haxe
// ✅ SOLUTION 1: Compiler Transformation (BEST for Lambda)
// In ElixirASTBuilder.hx:
case TCall(e, el) if (isLambdaCall(e)):
    var method = getLambdaMethod(e);
    return switch(method) {
        case "map": 
            ERemoteCall(makeAST(EVar("Enum")), "map", compileArgs(el));
        case "fold":
            // Reorder parameters during compilation
            var args = compileArgs(el);
            ERemoteCall(makeAST(EVar("Enum")), "reduce", [args[0], args[2], args[1]]);
    }
// Generates perfect idiomatic Elixir with correct parameter order

// ✅ SOLUTION 2: Regular class with __elixir__()
class Lambda {
    public static inline function map<A,B>(it: Iterable<A>, f: A -> B): Array<B> {
        return untyped __elixir__("Enum.map({0}, {1})", it, f);
    }
    
    public static inline function fold<A,B>(it: Iterable<A>, f: (A,B) -> B, init: B): B {
        // Handle parameter reordering here
        return untyped __elixir__("Enum.reduce({0}, {2}, {1})", it, f, init);
    }
}
// Works but creates unnecessary Lambda module in output

// ✅ SOLUTION 3: Extern inline (if you must use extern)
extern class Lambda {
    @:extern static inline function fold<A,B>(it: Iterable<A>, f: (A,B) -> B, init: B): B {
        return untyped __elixir__("Enum.reduce({0}, {2}, {1})", it, f, init);
    }
}
// Works but must be simple enough to inline
```

## Example: Providing Elixir's Enum to Haxe (Correct Extern Usage)

### The Enum Case - When Extern IS Appropriate

Unlike Lambda (which doesn't exist in Elixir), Enum DOES exist. Here's how to properly expose it to Haxe users:

```haxe
// std/elixir/Enum.hx
@:native("Enum")
extern class Enum {
    // Direct mapping when signatures match
    @:native("map")
    static function map<T,R>(enumerable: Array<T>, fun: T -> R): Array<R>;
    
    @:native("filter")
    static function filter<T>(enumerable: Array<T>, fun: T -> Bool): Array<T>;
    
    // But what about functions with Elixir-specific features?
    @:native("reduce")
    static function reduce<T,R>(enumerable: Array<T>, acc: R, fun: (T, R) -> R): R;
    
    // Elixir functions that return atoms - how to handle?
    @:native("any?")
    static function any<T>(enumerable: Array<T>, fun: T -> Bool): Bool;
    
    // Functions with multiple return types
    @:native("find")
    static function find<T>(enumerable: Array<T>, fun: T -> Bool): Null<T>;
}
```

### Handling Elixir-Specific Naming

**Problem**: Elixir uses `?` and `!` in function names, which aren't valid in Haxe.

```haxe
// ❌ This won't compile in Haxe
static function any?(enumerable: Array<T>, fun: T -> Bool): Bool;

// ✅ Solution 1: Use @:native to map names
@:native("any?")
static function any<T>(enumerable: Array<T>, fun: T -> Bool): Bool;

// ✅ Solution 2: Follow naming conventions
@:native("empty?")
static function isEmpty<T>(enumerable: Array<T>): Bool;

@:native("member?")
static function hasMember<T>(enumerable: Array<T>, element: T): Bool;
```

**Generated Elixir:**
```elixir
# Haxe: Enum.any(list, fn)
# Generates: Enum.any?(list, fn)

# Haxe: Enum.isEmpty(list)
# Generates: Enum.empty?(list)
```

### Handling Parameter Differences

**Problem**: Some Enum functions have optional parameters or variable signatures.

```haxe
// Elixir's Enum.take has optional second parameter
// Enum.take(enumerable, count \\ 1)

// Solution 1: Use @:overload for different arities
extern class Enum {
    @:overload(function<T>(enumerable: Array<T>): T {})
    @:native("take")
    static function take<T>(enumerable: Array<T>, count: Int): Array<T>;
}

// Solution 2: Use optional parameters
extern class Enum {
    @:native("take")
    static function take<T>(enumerable: Array<T>, ?count: Int = 1): Array<T>;
}
```

### Handling Elixir-Specific Types

**Problem**: Elixir functions might return tuples or atoms.

```haxe
// Elixir's Enum.fetch returns {:ok, element} or :error
// How to represent in Haxe?

// Solution 1: Use abstracts for tagged tuples
abstract FetchResult<T>(Dynamic) {
    public function isOk(): Bool;
    public function getValue(): T;
    public function isError(): Bool;
}

extern class Enum {
    @:native("fetch")
    static function fetch<T>(enumerable: Array<T>, index: Int): FetchResult<T>;
}

// Solution 2: Use enums (requires compiler support)
enum ElixirResult<T> {
    Ok(value: T);
    Error;
}

// Solution 3: Just use Dynamic (less type-safe)
extern class Enum {
    @:native("fetch")
    static function fetch<T>(enumerable: Array<T>, index: Int): Dynamic;
}
```

### Advanced: Handling Functions as Parameters

Elixir often uses capture syntax (&Module.function/arity). How to handle?

```haxe
// Elixir: Enum.map(list, &String.upcase/1)
// Haxe needs function references

extern class Enum {
    // Allow both lambda and function references
    @:native("map")
    static function map<T,R>(enumerable: Array<T>, fun: T -> R): Array<R>;
    
    // For capture syntax, provide helper
    @:native("map")
    @:overload(function<T,R>(enumerable: Array<T>, capture: String): Array<R> {})
    static function mapWithCapture<T,R>(enumerable: Array<T>, fun: T -> R): Array<R>;
}

// Usage:
Enum.map(list, s -> s.toUpperCase());  // Lambda
Enum.mapWithCapture(list, "&String.upcase/1");  // Capture syntax
```

### Complete Example: Well-Designed Enum Extern

```haxe
// std/elixir/Enum.hx
package elixir;

/**
 * Type-safe wrapper for Elixir's Enum module
 * All functions map directly to Elixir's Enum functions
 */
@:native("Enum")
extern class Enum {
    // Basic operations with direct mapping
    @:native("map")
    static function map<T,R>(enumerable: Array<T>, fun: T -> R): Array<R>;
    
    @:native("filter")
    static function filter<T>(enumerable: Array<T>, fun: T -> Bool): Array<T>;
    
    @:native("reduce")
    static function reduce<T,R>(enumerable: Array<T>, acc: R, fun: (T, R) -> R): R;
    
    // Handle ? in names
    @:native("any?")
    static function any<T>(enumerable: Array<T>, ?fun: T -> Bool): Bool;
    
    @:native("all?")
    static function all<T>(enumerable: Array<T>, ?fun: T -> Bool): Bool;
    
    @:native("empty?")
    static function isEmpty<T>(enumerable: Array<T>): Bool;
    
    @:native("member?")
    static function member<T>(enumerable: Array<T>, element: T): Bool;
    
    // Functions with multiple signatures
    @:overload(function<T>(enumerable: Array<T>): T {})
    @:native("take")
    static function take<T>(enumerable: Array<T>, count: Int): Array<T>;
    
    // Complex returns (using Dynamic for simplicity)
    @:native("fetch")
    static function fetch<T>(enumerable: Array<T>, index: Int): Dynamic;
    
    @:native("fetch!")
    static function fetchOrThrow<T>(enumerable: Array<T>, index: Int): T;
    
    // With index operations
    @:native("with_index")
    static function withIndex<T>(enumerable: Array<T>, ?offset: Int = 0): Array<{value: T, index: Int}>;
}
```

**Usage in Haxe:**
```haxe
import elixir.Enum;

class Main {
    static function main() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Direct Enum usage - generates clean Elixir calls
        var doubled = Enum.map(numbers, n -> n * 2);
        var evens = Enum.filter(numbers, n -> n % 2 == 0);
        var sum = Enum.reduce(numbers, 0, (n, acc) -> acc + n);
        var hasEven = Enum.any(numbers, n -> n % 2 == 0);
    }
}
```

**Generated Elixir:**
```elixir
defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    
    # Perfect, idiomatic Elixir!
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    sum = Enum.reduce(numbers, 0, fn n, acc -> acc + n end)
    has_even = Enum.any?(numbers, fn n -> rem(n, 2) == 0 end)
  end
end
```

### Key Takeaway: Extern for Enum vs Lambda

| Aspect | Enum (Good for Extern) | Lambda (Bad for Extern) |
|--------|------------------------|-------------------------|
| Exists in target? | ✅ Yes - Enum module exists | ❌ No - Lambda doesn't exist |
| Direct mapping? | ✅ Most functions map directly | ❌ Would need transformation |
| Parameter order? | ✅ Can use as-is | ❌ Different order (fold/reduce) |
| Result | Clean extern class | Need compiler transformation |

## Summary: The Extern Mental Model

Think of extern as a **TRUST DECLARATION**:
- "Trust me, this exists in the target"
- "Trust me, it has this interface"
- "Go ahead and generate calls to it"

The compiler trusts you and generates calls.
If you lied (the module doesn't exist), you get runtime errors.

**Extern = Reference to existing code**
**NOT Extern = Generate new code**

This is why Lambda, ArrayTools, StringTools should NOT be externs - they don't exist in Elixir. We need to GENERATE the implementation (even if that implementation is just calling Enum functions).