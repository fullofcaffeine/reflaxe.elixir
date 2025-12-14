# 🔍 Complete Guide: @:native and Related Metadata in All Scenarios

## Tested and Verified: What Actually Works

Based on actual testing with Reflaxe.Elixir, here's what REALLY happens with `@:native` and related metadata:

### ✅ @:native WORKS on Regular (Non-Extern) Classes

**DISCOVERY**: `@:native` DOES work on regular classes and changes the generated module/function names!

```haxe
// INPUT: Regular class with @:native
@:native("ElixirModuleName")
class RegularClassWithNative {
    public static function test(): String {
        return "Testing @:native on regular class";
    }
}

// GENERATED ELIXIR:
defmodule ElixirModuleName do  # <-- Used the @:native name!
  def test() do
    "Testing @:native on regular class"
  end
end
```

### ✅ @:native WORKS on Methods in Regular Classes

```haxe
// INPUT: Method with @:native
class RegularClassMethodNative {
    @:native("elixir_method_name")
    public static function haxeMethodName(): String {
        return "Testing @:native on regular method";
    }
}

// GENERATED ELIXIR:
defmodule RegularClassMethodNative do
  def elixir_method_name() do  # <-- Used the @:native name!
    "Testing @:native on regular method"
  end
end
```

### ⚠️ @:native on Regular Class Creates Real Module (PROBLEM!)

```haxe
// INPUT: Trying to hijack Enum module name
@:native("Enum")
class LambdaAsRegular {
    @:native("map")
    public static function map<A,B>(it: Array<A>, f: A -> B): Array<B> {
        return untyped __elixir__("Enum.map({0}, {1})", it, f);
    }
}

// GENERATED ELIXIR:
defmodule Enum do  # <-- Creates a NEW Enum module!
  def map(it, f) do
    __elixir__.call("Enum.map({0}, {1})", it, f)  # Broken!
  end
end
```

**CRITICAL ISSUE**: This SHADOWS Elixir's built-in Enum module! Your code would break because it replaces the real Enum.

### ✅ Abstract with @:native and inline

```haxe
// INPUT: Abstract with inline methods
@:native("Enum")
abstract LambdaAbstract(Dynamic) {
    @:native("reduce")
    public static inline function fold<A,B>(it: Array<A>, f: (A,B) -> B, init: B): B {
        return untyped __elixir__("Enum.reduce({0}, {2}, {1})", it, f, init);
    }
}

// USAGE:
LambdaAbstract.fold([1,2,3], (x, acc) -> acc + x, 0);

// GENERATED ELIXIR:
__elixir__.call("Enum.reduce({0}, {2}, {1})", [1, 2, 3], fn x, acc -> acc + x end, 0)
```

**NOTE**: The abstract's inline function was inlined, but it didn't generate clean Enum.reduce - it kept the __elixir__ wrapper.

## All Metadata Combinations and Their Effects

### 1. extern class with @:native

```haxe
@:native("Phoenix.LiveView.Socket")
extern class Socket {
    var assigns: Dynamic;
}

// EFFECT: References Phoenix.LiveView.Socket, no implementation generated
// USAGE: Socket.assigns → Phoenix.LiveView.Socket.assigns
```

### 2. Regular class with @:native

```haxe
@:native("MyElixirModule")
class MyHaxeClass {
    public static function test(): Void {}
}

// EFFECT: Generates module with name MyElixirModule
// GENERATED: defmodule MyElixirModule do ... end
```

### 3. Method @:native in regular class

```haxe
class MyClass {
    @:native("my_elixir_function")
    public static function myHaxeFunction(): Void {}
}

// EFFECT: Method compiles to my_elixir_function
// GENERATED: def my_elixir_function() do ... end
```

### 4. Method @:native in extern class

```haxe
extern class ElixirModule {
    @:native("function_with_question?")
    static function hasQuestion(): Bool;
}

// EFFECT: Calls ElixirModule.function_with_question?()
// NO IMPLEMENTATION GENERATED
```

### 5. Enum with @:native

```haxe
@:native("ElixirAtomName")
enum MyEnum {
    OptionOne;
    OptionTwo;
}

// GENERATED: 
defmodule ElixirAtomName do
  def option_one(), do: {:option_one}
  def option_two(), do: {:option_two}
end
```

### 6. Interface with @:native

```haxe
@:native("ElixirProtocol")
interface MyInterface {
    function implementMe(): String;
}

// GENERATED: Empty module (interfaces need special handling)
defmodule ElixirProtocol do
end
```

### 7. @:extern metadata (NOT extern keyword)

```haxe
class MyClass {
    @:extern static function dontGenerate(): Void {}
}

// EFFECT: Method is NOT generated in output
// This is different from extern class!
```

### 8. @:nativeGen

```haxe
@:nativeGen
class NativeGenClass {
    public function new() {}
}

// EFFECT: Class is generated with native platform optimizations
// For Elixir: Regular module generation (no special effect observed)
```

## Decision Matrix: Which Approach for Lambda/ArrayTools?

| Approach | What Happens | Problems | Verdict |
|----------|-------------|----------|---------|
| **Regular class with @:native("Enum")** | Creates new Enum module | Shadows Elixir's Enum! | ❌ BAD |
| **extern class with @:native("Enum")** | References Enum, no implementation | Can't reorder parameters | ❌ Limited |
| **extern inline with @:native** | Inline at call site | Must be simple to inline | ⚠️ OK |
| **Abstract with inline** | Methods inlined | Still uses __elixir__ | ⚠️ OK |
| **Compiler transformation** | Direct AST manipulation | Perfect control | ✅ BEST |
| **Regular class with __elixir__** | Generates Lambda module | Extra module in output | ✅ Good |

## The Final Answer: Best Practices

### For Lambda (Haxe stdlib that maps to Elixir's Enum)

**DON'T USE**:
- ❌ Regular class with @:native("Enum") - shadows real Enum
- ❌ extern class - Lambda doesn't exist in Elixir

**DO USE**:
- ✅ **Compiler transformation** (best) - detect Lambda calls and transform to Enum
- ✅ **Regular class with __elixir__** (good) - generates Lambda module with Enum calls
- ⚠️ **extern inline** (ok) - if functions are simple enough

### For Enum (Exposing Elixir's Enum to Haxe)

**DO USE**:
- ✅ **extern class with @:native** - perfect for wrapping existing modules

```haxe
@:native("Enum")
extern class Enum {
    @:native("map")
    static function map<T,R>(items: Array<T>, fn: T -> R): Array<R>;
    
    @:native("any?")
    static function any<T>(items: Array<T>, fn: T -> Bool): Bool;
}
```

### For ArrayTools (Haxe utilities using Elixir functions)

**DO USE**:
- ✅ **Regular class with __elixir__** - full control over generated code

```haxe
class ArrayTools {  // No @:native - we want ArrayTools module
    public static inline function forEach<T>(arr: Array<T>, fn: T -> Void): Void {
        return untyped __elixir__("Enum.each({0}, {1})", arr, fn);
    }
}
```

## Key Insights

1. **@:native works on regular classes** - Changes the generated module/method names
2. **Don't shadow existing modules** - Using @:native("Enum") on a regular class is dangerous
3. **extern = reference, not generation** - extern classes don't generate implementations
4. **inline is key for transformations** - Allows code injection at call sites
5. **Compiler transformations are most powerful** - Direct AST manipulation gives perfect control

## Summary Table: When to Use What

| Goal | Best Approach | Example |
|------|--------------|---------|
| Wrap existing Elixir module | extern class with @:native | Phoenix, Ecto, Enum |
| Transform Haxe stdlib to Elixir | Compiler transformation | Lambda → Enum |
| Provide utilities using Elixir | Regular class with __elixir__ | ArrayTools, StringTools |
| Simple name mapping | @:native on methods | Haxe name → Elixir name |
| Prevent generation | @:extern on method | Skip certain methods |
| Force inlining | extern inline or @:extern inline | Simple transformations |

This guide is based on actual testing and compilation results, not just documentation!