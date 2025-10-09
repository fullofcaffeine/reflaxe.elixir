# AST Modularization Infrastructure Documentation

> **Created**: January 2025
> **Status**: Phase 1 Complete - Infrastructure Ready
> **Next Steps**: Phase 2 - Integration with Compiler

## 📋 Overview

This document describes the modular infrastructure created for the Reflaxe.Elixir AST pipeline. This infrastructure enables breaking down the monolithic 10,000+ line ElixirASTBuilder into focused, testable modules while maintaining coordination across compilation phases.

## 🏗️ Architecture

The infrastructure follows a **three-layer architecture**:

```
┌─────────────────────────────────────────────────┐
│            Application Layer                     │
│  ElixirASTBuilder, ElixirASTTransformer, etc.   │
└─────────────────────────────────────────────────┘
                    ↓ implements
┌─────────────────────────────────────────────────┐
│            Interface Layer                       │
│   BuildContext, TransformContext, etc.          │
└─────────────────────────────────────────────────┘
                    ↓ uses
┌─────────────────────────────────────────────────┐
│            Core State Layer                      │
│         ElixirASTContext (shared state)         │
└─────────────────────────────────────────────────┘
```

## 📦 Core Components

### 1. ElixirASTContext (`ast/context/ElixirASTContext.hx`)

**Purpose**: Central state container for the entire compilation pipeline.

**Key Features**:
- **Variable Mapping Systems**: Multiple mapping layers with priority hierarchy
- **Pattern Variable Registry**: Highest-priority mappings for user-specified names
- **Metadata Storage**: Cross-phase communication via node metadata
- **ClauseContext Stack**: Management of nested switch cases
- **Test Progress Integration**: Hooks for incremental test execution
- **Naming Convention Cache**: Efficient transformation lookups

**Usage Example**:
```haxe
// Create context at compilation start
var context = new ElixirASTContext();

// Register pattern variable (highest priority)
context.registerPatternVariable(tvarId, "email");

// Resolve variable with priority hierarchy
var name = context.resolveVariable(tvarId, "defaultName");
// Returns "email" if registered, otherwise checks other mappings

// Store metadata for transformation phase
context.setNodeMetadata("node_123", {
    isEnumMatch: true,
    idiomaticType: "option"
});
```

**Priority Hierarchy for Variable Resolution**:
1. **Pattern Variable Registry** - User-specified pattern names
2. **Current ClauseContext** - Case-specific mappings
3. **Global Variable Map** - Function/module level
4. **Default Name** - Fallback

### 2. BuildContext Interface (`ast/context/BuildContext.hx`)

**Purpose**: Clean interface for AST builders to access shared state without coupling to main compiler.

**Key Methods**:
```haxe
interface BuildContext {
    // Access shared state
    function getASTContext(): ElixirASTContext;

    // Variable resolution
    function resolveVariable(tvarId: Int, defaultName: String): String;
    function registerPatternVariable(tvarId: Int, patternName: String): Void;

    // Position tracking
    function getCurrentPosition(): Position;
    function setCurrentPosition(pos: Position): Void;

    // Type context
    function getCurrentModule(): Null<ModuleType>;
    function getCurrentClass(): Null<ClassType>;

    // Metadata management
    function setNodeMetadata(nodeId: String, metadata: Dynamic): Void;
    function generateNodeId(): String;

    // Error reporting
    function warning(message: String, ?pos: Position): Void;
    function error(message: String, ?pos: Position): Void;
}
```

**Benefits**:
- **Dependency Inversion**: Builders depend on interface, not implementation
- **Testability**: Can mock BuildContext for unit testing
- **Modularity**: Builders remain independent
- **Consistency**: All builders use same resolution logic

### 3. TransformContext Interface (`ast/context/TransformContext.hx`)

**Purpose**: Interface for transformation passes to coordinate and track changes.

**Key Features**:
- **Transformation Tracking**: Prevents duplicate transformations
- **Pattern Detection Registry**: Records detected patterns
- **Pass Statistics**: Performance and effectiveness metrics
- **Configuration Access**: Pass-specific settings

**Usage Example**:
```haxe
// In a transformation pass
class EnumPatternPass {
    function transform(node: ElixirAST, context: TransformContext): ElixirAST {
        var nodeId = node.metadata.nodeId;

        // Check if already transformed
        if (context.hasTransformation(nodeId, "enumPattern")) {
            return node;
        }

        // Read metadata from builder phase
        var metadata = context.getNodeMetadata(nodeId);
        if (metadata != null && metadata.isEnumMatch) {
            // Apply transformation
            var transformed = convertToIdiomaticPattern(node);

            // Mark as transformed
            context.markTransformed(nodeId, "enumPattern");

            // Record statistics
            context.recordMetric("enumPatternsTransformed", 1);

            return transformed;
        }

        return node;
    }
}
```

### 4. TestProgressTracker (`test/TestProgressTracker.hx`)

**Purpose**: Enables incremental test execution by tracking compilation progress and detecting changes.

**Key Features**:
- **Change Detection**: MD5 fingerprinting of test files
- **Real-time Progress**: JSON output for test runner integration
- **Test Manifest**: Lists all tests with recompilation status
- **Persistent State**: Maintains history across runs

**Output Files**:
```json
// .test-progress.json
{
  "timestamp": "2025-01-15 10:30:00",
  "elapsed": 12.5,
  "total": 100,
  "completed": 45,
  "failed": 2,
  "inProgress": 1,
  "tests": [
    {
      "path": "test/snapshot/core/arrays",
      "name": "arrays",
      "status": "Success",
      "fingerprint": "abc123_1234567890_def456"
    }
  ]
}

// .test-manifest.json
{
  "version": "1.0",
  "timestamp": "2025-01-15 10:30:00",
  "totalTests": 100,
  "tests": [
    {
      "path": "test/snapshot/core/arrays",
      "name": "arrays",
      "category": "core",
      "needsRecompilation": false
    }
  ]
}
```

### 5. PatternMatchBuilder (`ast/builders/PatternMatchBuilder.hx`)

**Purpose**: Template demonstrating how to create specialized builders using the infrastructure.

**Pattern for Creating New Builders**:
```haxe
class NewFeatureBuilder {
    var context: BuildContext;

    public function new(context: BuildContext) {
        this.context = context;
    }

    public function buildFeature(expr: TypedExpr): ElixirAST {
        // Use context for all shared operations
        var pos = expr.pos;
        context.setCurrentPosition(pos);

        // Generate unique ID for metadata
        var nodeId = context.generateNodeId();

        // Build AST node
        var node = {
            def: EFeature(...),
            metadata: {nodeId: nodeId, ...},
            pos: pos
        };

        // Store metadata for transformer
        context.setNodeMetadata(nodeId, {
            featureType: "special",
            needsTransform: true
        });

        return node;
    }
}
```

## 🔄 Integration Guide (Phase 2)

### Step 1: Implement BuildContext in ElixirASTBuilder

```haxe
// In ElixirASTBuilder.hx
class ElixirASTBuilder extends GenericCompiler<...> implements BuildContext {
    var astContext: ElixirASTContext;
    var patternBuilder: PatternMatchBuilder;

    public function new() {
        super();
        astContext = new ElixirASTContext();
        patternBuilder = new PatternMatchBuilder(this);
    }

    // Implement BuildContext interface
    public function getASTContext(): ElixirASTContext {
        return astContext;
    }

    public function resolveVariable(tvarId: Int, defaultName: String): String {
        return astContext.resolveVariable(tvarId, defaultName);
    }

    // ... implement other BuildContext methods
}
```

### Step 2: Extract Specialized Builders

```haxe
// Before: Monolithic method in ElixirASTBuilder
function compileSwitch(expr: TypedExpr, cases: Array<Case>, ...): ElixirAST {
    // 500+ lines of pattern matching logic
}

// After: Delegated to specialized builder
function compileSwitch(expr: TypedExpr, cases: Array<Case>, ...): ElixirAST {
    return patternBuilder.buildCaseExpression(expr, cases, defaultExpr, edef);
}
```

### Step 3: Wire TestProgressTracker

```haxe
// In ElixirCompiler.hx or ElixirASTBuilder.hx
var testTracker: TestProgressTracker;

override function onCompileStart() {
    if (isTestMode()) {
        testTracker = new TestProgressTracker("test/.cache");
        var testPath = getCurrentTestPath();
        testTracker.startTest(testPath, extractTestName(testPath));
    }
}

override function onCompileEnd(success: Bool) {
    if (testTracker != null) {
        if (success) {
            testTracker.completeTest();
        } else {
            testTracker.failTest("Compilation failed");
        }
        testTracker.finalize();
    }
}
```

### Step 4: Update Test Infrastructure

```makefile
# In test/Makefile
# Check manifest before running test
test-%: check-recompilation-%
    @$(MAKE) run-test-$*

check-recompilation-%:
    @if [ -f .cache/.test-manifest.json ]; then \
        needs=$$(jq -r '.tests[] | select(.name == "$*") | .needsRecompilation' .cache/.test-manifest.json); \
        if [ "$$needs" = "false" ]; then \
            echo "⏭️  Skipping $* (unchanged)"; \
            exit 0; \
        fi; \
    fi
```

## 📊 Benefits of This Architecture

### 1. **Separation of Concerns**
- Each builder focuses on one compilation aspect
- Transformers handle specific patterns
- Context manages shared state

### 2. **Testability**
```haxe
// Test builders in isolation
class PatternMatchBuilderTest {
    function testEnumPattern() {
        var mockContext = new MockBuildContext();
        var builder = new PatternMatchBuilder(mockContext);

        var result = builder.buildEnumPattern(...);

        Assert.equals(":rgb", result.def.elements[0].def);
        Assert.isTrue(mockContext.patternVariablesCalled);
    }
}
```

### 3. **Performance**
- Incremental test execution saves ~80% time on unchanged tests
- Cached naming transformations avoid redundant computation
- Transformation tracking prevents duplicate work

### 4. **Maintainability**
- 10,000+ line file → Multiple 200-500 line focused modules
- Clear interfaces between components
- Easy to add new features without breaking existing code

### 5. **Debugging**
```haxe
// Enhanced debugging with context tracking
#if debug_ast_builder
var nodeId = context.generateNodeId();
trace('[Builder] Created node ${nodeId} at ${context.getCurrentPosition()}');
context.setNodeMetadata(nodeId, {
    createdBy: "PatternMatchBuilder",
    timestamp: Sys.time()
});
#end
```

## 🚀 Next Steps

### Immediate (Phase 2A)
1. [ ] Implement BuildContext in ElixirASTBuilder
2. [ ] Extract LoopBuilder from loop compilation logic
3. [ ] Extract FunctionBuilder from function compilation
4. [ ] Wire TestProgressTracker to compiler

### Short-term (Phase 2B)
1. [ ] Create transformation pass infrastructure
2. [ ] Implement EnumPatternPass
3. [ ] Implement LoopOptimizationPass
4. [ ] Add pass orchestration to ElixirASTTransformer

### Medium-term (Phase 3)
1. [ ] Full modularization of ElixirASTBuilder
2. [ ] Performance profiling with statistics
3. [ ] Visual test progress dashboard
4. [ ] Parallel compilation support

## 📚 Related Documentation

- [`/src/reflaxe/elixir/ast/AGENTS.md`](../../src/reflaxe/elixir/ast/AGENTS.md) - AST-specific development context
- [`/src/reflaxe/elixir/AGENTS.md`](../../src/reflaxe/elixir/AGENTS.md) - Compiler development guidelines
- [`/docs/05-architecture/AST_PIPELINE_MIGRATION.md`](../05-architecture/AST_PIPELINE_MIGRATION.md) - AST pipeline architecture
- [`/test/AGENTS.md`](../../test/AGENTS.md) - Test infrastructure documentation

## 🎯 Success Metrics

Once fully integrated, this infrastructure should achieve:
- **File size reduction**: ElixirASTBuilder from 10,668 → <2,000 lines
- **Test execution time**: 60s → ~15s for unchanged tests
- **Module count**: 1 monolithic → 15-20 focused modules
- **Test isolation**: Each builder testable independently
- **Compilation performance**: 10-20% faster through caching

---

**Remember**: This infrastructure is the foundation for sustainable compiler development. Take time to understand it before making changes.