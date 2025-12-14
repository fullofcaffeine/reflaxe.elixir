# Product Requirements Document: Migration to GenericCompiler Architecture

## Executive Summary

This document outlines the critical architectural migration of the Reflaxe.Elixir compiler from `DirectToStringCompiler` to `GenericCompiler<ElixirAST>`, following the proven pattern established by Reflaxe.CSharp. This migration will resolve fundamental architectural tensions, fix the `__elixir__()` injection mechanism, and enable truly idiomatic Elixir code generation.

## Problem Statement

### Current Architecture Issues

The Reflaxe.Elixir compiler currently extends `DirectToStringCompiler`, which creates fundamental architectural tensions:

1. **Injection Mechanism Failure**: The built-in `__elixir__()` injection doesn't work because we bypass the normal expression compilation flow
2. **Architectural Mismatch**: DirectToStringCompiler expects incremental string building, but we use a full AST pipeline
3. **Debugging Nightmares**: Mixed string/AST approaches create complex debugging scenarios
4. **Band-aid Solutions**: We've accumulated workarounds (like injection handling in ElixirASTBuilder) that shouldn't exist
5. **Lost Reflaxe Features**: We can't leverage Reflaxe's built-in features properly due to architectural conflicts

### Why DirectToStringCompiler Fails for Elixir

DirectToStringCompiler works well for imperative, OOP languages (C++, Go) where:
- Classes map directly to target language classes
- Methods remain methods
- Inheritance exists natively
- Expressions can be translated incrementally

Elixir is fundamentally different:
- **Functional paradigm**: Requires complete structural transformations
- **No classes**: Must transform to modules + structs
- **No inheritance**: Must convert to delegation patterns
- **Immutability**: Loops must become recursion/comprehensions
- **Pattern matching**: Switch statements need complete restructuring

### The Injection Problem Explained

**How it should work (DirectToStringCompiler flow):**
```
compileExpression() 
  → checks for __elixir__() injection
  → if found, returns injected string directly
  → else calls compileExpressionImpl()
```

**What actually happens in our code:**
```
compileClassImpl()
  → buildClassAST() 
  → builds entire function body AST at once
  → never calls compileExpression() for individual expressions
  → injection check never runs!
```

Our band-aid: Detection in ElixirASTBuilder at lines 576-644, which shouldn't be necessary.

## Solution: GenericCompiler<ElixirAST> Architecture

### Precedent: Reflaxe.CSharp's Success

The C# compiler faced similar challenges and solved them elegantly:

```haxe
// C# uses GenericCompiler with AST types
class CSCompiler extends GenericCompiler<CSTopLevel, CSTopLevel, CSStatement> {
    // Returns AST nodes, not strings
    public function compileClassImpl(...): CSTopLevel
    public function compileExpressionImpl(...): CSStatement
    
    // Separate output iterator handles AST→String conversion
    public function generateOutputIterator(): Iterator<...>
}
```

This proves that AST-based compilation is not only viable but superior for complex language targets.

### Why GenericCompiler Is Right for Elixir

| Aspect | DirectToStringCompiler | GenericCompiler<ElixirAST> |
|--------|------------------------|---------------------------|
| **Architecture Fit** | Fighting the framework | Natural alignment |
| **Idiomatic Output** | Nearly impossible | Natural via AST transforms |
| **Multi-pass Optimization** | Can't revisit strings | Easy AST traversal |
| **Pattern Detection** | Fragile string parsing | Robust structural matching |
| **Debugging** | Mixed string/AST confusion | Clear phase separation |
| **Reflaxe Integration** | Bypassing features | Full feature access |

### Architectural Benefits

1. **Clean Separation of Concerns**
   - Building: TypedExpr → ElixirAST
   - Transformation: ElixirAST → ElixirAST (optimized)
   - Printing: ElixirAST → String

2. **Proper Injection Handling**
   - Can detect injection at the right level
   - No band-aids needed
   - Works with Reflaxe's design

3. **Enables Sophisticated Transformations**
   - Convert OOP patterns to functional idioms
   - Optimize comprehensions
   - Generate idiomatic pattern matching

## Implementation Plan

### Phase 1: Create Output Iterator

**New file:** `src/reflaxe/elixir/ElixirOutputIterator.hx`

```haxe
@:access(reflaxe.elixir.ElixirCompiler)
class ElixirOutputIterator {
    var compiler: ElixirCompiler;
    var index: Int;
    var maxIndex: Int;
    
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        index = 0;
        maxIndex = compiler.classes.length + compiler.enums.length;
    }
    
    public function hasNext(): Bool {
        return index < maxIndex;
    }
    
    public function next(): DataAndFileInfo<StringOrBytes> {
        final ast = getNextAST();
        final transformed = ElixirASTTransformer.transform(ast);
        final output = ElixirASTPrinter.print(transformed, 0);
        return dataAndFileInfo.withOutput(output);
    }
}
```

### Phase 2: Update ElixirCompiler Base Class

**Change inheritance:**
```haxe
// FROM:
class ElixirCompiler extends DirectToStringCompiler

// TO:
class ElixirCompiler extends GenericCompiler<ElixirAST, ElixirAST, ElixirAST, ElixirAST, ElixirAST>
```

**Update method signatures:**
```haxe
public function compileClassImpl(...): ElixirAST {
    return buildClassAST(classType, varFields, funcFields);
}

public function compileEnumImpl(...): ElixirAST {
    return buildEnumAST(enumType, options);
}

public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): ElixirAST {
    return ElixirASTBuilder.buildFromTypedExpr(expr);
}
```

### Phase 3: Handle Injection Properly

```haxe
public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): ElixirAST {
    // Check for __elixir__ injection
    switch(expr.expr) {
        case TCall(e, args):
            switch(e.expr) {
                case TIdent("__elixir__") | TLocal({name: "__elixir__"}):
                    return handleElixirInjection(args);
                default:
            }
        default:
    }
    return super.compileExpression(expr, topLevel);
}
```

### Phase 4: Remove Deprecated Code

**Delete:**
- All string concatenation methods in ElixirCompiler
- The `compileExpressionViaAST` wrapper
- Band-aid injection handling in ElixirASTBuilder (lines 576-644)
- Unused string manipulation utilities
- Legacy pattern matching string builders

### Phase 5: Implement generateOutputIterator

```haxe
public function generateOutputIterator(): Iterator<DataAndFileInfo<StringOrBytes>> {
    return new ElixirOutputIterator(this);
}
```

## Success Criteria

1. **All snapshot tests pass** (`npm test`)
2. **Todo-app compiles without errors or warnings**
3. **Todo-app runs correctly** (`mix phx.server`)
4. **`__elixir__()` injection works without band-aids**
5. **Clean architecture with clear phase separation**
6. **No deprecated string manipulation code remains**

## Risk Mitigation

1. **Incremental Migration**: Each phase can be tested independently
2. **Git Checkpoint**: Commit before starting (already done: fae97aa)
3. **Preserve Working Code**: Keep all AST infrastructure (builder, transformer, printer)
4. **Follow Proven Pattern**: C# compiler validates this approach

## Long-term Benefits

1. **Maintainability**: Clear architecture makes future changes easier
2. **Debuggability**: Each phase can be debugged independently
3. **Extensibility**: Easy to add new transformations
4. **Performance**: Single AST pass instead of string manipulation
5. **Correctness**: Working with Reflaxe's design, not against it

## Technical Debt Eliminated

- Remove ~500+ lines of deprecated string manipulation code
- Eliminate band-aid fixes and workarounds
- Remove architectural friction with Reflaxe
- Clean up mixed string/AST confusion

## Conclusion

This migration from DirectToStringCompiler to GenericCompiler<ElixirAST> is not just a refactoring—it's a fundamental architectural correction that aligns our compiler with Reflaxe's design patterns and enables truly idiomatic Elixir code generation. The C# compiler has proven this approach works, and our existing AST infrastructure makes the migration straightforward.

The key insight: **Elixir is too different from imperative OOP languages to use DirectToStringCompiler effectively**. By embracing GenericCompiler with AST types, we're choosing the architecture that matches our target language's needs.

## References

- Reflaxe.CSharp implementation: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/reflaxe.CSharp/`
- Current problematic code: `ElixirCompiler.hx`, `ElixirASTBuilder.hx` (lines 576-644)
- Reflaxe documentation: `reflaxe/src/reflaxe/GenericCompiler.hx`

## Appendix: Key Code Locations

### Files to Modify
1. `src/reflaxe/elixir/ElixirCompiler.hx` - Major refactor
2. `src/reflaxe/elixir/ast/ElixirASTBuilder.hx` - Remove injection band-aid
3. `src/reflaxe/elixir/ElixirOutputIterator.hx` - New file

### Critical Sections to Update
- ElixirCompiler class declaration (line ~50)
- compileClassImpl method (lines 335-358)
- compileEnumImpl method (lines 364-379)
- compileExpressionImpl method (lines 309-313)
- Remove compileExpressionViaAST (lines 309-313)
- Remove injection detection in ElixirASTBuilder (lines 576-644)

## Version History

- v1.0 (2024-12-30): Initial PRD documenting migration from DirectToStringCompiler to GenericCompiler<ElixirAST>