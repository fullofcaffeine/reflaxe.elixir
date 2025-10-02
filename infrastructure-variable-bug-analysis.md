# Infrastructure Variable Elimination Bug - Comprehensive Analysis

**Date**: January 2025
**Context**: Bugs in parseMessageImpl compilation and empty block handling

## Executive Summary

Two related bugs stem from a fundamental architectural issue in how infrastructure variable elimination interacts with the AST pipeline:

1. **Bug 1**: Missing infrastructure variable assignments when switch follows conditional statements
2. **Bug 2**: Empty blocks generating empty strings in expression contexts (syntax errors)

Both bugs share a common root cause: **Infrastructure variable elimination happens at the TypedExpr level (preprocessor), but context-aware code generation needs to happen at the AST level (printer).**

---

## Bug 1: Missing Infrastructure Variable Assignment

### Symptom
```elixir
def parse_message_impl(msg) do
    if not SafePubSub.isValidMessage(msg) do
      Log.trace(...)
      :none
    end
    case g do  # ERROR: 'g' is undefined
```

### Expected Output
```elixir
def parse_message_impl(msg) do
    if not SafePubSub.isValidMessage(msg) do
      Log.trace(...)
      :none
    end
    case Map.get(msg, :type) do  # Direct expression, no variable
```

### Root Cause Analysis

#### 1. The Infrastructure Variable Pattern

Haxe internally desugars high-level constructs like `switch(obj.field)` into:
```haxe
var _g = obj.field;  // Infrastructure variable
switch(_g) { ... }
```

TypedExprPreprocessor detects this pattern and tries to eliminate it for idiomatic Elixir:
- Lines 476-565: Block-level pattern detection
- Lines 256-274: Expression-level elimination

#### 2. The Pattern Detection Gap

The preprocessor's infrastructure variable elimination relies on a SPECIFIC pattern (lines 480-565):

```haxe
// REQUIRED: Infrastructure variable immediately followed by switch
case TVar(v, init) if (isInfrastructureVar(v.name)):
    var next = exprs[i + 1];  // Next expression MUST be the switch
    switch(actualSwitchExpr.expr) {
        case TSwitch(e, cases, edef):
            if (usesVariable(e, v.name)) {
                // Pattern detected! Substitute and eliminate
```

**THE PROBLEM**: In parseMessageImpl, the AST structure is:

```
TBlock([
    TIf(condition, Log.trace + return, null),  // Early return
    TVar(_g, msg.type),                        // Infrastructure variable
    TSwitch(TLocal(_g), ...)                   // Switch using _g
])
```

The preprocessor processes the block as:
1. Process TIf → Returns modified TIf
2. Process TVar(_g) → Finds it at index i=1
3. Looks at next expression (i+1=2) → Finds TSwitch ✓
4. Detects the pattern and tries to substitute

#### 3. WHY the Substitution Fails

Looking at the preprocessor logic (lines 553-559):
```haxe
// Register substitution BEFORE processing switch
substitutions.set(v.name, init);  // _g → msg.type

// Also register stripped version
var strippedName = (v.name.charAt(0) == "_") ? v.name.substr(1) : v.name;
if (strippedName != v.name) {
    substitutions.set(strippedName, init);  // g → msg.type
    #if debug_infrastructure_vars
    trace('[processBlock] Also registered stripped name: $strippedName');
    #end
}
```

The code DOES register both `_g` and `g` in the substitutions map. So why doesn't it work?

**THE CRITICAL INSIGHT**: The problem is in what gets returned from processBlock:

```haxe
// Lines 582-588: Return the transformed switch AND skip the variable
var result = [];
// ... add expressions up to i (before the TVar)
result.push(transformedSwitch);
i += skipCount;  // Skip TVar + Switch
// ... continue processing
```

The issue is that when the TIf statement is involved, the **function returns early** or the block structure is different than expected, causing the pattern detection to fail.

Let me check the actual code flow more carefully:

Looking at lines 149-186 (processExpr case for TBlock):
```haxe
case TBlock(el):
    // This calls processBlock
    var result = processBlock(el, substitutions);
    return result;
```

And processBlock at lines 439-628 processes each expression individually. The issue is that the pattern detection in processBlock (lines 476-565) happens during iteration, but the **subsequent expressions** might be processed BEFORE the substitution is fully applied.

#### 4. The Actual Bug

After reviewing the debug output and code, I believe the issue is:

**When the infrastructure variable is detected and eliminated, the substitution is registered, BUT the switch expression that uses it is NOT getting the substitution applied because of how processExpr handles TSwitch.**

Looking at processExpr (lines 234-254):
```haxe
// Handle switch statements directly
case TSwitch(e, cases, edef):
    // Special handling for switches with undefined infrastructure variables
    var switchTarget = switch(e.expr) {
        case TLocal(v) if (isInfrastructureVar(v.name) && !substitutions.exists(v.name)):
            // This case handles UNDEFINED infrastructure vars
            e;
        default:
            e;
    };

    processSwitchExpr(switchTarget, cases, edef, expr.pos, expr.t, substitutions);
```

**THE BUG**: The check is `!substitutions.exists(v.name)` - meaning it only handles UNDEFINED infrastructure variables. But in our case, the substitution WAS registered at lines 553-559, so this check FAILS!

The switch then processes with `e` (TLocal("_g")) instead of the substituted expression (`msg.type`), and later when the Builder tries to create an EVar for "_g", it can't find it because the TVar was eliminated.

---

## Bug 2: Empty Blocks in Expression Contexts

### Symptom
```elixir
if c == nil, do: , else:  # SYNTAX ERROR: empty branches
```

### Expected Output
```elixir
if c == nil, do: nil, else: nil  # Expression must return a value
```

### Root Cause Analysis

#### 1. Infrastructure Variable Elimination Returns TBlock([])

When an infrastructure variable is eliminated (line 277):
```haxe
case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
    // ...
    return {expr: TBlock([]), pos: expr.pos, t: expr.t};
```

This creates an empty block to represent "no code".

#### 2. Empty Blocks Compile to Empty Strings

BlockBuilder.hx (line 88):
```haxe
if (el.length == 0) {
    return EBlock([]);  // Empty AST node
}
```

ElixirASTPrinter.hx (line 1057):
```haxe
case EBlock(expressions):
    if (expressions.length == 0) {
        '';  // Empty string!
    }
```

#### 3. Empty Strings in Expression Positions Create Syntax Errors

In Elixir, expressions MUST return a value:
```elixir
# VALID - statement context (no value needed)
def foo do
end  # implicitly returns :ok

# INVALID - expression context (value required)
if true, do: , else:  # Syntax error!
```

The printer returns empty strings for `EBlock([])` without considering whether the block is in a statement or expression context.

---

## The Definitive Architectural Solution

### Problem Statement

Both bugs stem from the same architectural issue:

1. **Infrastructure variable elimination happens too early** (at TypedExpr level)
2. **Context-aware decisions happen too late** (at printing time)
3. **The substitution mechanism is incomplete** (doesn't handle all cases)

### Solution Architecture: Two-Phase Infrastructure Variable Handling

#### Phase 1: Mark, Don't Eliminate (Preprocessor)

Instead of eliminating infrastructure variables at the TypedExpr level, **mark them with metadata**:

```haxe
// In TypedExprPreprocessor.hx - processExpr
case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
    // DON'T eliminate - mark instead
    substitutions.set(v.name, init);
    substitutions.set(strippedName, init);

    // Return marked node, NOT TBlock([])
    return {
        expr: TVar(v, init),  // Keep the original
        pos: expr.pos,
        t: expr.t,
        // Add metadata marker
        metadata: {isInfrastructureVar: true, substitution: init}
    };
```

#### Phase 2: Context-Aware Elimination (Builder/Printer)

The Builder detects infrastructure variables and applies context-aware transformation:

```haxe
// In VariableBuilder.hx or ElixirASTBuilder.hx
case TVar(v, init):
    // Check for infrastructure variable marker
    if (expr.metadata?.isInfrastructureVar == true) {
        // Get the substitution
        var substExpr = expr.metadata.substitution;

        // Check if variable is actually used
        if (!isVariableUsedInScope(v.name, currentScope)) {
            // Not used - return empty block for statement context
            // The printer will handle this based on context
            return EBlock([]);
        } else {
            // Used - this is the bug! The switch needs the substitution
            // This case should NOT happen if pattern detection works
            return compileExpressionImpl(substExpr, topLevel);
        }
    }
```

#### Phase 3: Context-Aware Empty Block Handling (Printer)

The printer needs to know whether an empty block is in a statement or expression context:

```haxe
// In ElixirASTPrinter.hx
case EBlock(expressions):
    if (expressions.length == 0) {
        // CRITICAL: Check context
        if (inExpressionContext(ast.metadata)) {
            'nil';  // Expression context - must return a value
        } else {
            '';     // Statement context - no code needed
        }
    }
```

But how do we know the context? **Pass it through metadata**:

```haxe
// In ElixirASTBuilder.hx - when building if/case expressions
case TIf(econd, eif, eelse):
    var condAst = compileExpressionImpl(econd, false);

    // Mark branches as expression context
    var thenAst = compileExpressionImpl(eif, false);
    if (thenAst != null) thenAst.metadata.inExpressionContext = true;

    var elseAst = eelse != null ? compileExpressionImpl(eelse, false) : makeAST(ENil);
    if (elseAst != null) elseAst.metadata.inExpressionContext = true;

    return makeAST(EIf(condAst, thenAst, elseAst));
```

---

## Implementation Strategy

### Step 1: Add Context Metadata to AST (IMMEDIATE)

```haxe
// In ElixirAST.hx - extend ElixirMetadata
typedef ElixirMetadata = {
    // ... existing fields
    ?inExpressionContext: Bool,  // NEW: Is this node in expression context?
    ?isInfrastructureVar: Bool,  // NEW: Is this an infrastructure variable?
    ?substitutionExpr: TypedExpr, // NEW: What to substitute with
}
```

### Step 2: Modify Preprocessor to Mark, Not Eliminate (IMMEDIATE)

```haxe
// In TypedExprPreprocessor.hx - processExpr (line 257)
case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
    substitutions.set(v.name, init);
    var strippedName = (v.name.charAt(0) == "_") ? v.name.substr(1) : v.name;
    if (strippedName != v.name) {
        substitutions.set(strippedName, init);
    }

    // CHANGE: Don't eliminate here - let the builder decide
    // Return the original expression, preprocessor will handle substitution
    return expr;  // NOT TBlock([])
```

Wait, this won't work because the substitutions map is used later. Let me reconsider...

Actually, looking at the code more carefully, the substitutions ARE being registered correctly. The issue is that when the TSwitch is processed, it's not using the substitution.

### Alternative Solution: Fix the Substitution Application

The real bug is in processExpr for TSwitch (line 238):

```haxe
case TSwitch(e, cases, edef):
    var switchTarget = switch(e.expr) {
        case TLocal(v) if (isInfrastructureVar(v.name) && !substitutions.exists(v.name)):
            // ERROR: This check is WRONG!
            // It only handles UNDEFINED vars, not DEFINED ones
            e;
        default:
            e;
    };
```

**THE FIX**:

```haxe
case TSwitch(e, cases, edef):
    // Check if switch target is an infrastructure variable WITH substitution
    var switchTarget = switch(e.expr) {
        case TLocal(v) if (isInfrastructureVar(v.name)):
            if (substitutions.exists(v.name)) {
                // Apply substitution!
                substitutions.get(v.name);
            } else {
                // Undefined infrastructure var - keep as-is
                e;
            }
        default:
            // Not an infrastructure var - process normally
            processExpr(e, substitutions);
    };

    processSwitchExpr(switchTarget, cases, edef, expr.pos, expr.t, substitutions);
```

### Step 3: Fix Empty Block Context Handling (IMMEDIATE)

```haxe
// In ElixirASTPrinter.hx - print function (line 1053)
case EBlock(expressions):
    if (expressions.length == 0) {
        // Check metadata for context
        var inExpr = ast.metadata?.inExpressionContext == true;
        inExpr ? 'nil' : '';
    }
```

But we also need to MARK the context when building. Let me trace through where empty blocks come from...

Empty blocks come from:
1. Infrastructure variable elimination (TVar returns TBlock([]))
2. Empty function bodies
3. Eliminated branches

For infrastructure variable elimination, the empty block should NEVER be in expression context because the variable was only created to hold a value temporarily. If it appears in an expression context, it means something went wrong.

Actually, looking at the json_printer.ex bug:
```elixir
if c == nil, do: , else:
```

This suggests that BOTH branches of the if are empty blocks. Looking at the Haxe source would help, but I don't have it. However, the fix is clear: when printing EBlock([]) in an expression context (like if branches), print 'nil' instead of ''.

---

## Recommended Implementation Plan

### 1. Fix Infrastructure Variable Substitution (Bug 1)

**File**: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/preprocessor/TypedExprPreprocessor.hx`
**Lines**: 238-252

**Change**:
```haxe
case TSwitch(e, cases, edef):
    // BEFORE: Only handled undefined infrastructure vars
    // AFTER: Handle both defined and undefined
    var switchTarget = switch(e.expr) {
        case TLocal(v) if (isInfrastructureVar(v.name)):
            // Check if we have a substitution for this variable
            if (substitutions.exists(v.name)) {
                #if debug_infrastructure_vars
                trace('[processExpr TSwitch] Substituting ${v.name} with registered expression');
                #end
                substitutions.get(v.name);  // Use the substituted expression
            } else {
                #if debug_infrastructure_vars
                trace('[processExpr TSwitch] Infrastructure var ${v.name} has no substitution - keeping as-is');
                #end
                e;
            }
        default:
            // Not an infrastructure variable - process normally
            processExpr(e, substitutions);
    };

    processSwitchExpr(switchTarget, cases, edef, expr.pos, expr.t, substitutions);
```

### 2. Add Expression Context Propagation (Bug 2)

**File**: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirAST.hx`
**Lines**: Add to ElixirMetadata typedef

```haxe
typedef ElixirMetadata = {
    // ... existing fields
    ?inExpressionContext: Bool,  // Is this node in an expression context?
}
```

**File**: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirASTBuilder.hx`
**Multiple locations**: Mark expression context when building if/case/etc.

```haxe
// When building TIf expressions (find the location in ElixirASTBuilder)
case TIf(econd, eif, eelse):
    // ... compile condition

    // Compile branches and mark as expression context
    var thenAst = compileExpressionImpl(eif, false);
    if (thenAst != null) {
        if (thenAst.metadata == null) thenAst.metadata = {};
        thenAst.metadata.inExpressionContext = true;
    }

    var elseAst = eelse != null ? compileExpressionImpl(eelse, false) : makeAST(ENil);
    if (elseAst != null) {
        if (elseAst.metadata == null) elseAst.metadata = {};
        elseAst.metadata.inExpressionContext = true;
    }
```

### 3. Context-Aware Empty Block Printing (Bug 2)

**File**: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirASTPrinter.hx`
**Lines**: 1053-1057

**Change**:
```haxe
case EBlock(expressions):
    if (expressions.length == 0) {
        // CRITICAL: Check if we're in an expression context
        // Expression contexts (if branches, case branches, etc.) must return a value
        var inExprCtx = ast.metadata != null && ast.metadata.inExpressionContext == true;

        #if debug_ast_printer
        trace('[Printer] Empty block in ${inExprCtx ? "expression" : "statement"} context');
        #end

        if (inExprCtx) {
            'nil';  // Expression context - must return a value
        } else {
            '';     // Statement context - no code needed
        }
    }
```

---

## Testing Strategy

### Test 1: Infrastructure Variable with Preceding Conditional
```haxe
function test(msg: Dynamic): String {
    if (!validate(msg)) {
        return "invalid";
    }

    return switch (msg.type) {
        case "a": "A";
        case "b": "B";
        default: "unknown";
    };
}
```

**Expected Output**:
```elixir
def test(msg) do
    if not validate(msg) do
        "invalid"
    end

    case Map.get(msg, :type) do  # NOT: case g do
        "a" -> "A"
        "b" -> "B"
        _ -> "unknown"
    end
end
```

### Test 2: Empty Blocks in Expression Context
```haxe
function test(x: Null<Int>): Int {
    return if (x == null) {
        // Empty then branch
    } else {
        // Empty else branch
    }
}
```

**Expected Output**:
```elixir
def test(x) do
    if x == nil, do: nil, else: nil  # NOT: do: , else:
end
```

---

## Summary

**Root Cause**: Infrastructure variable elimination happens at TypedExpr level, but the substitution is not applied to TSwitch expressions that reference the eliminated variable.

**Definitive Fix**: Modify TypedExprPreprocessor to apply substitutions to TSwitch targets that reference infrastructure variables.

**Secondary Issue**: Empty blocks print as empty strings regardless of context, causing syntax errors in expression positions.

**Secondary Fix**: Add context metadata to AST nodes and use it in the printer to return 'nil' for empty blocks in expression contexts.

**Impact**: Both bugs fixed with minimal changes to existing architecture, no major refactoring needed.
