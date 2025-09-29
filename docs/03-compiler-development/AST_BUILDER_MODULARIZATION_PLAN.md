# ElixirASTBuilder Modularization Plan

## Current State Analysis (Task 1)

### File Statistics
- **Total Lines**: 12,567
- **Total Functions**: 111 static functions
- **Previous Failed Attempt**: Commit ecf50d9d (September 2025) - reverted due to loss of critical functionality

### Function Categories by Prefix

| Prefix | Count | Purpose |
|--------|-------|---------|
| is* | 18 | Type/pattern checking predicates |
| extract* | 12 | Data extraction from AST nodes |
| convert* | 9 | Type/pattern conversion |
| try* | 7 | Optional transformations |
| build* | 7 | AST construction |
| generate* | 6 | Code generation |
| detect* | 5 | Pattern detection |
| transform* | 3 | AST transformations |

### Identified Logical Components

## 1. Pattern Module (~2,500 lines)
**Responsibility**: Pattern matching, conversion, and extraction

### Core Functions:
- `convertPattern()`
- `convertPatternWithExtraction()`
- `convertIdiomaticEnumPattern*()`
- `convertRegularEnumPattern*()`
- `extractPatternVariableNames*()`
- All `is*Pattern()` predicates

### Dependencies:
- ElixirAST types
- EnumType information
- Variable usage maps

## 2. Variable Analysis Module (~1,500 lines)
**Responsibility**: Variable usage tracking, substitution, and naming

### Core Functions:
- `usesVariable()`
- `usesVariableInNode()`
- `substituteVariable()`
- `replaceNullCoalVar()`
- `toElixirVarName()`
- `updateMappingForUnderscorePrefixes()`
- `transformVariableReferences()`

### Dependencies:
- TVar tracking
- Usage maps
- Context management

## 3. Enum Handler Module (~2,000 lines)
**Responsibility**: Enum-specific pattern matching and parameter extraction

### Core Functions:
- `analyzeEnumParameterExtraction()`
- `createEnumBindingPlan()`
- `extractEnumConstructor*()`
- All enum-related `convert*()` functions
- Enum pattern detection predicates

### Dependencies:
- EnumType definitions
- Pattern extraction
- Variable binding plans

## 4. Loop Optimizer Module (~1,500 lines)
**Responsibility**: Loop pattern detection and optimization

### Core Functions:
- `detectArrayIterationPattern()`
- `analyzeLoopBody()`
- `generateEnumMap()`
- `generateEnumFilter()`
- `generateEnumReduce()`
- `tryOptimizeArrayPattern()`

### Dependencies:
- Array pattern detection
- Comprehension building
- Enum operations

## 5. Comprehension Builder Module (~1,000 lines)
**Responsibility**: Array/list comprehension reconstruction

### Core Functions:
- `tryBuildArrayComprehensionFromBlock()`
- `tryReconstructConditionalComprehension()`
- `tryReconstructFromElements()`
- `transformConditionToFilter()`
- `extractComprehensionComponents()`

### Dependencies:
- Pattern matching
- Filter extraction
- Variable tracking

## 6. Metadata Manager Module (~500 lines)
**Responsibility**: AST metadata creation and management

### Core Functions:
- `createMetadata()`
- `moduleToMetadata()`
- `trackDependency()`
- Cycle detection functions

### Dependencies:
- CompilationContext
- Type information

## 7. Core Builder Module (~2,000 lines)
**Responsibility**: Main AST building coordination

### Core Functions:
- `buildFromTypedExpr()` (public entry point)
- `buildFromTypedExprWithContext()`
- `buildFromTypedExprHelper()`
- Core switch statement handling

### Dependencies:
- ALL other modules (coordinator role)

## Incremental Extraction Strategy

### Phase 1: Low-Risk Extractions (Week 1)
1. **Metadata Manager** - Most independent, clear boundaries
2. **Variable Analysis** - Well-defined responsibility
3. Create comprehensive test suite

### Phase 2: Medium-Risk Extractions (Week 2)
4. **Pattern Module** - Large but self-contained
5. **Comprehension Builder** - Clear single purpose
6. Validate with full test suite

### Phase 3: High-Risk Extractions (Week 3)
7. **Enum Handler** - Complex interdependencies
8. **Loop Optimizer** - Depends on multiple modules
9. Integration testing with todo-app

### Phase 4: Final Refactoring (Week 4)
10. **Core Builder** cleanup - Now a thin coordinator
11. Performance optimization
12. Documentation and code review

## Success Criteria

### Per-Module Extraction:
- [ ] Module compiles independently
- [ ] All tests pass (`npm test`)
- [ ] Todo-app compiles and runs
- [ ] No functionality lost
- [ ] Clear interface defined

### Overall Success:
- [ ] No file exceeds 2,000 lines
- [ ] Each module has single responsibility
- [ ] No circular dependencies
- [ ] Performance maintained or improved
- [ ] All original functionality preserved

## Risk Mitigation

### Lessons from Failed Attempt:
1. **Lost @:application handling** - Ensure all metadata processing preserved
2. **Incomplete extraction** - Use feature flags for gradual rollout
3. **Test coverage gaps** - Create tests BEFORE extraction
4. **All-or-nothing approach** - Make each step reversible

### Mitigation Strategies:
1. **Feature flags** - Allow switching between old/new implementation
2. **Parallel development** - Keep old code until new is proven
3. **Incremental commits** - Each extraction is a separate, tested commit
4. **Regression test suite** - Comprehensive tests for each responsibility
5. **Code review checkpoints** - Review after each phase

## Next Steps

1. **Create test harness** - Comprehensive tests for current behavior
2. **Start with Metadata Manager** - Smallest, most independent module
3. **Establish module interfaces** - Define contracts before moving code
4. **Set up continuous validation** - Automated testing after each change