# Haxe Macro API Usage Guide

## Critical Distinction: Macro Functions vs Macro Context Functions

### The Problem

A common confusion when developing Reflaxe compilers is the difference between `haxe.macro.Compiler` and `haxe.macro.Context` APIs. Using the wrong API causes "macro-in-macro" compilation errors.

### Key Principle

**Reflaxe compilers run entirely in macro context.** All code in ElixirCompiler executes during compilation, not at runtime.

## The APIs Explained

### haxe.macro.Compiler APIs

These are **macro functions** designed to be called from regular Haxe code to generate compile-time expressions.

```haxe
// This is a MACRO FUNCTION - note the 'macro' keyword
macro static public function getDefine(key:String) {
    return macro $v{haxe.macro.Context.definedValue(key)};
}
```

**Usage**: From regular Haxe code when you want compile-time values:
```haxe
class MyClass {
    static var appName = haxe.macro.Compiler.getDefine("app_name"); // ✅ Correct context
}
```

### haxe.macro.Context APIs

These are **regular functions** designed to be called from within macro context.

```haxe
public static function definedValue(key:String):String {
    return load("defined_value", 1)(key);
}
```

**Usage**: From macro context (like Reflaxe compilers):
```haxe
#if (macro || reflaxe_runtime)
class ElixirCompiler {
    private function getCurrentAppName(): String {
        var appName = haxe.macro.Context.definedValue("app_name"); // ✅ Correct context
        return appName;
    }
}
#end
```

## Common Errors and Solutions

### ❌ Wrong: "macro-in-macro" Error

```haxe
#if (macro || reflaxe_runtime)
class ElixirCompiler {
    private function getCurrentAppName(): String {
        // ERROR: Calling macro function from macro context
        var appName = haxe.macro.Compiler.getDefine("app_name");
        return appName;
    }
}
#end
```

**Error Message**: `Uncaught exception macro-in-macro`

### ✅ Correct: Use Context APIs in Macro Context

```haxe
#if (macro || reflaxe_runtime)
class ElixirCompiler {
    private function getCurrentAppName(): String {
        // Correct: Using Context API in macro context
        var appName = haxe.macro.Context.definedValue("app_name");
        return appName;
    }
}
#end
```

## Quick Reference

| Context | For Defines | For Types | For Metadata |
|---------|-------------|-----------|---------------|
| **Regular Code** | `Compiler.getDefine()` | `Compiler.getType()` | N/A |
| **Macro Context** | `Context.definedValue()` | `Context.getType()` | `Context.getLocalClass()` |

## When to Use Which

### Use haxe.macro.Compiler when:
- Writing regular Haxe application code
- You want compile-time constants in your classes
- Building macros that generate expressions for regular code

### Use haxe.macro.Context when:
- Writing macros, build macros, or initialization macros
- Developing Reflaxe compilers (like ElixirCompiler)
- Any code marked with `#if (macro || reflaxe_runtime)`
- Inside `--macro` functions

## Real Example: App Name Configuration

### The Problem
We needed to configure the Phoenix application name for PubSub calls. Using the wrong API caused compilation failures.

### The Solution
```haxe
private function getCurrentAppName(): String {
    // ✅ CORRECT: Use Context.definedValue() in macro context
    #if app_name
    var defineValue = haxe.macro.Context.definedValue("app_name");
    if (defineValue != null && defineValue.length > 0) {
        return defineValue;
    }
    #end
    
    // Fallback to other methods...
    return "App";
}
```

### Build Configuration
```hxml
# In build.hxml - single source of truth for app name
-D app_name=TodoApp
```

### Result
All PubSub calls now correctly use `TodoApp.PubSub` instead of hardcoded `App.PubSub`.

## Best Practices

1. **Single Source of Truth**: Use compiler defines (`-D`) for configuration values
2. **Priority System**: Define > Annotation > Inference > Fallback
3. **Clear Documentation**: Always comment why you're using Context vs Compiler APIs
4. **Test Both Contexts**: Verify your code works in the intended macro context

## Further Reading

- [Haxe Manual - Conditional Compilation](https://haxe.org/manual/lf-condition-compilation.html)
- [Haxe Manual - Macros](https://haxe.org/manual/macro.html)
- [Haxe API Documentation](https://api.haxe.org/)