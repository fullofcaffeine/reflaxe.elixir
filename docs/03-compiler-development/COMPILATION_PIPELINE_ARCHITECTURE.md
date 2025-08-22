# Compilation Pipeline Architecture: Haxe → Reflaxe → Target

## Executive Summary

When using Reflaxe, we bypass Haxe's optimization phase entirely. This is an **intentional architectural design** that gives us full control over code generation at the cost of implementing our own optimizations.

## The Standard Haxe Compilation Pipeline

```
Source Code → Parser → Typer → TypedExpr → FILTERS/OPTIMIZER → DCE → Generator → Target Code
                                    ↑            ↑              ↑
                            onAfterTyping   onGenerate    (never reached
                            (we hook here)  (before_dce)   with Reflaxe)
```

### Key Phases

1. **Parsing**: Source → AST
2. **Typing**: AST → TypedExpr (fully typed)
3. **onAfterTyping**: Last point for additional typing
4. **Filters**: Various AST transformations
5. **onGenerate**: Actually called "before_dce" internally
6. **DCE**: Dead Code Elimination removes unused code
7. **Optimizer**: Static analyzer (const propagation, etc.)
8. **Generator**: Target-specific code generation

## The Reflaxe Pipeline

```
Source Code → Parser → Typer → TypedExpr → REFLAXE COMPILER → Target Code
                                    ↑
                            We intercept here
                        (bypass all optimizations)
```

### What We Get vs What We Miss

| We Get | We Miss |
|--------|---------|
| ✅ Fully typed AST | ❌ Dead Code Elimination |
| ✅ Type information | ❌ Static analyzer optimizations |
| ✅ Complete control | ❌ Const propagation |
| ✅ Direct generation | ❌ Loop unrolling |
| ✅ Custom patterns | ❌ Tail recursion optimization |

## Evidence from Reference Implementations

### Reflaxe.CPP Configuration
```haxe
// From reflaxe.CPP/src/cxxcompiler/CompilerInit.hx
ReflectCompiler.AddCompiler(new Compiler(), {
    manualDCE: true,  // ← Explicit manual DCE requirement
    // ... other options
});
```

### Reflaxe Core Hooks
```haxe
// From reflaxe/src/reflaxe/ReflectCompiler.hx
Context.onAfterTyping(onAfterTyping);   // Get TypedExpr here
Context.onAfterGenerate(onAfterGenerate); // Just starts compilation
```

## Why This Architecture?

### Haxe's Perspective
From the Haxe manual and source:
- **onGenerate** is misleadingly named - it's actually "before_dce"
- **DCE** runs after typing but before target generation
- **Optimizations** are target-specific (JS optimizer, C++ optimizer, etc.)
- **TypedExpr** contains all typing artifacts, even if unused

### Reflaxe's Design Choice
This is **intentional**, not a limitation:
1. **Full Control**: Generate exactly the target code we want
2. **Idiomatic Output**: Create natural-looking target language code
3. **Custom Patterns**: Implement target-specific optimizations
4. **Trade-off**: We handle optimizations ourselves

## Implications for Our Compiler

### The Orphaned Variable Problem
When Haxe compiles:
```haxe
switch (spec) {
    case Repo(config): // config never used
        // empty body
}
```

We receive:
```
TBlock([
    TEnumParameter(spec, Repo, 0),  // Extract parameter
    TLocal(g)                        // Reference temp variable
])
```

This is **expected behavior** because:
1. Haxe generates this for type validation
2. DCE would normally remove it
3. We receive it before DCE runs
4. We must handle the cleanup ourselves

### Our Solution Strategy

Since we can't use Haxe's optimizer, we implement:

1. **Reflaxe Preprocessors** (when applicable):
   ```haxe
   options.expressionPreprocessors = [
       SanitizeEverythingIsExpression({}),
       RemoveConstantBoolIfs,
       // etc.
   ];
   ```

2. **Compilation-Time Detection** (our approach):
   ```haxe
   // Detect and skip orphaned patterns during compilation
   if (isOrphanedEnumParameterPattern(expressions, i)) {
       i += 2; // Skip both expressions
       continue;
   }
   ```

## Validation and Testing

To verify this architecture:
1. Check if `-dce full` affects our output (it doesn't)
2. Observe TypedExpr contains unoptimized patterns
3. Note other Reflaxe compilers use `manualDCE: true`
4. See that preprocessors exist specifically for this gap

## Best Practices

Given this architecture:

1. **Always assume unoptimized AST**: The TypedExpr is typed but not optimized
2. **Handle cleanup at compilation**: Don't rely on post-processing
3. **Use AST analysis**: Detect patterns at the structural level
4. **Document optimizations**: Each optimization we implement should be documented
5. **Test thoroughly**: Without Haxe's optimizer, we must validate output quality

## References

- [Haxe Manual: Dead Code Elimination](https://haxe.org/manual/cr-dce.html)
- [Reflaxe.CPP Implementation](../reference/reflaxe.CPP/src/cxxcompiler/CompilerInit.hx)
- [Reflaxe Core Architecture](../reference/reflaxe/src/reflaxe/ReflectCompiler.hx)
- [Haxe Compiler Phases Discussion](https://community.haxe.org/t/generate-code-in-onaftertyping/540)

## Conclusion

The lack of automatic optimization in Reflaxe is **by design**, not a bug or limitation. It's the price we pay for the ability to generate idiomatic, controlled target code. Understanding this architecture is crucial for compiler development.