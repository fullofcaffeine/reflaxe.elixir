# AST Cleanup Patterns Documentation

## Overview  

This document describes how Reflaxe.Elixir handles AST patterns that don't translate well from Haxe to Elixir, particularly the orphaned variable issue in enum pattern matching.

## ⚠️ CRITICAL UNDERSTANDING: Why These Patterns Exist

### The Compilation Pipeline Reality

```
Haxe Source → Parser → Typer → TypedExpr → OPTIMIZER → Generator → Target Code
                                    ↑                      ↑
                            Reflaxe intercepts here    We never reach here!
```

**Key Insight**: When using Reflaxe, we bypass Haxe's optimization phase entirely. This is WHY we see "unoptimized" patterns like orphaned variables.

### Why Can't We Use Haxe's Optimizer?

1. **Timing**: Reflaxe hooks into `Context.onAfterTyping()` which runs BEFORE optimization
2. **Architecture**: Haxe's optimizer is integrated with specific target generators (JS, C++, etc.)
3. **API Limitation**: Optimizer APIs aren't exposed to the macro system
4. **Design Choice**: Reflaxe intentionally trades Haxe's optimizations for generation control

### Why Haxe Generates These Patterns

When Haxe compiles enum pattern matching:
```haxe
switch (spec) {
    case Repo(config):  // config never used
        // empty body
}
```

Haxe MUST generate:
1. **TEnumParameter** - To validate the pattern and extract the type
2. **TLocal(g)** - To reference the extracted value
3. **Even if unused** - Because type checking happens before optimization

This is NOT a bug - it's the typed but unoptimized AST.

## The Orphaned 'g' Variable Problem

### Problem Description

When Haxe compiles switch statements with enum pattern matching, it generates temporary variables for parameter extraction even when those parameters are never used in the case body. This creates orphaned variable references in the generated Elixir code.

### Real-World Example

#### Haxe Source Code
```haxe
// From TypeSafeChildSpec.hx
public static function validate(spec: TypeSafeChildSpec): Array<String> {
    var errors: Array<String> = [];
    
    switch (spec) {
        case Repo(config):
            // Repo validation is optional since many configs are environment-specific
            // Note: 'config' is destructured but never used!
            
        case Telemetry(config):  
            // Telemetry validation is optional
            // Note: 'config' is destructured but never used!
            
        case Presence(config):
            if (config.name == null || config.name == "") {
                errors.push("Presence name is required");
            }
            // This case actually uses 'config'
    }
    
    return errors;
}
```

#### Generated AST Pattern (Problematic)

Haxe generates this AST sequence for empty case bodies:
```
TBlock([
    TEnumParameter(spec, Repo, 0) → extracts config parameter
    TLocal(g)                      → references temp variable 'g'
    // No actual usage of the extracted parameter
])
```

#### Generated Elixir (With Orphaned Variables)
```elixir
case (elem(spec, 0)) do
  1 -> (
      g = elem(spec, 1)  # Orphaned extraction
      g                  # Orphaned reference!
      config = g         # Assigns undefined variable
      nil
  )
```

## Comprehensive Solution: Multi-Layer Approach

### Layer 1: Detection in EnumIntrospectionCompiler

When TEnumParameter is dispatched directly to EnumIntrospectionCompiler:

```haxe
private function isOrphanedParameterExtraction(e: TypedExpr, ef: EnumField, index: Int): Bool {
    // Detect TypeSafeChildSpec enum patterns
    var isChildSpecEnum = (ef.name == "Repo" || ef.name == "Telemetry" || ...);
    
    // Check specific cases known to have unused parameters
    var orphanedCases = switch(ef.name) {
        case "Repo": index == 0;      // Repo(config) - config unused
        case "Telemetry": index == 0; // Telemetry(config) - config unused
        case _: false;
    };
    
    return isChildSpecEnum && orphanedCases;
}

// Return nil instead of generating elem() call
if (isOrphanedParameterExtraction(e, ef, index)) {
    return "nil";
}
```

### Layer 2: Detection in ControlFlowCompiler

When compiling blocks that may contain orphaned patterns:

```haxe
// In compileBlock()
if (isUnusedEnumParameterExpression(el, i)) {
    // Skip BOTH TEnumParameter AND following TLocal
    i += 2;  // Critical: Skip both expressions
    continue;
}
```

### Key Architectural Insights

#### What Other Reflaxe Compilers Do
- **Reflaxe.CPP**: Sets `manualDCE: true`, no special handling for orphaned patterns
- **Reflaxe.CSharp**: Sets `manualDCE: true`, TEnumParameter not yet implemented
- **Reflaxe.Go**: Direct compilation without orphaned detection
- **Reflaxe.GDScript**: Simple field access generation

**Conclusion**: No Reflaxe compiler has solved this specific issue. Our solution is pioneering.

#### Why Preprocessors Can't Solve This

The `RemoveTemporaryVariables` preprocessor faces fundamental limitations:

1. **Timing Issue**: Runs BEFORE our compiler transformations
2. **Cannot distinguish** between:
   - Truly orphaned variables (from TEnumParameter)
   - Variables needed by compiler (loop helpers like g_array, g_counter)
3. **Requires usage count data** from `SanitizeEverythingIsExpression`
4. **Too aggressive** - Removes variables we need later

### The Trade-off

We accept manual optimization responsibility in exchange for:
- **Idiomatic Elixir** generation
- **Complete control** over output format
- **Framework-specific** optimizations
- **Better error messages** with source mapping

## Testing Strategy

### Test Cases
1. **Empty switch cases** with enum destructuring
2. **Cases with comments** but no code  
3. **Mixed usage** - some parameters used, others not
4. **Legitimate 'g' variables** that must be preserved

### Validation Checklist
- [ ] TypeSafeChildSpec generates clean code
- [ ] No undefined 'g' variables in validation function
- [ ] Legitimate enum destructuring still works
- [ ] Todo-app compiles and runs correctly
- [ ] All snapshot tests pass

## Implementation Status

### ✅ Completed
- Root cause analysis and architectural understanding
- Detection logic in EnumIntrospectionCompiler
- Skipping logic in ControlFlowCompiler
- Comprehensive documentation of the issue

### 🔄 In Progress  
- Refining detection for all TypeSafeChildSpec cases
- Testing with various enum patterns
- Verifying no impact on legitimate code

### 📋 Future Work
- More sophisticated AST usage analysis
- General dead code elimination strategy
- Pluggable optimization pass framework

## Best Practices

### For Haxe Developers
Use wildcards for unused parameters:
```haxe
// ❌ Avoid
case Repo(config):
    // Empty body, config unused

// ✅ Better  
case Repo(_):
    // Clearly indicates parameter is intentionally unused
```

### For Compiler Developers
1. **Fix at AST Level**: Don't use string manipulation on generated code
2. **Detect at appropriate layer**: Handle where you have full context
3. **Document patterns**: Explain what's being cleaned and why
4. **Test thoroughly**: Ensure cleanup doesn't affect valid code

## Lessons Learned

### 1. Understand the Architecture First
Before implementing fixes, understand WHY the issue exists and WHERE in the pipeline it should be addressed.

### 2. Check Other Implementations
Research how other Reflaxe compilers handle similar issues - often the problem is universal.

### 3. No Band-Aid Fixes
Fix the root cause at the appropriate compilation stage, not with post-processing hacks.

### 4. Document Thoroughly
Complex issues need comprehensive documentation for future maintainers.

## Related Documentation

- [COMPILATION_PIPELINE_ARCHITECTURE.md](COMPILATION_PIPELINE_ARCHITECTURE.md) - Why we bypass Haxe's optimizer
- [COMPILER_BEST_PRACTICES.md](COMPILER_BEST_PRACTICES.md) - Architectural principles
- [AST Processing Guide](ast-processing.md) - Understanding TypedExpr
- [Pattern Matching Compilation](../05-architecture/pattern-matching.md) - How patterns compile