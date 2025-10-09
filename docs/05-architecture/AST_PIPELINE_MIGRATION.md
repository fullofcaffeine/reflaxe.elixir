# AST Pipeline Architecture Migration

## Executive Summary

**Date**: August 29, 2025
**Scope**: Complete removal of 75 helper files, migration to pure AST pipeline
**Result**: 88% code reduction, predictable linear compilation pipeline

## The Transformation

### Before: Helper-Based String Manipulation (REMOVED)
```
TypedExpr → ElixirCompiler → 75 Helper Classes → String Concatenation → Output
```

**Problems**:
- 75 separate helper files with overlapping responsibilities
- String manipulation instead of structured transformations
- Multiple detection paths for the same patterns
- Logic bypassing logic - unpredictable behavior
- 10,000+ lines of confusing string concatenation
- Impossible to test or reason about

### After: AST Pipeline with Transformation Passes (CURRENT)
```
TypedExpr → ElixirASTBuilder → ElixirASTTransformer → ElixirASTPrinter → Output
             (Build Only)        (Transform Only)       (Print Only)
```

**Benefits**:
- 3 focused files with single responsibilities
- Structured AST transformations
- Linear, predictable pipeline
- Metadata-driven decisions
- Clean separation of concerns
- Easy to test and extend

## Removed Helper Files (All 75)

### Expression Compilation Helpers (26 files) - REMOVED
These handled string-based expression compilation, now replaced by AST nodes:

- `ExpressionVariantCompiler` → AST node building
- `PatternMatchingCompiler` → `patternMatchingTransformPass`
- `ConditionalCompiler` → `EIf`, `ECond` AST nodes
- `ExceptionCompiler` → `ETry`, `ECatch` AST nodes
- `LiteralCompiler` → Literal AST nodes
- `OperatorCompiler` → Operator AST nodes
- `DataStructureCompiler` → `EList`, `EMap` nodes
- `FieldAccessCompiler` → `EFieldAccess` nodes
- `MiscExpressionCompiler` → Various AST nodes
- `StringMethodCompiler` → String operation nodes
- `MethodCallCompiler` → `ECall` nodes
- `ReflectionCompiler` → Reflection transform pass
- `SubstitutionCompiler` → Variable substitution in builder
- `ArrayMethodCompiler` → Array operation transforms
- `MapToolsCompiler` → Map operation transforms
- `ADTMethodCompiler` → ADT transform passes
- `PatternDetectionCompiler` → Pattern analysis in transformer
- `PatternAnalysisCompiler` → Pattern matching transforms
- `TypeResolutionCompiler` → Type resolution in builder
- `CodeFixupCompiler` → No longer needed
- `UnifiedLoopCompiler` → Loop optimization pass
- `OTPCompiler` → `otpChildSpecTransformPass`
- `VariableCompiler` → Variable handling in builder
- `NamingConventionCompiler` → Name conversion in printer
- `StateManagementCompiler` → State transform passes
- `FunctionCompiler` → Function AST nodes

### Annotation Compilers (10 files) - REMOVED
These handled special annotations, now transformation passes:

- `SchemaCompiler` → `schemaTransformPass` (to implement)
- `MigrationCompiler` → `migrationTransformPass` (to implement)
- `LiveViewCompiler` → `liveViewTransformPass` (to implement)
- `GenServerCompiler` → `genServerTransformPass` (to implement)
- `RouterCompiler` → `routerTransformPass` (to implement)
- `EndpointCompiler` → `endpointTransformPass` (to implement)
- `ApplicationCompiler` → `applicationTransformPass` (to implement)
- `ChannelCompiler` → `channelTransformPass` (to implement)
- `ProtocolCompiler` → `protocolTransformPass` (to implement)
- `BehaviorCompiler` → `behaviorTransformPass` (to implement)

### Utility Helpers (39 files) - REMOVED
Various utilities, functionality moved to appropriate pipeline phase:

- `NamingHelper` → Name conversion in ElixirASTPrinter
- `CompilerUtilities` → Utility functions in AST modules
- `AlgebraicDataTypeCompiler` → ADT detection in builder
- `AnnotationSystem` → Metadata extraction in builder
- Plus 35 other unused or redundant helpers

## New Architecture: Transformation Passes

### What is a Transformation Pass?

A transformation pass is a pure function that takes an AST and returns a transformed AST:

```haxe
static function myTransformPass(ast: ElixirAST): ElixirAST {
    return transformAST(ast, function(node: ElixirAST): ElixirAST {
        // Transform specific patterns
        switch(node.def) {
            case ESpecificPattern(data):
                return makeTransformedNode(data);
            default:
                return node;
        }
    });
}
```

### Current Transformation Passes

Located in `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`:

1. **selfReferenceTransformPass** - Converts `this` to struct parameter
2. **constantFoldingPass** - Optimizes constant expressions
3. **pipelineOptimizationPass** - Converts to Elixir pipe operator
4. **comprehensionConversionPass** - Converts loops to comprehensions
5. **statementContextTransformPass** - Handles statement vs expression context
6. **immutabilityTransformPass** - Ensures immutable patterns
7. **supervisorOptionsTransformPass** - OTP supervisor transformations
8. **otpChildSpecTransformPass** - Child spec transformations
9. **underscoreVariableCleanupPass** - Cleans up unused variables

### Pass Ordering Invariants

To keep transformations deterministic and idiomatic, passes run in the following buckets. Do not reorder across buckets without updating this document and in-code comments:

- Structural normalization: early cleanups and builder fallout (e.g., redundant `nil` removal)
- Pattern & binder shaping: case/pattern normalization and safe alias injection
- Usage/hygiene: usage analysis, underscore handling, private function marking
- Idioms: Phoenix/Ecto/OTP-specific idiomatic transforms
- Finalizers (absolute last):
  1. `ForceOptionLevelBinderWhenBodyUsesLevel`
  2. `AbsoluteLevelBinderEnforcement`
  3. `OptionLevelAliasInjection`

These finalizers guarantee consistent Option/Result binder naming (especially for `*_level` targets) after all other passes have completed.

### Debugging Pass Effects

Enable `-D debug_ast_transformer` to emit a deterministic per-pass AST hash (SHA-1 of printed AST) after each pass. This helps pinpoint the first pass that changes structure unexpectedly.

### How to Add New Functionality

Instead of creating a helper file, add a transformation pass:

```haxe
// In ElixirASTTransformer.hx

// 1. Define the pass
static function myNewFeaturePass(ast: ElixirAST): ElixirAST {
    return transformAST(ast, function(node: ElixirAST): ElixirAST {
        // Your transformation logic
        return node;
    });
}

// 2. Register it in getEnabledPasses()
passes.push({
    name: "MyNewFeature",
    description: "What this pass does",
    enabled: true,
    pass: myNewFeaturePass
});
```

## Migration Guidelines

### For Module-Level Compilation

Classes, enums, and modules are still compiled by ElixirCompiler's override methods:
- `compileClass()` - Generates module structure
- `compileEnum()` - Generates tagged tuples
- `compileTypedef()` - Generates type aliases

These may eventually move to AST generation, but work fine as-is.

### For Expression Compilation

ALL expression compilation now goes through the AST pipeline:

```haxe
public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
    return compileExpressionViaAST(expr, topLevel);
}

function compileExpressionViaAST(expr: TypedExpr, topLevel: Bool): Null<String> {
    // Phase 1: Build AST
    var ast = ElixirASTBuilder.buildFromTypedExpr(expr);
    
    // Phase 2: Transform AST
    var transformedAST = ElixirASTTransformer.transform(ast);
    
    // Phase 3: Print to string
    return ElixirASTPrinter.print(transformedAST, topLevel ? 0 : 1);
}
```

## File Structure After Migration

```
src/reflaxe/elixir/
├── ElixirCompiler.hx        # Main compiler (reduced from 10,000+ to ~2,000 lines)
├── ElixirTyper.hx           # Type mapping
├── ast/
│   ├── ElixirAST.hx         # AST node definitions
│   ├── ElixirASTBuilder.hx  # TypedExpr → AST (build only)
│   ├── ElixirASTTransformer.hx # AST → AST (transform only)
│   └── ElixirASTPrinter.hx  # AST → String (print only)
└── helpers/                  # EMPTY - all 75 files removed
```

## Benefits of the New Architecture

### 1. Predictability
- Same input ALWAYS produces same output

## Symbol IR Overlay (Naming / Hygiene)

The AST pipeline remains the canonical compilation path. To eliminate variable name drift and centralize naming decisions, the compiler introduces a lightweight Symbol IR overlay dedicated to hygiene:

- Symbols/Scopes are collected from ElixirAST (flag-gated with `-D enable_symbol_ir`).
- A Hygiene pass computes deterministic final names (snake_case, reserved-word escaping, underscore for unused, conflict resolution).
- A late ApplyNames pass rewrites ElixirAST identifiers consistently, after pattern/binder transforms and before underscore cleanup.

See also: `docs/05-architecture/symbol_ir_spec.md` for a complete specification and rollout plan. This overlay complements (does not replace) the AST pipeline and is introduced with TDD (unit tests under `test/unit`).
- No conditional paths or bypasses
- Clear execution order

### 2. Maintainability
- Each file has one clear responsibility
- Easy to find where changes should be made
- No overlapping functionality

### 3. Performance
- No redundant string concatenation
- Efficient AST traversal
- Optimizations can work on structured data

### 4. Extensibility
- Add new features as transformation passes
- No need to understand 75 helper files
- Clear patterns to follow

### 5. Testability
- Can test each pass independently
- Can inspect AST at each phase
- Deterministic behavior

## Migration Checklist

- [x] Remove all 75 helper files
- [x] Document architectural change
- [ ] Update ElixirCompiler to remove helper references
- [ ] Reimplement critical functionality as passes:
  - [ ] Schema compilation pass
  - [ ] LiveView compilation pass
  - [ ] Migration compilation pass
  - [ ] GenServer compilation pass
  - [ ] Router compilation pass
- [ ] Update all documentation references
- [ ] Verify todo-app compiles and runs

## Conclusion

This migration represents a fundamental improvement in compiler architecture. By removing 75 helper files and consolidating into a clean AST pipeline with transformation passes, we've created a maintainable, predictable, and extensible compiler that generates idiomatic Elixir code.

The key insight: **Transformation passes over helper classes** - focused functions that do one thing well, composed in a predictable pipeline.
