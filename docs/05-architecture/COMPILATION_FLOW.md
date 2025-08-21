# Reflaxe.Elixir Compilation Flow

## Overview

This document explains the complete compilation flow from Haxe source code to idiomatic Elixir code, including the critical **desugaring** and **re-sugaring** processes that make Reflaxe.Elixir unique.

## The Complete Flow

```
Haxe Source Code
       ↓
   Haxe Parser → Untyped AST
       ↓
   Haxe Typer → TypedExpr AST (with desugaring)
       ↓
   Reflaxe Hook (Context.onAfterTyping)
       ↓
   ElixirCompiler.compileExpression()
       ↓
   Pattern Detection & Re-sugaring
       ↓
   Idiomatic Elixir Code
```

## Stage 1: Haxe Source Code

**Input**: High-level Haxe code with convenient syntax

```haxe
// Array methods with lambdas
var doubled = numbers.map(n -> n * 2);
var evens = numbers.filter(n -> n % 2 == 0);

// For-in loops
for (fruit in fruits) {
    trace('Fruit: $fruit');
}

// Phoenix LiveView component
@:liveview
class TodoLive extends LiveView {
    function render() {
        return <div class="todo-list">
            {todos.map(todo -> <TodoItem todo={todo} />)}
        </div>;
    }
}
```

## Stage 2: Haxe Parsing & Typing

**Process**: Haxe compiler parses source and creates typed AST

### 2.1 Parsing
- Converts source text to untyped AST
- Handles syntax like `->` lambdas, `@:annotations`, HXX templates

### 2.2 Typing Phase
- Resolves types for all expressions
- **CRITICAL**: This is where **desugaring** happens
- Transforms high-level constructs to low-level equivalents

### 2.3 Desugaring Examples

**Array Methods → While Loops**:
```haxe
// Original: numbers.map(n -> n * 2)
// Desugared to something like:
{
    temp_array = null;
    _g = [];
    _g1 = 0;
    _g2 = numbers;
    while (_g1 < length(_g2)) {
        var n = _g2[_g1];
        _g.push(n * 2);
        _g1++;
    }
    temp_array = _g;
    temp_array;  // Result
}
```

**For-in Loops → While Loops**:
```haxe
// Original: for (fruit in fruits) { trace(fruit); }
// Desugared to:
{
    _g = 0;
    while (_g < fruits.length) {
        var fruit = fruits[_g];
        trace(fruit);
        _g++;
    }
}
```

**Lambda Expressions → Function Expressions**:
```haxe
// Original: n -> n * 2
// Desugared to: function(n) { return n * 2; }
```

## Stage 3: Reflaxe Hook

**Entry Point**: `Context.onAfterTyping(compileTypes)`

- Haxe calls our callback with fully typed and desugared AST
- We receive `Array<ModuleType>` containing all compiled modules
- Each module contains `TypedExpr` trees representing the desugared code

## Stage 4: ElixirCompiler Processing

### 4.1 Main Entry Point

`ElixirCompiler.compileExpression(expr: TypedExpr)` - the core compilation method

### 4.2 Expression Dispatch

Based on `expr.expr` type:
- `TVar(v, init)` → Variable declarations
- `TCall(e, args)` → Method calls
- `TWhile(cond, body, _)` → **CRITICAL**: Where re-sugaring happens
- `TBlock(exprs)` → Statement blocks
- `TFunction(func)` → Lambda functions
- `TLocal(v)` → Variable references
- And 20+ other expression types...

### 4.3 The Re-sugaring Process

This is where Reflaxe.Elixir's intelligence shines:

#### Pattern Detection
```haxe
case TWhile(econd, ebody, _):
    // Try to detect and optimize common for-in loop patterns
    var optimized = tryOptimizeForInPattern(econd, ebody);
    if (optimized != null) {
        return optimized;  // Re-sugared!
    }
    // Fall back to regular while loop compilation
```

#### Key Re-sugaring Functions

1. **`tryOptimizeForInPattern()`** - Detects desugared loops
2. **`optimizeArrayLoop()`** - Recognizes array iteration patterns  
3. **`analyzeLoopBody()`** - Analyzes what the loop is doing
4. **`generateEnumMapPattern()`** - Creates idiomatic `Enum.map` calls
5. **`generateEnumFilterPattern()`** - Creates idiomatic `Enum.filter` calls

#### Variable Substitution

Critical for generating clean code:

```haxe
// Haxe desugaring uses generated variables like "_g", "v"
// We substitute with meaningful names like "item"
compileExpressionWithVarMapping(expr, sourceVar: "v", targetVar: "item")
// Result: "v rem 2 == 0" becomes "item rem 2 == 0"
```

## Stage 5: Pattern-Specific Compilation

### 5.1 Array Method Re-sugaring

**Detection**: Look for while loops with array iteration patterns
**Analysis**: Determine if it's mapping, filtering, finding, counting
**Generation**: Produce idiomatic Elixir

```
Input AST: Complex while loop with _g variables
Output: Enum.map(numbers, fn item -> item * 2 end)
```

### 5.2 Phoenix LiveView Compilation

**Detection**: `@:liveview` annotation on classes
**Processing**: 
1. Generate LiveView module structure
2. Compile HXX templates to HEEx
3. Create mount/handle_event functions
4. Add proper imports and use statements

### 5.3 Ecto Schema Compilation

**Detection**: `@:schema` annotation
**Processing**:
1. Generate schema module with `use Ecto.Schema`
2. Create field definitions from Haxe class fields
3. Generate changesets from `@:changeset` functions
4. Add timestamps and relationships

## Stage 6: Code Generation

### 6.1 Expression Compilation

Each TypedExpr becomes a string of Elixir code:
- Variables: `var x = 5` → `x = 5`
- Function calls: `Math.abs(-5)` → `abs(-5)`
- Binops: `a + b` → `a + b` (with operator mapping)
- Pattern matching: Haxe switch → Elixir case

### 6.2 Idiomatic Transformations

**Functional Style**: Imperative loops → Functional Enum operations
**Pattern Matching**: Switch statements → case expressions
**Immutability**: Variable reassignment → rebinding or function chaining
**Error Handling**: Try/catch → case with tuples

### 6.3 Framework Integration

**Phoenix Router**: `@:routes` → router.ex file
**LiveView**: Class structure → LiveView module
**Ecto**: Schema annotations → proper schema files

## Stage 7: Final Output

**Result**: Idiomatic Elixir code that:
- Follows BEAM/OTP conventions
- Uses functional programming patterns
- Integrates seamlessly with Phoenix/Ecto
- Maintains type safety where possible
- Provides clear error messages

```elixir
# Clean, idiomatic output
def array_methods() do
  numbers = [1, 2, 3, 4, 5]
  doubled = Enum.map(numbers, fn item -> item * 2 end)
  evens = Enum.filter(numbers, fn item -> item rem 2 == 0 end)
  
  # More functional operations...
end
```

## Key Insights for Developers

### 1. Macro-Time vs Runtime
- **All compilation happens at macro-time** (during `haxe build.hxml`)
- **ElixirCompiler disappears after compilation** - it's not available at runtime
- **Generated .ex files are the final product** - no runtime Haxe dependency

### 2. AST-Level Transformations
- **Work with TypedExpr, not strings** as long as possible
- **Variable substitution at AST level** prevents string manipulation bugs
- **Pattern matching on expression structure** is more reliable than regex

### 3. Desugaring Awareness
- **Haxe transforms convenient syntax before we see it**
- **Our job is to detect and reverse this process**
- **Pattern recognition is key to generating clean output**

### 4. Framework Knowledge
- **Must understand target framework conventions** (Phoenix, Ecto, OTP)
- **Generate structure that matches framework expectations**
- **File placement and naming conventions matter**

## Testing the Flow

### Snapshot Testing
```bash
haxe test/Test.hxml test=arrays
# Tests the complete flow: Haxe → AST → Elixir
```

### Mix Integration Testing
```bash
MIX_ENV=test mix test
# Tests that generated Elixir code actually works in BEAM
```

### Debug Techniques
```haxe
// Add trace() calls to see AST structure
trace('Expression type: ${expr.expr}');
trace('Generated code: ${result}');
```

## Common Challenges

### 1. Variable Name Conflicts
- Haxe uses generated names that don't match lambda parameters
- Solution: Variable substitution with meaningful names

### 2. Complex Desugaring Patterns
- Single Haxe construct may become multiple AST nodes
- Solution: Multi-expression pattern detection

### 3. Framework Integration
- Generated code must follow target conventions exactly
- Solution: Deep understanding of Elixir/Phoenix patterns

### 4. Performance
- Avoid string manipulation, prefer AST transformations
- Cache compiled expressions where possible
- Use efficient pattern matching

## Future Enhancements

1. **More Aggressive Optimization**: Detect more complex patterns
2. **Better Error Messages**: Provide Haxe source context in Elixir errors
3. **Performance Profiling**: Optimize compilation speed
4. **Advanced Phoenix Features**: LiveComponents, Channels, etc.

This compilation flow is what makes Reflaxe.Elixir unique - it's not just a syntax converter, but an intelligent transpiler that understands both languages deeply and generates truly idiomatic code.