# ElixirASTBuilder Complete Function Inventory

## File Statistics
- **Total Lines**: 12,567
- **Total Functions**: 108 static functions (verified via grep)
- **Analysis Date**: September 2025
- **Previous Failed Attempt**: Commit ecf50d9d - lost @:application handling

## Function Categorization and Dependencies

### 1. Core Building Functions (Entry Points)
These are the main entry points for AST construction:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `buildFromTypedExpr` | 479 | Public entry point for AST building | buildFromTypedExprHelper, CompilationContext |
| `buildFromTypedExprHelper` | 491 | Main recursive builder | All pattern/loop/enum functions |
| `buildFromTypedExprWithContext` | 512 | Context-aware building | buildFromTypedExprHelper |
| `convertExpression` | 635 | Core TypedExpr switch handler | All conversion functions |

### 2. Pattern Matching Functions (~2,500 lines)
Handle pattern matching, extraction, and conversion:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `convertPattern` | 7356 | Main pattern converter | extractPattern |
| `convertPatternWithExtraction` | 7443 | Pattern with variable extraction | convertPattern |
| `extractPattern` | 9364 | Extract pattern from TypedExpr | None |
| `extractPatternVariableNamesFromValues` | 7518 | Extract var names from patterns | None |
| `analyzeEnumParameterExtraction` | 7571 | Analyze enum parameter usage | isEnumParameterUsedAtIndex |
| `createEnumBindingPlan` | 8085 | Create variable binding plan | isPatternVariableUsedById |
| `convertIdiomaticEnumPatternWithExtraction` | 8402 | Idiomatic enum patterns | convertIdiomaticEnumPatternWithTypeImpl |
| `convertIdiomaticEnumPatternWithType` | 8413 | Type-aware enum patterns | convertIdiomaticEnumPatternWithTypeImpl |
| `convertRegularEnumPatternWithExtraction` | 8426 | Regular enum patterns | None |
| `convertIdiomaticEnumPatternWithTypeImpl` | 8615 | Implementation for idiomatic enums | toElixirAtomName |
| `convertIdiomaticEnumPattern` | 8829 | Simple idiomatic enum pattern | getEnumTypeName |
| `computePatternKey` | 12022 | Generate pattern hash key | None |
| `extractBoundVariables` | 12079 | Extract bound variables from pattern | collectBoundVarsHelper |
| `collectBoundVarsHelper` | 12085 | Helper for bound var collection | Recursive |
| `applyUnderscorePrefixToUnusedPatternVars` | 11902 | Prefix unused pattern vars | updateMappingForUnderscorePrefixes |
| `updateMappingForUnderscorePrefixes` | 11841 | Update var mappings for underscores | None |

### 3. Variable Management Functions (~1,500 lines)
Handle variable usage, substitution, and naming:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `getVariableInitValue` | 252 | Get variable initialization value | CompilationContext |
| `replaceNullCoalVar` | 272 | Replace null coalescing variables | substituteVariable |
| `substituteVariable` | 312 | Substitute variable in expression | Recursive |
| `toElixirVarName` | 9485 | Convert to Elixir variable name | None |
| `isCamelCaseParameter` | 9467 | Check if param is camelCase | None |
| `isTempPatternVarName` | 9539 | Check if temp pattern var | None |
| `usesVariable` | 10382 | Check if var used in nodes | usesVariableInNode |
| `usesVariableInNode` | 10394 | Check if var used in single node | Recursive |
| `transformVariableReferences` | 10412 | Transform var references | applyParameterRenaming |
| `applyParameterRenaming` | 9398 | Apply parameter renaming | Recursive |
| `isVariableUsedInAST` | 10158 | Check var usage in AST | Recursive |
| `countVarOccurrencesInAST` | 10054 | Count var occurrences | Recursive |
| `replaceVarInAST` | 10071 | Replace var in AST | Recursive |
| `prefixUnusedVariablesInAST` | 7309 | Prefix unused variables | Recursive |
| `isPatternVariableUsed` | 11665 | Check if pattern var used | isPatternVariableUsedById |
| `isPatternVariableUsedById` | 11800 | Check pattern var by ID | Recursive |
| `isEnumParameterUsedAtIndex` | 11614 | Check enum param usage | Recursive |
| `createVariableMappingsForCase` | 9616 | Create var mappings for case | ClauseContext |

### 4. Enum Handling Functions (~2,000 lines)
Enum-specific pattern matching and parameter extraction:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `isEnumConstructor` | 8862 | Check if enum constructor | None |
| `hasIdiomaticMetadata` | 8889 | Check idiomatic metadata | None |
| `getEnumTypeName` | 8940 | Get enum type name | None |
| `toElixirAtomName` | 8961 | Convert to Elixir atom | None |
| `extractEnumTag` | 9345 | Extract enum tag | None |
| `createEnumBindingPlan` | 8085 | Create binding plan | isPatternVariableUsedById |
| `processEnumCaseBody` | 7259 | Process enum case body | ClauseContext |

### 5. Loop Optimization Functions (~1,500 lines)
Detect and optimize loop patterns:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `tryOptimizeArrayPattern` | 6829 | Try optimize array patterns | detectArrayIterationPattern |
| `detectArrayIterationPattern` | 6906 | Detect array iteration | None |
| `analyzeLoopBody` | 6977 | Analyze loop body | containsPush |
| `generateEnumMapSimple` | 7052 | Generate simple Enum.map | buildFromTypedExpr |
| `generateEnumFilterSimple` | 7073 | Generate simple Enum.filter | buildFromTypedExpr |
| `generateEnumMap` | 7093 | Generate Enum.map | extractMapTransformation |
| `generateEnumFilter` | 7117 | Generate Enum.filter | extractFilterCondition |
| `generateEnumReduce` | 7138 | Generate Enum.reduce | buildFromTypedExpr |
| `extractMapTransformation` | 7147 | Extract map transformation | buildFromTypedExprWithSubstitution |
| `extractFilterCondition` | 7188 | Extract filter condition | buildFromTypedExpr |
| `containsPush` | 7223 | Check for push operations | Recursive |
| `detectArrayOperationPattern` | 10231 | Detect array operations | None |
| `generateIdiomaticEnumCall` | 10308 | Generate idiomatic Enum calls | None |
| `processLoopIntent` | 12290 | Process loop intent | LoopBuilder |

### 6. Comprehension Building Functions (~1,000 lines)
Array and list comprehension reconstruction:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `tryBuildArrayComprehensionFromBlock` | 11418 | Build array comprehension | isComprehensionPattern |
| `tryReconstructConditionalComprehension` | 11177 | Reconstruct conditional comp | extractYieldExpression |
| `tryReconstructFromElements` | 10963 | Reconstruct from elements | None |
| `transformConditionToFilter` | 11048 | Transform condition to filter | buildFromTypedExpr |
| `extractComprehensionData` | 10812 | Extract comprehension data | None |
| `isComprehensionPattern` | 10687 | Check comprehension pattern | None |
| `isUnrolledComprehension` | 10745 | Check unrolled comprehension | None |
| `buildIteratorAST` | 10869 | Build iterator AST | buildFromTypedExpr |
| `extractUnrolledElements` | 10888 | Extract unrolled elements | buildFromTypedExpr |
| `replaceIndexInCondition` | 11024 | Replace index in condition | Recursive |
| `extractYieldExpression` | 12224 | Extract yield expression | buildFromTypedExpr |
| `looksLikeListBuildingBlock` | 11527 | Detect list building | containsPushToVar |
| `containsPushToVar` | 11368 | Check push to variable | None |
| `extractPushBody` | 11385 | Extract push body | None |
| `extractListElements` | 12122 | Extract list elements | None |

### 7. Helper/Utility Functions (~1,000 lines)
General utilities and helpers:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `createMetadata` | 7328 | Create metadata | None |
| `trackDependency` | 214 | Track module dependency | compiler |
| `extractFieldName` | 9591 | Extract field name | None |
| `typeToElixir` | 10085 | Convert type to Elixir | None |
| `isPure` | 10101 | Check if expression pure | None |
| `canBeInlined` | 10115 | Check if can inline | isPure |
| `isConstant` | 10127 | Check if constant | None |
| `hasSideEffects` | 10137 | Check side effects | None |
| `convertAssignOp` | 9377 | Convert assignment op | None |
| `unwrapMetaParens` | 10664 | Unwrap meta parentheses | None |
| `isEmptyCaseBody` | 11881 | Check empty case body | None |
| `analyzesAsExpression` | 12539 | Check if expression | None |

### 8. Template/HXX Functions (~500 lines)
Handle HXX template compilation:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `collectTemplateContent` | 9827 | Collect template content | collectTemplateArgument |
| `collectTemplateArgument` | 9879 | Collect template argument | None |
| `isHXXModule` | 9911 | Check if HXX module | None |

### 9. Special Pattern Detection (~1,000 lines)
Detect specific patterns:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `buildFieldPatternSwitch` | 6690 | Build field pattern switch | buildFromTypedExpr |
| `containsIfStatement` | 8979 | Check for if statements | Recursive |
| `isArrayType` | 9019 | Check if array type | None |
| `isMapType` | 9326 | Check if map type | None |
| `isMapAccess` | 9960 | Check map access | None |
| `isAssertClass` | 9935 | Check assert class | None |
| `isModuleCall` | 9950 | Check module call | None |
| `detectFluentAPIPattern` | 9102 | Detect fluent API | None |
| `detectMapIterationPattern` | 12370 | Detect map iteration | None |
| `buildMapIteration` | 12507 | Build map iteration | buildFromTypedExpr |
| `tryBuildMapLiteralFromBlock` | 11309 | Build map literal | buildFromTypedExpr |

### 10. Expansion/Injection Functions (~500 lines)
Handle Elixir code injection:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `tryExpandElixirInjection` | 9042 | Expand __elixir__ injection | None |
| `tryExpandElixirCall` | 9201 | Expand Elixir calls | None |
| `getExternNativeModuleNameFromType` | 9971 | Get extern native module | None |
| `moduleTypeToString` | 9995 | Module type to string | None |

### 11. Return/Halt Transformation (~300 lines)
Handle early returns and halts:

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `checkForEarlyReturns` | 10574 | Check early returns | Recursive |
| `transformReturnsToHalts` | 10589 | Transform returns to halts | wrapWithHaltIfNeeded |
| `wrapWithHaltIfNeeded` | 10634 | Wrap with halt | None |

### 12. Debug/Instrumentation Functions (~200 lines)
Compilation hang diagnosis (only in debug mode):

| Function | Line | Purpose | Dependencies |
|----------|------|---------|--------------|
| `logCompilationProgress` | 92 | Log compilation progress | None |
| `enterNode` | 99 | Enter node tracking | None |
| `exitNode` | 155 | Exit node tracking | None |
| `detectCycle` | 167 | Detect compilation cycles | None |

## Dependency Analysis

### High-Level Dependencies
1. **buildFromTypedExprHelper** - Central hub, depends on almost all other functions
2. **CompilationContext** - Passed through most functions for state management
3. **ClauseContext** - Used in pattern matching and case handling
4. **Recursive patterns** - Many functions call themselves for nested AST traversal

### Circular Dependencies
- `buildFromTypedExpr` ↔ Pattern functions (through helper)
- Variable substitution functions have mutual recursion
- Pattern extraction functions call each other

### External Dependencies
- `LoopBuilder` - External builder for loop handling
- `CoreExprBuilder` - Basic expression building
- `PatternDetector` - Pattern detection helper
- `ElixirNaming` - Naming conventions

## Refactoring Risk Assessment

### Low Risk Functions (Can Extract First)
- Metadata creation functions
- Simple utility functions (isPure, isConstant, etc.)
- Template/HXX functions (isolated subsystem)
- Debug instrumentation (already conditional)

### Medium Risk Functions (Extract with Care)
- Variable management (used everywhere but well-defined interface)
- Comprehension building (somewhat isolated)
- Return/halt transformation (limited scope)

### High Risk Functions (Extract Last)
- Core building functions (heart of the system)
- Pattern matching (complex interdependencies)
- Enum handling (tightly coupled with patterns)
- Loop optimization (depends on many subsystems)

## Module Extraction Plan

Based on this analysis, recommended extraction order:

1. **DebugInstrumentation** (~200 lines) - Already conditional, zero risk
2. **MetadataManager** (~300 lines) - Simple, no dependencies
3. **TemplateHandler** (~500 lines) - Isolated HXX subsystem
4. **UtilityFunctions** (~800 lines) - Pure functions, easy to test
5. **VariableAnalyzer** (~1,500 lines) - Clear interface, widely used
6. **ComprehensionBuilder** (~1,000 lines) - Somewhat isolated
7. **PatternMatcher** (~2,500 lines) - Large but cohesive
8. **EnumHandler** (~2,000 lines) - Coupled with patterns
9. **LoopOptimizer** (~1,500 lines) - Complex dependencies
10. **CoreBuilder** (~2,000 lines) - Final orchestrator

## Notes on Previous Failure

The previous attempt (commit ecf50d9d) failed because:
1. **Lost @:application handling** - Not properly tracked in extraction
2. **Incomplete extraction** - Some functions left behind, others duplicated
3. **No test harness** - Couldn't verify functionality preserved
4. **All-or-nothing approach** - Too many changes at once

This analysis ensures we understand every function's role before extraction.