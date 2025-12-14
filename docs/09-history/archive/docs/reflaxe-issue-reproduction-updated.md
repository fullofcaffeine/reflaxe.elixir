# Replace the "Reproduction" section with:

## Reproduction

To reproduce the issue:

1. **Set up a custom Reflaxe target with proper injection configuration:**

```haxe
// In your CompilerInit.hx or equivalent initialization
package mycompiler;

class CompilerInit {
    public static function Start() {
        ReflectCompiler.AddCompiler(new MyCompiler(), {
            fileOutputExtension: ".ex",
            outputDirDefineName: "elixir-output",
            targetCodeInjectionName: "__elixir__",  // ← Properly configured!
            // ... other options
        });
    }
}
```

2. **Create a `@:coreApi` class that attempts to use `@:runtime inline` with the injection function:**

```haxe
// Array.hx in your standard library
@:coreApi
class Array<T> {
    // This will fail with "Unknown identifier: __elixir__"
    @:runtime public inline function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
    
    // This works fine (without @:runtime)
    public function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__('Enum.filter({0}, {1})', this, f);
    }
}
```

3. **Configure your build with the proper initialization:**

```hxml
# extraParams.hxml
-D elixir
--macro mycompiler.CompilerInit.Start()
-cp src
-cp std
```

4. **Try to compile any code using the Array class:**

```haxe
// Main.hx
class Main {
    static function main() {
        var arr = [1, 2, 3];
        var doubled = arr.map(x -> x * 2);  // Compilation fails here
    }
}
```

**Result**: Compilation fails with:
```
Array.hx:6: characters 15-25 : Unknown identifier : __elixir__
```

**Note**: The same code works perfectly if you remove `@:runtime inline` from the method declaration, proving that the injection function is properly configured and working - it just doesn't exist during the typing phase when `@:runtime` needs it.

### Verification with Native Targets

For comparison, the exact same pattern works with native Haxe targets:

```haxe
// This works in C++ target (std/cpp/)
@:coreApi
class Array<T> {
    @:runtime public inline function reverse(): Void {
        untyped __cpp__("std::reverse({0}, {1})", this.begin(), this.end());
    }
}

// This works in C# target (std/cs/)
@:coreApi 
class Array<T> {
    @:runtime public inline function sort(): Void {
        untyped __cs__("System.Array.Sort({0})", this);
    }
}
```

Both compile successfully because `__cpp__` and `__cs__` are built into Haxe.