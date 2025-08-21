# Static Extension Patterns in Reflaxe.Elixir

## Overview

Static extensions in Haxe (using `using ModuleTools`) require special handling in the Reflaxe.Elixir compiler to generate idiomatic target code. This document captures the proven patterns for implementing static extension support.

## ✅ IMPLEMENTATION STATUS: COMPLETE
**ArrayTools static extension implementation completed successfully with all 8 new functional methods working correctly. This pattern has been proven and is ready for use in future extensions.**

## The Challenge

When using `using ArrayTools`, Haxe transforms method calls at compile-time:

```haxe
// Developer writes:
using ArrayTools;
var sum = numbers.reduce((acc, item) -> acc + item, 0);

// Haxe compiler transforms to:
var sum = ArrayTools.reduce(numbers, (acc, item) -> acc + item, 0);
```

Without proper handling, this generates incorrect Elixir code:
```elixir
# WRONG: Calls non-existent ArrayTools module
sum = ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)

# CORRECT: Uses idiomatic Enum module
sum = Enum.reduce(numbers, 0, fn item, acc -> acc + item end)
```

## The Solution Pattern

### 1. **Static Extension Detection Architecture**

The solution follows the established pattern used for OptionTools and ResultTools:

```haxe
// In compileExpression() TCall handler, around line 2204
if (objStr == "ArrayTools" && isArrayMethod(methodName)) {
    // ArrayTools static extensions need to be compiled to idiomatic Elixir Enum calls
    // The first argument is the array, remaining arguments are method parameters
    if (args.length > 0) {
        var arrayExpr = compileExpression(args[0]);  // First arg is the array
        var methodArgs = args.slice(1);             // Remaining args are method parameters
        return compileArrayMethod(arrayExpr, methodName, methodArgs);
    } else {
        // Fallback for methods with no arguments
        return 'ArrayTools.${methodName}()';
    }
}
```

### 2. **Method Detection Function**

Create a method detection function following the naming convention:

```haxe
/**
 * Check if a method name is an ArrayTools static extension method
 */
private function isArrayMethod(methodName: String): Bool {
    return switch (methodName) {
        case "reduce", "fold", "find", "findIndex", "exists", "any", 
             "foreach", "all", "forEach", "take", "drop", "flatMap":
            true;
        case _:
            false;
    };
}
```

### 3. **Specialized Compiler Routing**

Forward detected static extensions to specialized compilation logic:
- **ArrayTools** → `compileArrayMethod()` → Generates `Enum.*` calls
- **StringTools** → `compileStringMethod()` → Generates idiomatic string operations
- **MapTools** → `compileMapMethod()` → Generates `Map.*` or custom logic

## Implementation Steps for New Static Extensions

### Step 1: Create the Static Extension Class

```haxe
// std/NewTools.hx
class NewTools {
    public static function methodName<T>(target: TargetType<T>, ...args): ReturnType {
        // Cross-platform fallback implementation
        // This will be used for non-Elixir targets
    }
}
```

### Step 2: Add Method Detection Function

```haxe
// In ElixirCompiler.hx
private function isNewMethod(methodName: String): Bool {
    return switch (methodName) {
        case "method1", "method2", "method3":
            true;
        case _:
            false;
    };
}
```

### Step 3: Add Detection in TCall Handler

```haxe
// In compileExpression() TCall handler, after existing static extension checks
} else if (objStr == "NewTools" && isNewMethod(methodName)) {
    // NewTools static extensions need to be compiled to idiomatic Elixir
    if (args.length > 0) {
        var targetExpr = compileExpression(args[0]);  // First arg is the target
        var methodArgs = args.slice(1);              // Remaining args are method parameters
        return compileNewMethod(targetExpr, methodName, methodArgs);
    } else {
        return 'NewTools.${methodName}()';
    }
}
```

### Step 4: Implement Specialized Compiler

```haxe
// In ElixirCompiler.hx
private function compileNewMethod(targetStr: String, methodName: String, args: Array<TypedExpr>): String {
    var compiledArgs = args.map(arg -> compileExpression(arg));
    
    return switch (methodName) {
        case "method1":
            // Generate idiomatic Elixir for method1
            'Elixir.IdomaticModule.method1(${targetStr}, ${compiledArgs.join(", ")})';
        case "method2":
            // Handle lambda parameter substitution if needed
            if (args.length > 0) {
                switch (args[0].expr) {
                    case TFunction(func):
                        var paramName = func.args.length > 0 ? 
                            NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "item";
                        var paramTVar = func.args.length > 0 ? func.args[0].v : null;
                        var body = paramTVar != null ? 
                            compileExpressionWithTVarSubstitution(func.expr, paramTVar, paramName) :
                            compileExpression(func.expr);
                        return 'Elixir.Module.method2(${targetStr}, fn ${paramName} -> ${body} end)';
                    case _:
                        return 'Elixir.Module.method2(${targetStr}, ${compiledArgs[0]})';
                }
            }
            'Elixir.Module.method2(${targetStr})';
        case _:
            // Default fallback
            '${targetStr}.${methodName}(${compiledArgs.join(", ")})';
    };
}
```

## Proven Patterns

### 1. **Parameter Reordering Pattern**

Static extensions often require parameter reordering for target idioms:

```haxe
// Haxe: ArrayTools.reduce(array, func, initial)
// Elixir: Enum.reduce(array, initial, func)

// Implementation:
return 'Enum.reduce(${arrayExpr}, ${compiledArgs[1]}, ${compiledArgs[0]})';
```

### 2. **Lambda Parameter Substitution Pattern**

For methods that take lambda functions, use the established substitution pattern:

```haxe
switch (args[0].expr) {
    case TFunction(func):
        var paramName = func.args.length > 0 ? 
            NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "item";
        var paramTVar = func.args.length > 0 ? func.args[0].v : null;
        var body = paramTVar != null ? 
            compileExpressionWithTVarSubstitution(func.expr, paramTVar, paramName) :
            compileExpression(func.expr);
        return 'Enum.method(${targetStr}, fn ${paramName} -> ${body} end)';
    case _:
        return 'Enum.method(${targetStr}, ${compiledArgs[0]})';
}
```

### 3. **Target Module Selection Pattern**

Choose appropriate target modules based on Elixir conventions:

```haxe
// Array operations → Enum module (idiomatic)
'Enum.map(${arrayStr}, fn item -> ${transformation} end)'

// String operations → String module (idiomatic) 
'String.trim(${stringStr})'

// Map operations → Map module (idiomatic)
'Map.get(${mapStr}, ${keyStr}, ${defaultStr})'

// Custom operations → Custom module (when no standard equivalent)
'MyApp.CustomModule.operation(${targetStr}, ${args})'
```

## Testing Static Extensions

### 1. **Create Comprehensive Test**

```haxe
// test/tests/new_tools/Main.hx
using NewTools;

class Main {
    public static function testNewMethods(): Void {
        var target = createTarget();
        
        // Test each method with various patterns
        var result1 = target.method1(arg1);
        var result2 = target.method2(x -> x + 1);
        var result3 = target.method3((acc, item) -> acc + item, initial);
        
        // Test method chaining
        var chained = target
            .method1(arg1)
            .method2(x -> transform(x))
            .method3((a, b) -> combine(a, b), start);
    }
}
```

### 2. **Verify Generated Code**

Run tests and verify the generated Elixir code is idiomatic:

```bash
haxe test/Test.hxml test=new_tools
# Check out/Main.ex for proper Elixir module calls
```

## Common Pitfalls and Solutions

### 1. **Duplicate Function Declaration**
**Problem**: Adding detection function multiple times
**Solution**: Search for existing function before adding: `grep -n "isNewMethod" ElixirCompiler.hx`

### 2. **Wrong Parameter Count**
**Problem**: Passing wrong number of arguments to specialized compiler
**Solution**: Check function signature and match parameter count exactly

### 3. **Missing Method Cases**
**Problem**: Some methods not being detected
**Solution**: Add all methods to detection function and specialized compiler

### 4. **Parameter Order Issues**
**Problem**: Generated code has wrong parameter order
**Solution**: Study target language conventions and reorder accordingly

### 5. **Lambda Compilation Issues**
**Problem**: Lambda functions not compiling correctly
**Solution**: Use established `compileExpressionWithTVarSubstitution` pattern

## Examples of Successful Static Extensions

### 1. **ArrayTools** ✅ IMPLEMENTED
- **Methods**: reduce, fold, find, findIndex, exists, any, foreach, all, forEach, take, drop, flatMap
- **Target**: Elixir Enum module
- **Pattern**: Lambda parameter substitution with Enum.* calls

### 2. **ResultTools** ✅ IMPLEMENTED  
- **Methods**: map, flatMap, filter, fold, unwrap, etc.
- **Target**: ResultTools module (custom algebraic data type handling)
- **Pattern**: ADT-aware compilation

### 3. **OptionTools** ✅ IMPLEMENTED
- **Methods**: map, filter, flatMap, etc.
- **Target**: OptionTools module (custom algebraic data type handling)  
- **Pattern**: ADT-aware compilation

### 4. **MapTools** ✅ IMPLEMENTED
- **Methods**: size, isEmpty, any, all, reduce, find, keys, values, toArray (9 working)
- **Disabled**: filter, map, mapKeys, merge, fromArray (5 methods - Haxe type inference issues)
- **Target**: Elixir Map module with idiomatic functional compilation
- **Pattern**: Dual-parameter lambda substitution with Map/Enum module calls

**Example Usage**:
```haxe
using MapTools;
var users = ["alice" => 85, "bob" => 72, "charlie" => 91];
var totalScore = users.reduce(0, (acc, k, v) -> acc + v);
var hasHighScore = users.any((k, v) -> v > 90);
var usernames = users.keys();
```

**Compilation Examples**:
- `map.size()` → `Map.size(map)`
- `map.isEmpty()` → `Map.equal?(map, %{})`
- `map.any((k,v) -> pred)` → `Enum.any?(Map.to_list(map), fn {k,v} -> pred end)`
- `map.reduce(init, (acc,k,v) -> f)` → `Map.fold(map, init, fn k, v, acc -> f end)`

**Known Limitations**: 5 methods temporarily disabled due to Haxe type system issues with `Map<K,V>` return types in static extension context. Compiler infrastructure fully supports these methods.

## Future Static Extension Candidates

### 1. **StringTools Enhanced** (Medium Priority)
```haxe
using StringTools;
var processed = text.split(",").map(s -> s.trim()).filter(s -> s.length > 0);
var capitalized = words.join(" ").capitalize();
```

**Target**: Elixir String module + Enum for collections
**Benefits**: Fluent string processing chains

### 2. **StreamTools** (Future)
```haxe
using StreamTools;
var result = numbers.stream().filter(x -> x > 0).map(x -> x * 2).take(10).toArray();
```

**Target**: Elixir Stream module
**Benefits**: Lazy evaluation and memory efficiency

## Architecture Benefits

### 1. **Idiomatic Code Generation**
- Generated Elixir uses proper modules (Enum, String, Map)
- Follows Elixir naming conventions (snake_case, ? suffixes)
- Leverages optimized native implementations

### 2. **Cross-Platform Consistency**
- Same Haxe API works on all targets
- Static extension provides fallback implementations
- Type safety maintained across platforms

### 3. **Developer Experience**
- Familiar functional programming patterns
- IDE autocomplete and type checking
- Method chaining support

### 4. **Maintainability**
- Clear separation between Haxe API and target compilation
- Consistent patterns across different static extensions
- Easy to add new methods following established patterns

## Conclusion

The static extension pattern provides a powerful way to add idiomatic target language support while maintaining cross-platform Haxe APIs. By following these established patterns, new static extensions can be implemented efficiently and maintain consistency with existing implementations.

The key is to:
1. **Detect** static extension calls in the TCall handler
2. **Extract** parameters correctly (first arg is target, rest are method args)
3. **Route** to specialized compilation logic
4. **Generate** idiomatic target code using appropriate modules
5. **Test** thoroughly with comprehensive test cases

This approach ensures that Haxe developers can use familiar functional programming patterns while generating efficient, idiomatic code for the target platform.

## Cross-References

- **[Array Functional Methods](ARRAY_FUNCTIONAL_METHODS.md)** - Complete ArrayTools implementation
- **[Compiler Patterns](COMPILER_PATTERNS.md)** - General compiler development patterns  
- **[Standard Library Handling](STANDARD_LIBRARY_HANDLING.md)** - Extern vs static extension patterns
- **[Functional Patterns](FUNCTIONAL_PATTERNS.md)** - Result and Option type patterns
- **[Testing Overview](TESTING_OVERVIEW.md)** - How to test static extensions

## Implementation Files

- **`src/reflaxe/elixir/ElixirCompiler.hx`** - Static extension detection (lines 2204-2223)
- **`std/ArrayTools.hx`** - Reference static extension implementation
- **`test/tests/arrays/Main.hx`** - Reference test patterns for static extensions