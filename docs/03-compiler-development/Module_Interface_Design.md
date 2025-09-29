# ElixirASTBuilder Module Interface Design

## Architecture Overview

The modularization follows a **Registry Pattern** with **Interface Segregation** to avoid the coupling issues that caused the previous failure.

```
┌─────────────────────────────────────────────────┐
│            ElixirASTBuilder (Facade)            │
│                 (Thin Orchestrator)              │
└─────────────────┬───────────────────────────────┘
                  │ delegates to
                  ▼
┌─────────────────────────────────────────────────┐
│             BuilderRegistry                      │
│        (Dynamic Builder Resolution)              │
└─────────────────┬───────────────────────────────┘
                  │ routes to
                  ▼
┌──────────────────────────────────────────────────┐
│              Specialized Builders                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Pattern  │ │   Loop   │ │   Enum   │  ...   │
│  │ Builder  │ │Optimizer │ │ Handler  │        │
│  └──────────┘ └──────────┘ └──────────┘        │
└──────────────────────────────────────────────────┘
                  │ all use
                  ▼
┌─────────────────────────────────────────────────┐
│              BuildContext                        │
│         (Shared State & Services)                │
└──────────────────────────────────────────────────┘
```

## Core Interfaces

### 1. IBuilder (Base Interface)
**Location**: `src/reflaxe/elixir/ast/builders/interfaces/IBuilder.hx`
```haxe
interface IBuilder {
    function canHandle(expr: TypedExpr, context: BuildContext): Bool;
    function build(expr: TypedExpr, context: BuildContext): Null<ElixirAST>;
    function getPriority(): Int;
    function getName(): String;
}
```

### 2. BuildContext (Already Exists)
**Location**: `src/reflaxe/elixir/ast/context/BuildContext.hx`
- Provides shared state and services
- Enables recursive building through callbacks
- Manages variable resolution and metadata

### 3. BuilderRegistry
**Location**: `src/reflaxe/elixir/ast/builders/BuilderRegistry.hx`
- Manages builder registration
- Routes expressions to appropriate builders
- Handles feature flags for gradual migration

## Specialized Module Interfaces

### 1. PatternBuilder Module
**Responsibility**: Pattern matching, conversion, and extraction (~2,500 lines)

```haxe
class PatternBuilder implements IBuilder {
    // IBuilder implementation
    function canHandle(expr: TypedExpr, context: BuildContext): Bool {
        return switch(expr.expr) {
            case TSwitch(_): true;
            case _: false;
        }
    }
    
    // Core pattern functions (extracted from ElixirASTBuilder)
    function convertPattern(value: TypedExpr, context: BuildContext): EPattern;
    function convertPatternWithExtraction(value: TypedExpr, extractedParams: Array<String>, context: BuildContext): EPattern;
    function extractPatternVariableNames(values: Array<TypedExpr>): Array<String>;
    function createEnumBindingPlan(caseExpr: TypedExpr, extractedParams: Array<String>, enumType: EnumType): Dynamic;
    function applyUnderscorePrefixToUnusedPatternVars(pattern: EPattern, usageMap: Map<Int, Bool>): EPattern;
}
```

### 2. LoopOptimizer Module
**Responsibility**: Loop pattern detection and optimization (~1,500 lines)

```haxe
class LoopOptimizer implements IBuilder {
    // IBuilder implementation
    function canHandle(expr: TypedExpr, context: BuildContext): Bool {
        return switch(expr.expr) {
            case TWhile(_, _, _): true;
            case TFor(_, _, _): true;
            case _: false;
        }
    }
    
    // Core loop functions
    function tryOptimizeArrayPattern(econd: TypedExpr, ebody: TypedExpr): Null<ElixirAST>;
    function detectArrayIterationPattern(econd: TypedExpr): Dynamic;
    function generateEnumMap(arrayExpr: TypedExpr, analysis: Dynamic, ebody: TypedExpr): ElixirAST;
    function generateEnumFilter(arrayExpr: TypedExpr, analysis: Dynamic, ebody: TypedExpr): ElixirAST;
    function generateEnumReduce(arrayExpr: TypedExpr, analysis: Dynamic, ebody: TypedExpr): ElixirAST;
}
```

### 3. EnumHandler Module
**Responsibility**: Enum-specific handling (~2,000 lines)

```haxe
class EnumHandler implements IBuilder {
    // IBuilder implementation
    function canHandle(expr: TypedExpr, context: BuildContext): Bool {
        return switch(expr.expr) {
            case TEnumParameter(_): true;
            case TEnumIndex(_): true;
            case TCall(e, _) if (isEnumConstructor(e)): true;
            case _: false;
        }
    }
    
    // Core enum functions
    function analyzeEnumParameterExtraction(caseExpr: TypedExpr): Array<String>;
    function convertIdiomaticEnumPattern(value: TypedExpr, enumType: EnumType): EPattern;
    function isEnumConstructor(expr: TypedExpr): Bool;
    function getEnumTypeName(expr: TypedExpr): String;
}
```

### 4. VariableAnalyzer Module
**Responsibility**: Variable usage tracking and naming (~1,500 lines)

```haxe
class VariableAnalyzer implements IBuilder {
    // IBuilder implementation
    function canHandle(expr: TypedExpr, context: BuildContext): Bool {
        return switch(expr.expr) {
            case TLocal(_): true;
            case TVar(_): true;
            case _: false;
        }
    }
    
    // Core variable functions
    function usesVariable(nodes: Array<ElixirAST>, varName: String): Bool;
    function substituteVariable(expr: TypedExpr, varToReplace: TVar, replacement: TypedExpr): TypedExpr;
    function toElixirVarName(name: String, preserveUnderscore: Bool = false): String;
    function transformVariableReferences(ast: ElixirAST, varMapping: Map<String, String>): ElixirAST;
}
```

### 5. ComprehensionBuilder Module
**Responsibility**: Array/list comprehension reconstruction (~1,000 lines)

```haxe
class ComprehensionBuilder implements IBuilder {
    // IBuilder implementation
    function canHandle(expr: TypedExpr, context: BuildContext): Bool {
        return switch(expr.expr) {
            case TBlock(stmts) if (isComprehensionPattern(stmts)): true;
            case TArrayDecl(_): true;
            case _: false;
        }
    }
    
    // Core comprehension functions
    function tryBuildArrayComprehensionFromBlock(statements: Array<TypedExpr>): Null<ElixirAST>;
    function tryReconstructConditionalComprehension(statements: Array<TypedExpr>): Null<ElixirAST>;
    function extractComprehensionData(statements: Array<TypedExpr>): Dynamic;
    function isComprehensionPattern(statements: Array<TypedExpr>): Bool;
}
```

## Communication Patterns

### 1. No Direct Dependencies Between Builders
- Builders NEVER import other builders
- All communication through BuildContext
- Recursive building through context.buildExpression()

### 2. Metadata Flow
```haxe
// Builder A sets metadata
context.setNodeMetadata("switch_123", {
    isIdiomaticEnum: true,
    extractedParams: ["x", "y"]
});

// Builder B reads metadata (in transformer phase)
var meta = context.getNodeMetadata("switch_123");
```

### 3. Variable Resolution Chain
```haxe
// Priority order (handled by BuildContext)
1. Pattern registry (highest priority)
2. Clause context (case-specific)
3. Global mappings (lowest priority)
```

## Backward Compatibility

### ElixirASTBuilder Becomes a Facade
```haxe
class ElixirASTBuilder {
    private static var registry: BuilderRegistry;
    
    // Public API remains unchanged
    public static function buildFromTypedExpr(expr: TypedExpr, context: CompilationContext): ElixirAST {
        // Initialize registry if needed
        if (registry == null) {
            initializeRegistry();
        }
        
        // Create BuildContext wrapper
        var buildContext = new BuildContextImpl(context);
        
        // Delegate to registry
        return registry.build(expr, buildContext);
    }
    
    // Legacy functions become thin wrappers
    public static function convertPattern(value: TypedExpr): EPattern {
        // Delegate to PatternBuilder
        return getPatternBuilder().convertPattern(value, currentContext);
    }
}
```

## Migration Strategy

### Phase 1: Infrastructure (No Risk)
1. Implement BuilderRegistry ✅
2. Create IBuilder interface ✅
3. Enhance BuildContext ✅

### Phase 2: Extract Utilities (Low Risk)
1. Extract MetadataManager (500 lines)
2. Extract DebugInstrumentation (200 lines)
3. Verify with validation script

### Phase 3: Extract VariableAnalyzer (Medium Risk)
1. Move variable functions to module
2. Register with feature flag disabled
3. Enable gradually, test each step

### Phase 4: Extract PatternBuilder (High Risk)
1. Most complex module with many dependencies
2. Extensive testing required
3. Critical for @:application handling

## Success Metrics

### Per-Module Success
- [ ] Module compiles independently
- [ ] All tests pass with module enabled
- [ ] No performance degradation
- [ ] Clear interface boundaries
- [ ] No circular dependencies

### Overall Success
- [ ] ElixirASTBuilder < 2,000 lines
- [ ] Each module < 2,000 lines
- [ ] All functionality preserved
- [ ] Better compilation performance
- [ ] Easier to maintain and extend

## Risk Mitigation

### Lessons from Previous Failure
1. **@:application handling lost** → Test specifically for this
2. **Incomplete extraction** → Use feature flags for gradual rollout
3. **No fallback** → Keep legacy code until new is proven
4. **All-or-nothing** → Extract one module at a time

### Safety Mechanisms
1. **Feature flags** per module
2. **Validation script** after each extraction
3. **Legacy fallback** for unhandled cases
4. **Comprehensive logging** in debug mode
5. **Rollback plan** for each phase