# Hygiene Transformations in Reflaxe.Elixir

## Overview

The Hygiene Transformation System is a sophisticated multi-pass AST transformation framework designed to eliminate compilation warnings and generate idiomatic Elixir code. This system addresses systematic hygiene issues in compiler-generated code through intelligent pattern detection and surgical AST modifications.

## Problem Statement

Prior to implementing hygiene transformations, the Reflaxe.Elixir compiler generated Elixir code with numerous hygiene issues:

- **390+ compilation warnings** per build cycle
- **Variable shadowing** causing "variable x is unused" warnings (25+ per file)
- **Incorrect underscore prefixing** - actually-used variables marked as unused
- **Quoted atoms** where bare atoms would be idiomatic
- **Type comparisons** using `==` instead of pattern matching
- **Unused imports/aliases** cluttering generated code

These issues degraded code quality, made debugging difficult, and created a poor developer experience.

## Architectural Solution

The hygiene transformation system implements a three-phase pipeline with scope-aware variable tracking and precise AST modifications.

### Three-Phase Transformation Pipeline

#### Phase 0: AST ID Assignment
Every AST node receives a unique identifier via metadata, enabling precise node targeting for transformations.

```haxe
static function assignAstIds(ast: ElixirAST): ElixirAST {
    var idCounter = 0;
    return ElixirASTTransformer.transformNode(ast, function(node) {
        if (node.metadata == null) node.metadata = {};
        Reflect.setField(node.metadata, "astId", ++idCounter);
        return node;
    });
}
```

#### Phase 1: Binding Collection & Usage Analysis
The system traverses the AST with context awareness, distinguishing between:
- **Pattern contexts** (where variables are bound)
- **Expression contexts** (where variables are read)
- **Pinned contexts** (reads within patterns)

Each binding is registered with a precise locator:
```haxe
typedef Binding = {
    name: String,
    used: Bool,
    kind: BindingKind,
    containerId: Int,          // AST ID of container node
    context: ContainerContext, // Type of container
    slotIndex: Int,           // Position within container
    path: Array<Int>          // Navigation path in nested patterns
}
```

#### Phase 2: Targeted Renaming
Using collected bindings, the system builds a rename index and applies transformations surgically:
```haxe
// Build index: Map<(containerId, context, slotIndex), Array<rename_operation>>
var renameIndex = new Map<String, Array<{path, oldName, newName}>>();

// Apply renames using precise locators
return ElixirASTTransformer.transformNode(ast, function(node) {
    // Check if this node has renames and apply them
});
```

## Key Innovation: Container/Slot/Path Locator System

Developed through architectural consultation with Codex, this system provides surgical precision for AST modifications.

### Example: Pattern Variable Locator
```elixir
def process({a, b, c}, d) do  # Container: def "process"
  # Locator for 'b':
  # - containerId: 42 (The EDef node's unique ID)
  # - context: DefParam (It's a function parameter)
  # - slotIndex: 0 (First parameter of the function)
  # - path: [1] (Second element of the tuple pattern)
end
```

This precision ensures that only the exact variable instance is renamed, avoiding unintended modifications.

## Transformation Passes

### 1. Usage Analysis Pass (IMPLEMENTED)
Detects unused variables through comprehensive AST traversal.

**Critical Feature**: Deep nested usage detection
```elixir
# Initial bug: 't' marked as unused
def from_time(t) do
  DateTime.from_unix!(Std.int(t), "millisecond")  # 't' is used!
end

# Fixed: Recursive traversal finds nested usage
```

**Implementation**:
```haxe
static function isVariableUsedInBody(varName: String, body: ElixirAST): Bool {
    var used = false;
    ElixirASTTransformer.transformNode(body, function(node) {
        switch(node.def) {
            case EVar(name): 
                if (name == varName) used = true;
            // ... other cases
        }
        return node;
    });
    return used;
}
```

### 2. Hygienic Naming Pass (PLANNED)
Alpha-renaming to eliminate variable shadowing.

### 3. Atom Normalization Pass (IMPLEMENTED)
Converts quoted atoms to bare atoms where safe.
```elixir
# Before: "atom :foo should be written as :foo" warning
:"foo"

# After: Clean bare atom
:foo
```

### 4. Equality-to-Pattern Pass (IMPLEMENTED)
Transforms equality comparisons to idiomatic pattern matching.
```elixir
# Before: Non-idiomatic comparison
if x == :atom do

# After: Idiomatic pattern matching
if match?(:atom, x) do
```

## Scope-Aware Variable Tracking

The system maintains a scope stack to correctly handle variable shadowing and nested scopes:

```haxe
enum ScopeKind {
    Module;
    Function;
    Clause;
    Block;
    CompGen;    // Comprehension generator
    CompFilter; // Comprehension filter
    Rescue;
    Receive;
    With;
}

typedef ScopeFrame = {
    bindings: Map<String, Array<Binding>>,  // Stack per name
    kind: ScopeKind,
    parent: Null<ScopeFrame>
}
```

### Binding Resolution
Variables are resolved by walking the scope stack from innermost to outermost:
```haxe
static function resolveVariable(state: HygieneState, name: String): Null<Binding> {
    var i = state.scopeStack.length - 1;
    while (i >= 0) {
        var frame = state.scopeStack[i];
        if (frame.bindings.exists(name)) {
            var binding = /* get most recent binding */;
            binding.used = true;  // Mark as used
            return binding;
        }
        i--;
    }
    return null;  // Not found (might be module attribute)
}
```

## Debug Infrastructure

The system includes comprehensive debug tracing controlled by compilation flags:

```haxe
#if debug_hygiene
trace('[XRay Hygiene] Entering scope: $kind (depth: ${state.scopeStack.length})');
trace('[XRay Hygiene] Bound variable "$name" in ${frame.kind} scope');
trace('[XRay Hygiene] Variable "$varName" is ${isUsed ? "USED" : "UNUSED"}');
#end
```

Enable with: `npx haxe build.hxml -D debug_hygiene`

## Testing Strategy

### Snapshot Tests
Comprehensive test suite in `test/snapshot/HygieneTransformUsageDetection/`:
- Nested usage detection
- Deep nesting scenarios
- Variable shadowing
- Unused parameters in various contexts

### Real-World Validation
The todo-app serves as the primary integration test:
```bash
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force 2>&1 | grep -c "warning:"
# Result: 371 warnings (down from 417)
```

### Test Coverage
- ✅ Function parameter usage detection
- ✅ Nested call argument detection (`Std.int(t)`)
- ✅ Case clause variable tracking
- ✅ Pattern matching variable binding
- ✅ Comprehension generator variables
- 🔄 Variable shadowing (in progress)
- 🔄 Unused imports/aliases (planned)

## Implementation Challenges & Solutions

### Challenge 1: Nested Variable Usage
**Problem**: Initial implementation missed variables used in nested contexts.
```elixir
def from_time(t) do
  DateTime.from_unix!(Std.int(t), "millisecond")  # 't' marked unused!
end
```

**Solution**: Use ElixirASTTransformer's recursive traversal instead of manual recursion.

### Challenge 2: Precise Variable Targeting
**Problem**: Multiple variables with same name in different contexts.
```elixir
case value do
  {:ok, x} -> process(x)    # Which 'x' to rename?
  {:error, x} -> log(x)     # Different 'x'!
end
```

**Solution**: Container/Slot/Path locator system for surgical precision.

### Challenge 3: Scope-Aware Tracking
**Problem**: Variables can be bound in patterns but used in expressions.

**Solution**: Maintain context stack distinguishing Pattern vs Expression contexts.

## Performance Characteristics

- **AST ID Assignment**: O(n) where n = number of AST nodes
- **Binding Collection**: O(n) single-pass traversal
- **Rename Application**: O(n) with O(1) index lookups
- **Overall Complexity**: O(n) linear in AST size

Memory usage is proportional to the number of unique variable bindings.

## Future Enhancements

### Immediate Priority
1. **Complete Hygienic Naming Pass**: Eliminate all variable shadowing warnings
2. **Unused Import Detection**: Remove unused alias/import/require statements
3. **Dead Code Elimination**: Remove unreachable code branches

### Medium-Term Goals
1. **Format String Optimization**: Convert string concatenation to interpolation
2. **Pattern Consolidation**: Merge related case clauses
3. **Comprehension Optimization**: Convert loops to comprehensions where idiomatic

### Long-Term Vision
1. **Style Enforcement**: Configurable Elixir style rules
2. **Performance Hints**: Suggest performance optimizations
3. **Documentation Generation**: Auto-generate @doc from Haxe comments

## Configuration & Usage

### Enabling Hygiene Passes
In `ElixirASTTransformer.hx`:
```haxe
passes.push({
    name: "UsageAnalysis",
    description: "Detect and mark unused variables",
    enabled: true,
    pass: HygieneTransforms.usageAnalysisPass
});
```

### Debug Flags
```bash
# Enable hygiene debug traces
npx haxe build.hxml -D debug_hygiene

# Verbose traversal logging
npx haxe build.hxml -D debug_hygiene_verbose

# Combined with AST debugging
npx haxe build.hxml -D debug_ast_transformer -D debug_hygiene
```

## API Reference

### Public Functions

#### `usageAnalysisPass(ast: ElixirAST): ElixirAST`
Main entry point for usage analysis transformation.

#### `hygienicNamingPass(ast: ElixirAST): ElixirAST`
Alpha-renaming for shadow elimination (planned).

#### `atomNormalizationPass(ast: ElixirAST): ElixirAST`
Converts quoted atoms to bare atoms where safe.

#### `equalityToPatternPass(ast: ElixirAST): ElixirAST`
Transforms equality comparisons to pattern matching.

### Data Types

See `HygieneTransforms.hx` for complete type definitions:
- `BindingContext` - Expression vs Pattern context
- `ContainerContext` - Type of containing structure
- `Binding` - Variable binding with locator
- `ScopeFrame` - Scope stack frame
- `HygieneState` - Traversal state

## Contributing

When adding new hygiene transformations:

1. **Design Phase**: Consult with Codex for architectural guidance
2. **Implementation**: Follow the three-phase pattern
3. **Testing**: Add snapshot tests and validate with todo-app
4. **Documentation**: Update this file with new passes

## References

- [ElixirASTTransformer.hx](../../src/reflaxe/elixir/ast/ElixirASTTransformer.hx) - Transformation pipeline
- [HygieneTransforms.hx](../../src/reflaxe/elixir/ast/transformers/HygieneTransforms.hx) - Implementation
- [Codex Consultation Transcripts](./CODEX_CONSULTATIONS.md) - Architectural discussions
- [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide) - Target idioms

## Metrics & Impact

### Before Hygiene Transformations
- **417 compilation warnings**
- Poor code readability
- Difficult debugging experience
- Non-idiomatic generated code

### After Hygiene Transformations
- **371 compilation warnings** (11% reduction, ongoing)
- Improved code clarity
- Better debugging experience
- More idiomatic Elixir output

### Success Metrics
- ✅ Zero false positives (no used variables marked unused)
- ✅ Correct nested usage detection
- ✅ Surgical precision (only target intended variables)
- 🎯 Goal: < 100 warnings by completion

## Conclusion

The Hygiene Transformation System represents a significant advancement in the Reflaxe.Elixir compiler's code generation quality. Through intelligent AST analysis and surgical transformations, it produces cleaner, more idiomatic Elixir code while maintaining correctness and performance.

The system's modular design allows for incremental improvements and easy addition of new transformation passes, ensuring the compiler can evolve to meet future code quality requirements.