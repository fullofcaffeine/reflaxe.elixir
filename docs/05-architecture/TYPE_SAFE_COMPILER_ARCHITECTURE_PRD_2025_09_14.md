# Type-Safe Compiler Architecture PRD
**Date**: September 14, 2025
**Author**: AI Development Assistant
**Status**: Draft
**Priority**: High

## Executive Summary

The Reflaxe.Elixir compiler currently uses a single, overly-generic `ElixirAST` type for all GenericCompiler type parameters, defeating the purpose of type safety and making the codebase harder to understand and maintain. This PRD proposes splitting `ElixirAST` into specific, well-documented types that properly leverage GenericCompiler's architecture.

## Problem Statement

### Current Issues

1. **Type Safety Lost**: Using `ElixirAST` for everything is like using `Dynamic` - we lose compile-time guarantees
2. **Poor Documentation**: ElixirAST variants aren't well-documented, making it unclear what each represents
3. **Architectural Mismatch**: Not following Reflaxe's intended patterns (as seen in C#, Go compilers)
4. **Debugging Difficulty**: Can't tell from types what a function should return
5. **Maintenance Burden**: New developers can't understand expected return types

### Current Architecture (Incorrect)
```haxe
class ElixirCompiler extends GenericCompiler<
    ElixirAST,  // Classes - too generic!
    ElixirAST,  // Enums - too generic!
    ElixirAST,  // Expressions - too generic!
    ElixirAST,  // Typedefs - too generic!
    ElixirAST   // Abstracts - too generic!
>
```

## Proposed Solution

### New Type-Safe Architecture

Create specific AST types for different language levels:

```haxe
class ElixirCompiler extends GenericCompiler<
    ElixirTopLevel,   // Classes → Top-level modules
    ElixirTopLevel,   // Enums → Top-level modules
    ElixirExpr,       // Expressions → Expression AST
    ElixirTopLevel,   // Typedefs → Top-level modules
    ElixirTopLevel    // Abstracts → Top-level modules
>
```

### New AST Type Definitions

#### 1. ElixirTopLevel - Module-Level Constructs
```haxe
/**
 * Represents top-level Elixir constructs (modules, behaviors, protocols)
 * Used as return type for compileClassImpl, compileEnumImpl, etc.
 */
enum ElixirTopLevel {
    /**
     * Elixir module definition
     * @param name Full module name (e.g., "TodoApp.User")
     * @param attributes Module attributes (@moduledoc, @behaviour, etc.)
     * @param body Module body (functions, macros, types)
     */
    TModule(name: String, attributes: Array<ElixirAttribute>, body: Array<ElixirModuleItem>);

    /**
     * Multiple modules in one file (rare but possible)
     */
    TMultiModule(modules: Array<ElixirTopLevel>);

    /**
     * Empty module (for abstracts with no runtime representation)
     */
    TEmpty;
}

enum ElixirModuleItem {
    MFunction(def: ElixirFunctionDef);
    MMacro(def: ElixirMacroDef);
    MType(def: ElixirTypeDef);
    MStruct(fields: Array<ElixirStructField>);
    MUse(module: String, opts: ElixirExpr);
    MImport(module: String, only: Array<String>);
    MAlias(module: String, as: String);
}
```

#### 2. ElixirExpr - Expression-Level Constructs
```haxe
/**
 * Represents Elixir expressions and statements
 * Used as return type for compileExpressionImpl
 */
enum ElixirExpr {
    // Literals
    EInt(value: Int);
    EFloat(value: Float);
    EString(value: String);
    EAtom(value: String);
    EBool(value: Bool);
    ENil;

    // Variables and identifiers
    EVar(name: String);
    EField(target: ElixirExpr, field: String);

    // Function calls
    ECall(target: ElixirExpr, func: String, args: Array<ElixirExpr>);
    ERemoteCall(module: String, func: String, args: Array<ElixirExpr>);

    // Data structures
    EList(items: Array<ElixirExpr>);
    ETuple(items: Array<ElixirExpr>);
    EMap(pairs: Array<{key: ElixirExpr, value: ElixirExpr}>);
    EStruct(type: String, fields: Array<{name: String, value: ElixirExpr}>);

    // Control flow
    EIf(cond: ElixirExpr, then: ElixirExpr, else_: Null<ElixirExpr>);
    ECase(expr: ElixirExpr, clauses: Array<ElixirClause>);
    ECond(clauses: Array<{cond: ElixirExpr, body: ElixirExpr}>);
    EWith(matches: Array<ElixirMatch>, body: ElixirExpr);

    // Pattern matching
    EMatch(left: ElixirPattern, right: ElixirExpr);

    // Functions
    EFn(clauses: Array<ElixirFnClause>);
    ECapture(module: String, func: String, arity: Int);

    // Binary operations
    EBinop(op: ElixirBinop, left: ElixirExpr, right: ElixirExpr);
    EUnop(op: ElixirUnop, expr: ElixirExpr);

    // Blocks and sequences
    EBlock(exprs: Array<ElixirExpr>);
    EPipe(exprs: Array<ElixirExpr>);

    // Special forms
    ETry(body: ElixirExpr, rescue: Array<ElixirRescue>, finally_: Null<ElixirExpr>);
    ERaise(exception: ElixirExpr);
    EThrow(value: ElixirExpr);

    // Comprehensions
    EFor(generators: Array<ElixirGenerator>, body: ElixirExpr);

    // Metadata (for transformer passes)
    EMeta(metadata: Dynamic, expr: ElixirExpr);
}
```

#### 3. ElixirPattern - Pattern Matching Constructs
```haxe
/**
 * Represents patterns used in pattern matching contexts
 */
enum ElixirPattern {
    PVar(name: String);
    PLiteral(value: ElixirExpr);
    PTuple(patterns: Array<ElixirPattern>);
    PList(patterns: Array<ElixirPattern>, tail: Null<ElixirPattern>);
    PMap(pairs: Array<{key: ElixirExpr, pattern: ElixirPattern}>);
    PStruct(type: String, fields: Array<{name: String, pattern: ElixirPattern}>);
    PPin(pattern: ElixirPattern);
    PAs(pattern: ElixirPattern, var: String);
    PWildcard;
}
```

## Implementation Plan

### Phase 1: Create New AST Types (Week 1)
1. Create `ElixirTopLevel.hx` with module-level types
2. Create `ElixirExpr.hx` with expression types
3. Create `ElixirPattern.hx` with pattern types
4. Add comprehensive documentation to each variant
5. Create conversion utilities between old and new types

### Phase 2: Update Compiler Signature (Week 2)
1. Change ElixirCompiler's GenericCompiler type parameters
2. Update compile method return types
3. Fix compilation errors in ElixirCompiler
4. Update test expectations

### Phase 3: Refactor AST Builder (Week 3-4)
1. Split ElixirASTBuilder into:
   - `ElixirTopLevelBuilder` for modules
   - `ElixirExprBuilder` for expressions
2. Update all build methods to return specific types
3. Integrate with CompilationContext

### Phase 4: Update Transformer (Week 5)
1. Create type-specific transformers:
   - `ElixirTopLevelTransformer`
   - `ElixirExprTransformer`
2. Update transformation passes for new types
3. Ensure all optimizations still work

### Phase 5: Update Printer (Week 6)
1. Create type-specific printers:
   - `ElixirTopLevelPrinter`
   - `ElixirExprPrinter`
2. Ensure output remains identical
3. Add type-based validation

### Phase 6: Testing and Migration (Week 7-8)
1. Update all snapshot tests
2. Ensure todo-app still compiles
3. Run parallel tests to verify
4. Update documentation

## Benefits

### Immediate Benefits
1. **Type Safety**: Compile-time guarantees about return types
2. **Better IDE Support**: Autocomplete knows exact types
3. **Clearer APIs**: Function signatures document themselves
4. **Easier Debugging**: Can see what type is expected vs actual

### Long-term Benefits
1. **Maintainability**: New developers understand the architecture
2. **Extensibility**: Easy to add new AST nodes to specific types
3. **Optimization**: Can optimize specific AST types differently
4. **Correctness**: Harder to return wrong AST type

## Success Criteria

1. ✅ All compile methods return appropriate specific types
2. ✅ Zero use of "ElixirAST" as a catch-all type
3. ✅ All AST variants have comprehensive documentation
4. ✅ Todo-app compiles and runs identically
5. ✅ All tests pass
6. ✅ Parallel test execution works
7. ✅ Code is easier to understand for new developers

## Risks and Mitigation

### Risk 1: Large Refactor Scope
**Mitigation**: Incremental migration with compatibility layer

### Risk 2: Breaking Existing Code
**Mitigation**: Keep old ElixirAST temporarily, migrate gradually

### Risk 3: Performance Impact
**Mitigation**: Benchmark before/after, optimize if needed

## Timeline

- **Week 1-2**: Type definitions and compiler signature
- **Week 3-4**: AST Builder refactor
- **Week 5**: Transformer updates
- **Week 6**: Printer updates
- **Week 7-8**: Testing and documentation
- **Total**: 8 weeks

## Dependencies

- CompilationContext refactor (completed)
- Current bug fixes (in progress)

## Open Questions

1. Should we keep ElixirAST as a legacy type temporarily?
2. How granular should the type separation be?
3. Should patterns be a separate type or part of expressions?

## Appendix: Reference Implementations

### C# Compiler (Reflaxe.CSharp)
```haxe
class CSCompiler extends GenericCompiler<CSTopLevel, CSTopLevel, CSStatement>
```

### Go Compiler (Reflaxe.Go)
```haxe
class Compiler extends GenericCompiler<AST.Class, AST.Enum, AST.Expr>
```

## Next Steps

1. Review and approve this PRD
2. Create detailed technical design document
3. Add tasks to Shrimp task manager
4. Begin Phase 1 implementation