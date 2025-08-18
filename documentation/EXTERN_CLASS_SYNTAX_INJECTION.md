# Extern Class Syntax Injection Implementation

**Date**: 2025-01-19  
**Purpose**: Document the proper implementation of syntax injection APIs using extern classes

## The Problem: Extern Classes vs Regular Classes

### Why Extern Classes Are Preferred
All established Haxe targets use `extern class` for syntax injection APIs:

1. **Haxe Core (`js.Syntax`)**: Uses `extern class` with built-in compiler support
2. **Reflaxe.CPP**: Uses `extern class` with `@:nativeFunctionCode` annotations  
3. **Reflaxe.Go**: Uses `extern class` with compiler detection
4. **Reflaxe.GDScript**: Uses `__gdscript__()` via TargetCodeInjection (no Syntax class)

### Why Regular Classes Are Wrong
- **Runtime pollution**: Regular classes generate actual runtime code  
- **Inconsistent with patterns**: Breaks established conventions
- **Error prone**: Can accidentally execute stub methods
- **Poor developer experience**: Throws runtime errors instead of compile-time handling

## The Technical Challenge

### Extern Class Detection Issues
Extern class static method calls don't generate the same AST as regular method calls:

```haxe
// Regular class: Generates TCall(TTypeExpr(...), args) 
MyClass.method(args);  // ✅ Detected by isElixirSyntaxCall()

// Extern class: May generate different AST patterns
extern class Syntax {
    static function code(...): Dynamic;  // ❌ Not detected consistently
}
```

### The AST Difference
- **Regular classes**: Create method call AST that our compiler can intercept
- **Extern classes**: May be resolved differently by Haxe's typer, bypassing our detection

## Implementation Strategies

### Strategy 1: Improve Detection Logic (Current Attempt)
Fix `isElixirSyntaxCall()` to properly handle extern class AST patterns:
```haxe
private function isElixirSyntaxCall(obj: TypedExpr, fieldName: String): Bool {
    // Enhanced detection for extern classes
    // Issue: Still doesn't work consistently
}
```

### Strategy 2: Use @:nativeFunctionCode (CPP Pattern)
Following Reflaxe.CPP's approach:
```haxe
@:noClosure
extern class Syntax {
    @:nativeFunctionCode("{arg0}")  // Direct code injection
    static function code(code: String, args: Rest<Dynamic>): Dynamic;
}
```

### Strategy 3: Compiler Hook Registration
Register `elixir.Syntax` as a special case in the compiler initialization.

### Strategy 4: Macro-Based Transform (Alternative)
Use build macros to transform `elixir.Syntax.code()` calls into `untyped __elixir__()`.

## Recommended Solution: @:nativeFunctionCode

Based on Reflaxe.CPP's proven approach, the most reliable pattern is:

```haxe
@:noClosure
extern class Syntax {
    /**
     * Inject Elixir code with placeholder interpolation.
     * Processed by ElixirCompiler.compileElixirSyntaxCall()
     */
    @:reflaxeElixir("code")
    static function code(code: String, args: Rest<Dynamic>): Dynamic;
    
    /**
     * Inject Elixir code without interpolation.  
     * Processed by ElixirCompiler.compileElixirSyntaxCall()
     */
    @:reflaxeElixir("plainCode")
    static function plainCode(code: String): Dynamic;
}
```

Then in ElixirCompiler, handle the custom annotation:
```haxe
// Check for @:reflaxeElixir annotation
if (fieldMetadata.has("reflaxeElixir")) {
    var method = fieldMetadata.extract("reflaxeElixir")[0].params[0];
    return compileElixirSyntaxCall(method, args);
}
```

## Key Learnings

1. **Follow established patterns**: Use `extern class` like other targets
2. **Annotations over detection**: Custom annotations are more reliable than AST pattern matching
3. **Reflaxe integration**: Work with Reflaxe's systems, not against them
4. **Runtime separation**: Keep compilation-time logic separate from runtime concerns

## Implementation Status

- ❌ **Current**: Regular class workaround (temporary fix)
- 🚧 **Next**: Implement proper extern class with annotations
- ✅ **Goal**: Clean extern class following established patterns

---

**Conclusion**: The temporary regular class solution works but violates best practices. The proper solution requires custom annotation handling in the compiler, following the proven patterns from other Reflaxe targets.