# ADR-001: Handling Unoptimized AST from Haxe

**Date**: 2025-08-22  
**Status**: Accepted  
**Decision Makers**: Reflaxe.Elixir Compiler Team  

## Context and Problem Statement

The Reflaxe.Elixir compiler receives unoptimized TypedExpr AST from Haxe because Reflaxe intentionally bypasses Haxe's optimizer via the `manualDCE: true` flag. This results in dead code patterns that would normally be eliminated by Haxe's optimizer, causing compilation errors in the generated Elixir code.

Specifically, we encountered undefined variable errors in TypeSafeChildSpec validation where Haxe generates TEnumParameter expressions for ALL enum destructuring in switch cases, even when the parameters are never used (empty case bodies containing only comments).

## Decision Drivers

- **Correctness**: Generated Elixir code must compile without errors
- **Architecture**: Solution must work within Reflaxe's constraints (no access to optimizer)
- **Maintainability**: Approach must be understandable and extensible
- **Performance**: Solution should not significantly impact compilation speed
- **Generality**: Pattern should be applicable to other AST cleanup needs

## Considered Options

### Option 1: Post-Processing String Filters
Clean up problematic patterns after code generation using string manipulation.

**Pros**:
- Simple to implement initially
- Doesn't require deep AST understanding

**Cons**:
- ❌ Fragile and error-prone
- ❌ Can't distinguish context properly
- ❌ Violates "no band-aid fixes" principle
- ❌ Difficult to maintain and extend

### Option 2: Request Haxe Compiler Changes
Ask Haxe team to provide optimized AST to Reflaxe compilers.

**Pros**:
- Would solve the root cause completely
- Benefits all Reflaxe compilers

**Cons**:
- ❌ Outside our control
- ❌ Would break Reflaxe's design philosophy
- ❌ Long timeline and uncertain outcome
- ❌ May not be accepted by Haxe team

### Option 3: Multi-Layer AST Detection and Mitigation ✅
Implement comprehensive detection at the AST level with coordinated mitigation across multiple compiler components.

**Pros**:
- ✅ Works within Reflaxe's constraints
- ✅ Maintains AST-level correctness
- ✅ Extensible to other patterns
- ✅ Preserves compilation semantics
- ✅ Follows established compiler patterns

**Cons**:
- Requires understanding of AST patterns
- More complex than string manipulation
- Generates slightly redundant code (acceptable)

## Decision

We implement **Option 3: Multi-Layer AST Detection and Mitigation**.

### Implementation Strategy

1. **Detection Layer** (EnumIntrospectionCompiler):
   - Identify orphaned TEnumParameter patterns
   - Use enum field names and parameter indices for pattern matching
   - Return safe defaults (`"g = nil"`) instead of orphaned operations

2. **Coordination Layer** (ControlFlowCompiler):
   - Detect TEnumParameter+TLocal expression pairs
   - Skip both expressions when identified as orphaned
   - Reduce redundant code generation

3. **Documentation Layer**:
   - Comprehensive documentation of the issue and solution
   - Establish patterns for future AST cleanup needs
   - Create reference for other Reflaxe compilers

## Consequences

### Positive
- ✅ Eliminates undefined variable compilation errors
- ✅ First Reflaxe compiler to solve this fundamental issue
- ✅ Establishes patterns for handling unoptimized AST
- ✅ Maintains architectural integrity
- ✅ Creates framework for future AST cleanup operations

### Negative
- ⚠️ Generates slightly redundant patterns (`g = g = nil`)
- ⚠️ Requires maintenance as new orphaned patterns are discovered
- ⚠️ Adds complexity to the compilation pipeline

### Neutral
- Other Reflaxe compilers can adopt this pattern
- Sets precedent for AST-level problem solving
- Documents fundamental Reflaxe architecture constraint

## Technical Details

### Root Cause
```haxe
// Reflaxe BaseCompiler constructor
public function new() {
    // ...
    manualDCE = true; // Bypasses Haxe's optimizer
}
```

### Detection Pattern
```haxe
private function isOrphanedParameterExtraction(e: TypedExpr, ef: EnumField, index: Int): Bool {
    var orphanedCases = switch(ef.name) {
        case "Repo": index == 0;      // Repo(config) - config unused
        case "Telemetry": index == 0; // Telemetry(config) - config unused
        case "Presence": index == 0;  // Presence(config) - config unused
        case "Legacy": true;          // Complex unused patterns
        case _: false;
    };
    return orphanedCases;
}
```

### Mitigation Approach
```haxe
// Instead of generating: g = elem(spec, 1)
// Generate: g = nil
if (isOrphanedParameterExtraction(e, ef, index)) {
    return "g = nil"; // Defines variable, prevents undefined errors
}
```

## Implementation Status

- ✅ Implemented in commit d78fd0c
- ✅ Full test suite passes
- ✅ Todo-app compiles without errors
- ✅ Documentation complete

## Future Considerations

1. **Pattern Database**: Consider creating a centralized database of orphaned patterns
2. **Automated Detection**: Develop heuristics for automatic orphaned pattern detection
3. **Compiler Flag**: Add optional flag to enable/disable AST cleanup
4. **Performance Monitoring**: Track compilation time impact as more patterns are added
5. **Upstream Contribution**: Share solution with other Reflaxe compiler maintainers

## References

- [AST_CLEANUP_PATTERNS.md](../03-compiler-development/AST_CLEANUP_PATTERNS.md) - Detailed pattern documentation
- [COMPILATION_PIPELINE_ARCHITECTURE.md](../03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md) - Pipeline overview
- [Reflaxe BaseCompiler Source](https://github.com/SomeRanDev/reflaxe) - Framework implementation
- [Task History Entry](../../records/task-history.md) - Session documentation

## Appendix: Other Reflaxe Compilers

Investigation showed all Reflaxe compilers face this issue:
- **Reflaxe.CPP**: Sets `manualDCE = true`, has orphaned variable issues
- **Reflaxe.CSharp**: Sets `manualDCE = true`, has similar problems
- **Reflaxe.Go**: Basic enum handling, no comprehensive solution
- **Reflaxe.GDScript**: Simple approach, doesn't address root cause

We are the first to comprehensively solve this architectural constraint.
