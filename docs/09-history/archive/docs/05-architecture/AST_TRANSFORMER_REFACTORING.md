# ElixirASTTransformer Refactoring Proposal

## Executive Summary

The ElixirASTTransformer class has grown to 2329 lines, exceeding our 2000-line maintainability limit. This document proposes splitting it into a modular architecture with separate transformation passes, following patterns from successful Reflaxe compilers.

## Current Problems

1. **File Size**: 2329 lines violates our maintainability standards
2. **Mixed Responsibilities**: Contains 10+ different transformation passes in one file
3. **Difficult Navigation**: Hard to find specific transformations
4. **Testing Challenges**: Can't test individual passes in isolation
5. **Merge Conflicts**: Large file increases likelihood of conflicts

## Proposed Architecture

### Package-Based Organization (Recommended Approach)

Keep `ElixirASTTransformer.hx` as the main orchestrator file but extract transformation logic into a subpackage:

```
src/reflaxe/elixir/
├── ast/
│   ├── ElixirAST.hx                  # AST type definitions (unchanged)
│   ├── ElixirASTBuilder.hx            # TypedExpr → ElixirAST (unchanged)
│   ├── ElixirASTPrinter.hx            # ElixirAST → String (unchanged)
│   ├── ElixirASTTransformer.hx        # Main orchestrator (~500 lines)
│   └── transforms/                    # NEW: Subpackage for transformation logic
│       ├── ITransformPass.hx          # Interface for all passes
│       ├── TransformContext.hx        # Shared context/utilities
│       ├── PatternMatchingTransform.hx
│       ├── ComprehensionTransform.hx
│       ├── TupleOptimizationTransform.hx
│       ├── VariableRenamingTransform.hx
│       ├── PipelineOptimizationTransform.hx
│       ├── MapMergeOptimizationTransform.hx
│       ├── SupervisorOptionsTransform.hx
│       ├── ChildSpecTransform.hx
│       ├── GenServerCallbackTransform.hx
│       ├── UnusedVariableTransform.hx
│       ├── EmptyBlockRemovalTransform.hx
│       └── RedundantParenthesesTransform.hx
```

**Package Names**:
- Main AST package: `reflaxe.elixir.ast`
- Transforms subpackage: `reflaxe.elixir.ast.transforms`

This approach:
- Keeps the main `ElixirASTTransformer.hx` in its current location
- Creates a clean subpackage hierarchy under `ast.transforms`
- Maintains backwards compatibility with existing imports
- Follows Haxe package conventions (flat structure in transforms)

### Interface Design

```haxe
// ast/transforms/ITransformPass.hx
package reflaxe.elixir.ast.transforms;

interface ITransformPass {
    /**
     * Pass metadata for debugging and configuration
     */
    var name(default, null): String;
    var description(default, null): String;
    var priority(default, null): Int; // Execution order
    
    /**
     * Check if this pass should run
     */
    function isEnabled(context: TransformContext): Bool;
    
    /**
     * Execute the transformation
     */
    function transform(ast: ElixirAST, context: TransformContext): ElixirAST;
```

### Transform Context

```haxe
// ast/transforms/TransformContext.hx
package reflaxe.elixir.ast.transforms;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTDef;

class TransformContext {
    // Shared state between passes
    public var metadata: Map<String, Dynamic>;
    public var debugMode: Bool;
    public var targetVersion: String;
    
    // Common utilities
    public function transformNode(node: ElixirAST, fn: ElixirAST->ElixirAST): ElixirAST;
    public function makeAST(def: ElixirASTDef): ElixirAST;
    public function trace(message: String): Void;
}
```

### Main Orchestrator (Simplified)

```haxe
// ast/ElixirASTTransformer.hx (reduced to ~500 lines)
package reflaxe.elixir.ast;

import reflaxe.elixir.ast.transforms.*;

class ElixirASTTransformer {
    static var passes: Array<ITransformPass> = [];
    
    public static function registerDefaultPasses(): Void {
        // Core passes
        passes.push(new PatternMatchingTransform());
        passes.push(new ComprehensionTransform());
        passes.push(new TupleOptimizationTransform());
        passes.push(new VariableRenamingTransform());
        
        // Idiomatic passes
        passes.push(new PipelineOptimizationTransform());
        passes.push(new MapMergeOptimizationTransform());
        
        // OTP passes
        passes.push(new SupervisorOptionsTransform());
        passes.push(new ChildSpecTransform());
        passes.push(new GenServerCallbackTransform());
        
        // Cleanup passes
        passes.push(new UnusedVariableTransform());
        passes.push(new EmptyBlockRemovalTransform());
        passes.push(new RedundantParenthesesTransform());
        
        // Sort by priority
        passes.sort((a, b) -> a.priority - b.priority);
    }
    
    public static function transform(ast: ElixirAST): ElixirAST {
        var context = new TransformContext();
        var result = ast;
        
        for (pass in passes) {
            if (pass.isEnabled(context)) {
                #if debug_ast_transformer
                trace('[Transform] Running ${pass.name}');
                #end
                result = pass.transform(result, context);
            }
        }
        
        return result;
    }
    
    // Keep commonly used utility methods in main class
    // for backwards compatibility and convenience
    public static function makeAST(def: ElixirASTDef): ElixirAST {
        // Implementation
    }
    
    public static function transformNode(node: ElixirAST, fn: ElixirAST->ElixirAST): ElixirAST {
        // Recursive transformation helper
    }
}
```

## Migration Strategy

### Phase 1: Setup Infrastructure (Day 1)
1. Create `transforms/` directory structure
2. Define `ITransformPass` interface
3. Implement `TransformContext` with shared utilities
4. Update ElixirASTTransformer to use pass system

### Phase 2: Extract Passes (Days 2-3)
Extract in order of independence:
1. **Cleanup passes** - Least dependencies
2. **OTP passes** - Domain-specific, isolated
3. **Idiom passes** - Moderate complexity
4. **Core passes** - Most complex, may have interdependencies

### Phase 3: Testing & Validation (Day 4)
1. Run full test suite after each extraction
2. Verify todo-app still compiles
3. Performance benchmarking
4. Documentation updates

## Benefits

### Immediate Benefits
- **Maintainability**: Each pass is 200-500 lines
- **Testability**: Can unit test individual passes
- **Discoverability**: Clear organization by purpose
- **Parallelization**: Independent passes could run in parallel

### Long-term Benefits
- **Extensibility**: Easy to add new passes
- **Configurability**: Can enable/disable specific passes
- **Reusability**: Passes could be shared between Reflaxe compilers
- **Performance**: Can optimize pass ordering and execution

## Implementation Example

```haxe
// ast/transforms/PipelineOptimizationTransform.hx
package reflaxe.elixir.ast.transforms;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTDef;

class PipelineOptimizationTransform implements ITransformPass {
    public var name = "PipelineOptimization";
    public var description = "Convert nested function calls to pipeline operator";
    public var priority = 100; // Run early in idiom phase
    
    public function new() {}
    
    public function isEnabled(context: TransformContext): Bool {
        #if disable_pipeline_optimization
        return false;
        #else
        return true;
        #end
    }
    
    public function transform(ast: ElixirAST, context: TransformContext): ElixirAST {
        return context.transformNode(ast, transformToPipeline);
    }
    
    function transformToPipeline(node: ElixirAST): ElixirAST {
        // Actual transformation logic moved from ElixirASTTransformer
        switch (node.def) {
            case ECall(target, method, args):
                // Check if this can be converted to pipeline
                if (isPipelineCandidate(target)) {
                    return makeAST(EPipeline(extractPipelineStart(target), method, args));
                }
            case _:
        }
        return node;
    }
    
    // Helper methods specific to this transformation
    function isPipelineCandidate(expr: ElixirAST): Bool {
        // Logic to detect pipeline candidates
    }
    
    function extractPipelineStart(expr: ElixirAST): ElixirAST {
        // Extract the starting value for the pipeline
    }
}
```

## Comparison with Other Approaches

### Alternative 1: Separate Package (reflaxe.elixir.transforms)
Create a completely separate package at the same level as `ast`.
- **Pro**: Complete separation of concerns
- **Con**: Transforms are inherently part of AST processing

### Alternative 2: Helper Pattern (like ElixirCompiler)
Create TransformHelper classes similar to existing compiler helpers.
- **Pro**: Consistent with current architecture
- **Con**: "Helper" implies utility, not core functionality

### Alternative 3: Monolithic File
Keep all transformations in ElixirASTTransformer.hx.
- **Pro**: Everything in one place
- **Con**: 2300+ lines violates maintainability standards

## Why the ast.transforms Subpackage Approach

**The `reflaxe.elixir.ast.transforms` subpackage is optimal** because:
1. **Logical hierarchy**: Transforms are part of AST processing
2. **Clear ownership**: The `ast` package owns all AST-related code
3. **Package cohesion**: Related functionality stays together
4. **Import clarity**: `import reflaxe.elixir.ast.transforms.*` is intuitive
5. **Backwards compatibility**: Main transformer stays in place
6. **Similar to Reflaxe.CPP**: Uses subcompilers pattern successfully

## Next Steps

1. **Approval**: Review and approve this proposal
2. **Create Infrastructure**: Set up directory and interfaces
3. **Pilot Extraction**: Start with one simple pass (EmptyBlockRemoval)
4. **Iterate**: Extract remaining passes incrementally
5. **Documentation**: Update architecture docs

## Success Metrics

- [ ] ElixirASTTransformer < 200 lines
- [ ] All transformation passes < 500 lines each
- [ ] Test suite continues to pass
- [ ] Todo-app compiles and runs
- [ ] No performance regression

## Timeline

- **Day 1**: Infrastructure setup
- **Days 2-3**: Pass extraction
- **Day 4**: Testing and documentation
- **Total**: 4 days of focused work

This refactoring will significantly improve code maintainability and make the transformation pipeline more transparent and testable.