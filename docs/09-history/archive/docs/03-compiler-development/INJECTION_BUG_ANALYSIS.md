# Target Code Injection Bug Analysis: __elixir__() in Void Contexts

## Issue Summary
The `__elixir__()` injection function works when assigned to a variable but fails when used as a standalone statement in void contexts.

## Symptoms
```haxe
// WORKS - Expression context (assigned to variable)
var result = untyped __elixir__('IO.puts("Hello")');

// BROKEN - Void context (standalone statement)
untyped __elixir__('Logger.info("Message")');
// Generated output: just "__elixir__" string, argument ignored
```

## Root Cause Analysis: WHY This Happens in Our Compiler

### The Critical Difference: Our compileExpression Override

The issue occurs **specifically in our Elixir compiler** because we override `compileExpression` and delegate to `compileExpressionImpl`:

```haxe
// Our ElixirCompiler.hx
public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
    // Call parent to check for injection
    var parentResult = super.compileExpression(expr, topLevel);
    if (parentResult != null) {
        return parentResult;
    }
    
    // Delegate to our implementation
    return compileExpressionImpl(expr, topLevel);
}
```

**The Problem**: When `untyped __elixir__(...)` appears in void context, Haxe doesn't give us a `TCall` node. Instead, it gives us:
1. `TIdent("__elixir__")` - processed separately
2. `TConst(TString("..."))` - processed as next expression

### Why Other Reflaxe Compilers Don't Have This Problem

#### 1. **CPP Compiler**: No compileExpression Override
- Inherits `DirectToStringCompiler.compileExpression` WITHOUT overriding
- Base class handles injection detection perfectly
- Never delegates to custom implementation that might miss patterns

#### 2. **C# Compiler**: Uses GenericCompiler Pattern
- Doesn't override `compileExpression` in the same way
- Handles injection in the `TCall` case of expression compiler
- Different architecture: `GenericCompiler` vs `DirectToStringCompiler`

#### 3. **Our Compiler**: Complex Override Chain
```haxe
// The problematic flow:
DirectToStringCompiler.compileExpression()
  ↓ checks for TCall(TIdent("__elixir__"), args) ✓
  ↓ but in void context gets TIdent("__elixir__") ✗
  ↓ returns null (no injection detected)
ElixirCompiler.compileExpression() 
  ↓ sees null from parent
  ↓ delegates to compileExpressionImpl()
ExpressionVariantCompiler.compileExpressionImpl()
  ↓ processes TIdent as regular identifier
  ↓ returns "__elixir__" string literal
```

### The AST Structure Issue

**In Expression Context (WORKS)**:
```
TCall(
  TIdent("__elixir__"),
  [TConst(TString("IO.puts('hello')"))]
)
```
- Single node, properly detected by `TargetCodeInjection.checkTargetCodeInjection()`

**In Void Context (BROKEN)**:
```
TBlock([
  TIdent("__elixir__"),        // Processed as separate expression
  TConst(TString("IO.puts...")) // Lost connection to __elixir__
])
```
- Haxe's `untyped` in void context doesn't preserve the call structure
- Parent's injection detection can't match the pattern

### Why Our Override Architecture Causes This

Our compiler has **extensive expression handling customization**:
- `compileExpressionImpl` for basic expressions
- `compileExpressionWithVarMapping` for variable substitution  
- `compileExpressionWithTVarSubstitution` for TVar handling
- `compileExpressionWithTypeAwareness` for operator handling
- Multiple specialized expression compilers

This complex delegation chain means:
1. We MUST override `compileExpression` to apply our transformations
2. But this breaks the simple injection detection that works in CPP
3. The base class never sees the complete pattern in void contexts

## Detailed Comparison with Other Compilers

### CPP Compiler (WORKS)
```haxe
// No compileExpression override
// DirectToStringCompiler.compileExpression handles everything
// TargetCodeInjection.checkTargetCodeInjection catches all patterns
```

### C# Compiler (WORKS)
```haxe
// Different architecture: GenericCompiler
case TCall(e, el): {
    // Checks injection WITHIN TCall handling
    final result = TargetCodeInjection.checkTargetCodeInjectionGeneric(...);
    // Never processes bare TIdent("__cs__") as injection
}
```

### Our Elixir Compiler (BROKEN)
```haxe
override function compileExpression(expr, topLevel) {
    // Parent can't detect split AST in void context
    var parentResult = super.compileExpression(expr, topLevel);
    
    // Falls through to our implementation
    return compileExpressionImpl(expr, topLevel); // Processes TIdent as string
}
```

## The Fundamental Problem

**Other compilers don't need to handle this** because:
1. They either don't override `compileExpression` (CPP)
2. Or they use a different architecture that doesn't expose the issue (C#)

**Our compiler exposes the issue** because:
1. We override `compileExpression` for necessary customizations
2. Haxe's `untyped` in void context creates split AST nodes
3. Our delegation pattern processes these nodes individually
4. The injection pattern is lost in the split

## Compiler Data Flow and Architectural Layers

### Understanding the Complete Flow

#### Layer 1: Haxe Parser & Type Checker
```
Haxe Source: untyped __elixir__('IO.puts("Hello")')
                ↓
Haxe Parser: Creates AST nodes
                ↓
Type Checker: Produces TypedExpr
```

**Critical Point**: The `untyped` keyword tells Haxe to skip type checking. In void contexts (statements), Haxe may optimize/restructure the AST differently than in expression contexts.

#### Layer 2: Reflaxe Framework Processing
```
TypedExpr from Haxe
        ↓
Reflaxe BaseCompiler receives module
        ↓
DirectToStringCompiler.compileExpression() [BASE CLASS]
        ├→ Checks targetCodeInjectionName
        ├→ Calls TargetCodeInjection.checkTargetCodeInjection()
        └→ Looks for pattern: TCall(TIdent("__elixir__"), args)
```

#### Layer 3: Our ElixirCompiler Override
```
ElixirCompiler.compileExpression() [OUR OVERRIDE]
        ├→ Calls super.compileExpression() first
        ├→ If parent returns null (no injection detected)
        └→ Delegates to compileExpressionImpl()
                ↓
ExpressionVariantCompiler.compileExpressionImpl()
        ├→ Massive switch on expr.expr
        ├→ TIdent case: returns identifier as string
        └→ Returns "__elixir__" literally
```

### Why Void Context Breaks the Pattern

#### Expression Context (Assignment) - WORKS
```haxe
var result = untyped __elixir__('IO.puts("Hello")');
```

**AST Flow**:
```
TVar("result", 
  TCall(
    TIdent("__elixir__"),
    [TConst(TString("IO.puts..."))]
  )
)
```
- Haxe preserves the call structure because it needs a value
- DirectToStringCompiler sees complete `TCall` pattern
- Injection detected successfully

#### Void Context (Statement) - BROKEN
```haxe
untyped __elixir__('Logger.info("Message")');
```

**AST Flow**:
```
TBlock([
  TIdent("__elixir__"),           // Expression 1
  TConst(TString("Logger.info...")) // Expression 2
])
```
- Haxe splits into separate expressions (no return value needed)
- DirectToStringCompiler sees `TIdent` alone, not `TCall`
- No injection detected, falls through to our handler

### The Critical Architectural Difference

#### Why CPP Compiler Works
```
CPPCompiler extends DirectToStringCompiler
    - NO compileExpression override
    - Base class handles ALL expression compilation
    - TargetCodeInjection always sees raw TypedExpr first
```

#### Why C# Compiler Works  
```
CSCompiler extends GenericCompiler<...>
    - Different architecture entirely
    - Injection checked in TCall case handler
    - Never processes bare TIdent as potential injection
```

#### Why Elixir Compiler Breaks
```
ElixirCompiler extends DirectToStringCompiler
    - OVERRIDES compileExpression for customizations
    - Must delegate after parent check
    - ExpressionVariantCompiler has 2000+ lines of custom logic
    - When parent returns null, we process TIdent as normal identifier
```

### The Delegation Chain Problem

Our compiler needs the override for:
1. **State threading** - Tracking immutable variable updates
2. **Variable substitution** - Lambda parameter renaming
3. **Type-aware operators** - String concatenation with `<>`
4. **Pattern matching** - Complex enum handling
5. **Framework annotations** - LiveView, Router, etc.

This creates a delegation chain:
```
DirectToStringCompiler.compileExpression()
    ↓ (checks injection - fails on split AST)
ElixirCompiler.compileExpression()
    ↓ (sees null, must continue)
ExpressionVariantCompiler.compileExpressionImpl()
    ↓ (2000+ lines of custom logic)
Multiple specialized handlers...
```

### Why This Is Hard to Fix

1. **We can't remove the override** - Would break all our customizations
2. **We can't detect at TBlock level** - Too late, already processing children
3. **We can't modify Haxe's AST generation** - That's upstream
4. **We must handle split AST nodes** - Unique to our architecture

## Current Status (December 2024) - FIXED

### The Solution
The fix was implemented in ExpressionDispatcher.hx by detecting `__elixir__` injection calls BEFORE routing them to MethodCallCompiler. This prevents the double-wrapping issue.

```haxe
case TCall(e, el):
    // Check for __elixir__ injection BEFORE delegating to MethodCallCompiler
    switch(e.expr) {
        case TIdent(id) if (id == "__elixir__"):
            // Let the parent's injection detection handle this
            var parentResult = compiler.compileExpression(expr, topLevel);
            if (parentResult != null) {
                return parentResult;
            }
        case _:
            // Not an injection, proceed normally
    }
    methodCallCompiler.compileCallExpression(e, el);
```

## Current Status (December 2024)

### What We've Discovered
1. **The injection IS being detected** - Output shows `__elixir__(...)` which means something is recognizing it
2. **The pattern isn't fully working** - The string should be injected directly, not wrapped in `__elixir__()`
3. **AST structure is indeed split in void contexts** - Confirmed by debug traces
4. **Other Reflaxe compilers don't have this issue** - They either don't override compileExpression or use different architecture

### Current Behavior
```elixir
# Generated (incorrect - function doesn't exist in Elixir):
__elixir__("Logger.info(\"Message\")")

# Should be (direct injection):
Logger.info("Message")
```

### The Real Problem
The issue appears to be that when the injection IS detected in expression context (assigned), it works correctly. But in void context, something in our compilation chain is wrapping the identifier `__elixir__` as a function call rather than processing it as an injection marker.

This suggests the problem might be:
1. We're somehow generating `__elixir__` as a regular function call
2. The injection detection is failing and falling back to regular identifier compilation
3. Our override chain is interfering with proper injection handling

## Potential Solutions

### Option 1: Override compileExpression (RECOMMENDED)
Override `compileExpression` to detect the split pattern:
```haxe
override function compileExpression(expr: TypedExpr, topLevel: Bool = false): String {
    // Check for bare __elixir__ identifier
    switch(expr.expr) {
        case TIdent("__elixir__") if (topLevel):
            // Check if next expression in block is the argument
            // Manually reconstruct the injection
        default:
            return super.compileExpression(expr, topLevel);
    }
}
```

### Option 2: Fix at TBlock Level
When processing TBlock, detect sequences of `TIdent("__elixir__")` followed by string constants.

### Option 3: Investigate Base Class Call
Check if we're properly calling the parent's injection detection in all cases.

## Testing Requirements

### Test Cases Needed
1. Void context: `untyped __elixir__('IO.puts("test")')`
2. Expression context: `var x = untyped __elixir__('...')`
3. Within functions vs top-level
4. Multiple arguments: `untyped __elixir__('func', arg1, arg2)`

### Validation
```bash
# After implementing fix
haxe test/Test.hxml test=ElixirInjection
# Check generated .ex file for proper injection
```

## Implementation Priority
**HIGH** - This is a core feature that should work consistently across all contexts.

## References
- C# implementation: `/haxe.elixir.reference/reflaxe/reflaxe_cs/src/cscompiler/components/CSCompiler_Expr.hx:290-321`
- CPP base class usage: Relies on `DirectToStringCompiler.compileExpression()`
- Reflaxe injection helper: `reflaxe.compiler.TargetCodeInjection`