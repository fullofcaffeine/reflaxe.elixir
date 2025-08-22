# Pattern Analysis Guide

> **Parent Context**: See [CLAUDE.md](CLAUDE.md) for compiler development context

This guide covers the comprehensive pattern detection system used in Reflaxe.Elixir to identify and transform AST patterns for optimal Elixir code generation.

## 🎯 Overview

**Pattern Analysis** is the process of recognizing specific AST structures that require special compilation strategies. The `PatternAnalysisCompiler` centralizes pattern detection logic for maintainability and performance.

## 📊 Core Pattern Categories

### 1. Structural Patterns
**Purpose**: Identify code structures that map to Elixir idioms

#### Pipeline Patterns
```haxe
// Sequential operations on same variable
var x = f(x);
x = g(x);
x = h(x);
// → Detected as pipeline candidate
```

#### Pattern Matching Structures
```haxe
switch(value) {
    case Some(x): process(x);
    case None: defaultValue();
}
// → Detected as Elixir pattern match
```

#### Recursive Patterns
```haxe
function factorial(n: Int): Int {
    return n <= 1 ? 1 : n * factorial(n - 1);
}
// → Detected as tail-recursive candidate
```

### 2. Framework Patterns
**Purpose**: Detect framework-specific annotations and structures

#### LiveView Patterns
```haxe
@:liveview
class TodoLive {
    function mount(params, session, socket) { }
    function handleEvent(event, params, socket) { }
}
// → Detected as LiveView component
```

#### Ecto Schema Patterns
```haxe
@:schema("todos")
class Todo {
    var id: Int;
    var title: String;
    var completed: Bool = false;
}
// → Detected as Ecto schema
```

### 3. Optimization Patterns
**Purpose**: Identify opportunities for performance improvements

#### Loop Transformation Patterns
```haxe
for (item in items) {
    results.push(transform(item));
}
// → Detected as Enum.map candidate
```

#### Accumulator Patterns
```haxe
var sum = 0;
for (n in numbers) {
    sum += n;
}
// → Detected as Enum.reduce candidate
```

## 🔍 Pattern Detection Algorithm

### AST Traversal Strategy
```haxe
function analyzeExpression(expr: TypedExpr): PatternInfo {
    var patterns = [];
    
    // Check for immediate patterns
    var immediatePattern = detectImmediatePattern(expr);
    if (immediatePattern != null) {
        patterns.push(immediatePattern);
    }
    
    // Recursively analyze sub-expressions
    switch(expr.expr) {
        case TBlock(exprs):
            for (e in exprs) {
                var subPatterns = analyzeExpression(e);
                patterns = patterns.concat(subPatterns);
            }
        case TIf(cond, then, else_):
            patterns = patterns.concat(analyzeExpression(cond));
            patterns = patterns.concat(analyzeExpression(then));
            if (else_ != null) {
                patterns = patterns.concat(analyzeExpression(else_));
            }
        // ... more cases
    }
    
    return combinePatterns(patterns);
}
```

### Pattern Matching Rules
```haxe
function detectImmediatePattern(expr: TypedExpr): Null<Pattern> {
    return switch(expr.expr) {
        // Variable reassignment pattern
        case TBinop(OpAssign, {expr: TLocal(v)}, right) 
            if (containsVariable(right, v.name)):
            {
                type: PipelineCandidate,
                variable: v.name,
                operation: right
            };
            
        // Method chaining pattern
        case TCall({expr: TField(obj, field)}, args):
            if (isChainableMethod(field)) {
                {
                    type: MethodChain,
                    object: obj,
                    method: field,
                    arguments: args
                };
            } else null;
            
        // Switch pattern
        case TSwitch(value, cases, default_):
            {
                type: PatternMatch,
                value: value,
                cases: cases,
                default: default_
            };
            
        default: null;
    };
}
```

## 📈 Pattern Confidence Scoring

### Confidence Levels
```haxe
enum PatternConfidence {
    High;    // 90-100% - Definitely should apply transformation
    Medium;  // 60-89%  - Likely beneficial
    Low;     // 30-59%  - Possible but uncertain
    None;    // 0-29%   - Not worth transforming
}
```

### Scoring Algorithm
```haxe
function scorePattern(pattern: Pattern): PatternConfidence {
    var score = 0;
    
    switch(pattern.type) {
        case PipelineCandidate:
            // High confidence for 3+ operations
            if (pattern.operationCount >= 3) score += 40;
            // Medium confidence for 2 operations
            else if (pattern.operationCount == 2) score += 25;
            
            // Bonus for idiomatic functions
            if (isIdiomaticFunction(pattern.operation)) score += 30;
            
            // Bonus for no side effects
            if (!hasSideEffects(pattern.operation)) score += 20;
            
        case MethodChain:
            // High confidence for Enum operations
            if (pattern.module == "Enum") score += 50;
            
            // Chain length bonus
            score += pattern.chainLength * 15;
            
        case PatternMatch:
            // High confidence for enum matching
            if (isEnumType(pattern.valueType)) score += 60;
            
            // Exhaustiveness bonus
            if (isExhaustive(pattern.cases)) score += 30;
    }
    
    return scoreToConfidence(score);
}
```

## 🧩 Pattern Context Analysis

### Variable Lifetime Analysis
```haxe
function analyzeVariableLifetime(variable: String, scope: TypedExpr): VariableLifetime {
    var firstUse = findFirstUse(variable, scope);
    var lastUse = findLastUse(variable, scope);
    var modifications = findModifications(variable, scope);
    
    return {
        variable: variable,
        firstUse: firstUse,
        lastUse: lastUse,
        modifications: modifications,
        isPipelineCandidate: modifications.length >= 2
    };
}
```

### Dependency Analysis
```haxe
function analyzeDependencies(expr: TypedExpr): DependencyGraph {
    var graph = new DependencyGraph();
    
    function visit(e: TypedExpr, dependencies: Array<String>) {
        switch(e.expr) {
            case TLocal(v):
                for (dep in dependencies) {
                    graph.addEdge(v.name, dep);
                }
            case TBinop(OpAssign, {expr: TLocal(v)}, right):
                var deps = extractVariables(right);
                graph.addNode(v.name, deps);
            // ... more cases
        }
    }
    
    visit(expr, []);
    return graph;
}
```

## ⚡ Performance Optimization

### Pattern Cache
```haxe
class PatternCache {
    var cache: Map<String, PatternInfo> = new Map();
    
    public function get(expr: TypedExpr): Null<PatternInfo> {
        var key = generateKey(expr);
        return cache.get(key);
    }
    
    public function set(expr: TypedExpr, info: PatternInfo): Void {
        var key = generateKey(expr);
        cache.set(key, info);
    }
    
    function generateKey(expr: TypedExpr): String {
        // Generate stable key from AST structure
        return Std.string(expr.expr);
    }
}
```

### Early Termination
```haxe
function quickPatternCheck(expr: TypedExpr): Bool {
    // Quick checks to avoid expensive analysis
    return switch(expr.expr) {
        case TConst(_): false;  // Constants never have patterns
        case TLocal(_): false;  // Single variables don't need analysis
        case TBlock(exprs) if (exprs.length < 2): false;  // Too small
        default: true;  // Worth analyzing
    };
}
```

## 🧪 Testing Pattern Analysis

### Pattern Test Framework
```haxe
class PatternTest {
    static function testPipelineDetection() {
        var code = "
            var x = init();
            x = transform1(x);
            x = transform2(x);
        ";
        
        var ast = parseHaxe(code);
        var patterns = analyzer.analyze(ast);
        
        assert(patterns.length == 1);
        assert(patterns[0].type == PipelineCandidate);
        assert(patterns[0].operationCount == 2);
    }
}
```

### Debug Visualization
```haxe
#if debug_pattern_analysis
function visualizePattern(pattern: Pattern): String {
    var viz = "\n=== PATTERN DETECTED ===\n";
    viz += "Type: " + pattern.type + "\n";
    viz += "Confidence: " + pattern.confidence + "\n";
    viz += "Location: " + pattern.pos + "\n";
    viz += "Suggestion: " + pattern.suggestion + "\n";
    viz += "=======================\n";
    return viz;
}
#end
```

## 🔧 Integration Points

### Compiler Integration
```haxe
// In ElixirCompiler.hx
override function compileExpression(expr: TypedExpr): String {
    // Analyze patterns first
    var patterns = patternAnalyzer.analyze(expr);
    
    // Apply transformations based on patterns
    if (patterns.hasPipelinePattern()) {
        return pipelineOptimizer.compilePipeline(expr, patterns);
    } else if (patterns.hasPatternMatch()) {
        return patternMatcher.compileMatch(expr, patterns);
    } else {
        return super.compileExpression(expr);
    }
}
```

### Optimization Pipeline
```
AST → Pattern Analysis → Confidence Scoring → Transformation → Code Generation
```

## 📊 Pattern Categories Reference

### Transformation Patterns
- **Pipeline**: Sequential operations on same variable
- **Map/Filter/Reduce**: Loop transformations
- **Pattern Match**: Switch to Elixir pattern matching
- **Tail Recursion**: Recursive function optimization

### Framework Patterns  
- **LiveView**: Component lifecycle methods
- **Ecto**: Schema and changeset structures
- **Phoenix**: Router, controller, channel patterns
- **GenServer**: OTP behavior patterns

### Optimization Patterns
- **Constant Folding**: Compile-time evaluation
- **Dead Code**: Unreachable code elimination
- **Inline Expansion**: Small function inlining
- **Loop Fusion**: Combining adjacent loops

## 📚 Related Documentation

- **[PIPELINE_ANALYSIS.md](PIPELINE_ANALYSIS.md)** - Specific pipeline pattern detection
- **[AST_CLEANUP_PATTERNS.md](AST_CLEANUP_PATTERNS.md)** - AST processing patterns
- **[COMPILATION_FLOW.md](COMPILATION_FLOW.md)** - Overall compilation pipeline
- **[DEBUG_XRAY_SYSTEM.md](DEBUG_XRAY_SYSTEM.md)** - Pattern analysis debugging

---

This guide provides the foundation for understanding pattern analysis in Reflaxe.Elixir. The goal is identifying opportunities to generate more idiomatic and performant Elixir code through intelligent pattern recognition.