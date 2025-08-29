# Variable Mapping Architecture and the Underscore Prefix Issue

## Executive Summary

This document explains a critical architectural issue in VariableCompiler where function parameter mappings were not being properly trusted, leading to incorrect underscore prefixing. The issue reveals fundamental problems with mapping hierarchy and trust boundaries in the compiler.

## The Problem Manifestation

### Symptom 1: TypeSafeChildSpecBuilder Issue
```elixir
# Expected (correct):
def pubsub(app_name) do
  {Phoenix.PubSub, name: app_name}  # Uses app_name
end

# Actual (incorrect):
def pubsub(app_name) do
  {Phoenix.PubSub, name: _app_name}  # Wrong: _app_name doesn't exist!
end
```

### Symptom 2: Container Issue (after our broken fix)
```elixir
# Expected (correct):
def get(struct, _index) do
  elem(struct, _index)  # Uses _index (unused parameter)
end

# Actual with broken fix:
def get(struct, _index) do
  elem(struct, index)  # Wrong: index doesn't exist!
end
```

## Root Cause Analysis

### The Variable Naming Pipeline

```
1. FunctionCompiler Phase
   ├── Analyzes parameter usage in function body
   ├── Determines if parameter is used or unused
   ├── Creates mapping: originalName → finalName
   │   ├── Used: appName → app_name
   │   └── Unused: index → _index
   └── Stores in currentFunctionParameterMap

2. VariableCompiler Phase  
   ├── Receives TLocal variable reference
   ├── Needs to resolve: originalName → outputName
   └── PROBLEM: Multiple mapping sources with unclear priority
       ├── currentFunctionParameterMap (authoritative for parameters)
       ├── underscorePrefixMap (for internal variables)
       └── Metadata checks (-reflaxe.unused)
```

### The Architectural Flaw

The core issue is **mapping hierarchy confusion**:

1. **No Clear Authority**: Multiple systems can map the same variable name
2. **Trust Boundary Violation**: VariableCompiler doesn't trust FunctionCompiler's decisions
3. **Second-Guessing**: Adding logic to "filter" or "validate" mappings instead of trusting them
4. **Context Loss**: underscorePrefixMap from one context polluting another

## Why Band-Aid Fixes Failed

### Attempt 1: The TARGETED FIX
```haxe
// WRONG: Second-guessing the mapping
if (mappedName != null && !StringTools.startsWith(mappedName, "_")) {
    return mappedName;  // Only return if no underscore
}
```

**Why it failed**: This assumes underscore = wrong, but some parameters NEED underscores!

### Attempt 2: String Manipulation
```haxe
// WRONG: Post-processing the output
if (output.contains("_app_name")) {
    output = output.replace("_app_name", "app_name");
}
```

**Why it would fail**: Fixes symptoms, not causes. What about _other_name, _third_name, etc?

## The Correct Architecture

### Principle 1: Single Source of Truth
Each mapping system has exclusive authority over its domain:
- **currentFunctionParameterMap**: Authoritative for function parameters
- **underscorePrefixMap**: Only for non-parameter local variables
- **Metadata**: Fallback for edge cases

### Principle 2: Trust Boundaries
Once FunctionCompiler decides a parameter name, VariableCompiler MUST trust it completely.

### Principle 3: Lookup Hierarchy
```
1. Is it a function parameter? → Use currentFunctionParameterMap (TRUST IT)
2. Is it a local variable? → Check underscorePrefixMap
3. Has metadata hints? → Apply metadata rules
4. Default → Convert to snake_case
```

## The Proper Fix

```haxe
/**
 * Compile variable reference with proper mapping hierarchy
 * 
 * WHY: Variable references must respect the authoritative mapping 
 *      from their declaration context
 * WHAT: Resolves TLocal to proper Elixir variable name
 * HOW: Checks mappings in strict priority order:
 *      1. Function parameters (authoritative)
 *      2. Local variables (context-specific)
 *      3. Metadata hints (fallback)
 */
public function compileVariableReference(tvar: TVar, compiler: ElixirCompiler): String {
    var originalName = getOriginalVarName(tvar);
    
    // FIRST: Check ID-based mapping (most specific)
    if (idVariableMap.exists(tvar.id)) {
        return idVariableMap.get(tvar.id);
    }
    
    // SECOND: Check function parameter map - AUTHORITATIVE for parameters
    // Trust it completely - no filtering, no second-guessing
    if (compiler.currentFunctionParameterMap.exists(originalName)) {
        return compiler.currentFunctionParameterMap.get(originalName);
    }
    
    var snakeName = NamingHelper.toSnakeCase(originalName);
    if (compiler.currentFunctionParameterMap.exists(snakeName)) {
        return compiler.currentFunctionParameterMap.get(snakeName);
    }
    
    // THIRD: Check underscore prefix map for LOCAL variables only
    // This is for variables declared within the function, not parameters
    if (underscorePrefixMap.exists(originalName)) {
        return underscorePrefixMap.get(originalName);
    }
    if (underscorePrefixMap.exists(snakeName)) {
        return underscorePrefixMap.get(snakeName);
    }
    
    // FOURTH: Apply metadata rules as fallback
    if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
        if (!StringTools.startsWith(snakeName, "_")) {
            return "_" + snakeName;
        }
    }
    
    // DEFAULT: Standard snake_case conversion
    return snakeName;
}
```

## Refactoring Opportunities

### 1. Consolidate Variable Tracking
Instead of multiple maps, use a single hierarchical mapping system:
```haxe
class VariableMapping {
    var byId: Map<Int, String>;           // Most specific
    var byParameter: Map<String, String>; // Function parameters
    var byLocal: Map<String, String>;     // Local variables
    
    public function resolve(tvar: TVar): String {
        // Single method with clear hierarchy
    }
}
```

### 2. Explicit Context Boundaries
```haxe
class FunctionContext {
    var parameters: Map<String, String>;
    var locals: Map<String, String>;
    
    public function new(parent: FunctionContext = null) {
        // Inherit from parent but maintain boundaries
    }
}
```

### 3. Remove Redundant Checks
The current code has multiple ways to check the same thing. Consolidate to one clear path.

## Lessons for Future Development

### Rule 1: Trust Your Own Compiler
When one compiler phase makes a decision (like FunctionCompiler determining parameter names), other phases must trust it completely.

### Rule 2: Clear Mapping Hierarchy
Document and enforce which mapping system has authority for which variables.

### Rule 3: No String Manipulation Fixes
If you're doing string replacement on generated output, you're fixing symptoms, not causes.

### Rule 4: Test Multiple Scenarios
Always test both:
- Parameters that should have underscores (_index)
- Parameters that shouldn't (app_name)

### Rule 5: Document Mapping Decisions
Every variable mapping should document:
- WHO made the decision (which compiler phase)
- WHY it was made (used/unused analysis)
- WHEN it applies (function scope, module scope, etc.)

## Testing Requirements

Any fix to variable mapping must pass ALL these scenarios:

1. **Unused parameter with underscore**: `def get(struct, _index)` → uses `_index`
2. **Used parameter without underscore**: `def pubsub(app_name)` → uses `app_name`
3. **Local unused variable**: `var _temp = 5;` → declared and used as `_temp`
4. **Shadowed variables**: Inner scope variables with same name as outer
5. **Lambda parameters**: Different naming in nested functions

## Conclusion

The variable mapping issue is not about underscore prefixes - it's about **trust and authority** in a multi-phase compiler. Each phase must respect the decisions made by previous phases, and the lookup hierarchy must be crystal clear.

The fix is not to filter or validate mappings, but to establish and follow a clear hierarchy of authority.

## Related Documentation
- [Macro-Time vs Runtime](./macro-time-vs-runtime.md)
- [Testing Infrastructure](./testing-infrastructure.md)
- [Compiler Best Practices](./best-practices.md)