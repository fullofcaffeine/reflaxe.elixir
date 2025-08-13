# Primitive Type Method Compilation

## Overview

This document explains how Reflaxe.Elixir handles method calls on primitive types (String, Int, Float, Bool) when transpiling from Haxe to Elixir.

## The Challenge

Haxe treats primitive types as objects with methods:
```haxe
// Haxe code
var s = "hello";
var c = s.charAt(0);       // String method
var code = s.charCodeAt(1); // String method
var len = s.length;         // String property
```

Elixir treats primitives as values with module functions:
```elixir
# Elixir code
s = "hello"
c = String.at(s, 0)        # Module function
code = :binary.first(String.at(s, 1))  # Module + Erlang function
len = String.length(s)      # Module function
```

## Implementation

### Compiler Detection and Transformation

In `ElixirCompiler.hx`, the `compileMethodCall` function detects primitive type methods:

```haxe
private function compileMethodCall(e: TypedExpr, args: Array<TypedExpr>): String {
    switch (e.expr) {
        case TField(obj, fa):
            var methodName = getFieldName(fa);
            var objStr = compileExpression(obj);
            
            // Check if this is a String method call
            switch (obj.t) {
                case TInst(t, _) if (t.get().name == "String"):
                    return compileStringMethod(objStr, methodName, args);
                case _:
                    // Handle other types...
            }
    }
}
```

### String Method Mappings

The `compileStringMethod` function maps Haxe String methods to Elixir equivalents:

```haxe
private function compileStringMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
    var compiledArgs = args.map(arg -> compileExpression(arg));
    
    return switch (methodName) {
        case "charAt":
            'String.at(${objStr}, ${compiledArgs[0]})';
            
        case "charCodeAt":
            'case String.at(${objStr}, ${compiledArgs[0]}) do ' +
            'nil -> nil; c -> :binary.first(c) end';
            
        case "toLowerCase":
            'String.downcase(${objStr})';
            
        case "toUpperCase":
            'String.upcase(${objStr})';
            
        case "substr" | "substring":
            if (compiledArgs.length >= 2) {
                'String.slice(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
            } else if (compiledArgs.length == 1) {
                'String.slice(${objStr}, ${compiledArgs[0]}..-1)';
            } else {
                objStr;
            }
            
        case "indexOf":
            'case :binary.match(${objStr}, ${compiledArgs[0]}) do ' +
            '{pos, _} -> pos; :nomatch -> -1 end';
            
        case "split":
            'String.split(${objStr}, ${compiledArgs[0]})';
            
        case "length":
            'String.length(${objStr})';
            
        case _:
            // Fallback to regular method call
            '${objStr}.${methodName}(${compiledArgs.join(", ")})';
    }
}
```

## Special Cases

### 1. Character Code Access
Haxe's `charCodeAt` returns a character code, while Elixir needs to:
1. Get the character with `String.at/2`
2. Convert to binary with `:binary.first/1`

### 2. Index Methods
Methods like `indexOf` need special handling for -1 return value (not found):
```elixir
# Elixir pattern matching for indexOf
case :binary.match(string, substring) do
  {pos, _} -> pos      # Found: return position
  :nomatch -> -1       # Not found: return -1 (Haxe convention)
end
```

### 3. Property Access
Properties like `length` are converted to function calls:
- Haxe: `s.length`
- Elixir: `String.length(s)`

## Other Primitive Types

### Integer Methods (Future)
```haxe
// Haxe
var n = 42;
var hex = n.hex();  // Would need mapping

// Elixir
n = 42
hex = Integer.to_string(n, 16)
```

### Float Methods (Future)
```haxe
// Haxe
var f = 3.14;
var rounded = f.round();  // Would need mapping

// Elixir
f = 3.14
rounded = Float.round(f)
```

## Benefits of This Approach

1. **Transparent**: Developers write natural Haxe code
2. **Efficient**: Direct module function calls in Elixir
3. **Maintainable**: Centralized mapping in compiler
4. **Extensible**: Easy to add new method mappings

## Testing Considerations

When testing primitive type methods:

1. **Test the mapping**: Ensure Haxe method → Elixir function
2. **Test edge cases**: null/nil, empty strings, out of bounds
3. **Test return values**: Ensure compatibility (-1 for not found, etc.)

## Future Improvements

1. **Automatic detection** of new String methods in Haxe updates
2. **Configuration file** for custom method mappings
3. **Macro generation** of mapping code from specification
4. **Performance optimization** for common patterns

## Related Documentation

- [STANDARD_LIBRARY_HANDLING.md](./STANDARD_LIBRARY_HANDLING.md) - Overall stdlib approach
- [STRINGTOOLS_STRATEGY.md](./STRINGTOOLS_STRATEGY.md) - StringTools specific implementation
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Compiler architecture overview