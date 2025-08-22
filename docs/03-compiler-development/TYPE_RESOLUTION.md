# Type Resolution Guide

> **Parent Context**: See [CLAUDE.md](CLAUDE.md) for compiler development context

This guide covers the comprehensive type mapping and resolution system used in Reflaxe.Elixir to translate Haxe types to idiomatic Elixir representations.

## 🎯 Overview

**Type Resolution** is the process of mapping Haxe's static type system to Elixir's dynamic type system while preserving type safety guarantees and generating idiomatic code.

## 📊 Type Mapping Strategy

### Core Type Mappings
```haxe
// Haxe → Elixir type mappings
Int         → integer()
Float       → float()
String      → String.t() | binary()
Bool        → boolean()
Dynamic     → any()
Array<T>    → list(T)
Map<K,V>    → %{K => V}
Date        → DateTime.t()
```

### Complex Type Resolution
```haxe
function resolveType(type: Type): String {
    return switch(type) {
        case TInst(t, params):
            resolveClassType(t.get(), params);
            
        case TEnum(e, params):
            resolveEnumType(e.get(), params);
            
        case TAbstract(a, params):
            resolveAbstractType(a.get(), params);
            
        case TFun(args, ret):
            resolveFunctionType(args, ret);
            
        case TAnonymous(a):
            resolveAnonymousType(a.get());
            
        case TDynamic(t):
            "any()";
            
        default:
            "term()";
    };
}
```

## 🔍 Class Type Resolution

### Standard Classes
```haxe
function resolveClassType(c: ClassType, params: Array<Type>): String {
    return switch(c.name) {
        case "String":
            "String.t()";
            
        case "Array":
            if (params.length > 0) {
                'list(${resolveType(params[0])})';
            } else {
                "list()";
            }
            
        case "Map" | "StringMap" | "IntMap":
            if (params.length >= 2) {
                '%{${resolveType(params[0])} => ${resolveType(params[1])}}';
            } else {
                "map()";
            }
            
        case "Date":
            "DateTime.t()";
            
        default:
            // Custom class - use module name
            getModuleName(c);
    };
}
```

### Generic Type Parameters
```haxe
function resolveGenerics(c: ClassType, params: Array<Type>): Map<String, String> {
    var resolved = new Map<String, String>();
    
    if (c.params.length == params.length) {
        for (i in 0...c.params.length) {
            var paramName = c.params[i].name;
            var paramType = resolveType(params[i]);
            resolved.set(paramName, paramType);
        }
    }
    
    return resolved;
}
```

## 📈 Enum Type Resolution

### Simple Enums
```haxe
enum Color {
    Red;
    Green;
    Blue;
}

// Resolves to Elixir atoms
:red | :green | :blue
```

### Parameterized Enums
```haxe
enum Option<T> {
    Some(value: T);
    None;
}

// Resolves to tagged tuples
{:some, T} | :none
```

### Resolution Implementation
```haxe
function resolveEnumType(e: EnumType, params: Array<Type>): String {
    var variants = [];
    
    for (construct in e.constructs) {
        if (construct.type.match(TFun(_, _))) {
            // Constructor with parameters
            var args = extractConstructorArgs(construct);
            var argTypes = args.map(a -> resolveType(a.t));
            variants.push('{:${construct.name.toLowerCase()}, ${argTypes.join(", ")}}');
        } else {
            // Simple constructor
            variants.push(':${construct.name.toLowerCase()}');
        }
    }
    
    return variants.join(" | ");
}
```

## 🧩 Abstract Type Resolution

### Underlying Type Extraction
```haxe
function resolveAbstractType(a: AbstractType, params: Array<Type>): String {
    // Check for special abstracts
    switch(a.name) {
        case "Null":
            if (params.length > 0) {
                return '${resolveType(params[0])} | nil';
            }
            return "nil";
            
        case "Float" | "Int":
            return "number()";
            
        default:
            // Resolve to underlying type
            return resolveType(a.type);
    }
}
```

### Custom Abstract Handling
```haxe
abstract UserId(Int) {
    public function new(id: Int) this = id;
}

// Resolution strategy
function resolveCustomAbstract(a: AbstractType): String {
    if (a.meta.has(":newtype")) {
        // Treat as distinct type
        return a.name + ".t()";
    } else {
        // Treat as alias
        return resolveType(a.type);
    }
}
```

## 🔄 Function Type Resolution

### Simple Functions
```haxe
function resolveFunctionType(args: Array<{t: Type}>, ret: Type): String {
    if (args.length == 0) {
        return '(() -> ${resolveType(ret)})';
    }
    
    var argTypes = args.map(a -> resolveType(a.t));
    return '((${argTypes.join(", ")}) -> ${resolveType(ret)})';
}
```

### Higher-Order Functions
```haxe
// Haxe: (Int -> Bool) -> Array<Int> -> Array<Int>
// Elixir: ((integer() -> boolean()), list(integer())) -> list(integer())

function resolveHigherOrderType(type: Type): String {
    return switch(type) {
        case TFun([{t: TFun(innerArgs, innerRet)}, ...rest], outerRet):
            var innerType = resolveFunctionType(innerArgs, innerRet);
            var restTypes = rest.map(a -> resolveType(a.t));
            '((${innerType}, ${restTypes.join(", ")}) -> ${resolveType(outerRet)})';
            
        default:
            resolveType(type);
    };
}
```

## ⚡ Type Inference

### Local Variable Type Inference
```haxe
function inferVariableType(v: TVar, init: Null<TypedExpr>): String {
    if (init != null) {
        // Infer from initialization
        return resolveType(init.t);
    } else if (v.t != null) {
        // Use declared type
        return resolveType(v.t);
    } else {
        // Unknown type
        return "any()";
    }
}
```

### Return Type Inference
```haxe
function inferReturnType(func: TFunc): String {
    // Collect all return expressions
    var returnTypes = [];
    
    function findReturns(expr: TypedExpr) {
        switch(expr.expr) {
            case TReturn(e) if (e != null):
                returnTypes.push(resolveType(e.t));
            case TBlock(exprs):
                for (e in exprs) findReturns(e);
            // ... other cases
        }
    }
    
    findReturns(func.expr);
    
    if (returnTypes.length == 0) {
        return "nil";
    } else if (returnTypes.length == 1) {
        return returnTypes[0];
    } else {
        // Union type
        return returnTypes.join(" | ");
    }
}
```

## 📊 Type Spec Generation

### Function Specs
```haxe
function generateFunctionSpec(name: String, func: TFunc): String {
    var args = func.args.map(a -> resolveType(a.v.t));
    var ret = inferReturnType(func);
    
    return '@spec ${name}(${args.join(", ")}) :: ${ret}';
}
```

### Module Attributes
```haxe
function generateTypeSpecs(c: ClassType): Array<String> {
    var specs = [];
    
    for (field in c.fields.get()) {
        if (field.kind.match(FMethod(_))) {
            var func = extractFunction(field);
            specs.push(generateFunctionSpec(field.name, func));
        }
    }
    
    return specs;
}
```

## 🧪 Type Resolution Testing

### Test Framework
```haxe
class TypeResolutionTest {
    static function testBasicTypes() {
        assert(resolveType(TInt) == "integer()");
        assert(resolveType(TFloat) == "float()");
        assert(resolveType(TString) == "String.t()");
        assert(resolveType(TBool) == "boolean()");
    }
    
    static function testGenericTypes() {
        var arrayType = TInst(Array, [TInt]);
        assert(resolveType(arrayType) == "list(integer())");
        
        var mapType = TInst(Map, [TString, TInt]);
        assert(resolveType(mapType) == "%{String.t() => integer()}");
    }
    
    static function testFunctionTypes() {
        var funcType = TFun([{t: TInt}, {t: TString}], TBool);
        assert(resolveType(funcType) == "((integer(), String.t()) -> boolean())");
    }
}
```

### Debug Visualization
```haxe
#if debug_type_resolution
function traceTypeResolution(type: Type): String {
    trace('[TypeResolution] Input type: ${type}');
    var resolved = resolveType(type);
    trace('[TypeResolution] Resolved to: ${resolved}');
    return resolved;
}
#end
```

## 🔧 Integration with Compiler

### Type Context Management
```haxe
class TypeContext {
    var typeCache: Map<String, String> = new Map();
    var genericBindings: Map<String, Type> = new Map();
    
    public function resolve(type: Type): String {
        var key = Std.string(type);
        
        if (typeCache.exists(key)) {
            return typeCache.get(key);
        }
        
        var resolved = typeResolver.resolveType(type);
        typeCache.set(key, resolved);
        return resolved;
    }
    
    public function withGenerics<T>(bindings: Map<String, Type>, f: () -> T): T {
        var old = genericBindings;
        genericBindings = bindings;
        var result = f();
        genericBindings = old;
        return result;
    }
}
```

## 📚 Related Documentation

- **[TypeResolutionCompiler.hx](../../src/reflaxe/elixir/helpers/TypeResolutionCompiler.hx)** - Implementation
- **[COMPILATION_FLOW.md](COMPILATION_FLOW.md)** - Type resolution in compilation
- **[AST_CLEANUP_PATTERNS.md](AST_CLEANUP_PATTERNS.md)** - Type-aware AST processing
- **[DEBUG_XRAY_SYSTEM.md](DEBUG_XRAY_SYSTEM.md)** - Type debugging

---

This guide provides comprehensive coverage of type resolution in Reflaxe.Elixir. The goal is preserving Haxe's type safety while generating idiomatic Elixir type specifications.