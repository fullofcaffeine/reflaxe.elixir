# Haxe Optimization Pipeline Investigation

## TL;DR

**Question**: Can Reflaxe leverage Haxe's optimization pipeline instead of bypassing it?

**Answer**: **No, not out of the box.** Reflaxe's architecture fundamentally uses `Context.onAfterTyping` (pre-optimization) with `manualDCE: true` to bypass the optimizer. This design prioritizes type safety and cross-target consistency over optimization benefits.

**Current Reality**: All Reflaxe compilers inherit unoptimized AST patterns (orphaned variables, dead code, etc.) and must handle them manually.

**Potential Solution**: A hybrid two-phase approach using both `onAfterTyping` and `onGenerate`, but this would require **extending the Reflaxe framework itself**, not just our Elixir compiler.

**Pragmatic Conclusion**: Our current manual AST cleanup approach is the appropriate solution within Reflaxe's existing architecture.

## Overview

This document details our investigation into whether Reflaxe can leverage Haxe's optimization pipeline instead of bypassing it entirely. This research was prompted by the discovery that Reflaxe operates on unoptimized AST, leading to patterns like orphaned variables that must be manually handled.

## Background: The Optimization Bypass Problem

### Current Reflaxe Architecture
All Reflaxe compilers use `manualDCE: true` in their configuration, which bypasses Haxe's optimization phases:

```haxe
// Standard Reflaxe pattern across ALL target compilers
ReflectCompiler.AddCompiler(new ElixirCompiler(), {
    fileOutputExtension: ".ex",
    outputDirDefineName: "elixir_output", 
    fileOutputType: FilePerModule,
    ignoreTypes: [],
    targetCodeInjectionName: "__elixir__",
    ignoreBodilessFunctions: false,
    manualDCE: true  // ← This bypasses Haxe's optimizer
});
```

### Consequences of Optimization Bypass
- **Orphaned Variables**: Temporary variables generated but never meaningfully used
- **Dead Code**: Unreachable branches and unused assignments remain in AST
- **Constant Propagation**: Runtime constants not folded at compile time
- **Local DCE**: Unused local variables not eliminated
- **Expression Fusion**: Redundant intermediate expressions not merged

## Haxe Compilation Phases

### Phase 1: onAfterTyping (Pre-Optimization)
- **When**: After type checking, before optimization
- **AST State**: Unoptimized TypedExpr with all original patterns
- **Usage**: This is where Reflaxe currently hooks in
- **Characteristics**:
  - Contains all temporary variables
  - Includes dead code branches
  - No constant folding applied
  - All intermediate expressions present

### Phase 2: Optimization Pipeline
- **Static Analyzer**: Performs const propagation, local DCE, expression fusion
- **Dead Code Elimination**: Removes unreachable code and unused variables
- **Expression Simplification**: Optimizes complex expressions
- **Control Flow Analysis**: Eliminates redundant conditions

### Phase 3: onGenerate (Post-Optimization)
- **When**: After optimization, before final code generation
- **AST State**: Optimized TypedExpr with cleaned patterns
- **Usage**: Not currently used by Reflaxe
- **Characteristics**:
  - Orphaned variables eliminated
  - Dead code removed
  - Constants folded
  - Expressions simplified

## Experimental Investigation

### Test Setup
Created `OptimizationTestCompiler.hx` to compare AST between phases:

```haxe
// Hook into both phases to compare AST
Context.onAfterTyping(function(moduleTypes: Array<ModuleType>) {
    trace("========== onAfterTyping Phase (BEFORE optimization) ==========");
    analyzeAST(moduleTypes);
});

Context.onGenerate(function(types: Array<Type>) {
    trace("========== onGenerate Phase (AFTER optimization) ==========");
    analyzeAST(types);
});
```

### Test Cases
Created test patterns demonstrating common optimization scenarios:

```haxe
// Unused variable pattern
var unusedVar = 42;

// Constant condition pattern  
if (true) {
    trace("Always executed");
} else {
    trace("Dead code");
}

// Enum parameter extraction pattern
switch (option) {
    case Some(value):
        // Empty case body - creates orphaned 'value' parameter
        return;
    case None:
        return;
}
```

### Results
**Unexpected Finding**: Both phases showed similar AST structure with minimal optimization visible.

**Possible Explanations**:
1. **Test Code Too Simple**: Our test patterns may not trigger significant optimizations
2. **Optimization Flags**: May need specific compiler flags to enable optimization
3. **Target-Dependent**: Optimization may be more aggressive for other targets
4. **Debug Mode**: Optimization may be disabled in debug builds

## Hybrid Compilation Approach (Proposed)

### Two-Phase Strategy
Instead of choosing between phases, use both strategically:

1. **Phase 1 (onAfterTyping)**: Type Information Collection
   - Extract type definitions and metadata
   - Build type mapping tables
   - Collect annotation information
   - Generate type declarations

2. **Phase 2 (onGenerate)**: Code Generation
   - Generate actual function implementations
   - Benefit from optimized AST
   - Reduced orphaned variable handling
   - Cleaner expression compilation

### Implementation Concept
```haxe
class HybridElixirCompiler {
    static var typeDefinitions: Map<String, String> = new Map();
    
    public static function Start() {
        // Phase 1: Collect type information before optimization
        Context.onAfterTyping(function(moduleTypes: Array<ModuleType>) {
            for (mt in moduleTypes) {
                switch (mt) {
                    case TClassDecl(c):
                        var classType = c.get();
                        typeDefinitions.set(classType.name, extractTypeInfo(classType));
                    case TEnumDecl(e):
                        var enumType = e.get();
                        typeDefinitions.set(enumType.name, extractEnumInfo(enumType));
                }
            }
        });
        
        // Phase 2: Generate code using optimized AST
        Context.onGenerate(function(types: Array<Type>) {
            for (type in types) {
                generateOptimizedCode(type, typeDefinitions);
            }
        });
    }
}
```

## Benefits of Hybrid Approach

### Optimization Advantages
- **Reduced Manual Cleanup**: Less need for orphaned variable detection
- **Better Performance**: Generated code benefits from Haxe's optimizations
- **Cleaner Output**: Fewer temporary variables and dead code patterns
- **Simplified Compiler**: Less complex AST cleanup logic needed

### Type Safety Preservation
- **Complete Type Information**: Collected before any optimization
- **Annotation Preservation**: Metadata extracted at typing phase
- **Interface Consistency**: Type definitions remain complete

### Development Benefits
- **Easier Debugging**: Optimized AST is cleaner to work with
- **Reduced Complexity**: Less special case handling needed
- **Better Maintainability**: Fewer workarounds for optimization artifacts

## Implementation Challenges

### Technical Hurdles
1. **Reflaxe Integration**: Current architecture assumes single-phase compilation
2. **State Management**: Need to preserve type information between phases
3. **Coordination**: Ensuring consistency between type and code generation
4. **Error Handling**: Managing errors across multiple phases

### Compatibility Concerns
1. **Reflaxe Changes**: May require modifications to base Reflaxe framework
2. **Target Differences**: Other Reflaxe targets might not benefit equally
3. **Breaking Changes**: Existing compiler customizations might break

## Next Steps

### Proof of Concept
1. **Enhanced Testing**: Create more complex test cases to trigger optimization
2. **Flag Investigation**: Test with different optimization flags enabled
3. **AST Comparison**: Detailed diff between onAfterTyping and onGenerate AST
4. **Performance Measurement**: Quantify benefits of optimized vs unoptimized compilation

### Implementation Planning
1. **Reflaxe Extension**: Design API extensions needed for hybrid approach
2. **Migration Strategy**: Plan transition from current single-phase approach
3. **Compatibility Layer**: Ensure existing code continues to work
4. **Documentation**: Update all compiler development documentation

## Conclusion

The investigation reveals a potential pathway to leverage Haxe's optimization pipeline through a hybrid two-phase compilation approach. While current test results show minimal optimization differences, this may be due to test case limitations rather than fundamental impossibility.

**Key Insight**: Instead of choosing between onAfterTyping (unoptimized) and onGenerate (optimized), we can strategically use both phases for their respective strengths - type collection and code generation.

This approach could significantly reduce the complexity of handling unoptimized AST patterns like orphaned variables, while preserving the complete type information needed for robust transpilation.

## Related Documentation
- [ADR-001: Handling Unoptimized AST](ADR-001-handling-unoptimized-ast.md) - Current orphaned variable solution
- [AST Cleanup Patterns](../03-compiler-development/AST_CLEANUP_PATTERNS.md) - Manual optimization handling
- [Compiler Development CLAUDE.md](../03-compiler-development/CLAUDE.md) - Development context

## Test Files
- `src/reflaxe/elixir/OptimizationTestCompiler.hx` - Experimental dual-phase compiler
- `test/tests/optimization_pipeline/` - Test cases for optimization investigation