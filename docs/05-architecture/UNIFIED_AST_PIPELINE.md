# Unified AST Pipeline Architecture

## Overview

**ALL code generation in Reflaxe.Elixir goes through a single, unified AST pipeline.**

This ensures predictable, consistent transformations regardless of whether we're compiling:
- **Classes** → Elixir modules
- **Enums** → Tagged tuple modules  
- **Expressions** → Elixir expressions
- **Functions** → Elixir functions
- **Any future constructs** → Their Elixir equivalents

## The Three-Phase Pipeline

```
Input (Haxe AST) → Phase 1: Build → Phase 2: Transform → Phase 3: Print → Output (Elixir String)
```

### Phase 1: Build (ElixirASTBuilder)
Converts Haxe's TypedExpr to ElixirAST nodes.

**Input Types**:
- `ClassType` → builds `EDefmodule` with functions
- `EnumType` → builds `EDefmodule` with tagged tuple constructors
- `TypedExpr` → builds expression nodes (EIf, ECall, etc.)

**Key Principle**: ONLY builds structure, NO transformations, NO string generation.

### Phase 2: Transform (ElixirASTTransformer)  
Applies semantic transformations via passes.

**ALL nodes go through the SAME transformation pipeline**:
```haxe
public static function transform(ast: ElixirAST): ElixirAST {
    var passes = getEnabledPasses();
    var result = ast;
    
    for (passConfig in passes) {
        result = passConfig.pass(result);  // Every node goes through every pass
    }
    
    return result;
}
```

**Transformation Passes** (applied to ALL AST nodes):
1. `selfReferenceTransformPass` - Converts `this` to struct parameters
2. `constantFoldingPass` - Optimizes constant expressions
3. `pipelineOptimizationPass` - Converts to Elixir pipe operator
4. `comprehensionConversionPass` - Loops to comprehensions
5. `immutabilityTransformPass` - Ensures immutable patterns
6. `otpChildSpecTransformPass` - OTP child spec transformations
7. ...and more

### Phase 3: Print (ElixirASTPrinter)
Converts ElixirAST to string representation.

**Key Principle**: ONLY formatting, NO logic, NO transformations.

## How It Works: Unified Processing

### Example 1: Class Compilation

```haxe
// Input: Haxe ClassType
class TodoList { 
    public function add(item: String) { ... }
}

// Phase 1: Build AST
EDefmodule("TodoList", 
    EBlock([
        EDef("add", ["item"], null, ...)
    ])
)

// Phase 2: Transform (goes through ALL passes)
// - selfReferenceTransformPass might convert 'this' references
// - immutabilityTransformPass ensures struct updates
// - Same passes that handle expressions!

// Phase 3: Print
defmodule TodoList do
    def add(item) do
        ...
    end
end
```

### Example 2: Enum with @:elixirIdiomatic

```haxe
// Input: Haxe EnumType
@:elixirIdiomatic
enum ChildSpecFormat {
    ModuleRef(name: String);
    ModuleWithConfig(module: String, config: Array<Dynamic>);
}

// Phase 1: Build AST (with metadata)
EDefmodule("ChildSpecFormat",
    EBlock([
        EDef("module_ref", ["name"], null, 
            ETuple([EAtom("ModuleRef"), EVar("name")])
        ),
        ...
    ])
)
// Metadata: {isIdiomaticEnum: true}

// Phase 2: Transform (otpChildSpecTransformPass detects metadata)
// Transforms: {:ModuleRef, "Phoenix.PubSub"} → Phoenix.PubSub
// This SAME pass also handles inline enum usage in expressions!

// Phase 3: Print
defmodule ChildSpecFormat do
    def module_ref(name), do: name  # Transformed!
end
```

### Example 3: Expression in Function Body

```haxe
// Input: TypedExpr from function body
var spec = ChildSpecFormat.ModuleRef("Phoenix.PubSub");

// Phase 1: Build AST
ECall(
    EFieldAccess("ChildSpecFormat", "ModuleRef"),
    [EString("Phoenix.PubSub")]
)
// Metadata: {isIdiomaticEnum: true}

// Phase 2: Transform (SAME otpChildSpecTransformPass!)
// Detects metadata, applies transformation
EString("Phoenix.PubSub")  // Transformed to just the module name

// Phase 3: Print
"Phoenix.PubSub"
```

## Key Benefits

### 1. **Consistency**
The SAME transformation logic applies whether an enum is:
- Defined as a type
- Used inline in an expression
- Part of a function parameter
- Nested in a complex structure

### 2. **No Duplication**
Write transformation logic ONCE in a pass, it works EVERYWHERE:
- No separate "expression compiler" vs "type compiler"
- No special cases for different contexts
- No "helper compilers" with overlapping functionality

### 3. **Predictability**
Every piece of code follows the same path:
```
Build → Transform → Print
```
No shortcuts, no bypasses, no special cases.

### 4. **Extensibility**
Add a new transformation? Just add a pass:
```haxe
passes.push({
    name: "MyNewTransform",
    description: "What it does",
    enabled: true,
    pass: myNewTransformPass
});
```
It automatically applies to ALL code - modules, enums, expressions, everything.

### 5. **Debugging**
With unified pipeline, debugging is straightforward:
```haxe
#if debug_ast_transformer
trace("Before transform: " + ast);
for (pass in passes) {
    trace("Applying pass: " + pass.name);
    ast = pass.pass(ast);
    trace("After pass: " + ast);
}
#end
```

## Architecture Invariants

1. **Builder ONLY builds** - No transformations in ElixirASTBuilder
2. **Transformer ONLY transforms** - No building new nodes from scratch
3. **Printer ONLY prints** - No logic or transformations
4. **ALL code goes through ALL passes** - No special paths
5. **Metadata drives decisions** - Not multiple detection systems

## Comparison with Old Architecture

### Old: Helper-Based (75 files)
```
ClassType → ClassCompiler → String
EnumType → EnumCompiler → String  
Expression → ExpressionCompiler → String
// Each with its own logic, own detection, own transformation
```

### New: Unified AST Pipeline (3 files)
```
ClassType ─┐
EnumType  ─┼→ ElixirASTBuilder → ElixirASTTransformer → ElixirASTPrinter → String
Expression ─┘
// ALL use the SAME pipeline, SAME passes, SAME transformations
```

## Conclusion

The unified AST pipeline ensures that every piece of code - whether it's a module definition, an enum, or a deeply nested expression - goes through exactly the same transformation pipeline. This creates predictable, consistent, and maintainable code generation that's easy to extend and debug.