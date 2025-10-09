# Variable Substitution Patterns Guide

> **Parent Context**: See [AGENTS.md](AGENTS.md) for compiler development context

This guide covers the comprehensive variable substitution system used in Reflaxe.Elixir for transforming variable names and references throughout AST structures.

## 🎯 Overview

**Variable Substitution** is the process of systematically replacing variable references in an AST with different names or expressions. This is critical for generating idiomatic Elixir code, especially for lambda expressions, loop transformations, and parameter mappings.

## 🔄 Core Substitution Patterns

### 1. Lambda Parameter Substitution
**Problem**: Haxe lambda parameters may have non-idiomatic names

**Example Transformation**:
```haxe
// Haxe source
items.map(function(arg0) return arg0 * 2);

// After substitution
items.map(function(item) return item * 2);
```

**Implementation**:
```haxe
function substituteLambdaParameter(expr: TypedExpr, oldName: String, newName: String): TypedExpr {
    return switch(expr.expr) {
        case TFunction(tf):
            // Substitute in function body
            var newBody = substituteInExpression(tf.expr, oldName, newName);
            // Update parameter name
            tf.args[0].v.name = newName;
            {expr: TFunction(tf), pos: expr.pos, t: expr.t};
            
        default:
            expr;
    };
}
```

### 2. Loop Variable Substitution
**Problem**: For-loop variables need transformation for Enum operations

**Example Transformation**:
```haxe
// Haxe source
for (i in items) {
    process(i);
}

// After substitution (conceptual)
Enum.each(items, fn item -> process(item) end)
```

**Implementation Pattern**:
```haxe
function substituteLoopVariable(loop: TypedExpr, items: TypedExpr): String {
    var loopVar = extractLoopVariable(loop);
    var body = extractLoopBody(loop);
    
    // Substitute variable in body
    var substitutedBody = substituteInExpression(body, loopVar, "item");
    
    return 'Enum.each(${compileExpression(items)}, fn item -> ${substitutedBody} end)';
}
```

### 3. Nested Scope Substitution
**Problem**: Variables in nested scopes need careful handling

**Scope Tracking**:
```haxe
class ScopeTracker {
    var scopes: Array<Map<String, String>> = [];
    
    public function enterScope() {
        scopes.push(new Map());
    }
    
    public function exitScope() {
        scopes.pop();
    }
    
    public function addSubstitution(oldName: String, newName: String) {
        if (scopes.length > 0) {
            scopes[scopes.length - 1].set(oldName, newName);
        }
    }
    
    public function getSubstitution(name: String): Null<String> {
        // Search from innermost to outermost scope
        for (i in 0...scopes.length) {
            var scope = scopes[scopes.length - 1 - i];
            if (scope.exists(name)) {
                return scope.get(name);
            }
        }
        return null;
    }
}
```

## 🔍 Substitution Algorithm

### Recursive AST Traversal
```haxe
public function substituteInExpression(expr: TypedExpr, oldName: String, newName: String): String {
    return switch(expr.expr) {
        case TLocal(v) if (v.name == oldName):
            // Direct substitution
            newName;
            
        case TField(e, fa):
            // Substitute in object expression
            var obj = substituteInExpression(e, oldName, newName);
            obj + "." + fieldName(fa);
            
        case TCall(e, el):
            // Substitute in function and arguments
            var func = substituteInExpression(e, oldName, newName);
            var args = el.map(arg -> substituteInExpression(arg, oldName, newName));
            func + "(" + args.join(", ") + ")";
            
        case TBinop(op, e1, e2):
            // Substitute in both operands
            var left = substituteInExpression(e1, oldName, newName);
            var right = substituteInExpression(e2, oldName, newName);
            left + " " + operatorString(op) + " " + right;
            
        case TBlock(exprs):
            // Substitute in all block expressions
            var substituted = exprs.map(e -> substituteInExpression(e, oldName, newName));
            substituted.join("\\n");
            
        case TIf(econd, eif, eelse):
            // Substitute in all branches
            var cond = substituteInExpression(econd, oldName, newName);
            var thenBranch = substituteInExpression(eif, oldName, newName);
            var elseBranch = eelse != null ? 
                substituteInExpression(eelse, oldName, newName) : "";
            'if ${cond} do\\n  ${thenBranch}\\n' + 
            (elseBranch != "" ? 'else\\n  ${elseBranch}\\nend' : 'end');
            
        case TVar(v, init) if (v.name == oldName):
            // Variable shadows the one we're substituting - stop here
            compileExpression(expr);
            
        case TVar(v, init):
            // Substitute in initialization if present
            var varName = v.name;
            if (init != null) {
                var initExpr = substituteInExpression(init, oldName, newName);
                '${varName} = ${initExpr}';
            } else {
                varName;
            }
            
        default:
            // No substitution needed
            compileExpression(expr);
    };
}
```

### Variable Shadowing Detection
```haxe
function detectShadowing(expr: TypedExpr, variableName: String): Bool {
    return switch(expr.expr) {
        case TVar(v, _) if (v.name == variableName):
            true;  // Variable is redeclared
            
        case TFunction(tf):
            // Check if any parameter shadows
            Lambda.exists(tf.args, arg -> arg.v.name == variableName);
            
        case TSwitch(_, cases, _):
            // Check if any case pattern shadows
            Lambda.exists(cases, c -> {
                patternIntroducesVariable(c.pattern, variableName);
            });
            
        default:
            false;
    };
}
```

## 📊 Substitution Strategies

### 1. Single-Pass Substitution
**Use Case**: Simple variable renaming with no nested scopes

```haxe
function singlePassSubstitute(expr: TypedExpr, oldName: String, newName: String): String {
    // Direct recursive substitution
    return substituteInExpression(expr, oldName, newName);
}
```

### 2. Multi-Pass Substitution
**Use Case**: Multiple variables need substitution

```haxe
function multiPassSubstitute(expr: TypedExpr, substitutions: Map<String, String>): String {
    var result = compileExpression(expr);
    
    // Apply each substitution
    for (oldName in substitutions.keys()) {
        var newName = substitutions.get(oldName);
        result = substituteInString(result, oldName, newName);
    }
    
    return result;
}
```

### 3. Context-Aware Substitution
**Use Case**: Different substitutions based on context

```haxe
function contextAwareSubstitute(expr: TypedExpr, context: SubstitutionContext): String {
    return switch(context.type) {
        case Lambda:
            substituteLambdaVariables(expr, context.lambdaParams);
            
        case Loop:
            substituteLoopVariables(expr, context.loopVars);
            
        case PatternMatch:
            substitutePatternVariables(expr, context.patternVars);
            
        default:
            compileExpression(expr);
    };
}
```

## 🧩 Advanced Patterns

### Capture Avoidance
**Problem**: Substitution must not capture free variables

```haxe
function avoidCapture(expr: TypedExpr, oldName: String, newName: String): String {
    // Collect all free variables in the expression
    var freeVars = collectFreeVariables(expr);
    
    // If newName would capture a free variable, rename it
    var safeName = newName;
    var counter = 0;
    while (freeVars.exists(safeName)) {
        counter++;
        safeName = newName + "_" + counter;
    }
    
    return substituteInExpression(expr, oldName, safeName);
}
```

### Hygenic Substitution
**Problem**: Maintain variable hygiene across transformations

```haxe
class HygenicSubstitution {
    var gensymCounter: Int = 0;
    
    public function gensym(base: String): String {
        gensymCounter++;
        return base + "_gen_" + gensymCounter;
    }
    
    public function substituteHygenic(expr: TypedExpr, oldName: String): String {
        var newName = gensym(oldName);
        return substituteInExpression(expr, oldName, newName);
    }
}
```

## ⚡ Performance Optimization

### Substitution Cache
```haxe
class SubstitutionCache {
    var cache: Map<String, Map<String, String>> = new Map();
    
    public function getCached(expr: String, oldName: String, newName: String): Null<String> {
        var key = expr + "|" + oldName + "|" + newName;
        return cache.get(key);
    }
    
    public function cache(expr: String, oldName: String, newName: String, result: String) {
        var key = expr + "|" + oldName + "|" + newName;
        cache.set(key, result);
    }
}
```

### Batch Substitution
```haxe
function batchSubstitute(expr: TypedExpr, substitutions: Array<{old: String, new: String}>): String {
    // Build substitution map for single pass
    var subMap = new Map<String, String>();
    for (sub in substitutions) {
        subMap.set(sub.old, sub.new);
    }
    
    // Single traversal with multiple substitutions
    return substituteWithMap(expr, subMap);
}
```

## 🧪 Testing Substitution

### Test Framework
```haxe
class SubstitutionTest {
    static function testBasicSubstitution() {
        var input = parseExpr("x + y * x");
        var result = substitute(input, "x", "z");
        assert(result == "z + y * z");
    }
    
    static function testShadowingRespected() {
        var input = parseExpr("x + (var x = 5; x * 2)");
        var result = substitute(input, "x", "z");
        assert(result == "z + (var x = 5; x * 2)");
    }
    
    static function testNestedScopes() {
        var input = parseExpr("function(x) { return x + y; }");
        var result = substitute(input, "y", "z");
        assert(result == "function(x) { return x + z; }");
    }
}
```

### Debug Tracing
```haxe
#if debug_substitution
function traceSubstitution(expr: TypedExpr, oldName: String, newName: String) {
    trace('[Substitution] Replacing "${oldName}" with "${newName}"');
    trace('[Substitution] Input: ${expr}');
    var result = substituteInExpression(expr, oldName, newName);
    trace('[Substitution] Output: ${result}');
    return result;
}
#end
```

## 🔧 Integration Guidelines

### Compiler Integration Points
```haxe
// In ElixirCompiler.hx
public function compileWithSubstitution(expr: TypedExpr, substitutions: Map<String, String>): String {
    if (substitutions.empty()) {
        return compileExpression(expr);
    }
    
    // Use substitution compiler for complex substitutions
    return substitutionCompiler.substitute(expr, substitutions);
}
```

### Common Use Cases
1. **Enum operations**: Loop variable → lambda parameter
2. **Pattern matching**: Case variables → pattern variables  
3. **Function composition**: Parameter threading
4. **Macro expansion**: Template variable substitution

## 📚 Related Documentation

- **[SubstitutionCompiler.hx](../../src/reflaxe/elixir/helpers/SubstitutionCompiler.hx)** - Implementation source
- **[AST_CLEANUP_PATTERNS.md](AST_CLEANUP_PATTERNS.md)** - AST manipulation patterns
- **[COMPILATION_FLOW.md](COMPILATION_FLOW.md)** - Where substitution fits
- **[DEBUG_XRAY_SYSTEM.md](DEBUG_XRAY_SYSTEM.md)** - Debugging substitutions

---

This guide provides comprehensive coverage of variable substitution patterns in Reflaxe.Elixir. The goal is maintaining correctness while generating idiomatic Elixir code through intelligent variable transformations.