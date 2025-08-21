# Standard Library Compilation Context - Critical Learnings

## Executive Summary

**Critical Finding**: `untyped __elixir__()` DOES work in std/ files. The confusion arose from not understanding WHY `untyped` is required for `__elixir__()` to function at all.

## The Two-Phase Compilation Process

### Phase 1: Haxe Type Checking (Where `untyped` Matters)

When Haxe compiles code, it goes through a strict type-checking phase BEFORE Reflaxe.Elixir ever sees the code:

```haxe
// Without untyped - Haxe's type checker tries to validate this
__elixir__("DateTime.to_unix({0}, :millisecond)", dt);
// ERROR: Unknown identifier: __elixir__
// Haxe doesn't know what __elixir__ is!

// With untyped - Bypasses Haxe's type checking
untyped __elixir__("DateTime.to_unix({0}, :millisecond)", dt);
// SUCCESS: Haxe skips type checking, passes raw expression to Reflaxe
```

### Phase 2: Reflaxe Compilation (Where Code Injection Happens)

After Haxe's type checking, Reflaxe.Elixir receives the TypedExpr AST:

```
1. Reflaxe sees: TUntyped(TCall(__elixir__, [args]))
2. Recognizes the __elixir__ pattern
3. Injects the Elixir code directly into output
4. Result: DateTime.to_unix(dt, :millisecond)
```

## WHY `untyped` is Required

### The Core Reason: `__elixir__` is Not a Real Function

`__elixir__()` is not:
- A Haxe function that exists at runtime
- A standard library function
- An extern definition
- A macro function

It's a **compile-time marker** that only Reflaxe.Elixir understands.

### The Fundamental Problem: Unknown Identifier

When Haxe sees `__elixir__("code")` without `untyped`, here's what happens:

```haxe
// Code: 
var result = __elixir__("DateTime.now()");

// Haxe's type checker thinks:
// 1. "I see an identifier '__elixir__'"
// 2. "Let me look this up in the current scope..."
// 3. "Not found in local variables"
// 4. "Not found in class fields" 
// 5. "Not found in imported modules"
// 6. "Not found in standard library"
// 7. ERROR: "Unknown identifier: __elixir__"
```

**The compilation STOPS here.** Haxe never gets to the point where Reflaxe could process it.

### How `untyped` Solves This

```haxe
// Code:
var result = untyped __elixir__("DateTime.now()");

// Haxe's type checker thinks:
// 1. "I see the 'untyped' keyword"
// 2. "This tells me to SKIP all type checking for this expression"
// 3. "I'll wrap whatever comes after in a TUntyped AST node"
// 4. "I won't try to resolve '__elixir__' or validate anything"
// 5. "Just pass it through to the next compilation phase"
```

### Perfect Analogy: Magic Comments

Think of `__elixir__` like a **comment that gets processed**:

```haxe
// Normal comment - ignored by compiler
// This text is completely ignored

// Magic comment - processed by special tool
untyped __elixir__("This gets processed by Reflaxe")
```

The `untyped` is like telling Haxe: "Don't try to understand this expression, just pass it along to the next tool in the pipeline."

### What `untyped` Does

The `untyped` keyword tells Haxe's type checker: "Don't validate this expression, just pass it through as-is."

```haxe
// Haxe Type Checker's Perspective:

// Sees this:
someFunction(); 
// Thinks: "I need to check if someFunction exists and is callable"

// Sees this:
untyped someExpression;
// Thinks: "Skip type checking, wrap in TUntyped node, move on"
```

### The AST Transformation

```haxe
// Source code:
untyped __elixir__("DateTime.now()")

// Haxe AST after parsing:
TUntyped(
    TCall(
        TIdent("__elixir__"),
        [TConst(TString("DateTime.now()"))]
    )
)

// Reflaxe output:
DateTime.now()
```

## Why This Works in BOTH Regular Code AND std/

### Initial Misconception
I incorrectly assumed std/ files had special compilation restrictions that prevented `__elixir__()` from working.

### The Reality
`untyped __elixir__()` works identically in:
- Application code (`examples/todo-app/src_haxe/`)
- Standard library code (`std/`)
- Test code (`test/`)

The compilation context doesn't change the fundamental mechanism.

### Proof Through Testing

Created test files that proved `untyped __elixir__()` works in std/:

```haxe
// std/TestInjection.hx
package;

class TestInjection {
    public static function testIt(): Int {
        return untyped __elixir__("42");
    }
}

// Generated output:
defmodule TestInjection do
  def test_it() do
    42
  end
end
```

## Common Pitfalls and Solutions

### Pitfall 1: Forgetting `untyped`
```haxe
// ❌ WRONG - Haxe can't find __elixir__
var result = __elixir__("DateTime.now()");

// ✅ CORRECT - Bypasses type checking
var result = untyped __elixir__("DateTime.now()");
```

### Pitfall 2: Trying to Type the Result
```haxe
// ❌ WRONG - Can't type check untyped expressions
var dt: DateTime = untyped __elixir__("DateTime.now()");

// ✅ CORRECT - Cast after the fact
var dt = cast untyped __elixir__("DateTime.now()");
```

### Pitfall 3: Complex Expressions
```haxe
// ❌ WRONG - Only the __elixir__ call is untyped
var result = someFunction(untyped __elixir__("value"));

// ✅ CORRECT - Make the whole expression untyped if needed
var result = untyped someFunction(__elixir__("value"));
```

## Best Practices for Standard Library Development

### 1. Minimize `__elixir__()` Usage
Use it only when:
- Extern methods have resolution issues
- Direct Elixir syntax is required
- Performance-critical paths need optimization

### 2. Prefer Pure Haxe Implementations
```haxe
// ✅ BETTER - Pure Haxe, fully typed
abstract Date(Float) {
    public function new(year: Int, month: Int, day: Int) {
        this = calculateTimestamp(year, month, day);
    }
}

// ⚠️ AVOID - Relies on Elixir injection
class Date {
    public function new(year: Int, month: Int, day: Int) {
        this.dt = untyped __elixir__("NaiveDateTime.new!({0}, {1}, {2})", 
                                      year, month, day);
    }
}
```

### 3. Document When Injection is Used
Always explain WHY injection was necessary:
```haxe
/**
 * Uses __elixir__ injection because:
 * - Extern method resolution fails for this specific API
 * - Need to access Elixir-specific syntax (atoms, tuples)
 * - Performance requirement demands native call
 */
public function specialMethod() {
    return untyped __elixir__("special_elixir_syntax()");
}
```

## Alternatives to `__elixir__()` Injection

### 1. Fix Extern Definitions
Instead of working around broken externs, fix them:
```haxe
// Instead of:
untyped __elixir__("NaiveDateTime.new!({0}, {1}, {2})", y, m, d)

// Fix the extern:
@:native("NaiveDateTime")
extern class NaiveDateTime {
    @:native("new!")
    static function new_datetime(year: Int, month: Int, day: Int): NaiveDateTime;
}
```

### 2. Use Abstract Types
Abstracts compile away, avoiding field access issues:
```haxe
abstract Date(Float) {
    // No field access problems, no injection needed
}
```

### 3. Generate Helper Modules
Create Elixir helper modules that provide clean APIs:
```elixir
# DateHelper.ex
defmodule DateHelper do
  def from_components(year, month, day) do
    NaiveDateTime.new!(year, month, day, 0, 0, 0)
  end
end
```

## Key Takeaways

1. **`untyped` is required** because `__elixir__` is not a real Haxe function - it's a compile-time marker
2. **Works everywhere** - std/, application code, tests - the mechanism is the same
3. **Haxe's two-phase compilation** - Type checking happens before Reflaxe sees the code
4. **Best avoided** - Pure Haxe implementations are always preferable
5. **Not a runtime mechanism** - It's purely compile-time code injection

## The Real Issue: Extern Method Resolution

While `untyped __elixir__()` works, the real problem in Date.hx is that extern methods like `NaiveDateTime.new_datetime()` don't resolve properly. This is a separate Reflaxe.Elixir compiler issue that needs investigation, not a limitation of the standard library compilation context.

## References

- Test proving `untyped __elixir__()` works: `/test/tests/elixir_injection/`
- Date.hx implementation: `/std/Date.hx`
- Haxe AST documentation: https://api.haxe.org/haxe/macro/TypedExprDef.html