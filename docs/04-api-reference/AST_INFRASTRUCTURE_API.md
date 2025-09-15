# AST Infrastructure API Reference

> **Version**: 1.0.0
> **Created**: January 2025
> **Package**: `reflaxe.elixir.ast.context`

## Table of Contents

1. [ElixirASTContext](#elixirastcontext)
2. [BuildContext](#buildcontext)
3. [TransformContext](#transformcontext)
4. [ClauseContext](#clausecontext)
5. [TestProgressTracker](#testprogresstracker)
6. [PatternMatchBuilder](#patternmatchbuilder)

---

## ElixirASTContext

**Package**: `reflaxe.elixir.ast.context`
**Type**: Class
**Purpose**: Central state container for compilation pipeline

### Constructor

```haxe
new ElixirASTContext()
```
Creates a new context with empty initial state.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `globalVariableMap` | `Map<Int, String>` | Global TVar.id to Elixir name mappings |
| `patternVariableRegistry` | `Map<Int, String>` | Highest-priority pattern variable mappings |
| `tempVariableMap` | `Map<String, String>` | Temp variable name mappings (g → actualName) |
| `clauseContextStack` | `Array<ClauseContext>` | Stack of active clause contexts |
| `nodeMetadata` | `Map<String, Dynamic>` | Metadata storage by node ID |
| `enumTypeCache` | `Map<String, EnumType>` | Cached enum type information |
| `idiomaticEnums` | `Map<String, Bool>` | Tracks @:elixirIdiomatic enums |
| `moduleNameMap` | `Map<String, String>` | Module name transformations cache |
| `functionNameMap` | `Map<String, String>` | Function name transformations cache |

### Methods

#### Variable Resolution

```haxe
function resolveVariable(tvarId: Int, defaultName: String): String
```
Resolves variable name using priority hierarchy.

**Priority Order**:
1. Pattern variable registry
2. Current clause context
3. Global variable map
4. Default name

```haxe
function registerPatternVariable(tvarId: Int, patternName: String): Void
```
Registers a pattern variable with highest priority.

```haxe
function registerTempMapping(tempName: String, actualName: String): Void
```
Maps generated temp names to meaningful names.

#### Clause Context Management

```haxe
function pushClauseContext(context: ClauseContext): Void
```
Pushes a new clause context onto the stack.

```haxe
function popClauseContext(): ClauseContext
```
Pops and returns the current clause context.

```haxe
function getCurrentClauseContext(): Null<ClauseContext>
```
Returns current active clause context or null.

#### Metadata Management

```haxe
function setNodeMetadata(nodeId: String, metadata: Dynamic): Void
```
Stores metadata for an AST node.

```haxe
function getNodeMetadata(nodeId: String): Dynamic
```
Retrieves metadata for an AST node.

```haxe
function isIdiomaticEnum(enumName: String, enumType: EnumType): Bool
```
Checks if enum has @:elixirIdiomatic metadata (cached).

#### Test Progress Integration

```haxe
function startTest(testPath: String): Void
```
Marks test compilation start.

```haxe
function completeTest(success: Bool): Void
```
Marks test completion with result.

```haxe
function getTestResults(): Map<String, TestResult>
```
Returns copy of test results.

---

## BuildContext

**Package**: `reflaxe.elixir.ast.context`
**Type**: Interface
**Purpose**: Interface for AST builders to access shared state

### Methods

#### Core Access

```haxe
function getASTContext(): ElixirASTContext
```
Returns the shared AST context.

#### Variable Resolution

```haxe
function resolveVariable(tvarId: Int, defaultName: String): String
```
Resolves variable name using context's priority hierarchy.

```haxe
function registerPatternVariable(tvarId: Int, patternName: String): Void
```
Registers pattern variable with highest priority.

#### Position Tracking

```haxe
function getCurrentPosition(): Position
```
Returns current source position.

```haxe
function setCurrentPosition(pos: Position): Void
```
Updates current position for error tracking.

#### Type Context

```haxe
function getCurrentModule(): Null<ModuleType>
```
Returns current module being compiled.

```haxe
function getCurrentClass(): Null<ClassType>
```
Returns current class being compiled.

```haxe
function getCurrentFunction(): Null<ClassField>
```
Returns current function being compiled.

#### Metadata Management

```haxe
function setNodeMetadata(nodeId: String, metadata: Dynamic): Void
```
Stores metadata for AST node.

```haxe
function generateNodeId(): String
```
Generates unique node identifier.

#### Type Checking

```haxe
function isIdiomaticEnum(enumType: EnumType): Bool
```
Checks for @:elixirIdiomatic metadata.

#### Clause Context

```haxe
function getClauseContext(caseIndex: Int): ClauseContext
```
Gets or creates clause context for case.

```haxe
function pushClauseContext(context: ClauseContext): Void
```
Activates clause context.

```haxe
function popClauseContext(): ClauseContext
```
Deactivates and returns clause context.

#### Naming Conventions

```haxe
function getModuleName(originalName: String): String
```
Returns transformed module name (cached).

```haxe
function getFunctionName(originalName: String): String
```
Returns transformed function name (cached).

#### Pattern Context

```haxe
function isInPattern(): Bool
```
Checks if currently building pattern.

```haxe
function setInPattern(inPattern: Bool): Void
```
Updates pattern context state.

#### Error Reporting

```haxe
function warning(message: String, ?pos: Position): Void
```
Reports compilation warning.

```haxe
function error(message: String, ?pos: Position): Void
```
Reports compilation error.

---

## TransformContext

**Package**: `reflaxe.elixir.ast.context`
**Type**: Interface
**Purpose**: Interface for transformation passes

### Methods

#### Core Access

```haxe
function getASTContext(): ElixirASTContext
```
Returns shared AST context.

#### Metadata Operations

```haxe
function getNodeMetadata(nodeId: String): Dynamic
```
Reads metadata from builder phase.

```haxe
function setNodeMetadata(nodeId: String, metadata: Dynamic): Void
```
Updates metadata for other passes.

```haxe
function hasMetadataFlag(nodeId: String, flag: String): Bool
```
Checks for boolean metadata flag.

#### Transformation Tracking

```haxe
function hasTransformation(nodeId: String, transformName: String): Bool
```
Checks if transformation already applied.

```haxe
function markTransformed(nodeId: String, transformName: String): Void
```
Records transformation application.

```haxe
function getAppliedTransformations(nodeId: String): Array<String>
```
Returns all transformations for node.

#### Variable Resolution

```haxe
function resolveVariable(tvarId: Int, defaultName: String): String
```
Uses context's variable resolution.

#### Mode Management

```haxe
function isIdiomaticMode(): Bool
```
Checks idiomatic transformation mode.

```haxe
function setIdiomaticMode(idiomatic: Bool): Void
```
Sets idiomatic transformation mode.

#### Pass Management

```haxe
function getCurrentPass(): String
```
Returns current pass name.

```haxe
function setCurrentPass(passName: String): Void
```
Updates current pass.

#### Pattern Detection

```haxe
function shouldTransformPattern(pattern: String): Bool
```
Checks if pattern should transform.

```haxe
function registerPatternDetection(nodeId: String, pattern: String): Void
```
Records pattern detection.

#### Statistics

```haxe
function getPassStatistics(passName: String): TransformStats
```
Returns pass statistics.

```haxe
function recordMetric(metric: String, value: Dynamic): Void
```
Records performance metric.

#### Configuration

```haxe
function getConfig(key: String): Dynamic
```
Accesses transformation config.

#### Sub-contexts

```haxe
function createSubContext(): TransformContext
```
Creates child context for recursion.

#### Logging

```haxe
function warning(message: String): Void
```
Logs transformation warning.

```haxe
function info(message: String): Void
```
Logs transformation info.

### Types

```haxe
typedef TransformStats = {
    var nodesExamined: Int;
    var nodesTransformed: Int;
    var patternsDetected: Map<String, Int>;
    var executionTime: Float;
    var customMetrics: Map<String, Dynamic>;
}
```

---

## ClauseContext

**Package**: `reflaxe.elixir.ast.context`
**Type**: Class
**Purpose**: Variable mapping for switch case bodies

### Constructor

```haxe
new ClauseContext(?locals: Map<String, Bool>, ?varMapping: Map<Int, String>)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `localToName` | `Map<Int, String>` | TVar.id to pattern variable name |
| `syntheticBindings` | `Array<{name: String, init: ElixirAST}>` | Synthetic variable bindings |
| `localsInScope` | `Map<String, Bool>` | Variables in scope |

### Methods

```haxe
function needTemp(name: String, buildInit: () -> ElixirAST): ElixirAST
```
Requests synthetic temporary variable.

```haxe
function wrapBody(body: ElixirAST): ElixirAST
```
Wraps body with synthetic bindings.

---

## TestProgressTracker

**Package**: `reflaxe.elixir.test`
**Type**: Class
**Purpose**: Incremental test execution tracking

### Constructor

```haxe
new TestProgressTracker(?outputDir: String)
```

### Methods

#### Test Lifecycle

```haxe
function startTest(testPath: String, testName: String): Void
```
Marks test start.

```haxe
function completeTest(): Void
```
Marks successful completion.

```haxe
function failTest(error: String, ?pos: Position): Void
```
Marks test failure.

```haxe
function addWarning(warning: String, ?pos: Position): Void
```
Adds warning to current test.

#### Change Detection

```haxe
function needsRecompilation(testPath: String): Bool
```
Checks if test changed.

```haxe
function getChangedTests(testPaths: Array<String>): Array<String>
```
Returns changed tests.

#### Output Generation

```haxe
function generateManifest(tests: Array<TestInfo>): Void
```
Creates test manifest JSON.

```haxe
function getSummary(): TestSummary
```
Returns summary statistics.

```haxe
function finalize(): Void
```
Completes tracking session.

### Types

```haxe
typedef TestInfo = {
    var path: String;
    var name: String;
    var status: TestStatus;
    var startTime: Float;
    var endTime: Null<Float>;
    var errors: Array<TestError>;
    var warnings: Array<TestWarning>;
    var fingerprint: String;
}

enum TestStatus {
    InProgress;
    Success;
    Failed;
}

typedef TestSummary = {
    var totalTests: Int;
    var successful: Int;
    var failed: Int;
    var inProgress: Int;
    var totalTime: Float;
    var changedTests: Int;
}
```

---

## PatternMatchBuilder

**Package**: `reflaxe.elixir.ast.builders`
**Type**: Class (Template)
**Purpose**: Specialized builder for pattern matching

### Constructor

```haxe
new PatternMatchBuilder(context: BuildContext)
```

### Methods

```haxe
function buildCaseExpression(
    expr: TypedExpr,
    cases: Array<Case>,
    defaultExpr: Null<TypedExpr>,
    edef: Null<TypedExpr>
): ElixirAST
```
Builds complete case expression.

```haxe
function buildCaseClause(
    switchCase: Case,
    clauseContext: ClauseContext
): Null<ElixirCaseClause>
```
Builds single case clause.

```haxe
function buildPattern(
    value: TypedExpr,
    clauseContext: ClauseContext
): Null<ElixirAST>
```
Builds pattern from value.

```haxe
function buildEnumPattern(
    ef: EnumField,
    args: Array<TypedExpr>,
    clauseContext: ClauseContext
): ElixirAST
```
Builds enum constructor pattern.

### Types

```haxe
typedef ElixirCaseClause = {
    var patterns: Array<ElixirAST>;
    var guard: Null<ElixirAST>;
    var body: ElixirAST;
}
```

---

## Usage Examples

### Creating a Specialized Builder

```haxe
class ArrayBuilder {
    var context: BuildContext;

    public function new(context: BuildContext) {
        this.context = context;
    }

    public function buildArrayComprehension(
        expr: TypedExpr,
        generator: TypedExpr,
        filter: Null<TypedExpr>
    ): ElixirAST {
        // Generate unique ID
        var nodeId = context.generateNodeId();

        // Build comprehension
        var ast = {
            def: EComprehension(...),
            metadata: {
                nodeId: nodeId,
                comprehensionType: "array"
            },
            pos: expr.pos
        };

        // Store metadata for transformer
        context.setNodeMetadata(nodeId, {
            hasFilter: filter != null,
            canOptimize: true
        });

        return ast;
    }
}
```

### Creating a Transformation Pass

```haxe
class OptimizationPass {
    function transform(
        node: ElixirAST,
        context: TransformContext
    ): ElixirAST {
        var nodeId = node.metadata.nodeId;

        // Check if already optimized
        if (context.hasTransformation(nodeId, "optimization")) {
            return node;
        }

        // Read metadata
        var metadata = context.getNodeMetadata(nodeId);
        if (metadata != null && metadata.canOptimize) {
            // Apply optimization
            var optimized = optimizeNode(node);

            // Mark as transformed
            context.markTransformed(nodeId, "optimization");

            // Record metric
            context.recordMetric("nodesOptimized", 1);

            return optimized;
        }

        return node;
    }
}
```

### Using TestProgressTracker

```haxe
class CompilerWithTracking {
    var tracker: TestProgressTracker;

    function compileTest(testPath: String) {
        tracker = new TestProgressTracker("test/.cache");

        // Check if needs recompilation
        if (!tracker.needsRecompilation(testPath)) {
            trace("Skipping unchanged test: " + testPath);
            return;
        }

        // Start tracking
        tracker.startTest(testPath, extractTestName(testPath));

        try {
            // Compile test
            compileFile(testPath);
            tracker.completeTest();
        } catch (e: Dynamic) {
            tracker.failTest(Std.string(e));
            throw e;
        }

        // Generate manifest
        tracker.generateManifest([...]);
        tracker.finalize();
    }
}
```

---

## Best Practices

### 1. Always Use Interfaces

```haxe
// ✅ GOOD: Depend on interface
class MyBuilder {
    var context: BuildContext;  // Interface type
}

// ❌ BAD: Depend on concrete implementation
class MyBuilder {
    var compiler: ElixirASTBuilder;  // Concrete type
}
```

### 2. Generate Node IDs for Metadata

```haxe
// ✅ GOOD: Unique ID for tracking
var nodeId = context.generateNodeId();
node.metadata.nodeId = nodeId;

// ❌ BAD: No way to track node
node.metadata = {};  // Can't correlate later
```

### 3. Use Priority Resolution

```haxe
// ✅ GOOD: Let context handle priority
var name = context.resolveVariable(tvarId, defaultName);

// ❌ BAD: Direct access to maps
var name = context.getASTContext().globalVariableMap.get(tvarId);
```

### 4. Track Transformations

```haxe
// ✅ GOOD: Prevent duplicate work
if (!context.hasTransformation(nodeId, "myTransform")) {
    // Transform...
    context.markTransformed(nodeId, "myTransform");
}

// ❌ BAD: May transform multiple times
// Transform without checking...
```

---

**Version History**:
- 1.0.0 (January 2025) - Initial infrastructure creation