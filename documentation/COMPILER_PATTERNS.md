# Compiler Development Patterns

This document captures key patterns and lessons learned during Reflaxe.Elixir compiler development, serving as a reference for future development and debugging.

## Table of Contents

- [Core Principles](#core-principles)
- [AST Transformation Patterns](#ast-transformation-patterns)
- [Variable Substitution](#variable-substitution)
- [Documentation Generation](#documentation-generation)
- [Error Handling](#error-handling)
- [Testing Patterns](#testing-patterns)
- [HXX Template Compilation Patterns](#hxx-template-compilation-patterns)
- [Common Pitfalls](#common-pitfalls)

## Core Principles

### 1. Never Leave TODOs in Production Code
**Rule**: Fix issues immediately, don't leave placeholders.

```haxe
// ❌ BAD: Leaving placeholders
// TODO: Need to substitute variables

// ✅ GOOD: Implement the substitution
var substitutedExpr = compileExpressionWithVarMapping(expr, sourceVar, targetVar);
```

**Why**: TODOs accumulate technical debt and indicate incomplete implementation.

### 2. Pass TypedExpr Through Pipeline as Long as Possible
**Rule**: Keep AST nodes (TypedExpr) until the very last moment before string generation.

```haxe
// ❌ BAD: Converting to strings early
var condition = compileExpression(conditionExpr);
var substituted = condition.replace(sourceVar, targetVar); // String manipulation

// ✅ GOOD: AST-level transformation
var substitutedExpr = compileExpressionWithSubstitution(conditionExpr, sourceVar, targetVar);
var condition = compileExpression(substitutedExpr);
```

**Why**: AST provides structural information for proper transformations. String manipulation is fragile and error-prone.

### 3. Apply Transformations at AST Level, Not String Level
**Rule**: Use recursive AST traversal for variable substitution and transformations.

```haxe
// ✅ Implementation pattern
function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
    return switch (expr.expr) {
        case TLocal(v): v.name == sourceVar ? targetVar : v.name;
        case TCall(e, el): 
            var compiledExpr = compileExpressionWithSubstitution(e, sourceVar, targetVar);
            var compiledArgs = el.map(arg -> compileExpressionWithSubstitution(arg, sourceVar, targetVar));
            // ... generate call with substituted components
        // ... handle other expression types
    }
}
```

**Benefits**: Type-safe, handles nested expressions, catches edge cases.

## AST Transformation Patterns

### Variable Substitution Pattern
**Problem**: Lambda parameters need different names than original loop variables.

**Solution**:
1. Find source variable in AST using `findLoopVariable(expr: TypedExpr)`
2. Apply recursive substitution with `compileExpressionWithSubstitution()`
3. Generate consistent lambda parameter names (`"item"`)

```haxe
// Input: numbers.map(n -> n * 2)
// Output: Enum.map(numbers, fn item -> item * 2 end)

// Implementation
var loopVar = findLoopVariable(transformExpr);
if (loopVar != null) {
    var substitutedBody = compileExpressionWithSubstitution(transformExpr, loopVar, "item");
    return 'Enum.map(${arrayExpr}, fn item -> ${substitutedBody} end)';
}
```

### Context-Aware Compilation
**Pattern**: Use flags to track compilation context for different behavior.

```haxe
class ElixirCompiler {
    var isInLoopContext: Bool = false;
    
    function compileWhileLoop(...) {
        var previousContext = isInLoopContext;
        isInLoopContext = true;
        // ... compile loop body
        isInLoopContext = previousContext; // Restore context
    }
    
    function shouldSubstituteVariable(varName: String): Bool {
        return isInLoopContext && isCommonLoopVariable(varName);
    }
}
```

### Function Call Pattern Detection
**Use Case**: Optimize `array.map(transform)` to `Enum.map(array, transform)` instead of lambda wrapper.

```haxe
// Pattern detection in generateEnumMapPattern()
var itemCallPattern = ~/^item\(([^)]+)\)$/;
if (itemCallPattern.match(transformation)) {
    var originalFunctionName = itemCallPattern.matched(1);
    if (originalFunctionName == "v") { // Renamed by Haxe
        return 'Enum.map(${arrayExpr}, transform)';
    }
}
```

## Variable Substitution

### System Variable Protection
**Pattern**: Protect certain variables from aggressive substitution.

```haxe
function isSystemVariable(varName: String): Bool {
    return switch (varName) {
        case "_g" | "_g1" | "_g2": true; // Generated variables
        case "temp_result" | "temp_option": true; // Temporary variables
        case name if (name.startsWith("_")): true; // Convention: underscore = system
        default: false;
    }
}
```

### Loop Variable Detection
**Pattern**: Identify variables that should be substituted in loop contexts.

```haxe
function isCommonLoopVariable(varName: String): Bool {
    return switch (varName) {
        case "i" | "j" | "k": true; // Classic loop counters
        case "item" | "elem" | "element": true; // Collection iteration
        case "id" | "index" | "idx": true; // Index variables
        case "n" | "num" | "number": true; // Numeric iteration
        default: false;
    }
}
```

## Documentation Generation

### Multi-line Documentation Detection
**Issue**: JavaDoc with newlines was being forced into single-line format, causing truncation.

**Solution**: Preserve original multi-line intent during cleaning.

```haxe
public static function cleanJavaDoc(docString: String): String {
    var lines = docString.split("\n");
    var wasMultiLine = lines.length > 1;
    
    // ... clean the documentation
    
    // Preserve multi-line format intent
    if (wasMultiLine && !result.contains("\n") && result.length > 0) {
        result = result + "\n"; // Force multi-line formatting
    }
    
    return result;
}
```

### String Escaping for Documentation
**Issue**: Using template strings with `${}` for documentation caused truncation when backquotes were present.

```haxe
// ❌ BAD: Unsafe template strings
return baseIndent + docType + ' "${cleanDoc}"';

// ✅ GOOD: Proper escaping
var escapedDoc = cleanDoc.split('"').join('\\"').split('\\').join('\\\\');
return baseIndent + docType + ' "' + escapedDoc + '"';
```

## Error Handling

### Compilation Error Patterns
**Pattern**: Always provide context and actionable error messages.

```haxe
// ❌ BAD: Generic error
throw "Compilation failed";

// ✅ GOOD: Contextual error
throw 'Failed to compile ${exprType} expression at ${pos}: ${reason}. 
       Consider using ${suggestedFix}';
```

### Graceful Degradation
**Pattern**: When compilation fails, generate valid fallback code with TODO comments.

```haxe
function compileComplexExpression(expr: TypedExpr): String {
    try {
        return attemptAdvancedCompilation(expr);
    } catch (e: Dynamic) {
        trace('Warning: Advanced compilation failed for ${expr}, using fallback');
        return '# TODO: Advanced compilation failed - ${e}\nnil';
    }
}
```

## Testing Patterns

### Snapshot Testing Philosophy
**Pattern**: Use snapshot tests for compiler output validation.

```haxe
// Test structure
test/tests/feature_name/
├── compile.hxml          # Compilation configuration
├── Main.hx              # Test source code
├── intended/            # Expected output
│   └── *.ex files
└── out/                 # Generated output (for comparison)
```

**Commands**:
- `haxe test/Test.hxml test=feature_name` - Run specific test
- `haxe test/Test.hxml update-intended` - Accept new output as correct

### Test-Driven Development for Compiler Features
1. **RED**: Write test that fails with current compiler
2. **GREEN**: Implement minimal fix to make test pass
3. **REFACTOR**: Improve implementation without breaking test

## Common Pitfalls

### 1. Hardcoded Variable Lists
**Problem**: Maintaining hardcoded lists of variables to substitute.

```haxe
// ❌ BAD: Hardcoded list
var aggressiveSubstitutionVars = ["i", "j", "item", "id"];

// ✅ GOOD: Function-based detection
function shouldSubstituteVariable(varName: String): Bool {
    return isCommonLoopVariable(varName) && !isSystemVariable(varName);
}
```

### 2. String Manipulation Instead of AST
**Problem**: Trying to fix compilation issues with string replacement.

```haxe
// ❌ BAD: Post-compilation string fixing
var output = compile(expr);
output = output.replace("wrong", "correct");

// ✅ GOOD: Fix at AST level
var correctedExpr = transformExpressionAST(expr);
var output = compile(correctedExpr);
```

### 3. Context-Blind Compilation
**Problem**: Applying the same compilation rules everywhere without considering context.

```haxe
// ❌ BAD: Context-blind
function compileVariable(varName: String): String {
    return aggressiveSubstitution ? "item" : varName; // Wrong!
}

// ✅ GOOD: Context-aware
function compileVariable(varName: String): String {
    if (isInLoopContext && shouldSubstituteVariable(varName)) {
        return "item";
    }
    return varName;
}
```

### 4. Ignoring Target Idioms
**Problem**: Generating syntactically correct but non-idiomatic target code.

```haxe
// ❌ BAD: Syntactically correct but not idiomatic
array.map(n -> n * 2)  // Generates: Enum.map(array, fn item -> item * 2 end)

// ✅ GOOD: Detect function reference pattern
array.map(transform)   // Generates: Enum.map(array, transform)
```

## HXX Template Compilation Patterns

### 1. HTML Attribute Function Name Conversion ✅ **RESOLVED (2025-08-17)**

**Issue**: HTML attributes and regular interpolations used different processing paths, causing inconsistent function name conversion.

**Previous Evidence**:
```haxe
// In UserLive.hx template:
<span class={getStatusClass(user.active)}>     // ❌ Was staying as getStatusClass
    ${getStatusText(user.active)}              // ✅ Was becoming get_status_text  
</span>

// Previously generated UserLive.ex:
<span class={getStatusClass(user.active)}>    // ❌ Function name not converted
    <%= get_status_text(user.active) %>       // ✅ Function name correctly converted
</span>
```

**Root Cause Identified**: 
The regex pattern in `convertFunctionNames()` used word boundaries (`\b`) which don't match after special characters like `{`. HTML attributes like `class={getStatusClass(...)}` weren't being processed because the word boundary `\b` failed to match after the `{` character.

**Solution Applied**:
Updated the regex pattern in `HxxCompiler.convertFunctionNames()` from:
```haxe
// ❌ OLD: Word boundary fails after { character
var functionPattern = ~/\b([a-z][a-zA-Z]*)(\\s*\()/g;

// ✅ NEW: Delimiter-aware pattern handles all contexts
var functionPattern = ~/(^|[^a-zA-Z0-9_])([a-z][a-zA-Z]*)(\s*\()/g;
```

**Current Result**:
```haxe
// In UserLive.hx template:
<span class={getStatusClass(user.active)}>     // ✅ Now converts properly
    ${getStatusText(user.active)}              // ✅ Still works as before
</span>

// Generated UserLive.ex:
<span class={get_status_class(user.active)}>  // ✅ Function name correctly converted
    <%= get_status_text(user.active) %>       // ✅ Function name correctly converted
</span>
```

**Technical Implementation**:
The new pattern preserves context delimiters while converting function names:
```haxe
return functionPattern.map(content, function(r) {
    var prefix = r.matched(1);      // Delimiter before function name
    var functionName = r.matched(2); // The actual function name
    var args = r.matched(3);         // Opening parenthesis
    var snakeCaseName = NamingHelper.toSnakeCase(functionName);
    return prefix + snakeCaseName + args;  // Preserve context
});
```

**Benefits Achieved**:
1. **Template Consistency**: Both interpolation types now have consistent function naming
2. **No Runtime Errors**: All function calls compile to valid snake_case Elixir functions
3. **Better Developer Experience**: Uniform Haxe→Elixir conversion across all template contexts
4. **Regex Robustness**: Pattern now handles any delimiter context (braces, spaces, start of string)

**Status**: ✅ **COMPLETELY RESOLVED** - All HXX templates now generate consistent, idiomatic Elixir code.

### 2. Function Name Conversion Pipeline

**Pattern**: The HxxCompiler uses a multi-stage transformation pipeline:

```haxe
compileHxxTemplate(expr) 
    → reconstructTemplate(expr)      // AST → TemplateNode
    → processPhoenixPatterns(data)   // Apply Elixir conventions  
    → convertFunctionNames(content)  // camelCase → snake_case
    → wrapInHEExSigil(content)      // Add ~H sigil
```

**Best Practice**: Function name conversion should happen at the AST level, not string level, for better reliability and context awareness.

**Implementation**: 
```haxe
// ✅ GOOD: AST-level conversion in compileFunctionCall()
var elixirMethod = NamingHelper.toSnakeCase(fieldName);
return FunctionCallNode(obj, elixirMethod, args);

// ⚠️ CURRENT: String-level conversion as fallback
var functionPattern = ~/\b([a-z][a-zA-Z]*)(\\s*\()/g;
return functionPattern.map(content, function(r) {
    return NamingHelper.toSnakeCase(r.matched(1)) + r.matched(2);
});
```

### 3. Template Context Awareness

**Pattern**: HXX templates need different processing based on context:
- Content interpolation: `<%= expression %>`
- Attribute interpolation: `attr={expression}`
- Component props: `<.component prop={expression}>`

**Current Implementation**: Context tracking exists but may not be used consistently:
```haxe
class TemplateContext {
    public var isInAttributeValue: Bool = false;  // Defined but not used
    public var isInComponent: Bool = false;
    public var depth: Int = 0;
}
```

**Recommendation**: Implement context-aware function name conversion based on interpolation type.

## Best Practices Summary

1. **Keep AST as long as possible** - Transform at AST level, not string level
2. **Use context flags** - Track compilation state for context-aware decisions
3. **Protect system variables** - Don't substitute compiler-generated variables
4. **Test-driven development** - Write failing tests before implementing features
5. **Document patterns** - Capture lessons learned for future reference
6. **Generate idiomatic code** - Follow target language conventions, not just syntax
7. **Provide helpful errors** - Include context and suggestions in error messages
8. **Never leave TODOs** - Fix issues immediately rather than deferring

## References

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall compiler architecture
- [TESTING_PRINCIPLES.md](TESTING_PRINCIPLES.md) - Testing methodology
- [TASK_HISTORY.md](TASK_HISTORY.md) - Historical implementation decisions