# Method Body Inspection and `__elixir__()` Expansion in Reflaxe.Elixir

## ✅ SOLVED: `__elixir__()` Injection Now Works with Standard Library Methods

### Executive Summary

We successfully implemented method body inspection in the AST builder to detect and expand `__elixir__()` calls from standard library methods. This allows us to generate idiomatic Elixir code from Haxe's standard library without hardcoding array method transformations in the compiler.

### The Solution Architecture

#### 1. Method Body Access via ClassField API
Using Haxe's `ClassField.expr()` API to access method implementations at compile time:

```haxe
// In ElixirASTBuilder.hx
case FInstance(_, _, cf):
    var classField = cf.get();
    var methodExpr = classField.expr();  // Get the method body AST
    if (methodExpr != null) {
        expandedElixir = tryExpandElixirInjection(methodExpr, obj, el);
        if (expandedElixir != null) {
            return expandedElixir.def;
        }
    }
```

#### 2. Recursive AST Traversal
The `tryExpandElixirInjection` function recursively searches method bodies for `__elixir__()` calls:

```haxe
static function tryExpandElixirInjection(methodExpr: TypedExpr, thisExpr: TypedExpr, args: Array<TypedExpr>): Null<ElixirAST> {
    switch(methodExpr.expr) {
        case TFunction(tfunc):
            // Extract function body
            if (tfunc.expr != null) {
                return tryExpandElixirInjection(tfunc.expr, thisExpr, args);
            }
        case TReturn(retOpt):
            // Handle return statements
            if (retOpt != null) {
                return tryExpandElixirCall(retOpt, thisExpr, args);
            }
        case TBlock(exprs):
            // Check last expression in block
            if (exprs.length > 0) {
                var lastExpr = exprs[exprs.length - 1];
                return tryExpandElixirCall(lastExpr, thisExpr, args);
            }
        case TIf(cond, ifExpr, elseExpr):
            // Handle conditional __elixir__() calls
            var ifResult = tryExpandElixirCall(ifExpr, thisExpr, args);
            var elseResult = elseExpr != null ? tryExpandElixirCall(elseExpr, thisExpr, args) : null;
            // Build conditional with expanded branches
            // ...
    }
}
```

#### 3. Parameter Substitution
The system replaces placeholders ({0}, {1}, etc.) with actual arguments:

```haxe
// Substitute {0} with 'this' (the array)
var thisAst = buildFromTypedExpr(thisExpr);
var thisStr = ElixirASTPrinter.printAST(thisAst);
processedCode = StringTools.replace(processedCode, "{0}", thisStr);

// Substitute other parameters
for (i in 1...callArgs.length) {
    if (i - 1 < methodArgs.length) {
        var argAst = buildFromTypedExpr(methodArgs[i - 1]);
        var argStr = ElixirASTPrinter.printAST(argAst);
        processedCode = StringTools.replace(processedCode, '{$i}', argStr);
    }
}
```

### Generated Output Examples

From `Array.hx` methods with `__elixir__()` injection:

| Haxe Method Call | Generated Elixir Code |
|------------------|----------------------|
| `array.map(fn)` | `Enum.map(array, fn)` |
| `array.filter(fn)` | `Enum.filter(array, fn)` |
| `array.concat(other)` | `array ++ other` |
| `array.contains(item)` | `Enum.member?(array, item)` |
| `array.indexOf(item)` | `Enum.find_index(array, fn item -> item == x end) \|\| -1` |
| `array.join(sep)` | `Enum.join(array, sep)` |
| `array.reverse()` | `Enum.reverse(array)` |
| `array.sort(cmp)` | `Enum.sort(array, cmp)` |

### Key Technical Insights

#### 1. AST Structure Understanding
- Method bodies are wrapped in `TFunction` nodes containing `tfunc.expr`
- Return statements are `TReturn` nodes wrapping the actual expression
- `untyped __elixir__()` becomes `TMeta({name: ":untyped"}, ...)` not `TUntyped`

#### 2. Handling Conditional Injection
Methods like `slice()` use if-else to choose between different `__elixir__()` calls:

```haxe
public function slice(pos: Int, ?end: Int): Array<T> {
    if (end == null) {
        return untyped __elixir__("Enum.slice({0}, {1}..-1)", this, pos);
    } else {
        return untyped __elixir__("Enum.slice({0}, {1}..{2})", this, pos, end);
    }
}
```

The system detects and expands both branches, creating a conditional in the output.

#### 3. Language Paradigm Differences
- **C# Compiler**: Doesn't need injection - method renaming suffices (OOP → OOP)
- **Elixir Compiler**: Needs complete restructuring (OOP → Functional)
- This is why `__elixir__()` is critical for idiomatic output

### Architectural Benefits

1. **Separation of Concerns**: Compiler doesn't need to know about Array methods
2. **Maintainability**: Standard library can evolve independently
3. **Idiomaticity**: Each stdlib method can generate optimal Elixir code
4. **Flexibility**: Easy to add new stdlib methods without compiler changes

### Historical Context: Why Other Approaches Failed

#### 1. Plain `inline` (❌ Doesn't Work)
```haxe
public inline function map<S>(f: T -> S): Array<S> {
    return untyped __elixir__("Enum.map({0}, {1})", this, f);
}
```
**Failure**: Haxe evaluates `inline` at macro time before `__elixir__()` exists

#### 2. `extern inline` (❌ Doesn't Apply to Array)
```haxe
extern class Array<T> {
    public extern inline function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__("Enum.map({0}, {1})", this, f);
    }
}
```
**Failure**: Array is a core Haxe type, not an extern class

#### 3. Hardcoded Transformations (❌ Architectural Smell)
```haxe
// In compiler
if (methodName == "map" && isArray) {
    return generateEnumMap(...);
}
```
**Problem**: Compiler has too much knowledge about stdlib implementation

### Implementation Timeline

1. **Discovery Phase**: Found that `ClassField.expr()` provides method body access
2. **AST Analysis**: Mapped how `__elixir__()` appears in TypedExpr AST
3. **Implementation**: Added `tryExpandElixirInjection` and `tryExpandElixirCall`
4. **Refinement**: Added support for TReturn, TIf, and TMeta wrappers
5. **Validation**: Confirmed idiomatic output for all Array methods

### Future Improvements

1. **Optimize Conditional Evaluation**: Currently generates runtime conditionals for compile-time known values
2. **Extended Stdlib Coverage**: Apply same pattern to String, Map, and other stdlib types
3. **Performance**: Cache expanded methods to avoid repeated AST traversal

### Conclusion

The method body inspection approach successfully bridges the gap between Haxe's OOP standard library and Elixir's functional idioms, allowing `__elixir__()` injection to work seamlessly without compiler-specific hardcoding.