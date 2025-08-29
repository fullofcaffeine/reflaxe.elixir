# Helper Cleanup Analysis

## Summary
- **Total helper files**: 75
- **AST pipeline uses**: 0 helpers (completely independent!)
- **String pipeline uses**: ~35 helpers (instantiated)

## Categories

### 1. KEEP - Static utilities used by both pipelines
- `NamingHelper` (15 uses) - Name conversions, used everywhere
- `AlgebraicDataTypeCompiler` (4 uses) - ADT detection, still needed
- `AnnotationSystem` (2 uses) - Annotation processing
- `CompilerUtilities` - Shared utilities

### 2. KEEP - Used by class/enum/module compilation (not expressions)
- `ClassCompiler` - Class → module compilation
- `EnumCompiler` - Enum → tagged tuple compilation  
- `SchemaCompiler` - @:schema annotation
- `MigrationCompiler` - @:migration annotation
- `LiveViewCompiler` - @:liveview annotation
- `GenServerCompiler` - @:genserver annotation
- `RouterCompiler` - @:router annotation
- `ExUnitCompiler` - @:test annotation

### 3. REMOVE - String-based expression compilation (replaced by AST)
All these are instantiated but ONLY used by string pipeline:
- `ExpressionVariantCompiler` - Main string expression compiler
- `PatternMatchingCompiler` - Switch/case string compilation
- `ConditionalCompiler` - If/else string compilation
- `ExceptionCompiler` - Try/catch string compilation
- `LiteralCompiler` - Literal string compilation
- `OperatorCompiler` - Operator string compilation
- `DataStructureCompiler` - Array/map string compilation
- `FieldAccessCompiler` - Field access string compilation
- `MiscExpressionCompiler` - Misc expression string compilation
- `StringMethodCompiler` - String method calls
- `MethodCallCompiler` - Method call compilation
- `ReflectionCompiler` - Reflect.* calls
- `SubstitutionCompiler` - Variable substitution
- `ArrayMethodCompiler` - Array method calls
- `MapToolsCompiler` - Map manipulation
- `ADTMethodCompiler` - ADT method calls
- `PatternDetectionCompiler` - Pattern detection
- `PatternAnalysisCompiler` - Pattern analysis
- `TypeResolutionCompiler` - Type resolution
- `CodeFixupCompiler` - String fixup
- `UnifiedLoopCompiler` - Loop compilation
- `OTPCompiler` - OTP pattern string generation
- `VariableCompiler` - Variable naming
- `NamingConventionCompiler` - Naming conventions
- `StateManagementCompiler` - State management
- `FunctionCompiler` - Function compilation

### 4. REMOVE - Never used anywhere
These are imported but never called:
- `APIDocExtractor`
- `ApplicationCompiler`
- `BehaviorCompiler`
- `ChangesetCompiler`
- `ChannelCompiler`
- `DebugHelper`
- `EctoErrorReporter`
- `EctoQueryAdvancedCompiler`
- `EndpointCompiler`
- `EnumPatternContext`
- `ExUnitBuilder`
- `FormatHelper`
- `GuardCompiler`
- `HxxCompiler`
- `ImportOptimizer`
- `LLMDocsGenerator`
- `MapCompiler`
- `MutabilityAnalyzer`
- `PatternExtractor`
- `PatternMatcher`
- `PhoenixPathGenerator`
- `PipelineAnalyzer`
- `PipelineOptimizer`
- `ProtocolCompiler`
- `QueryCompiler`
- `ReflectFieldsCompiler`
- `RepoCompiler`
- `RepositoryCompiler`
- `TableBuilder`
- `TelemetryCompiler`
- `TemplateCompiler`
- `TempVariableOptimizer`
- `TypedefCompiler`
- `VariableMappingManager`
- `WebModuleCompiler`

## Action Plan

### Phase 1: Remove unused helpers (40 files)
All files in category 4 can be deleted immediately - they're never used.

### Phase 2: Remove string-based expression helpers (26 files)
All files in category 3 can be deleted once we remove ExpressionVariantCompiler.

### Phase 3: Keep essential helpers (9 files)
Keep categories 1 and 2 - they're still needed for non-expression compilation.

## Result
**From 75 helpers → 9 helpers** (88% reduction!)