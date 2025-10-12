# Pipeline Analysis Guide

> **Parent Context**: See [AGENTS.md](AGENTS.md) for compiler development context

This guide covers the comprehensive pipeline pattern detection and analysis system used in Reflaxe.Elixir to generate idiomatic Elixir code with pipeline operators.

## 🎯 Overview

**Pipeline Analysis** is the process of detecting patterns in Haxe AST that should be compiled to Elixir's idiomatic pipeline operator (`|>`) syntax. The `PipelineAnalyzer` class centralizes this logic.

### Why Pipeline Analysis Matters

**Elixir Best Practice**: Functional transformations should use pipelines for readability:
```elixir
# ✅ IDIOMATIC: Pipeline style
data
|> Enum.filter(&valid?/1)
|> Enum.map(&transform/1)
|> Enum.reduce(0, &+/2)

# ❌ NESTED: Harder to read
Enum.reduce(Enum.map(Enum.filter(data, &valid?/1), &transform/1), 0, &+/2)
```

## 📊 Pipeline Pattern Detection

### Sequential Variable Operations Pattern
**Haxe Source**:
```haxe
var socket = assign(socket, :key1, value1);
socket = assign(socket, :key2, value2);
socket = assign(socket, :key3, value3);
```

**Generated Elixir**:
```elixir
socket
|> assign(:key1, value1)
|> assign(:key2, value2) 
|> assign(:key3, value3)
```

### Method Chaining Pattern
**Haxe Source**:
```haxe
var result = data.map(transform).filter(valid).reduce(combine);
```

**Generated Elixir**:
```elixir
data
|> Enum.map(&transform/1)
|> Enum.filter(&valid?/1)
|> Enum.reduce(&combine/2)
```

## 🔍 Core Analysis Functions

### Variable Reference Tracking
**Purpose**: Detect if an expression contains a reference to a specific variable

**Implementation Pattern**:
```haxe
function containsVariableReference(expr: TypedExpr, variableName: String): Bool {
    return switch(expr.expr) {
        case TLocal(v): v.name == variableName;
        case TField(e, fa): containsVariableReference(e, variableName);
        case TCall(e, el): 
            containsVariableReference(e, variableName) || 
            Lambda.exists(el, arg -> containsVariableReference(arg, variableName));
        // ... recursive traversal for all TypedExpr variants
    };
}
```

**Key Patterns**:
- **TLocal(v)**: Direct variable reference
- **TField(e, fa)**: Method calls on the variable
- **TCall(e, el)**: Function calls with variable as argument
- **Recursive traversal**: Check all sub-expressions

### Statement Targeting Analysis
**Purpose**: Identify statements that operate on a pipeline variable

**Pipeline-able Patterns**:
```haxe
// Pattern 1: Variable assignment with same variable usage
var x = f(x, other_args);

// Pattern 2: Reassignment with same variable usage  
x = f(x, other_args);
```

**Non-pipeline Patterns**:
```haxe
// Terminal operation: consumes variable but doesn't continue pipeline
var result = Repo.all(query);

// Different variable: breaks the pipeline chain
var y = f(x, other_args);
```

### Terminal Operation Detection
**Purpose**: Identify operations that end a pipeline chain

**Common Terminal Functions**:
- **Repo operations**: `Repo.all`, `Repo.one`, `Repo.get`, `Repo.insert`
- **Collection endpoints**: Operations that return final results
- **Side effects**: Logging, IO operations

**Pattern**:
```haxe
function isTerminalOperation(stmt: TypedExpr, variableName: String): Bool {
    return switch(stmt.expr) {
        case TCall(funcExpr, args):
            var funcName = extractFunctionNameFromCall(funcExpr);
            var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get"];
            
            if (terminalFunctions.indexOf(funcName) >= 0) {
                // Check if first argument references our variable
                args.length > 0 && containsVariableReference(args[0], variableName);
            } else {
                false;
            }
        default: false;
    };
}
```

## 🧩 Function Name Extraction

### Multi-form Function Calls
Elixir function calls can take multiple forms in the Haxe AST:

**Module.function Pattern**:
```haxe
case TField({expr: TLocal({name: moduleName})}, fa):
    // Repo.all, String.trim, etc.
    moduleName + "." + funcName;
```

**Type.function Pattern**:
```haxe
case TField({expr: TTypeExpr(moduleType)}, fa):
    // Static calls like Repo.all
    switch(fa) {
        case FStatic(classRef, cf):
            var moduleName = classRef.get().name;
            var methodName = cf.get().name;
            moduleName + "." + methodName;
    }
```

**Simple Function Pattern**:
```haxe
case TLocal({name: funcName}):
    // Direct function call
    funcName;
```

## 📈 Pipeline Compilation Strategy

### Processing Statement Indices
**Problem**: After detecting a pipeline, we need to know which statements were processed to avoid double-compilation.

**Solution**:
```haxe
function getProcessedStatementIndices(statements: Array<TypedExpr>, pattern: PipelinePattern): Array<Int> {
    var processedIndices = [];
    var targetVariable = pattern.variable;
    
    for (i in 0...statements.length) {
        var stmt = statements[i];
        if (statementTargetsVariable(stmt, targetVariable)) {
            processedIndices.push(i);
        }
    }
    
    return processedIndices;
}
```

### Terminal Call Extraction
**Purpose**: Convert terminal operations from function calls to pipeline form

**Example Transformation**:
```haxe
// Input: Repo.all(query, timeout: 5000)
// Variable: query
// Output: "Repo.all(timeout: 5000)"

function extractTerminalCall(expr: TypedExpr, variableName: String): String {
    // Extract remaining arguments after removing pipeline variable
    var remainingArgs = [];
    for (i in 1...args.length) {
        remainingArgs.push(compiler.compileExpression(args[i]));
    }
    
    return funcName + "(" + remainingArgs.join(", ") + ")";
}
```

## ⚡ Performance Considerations

### Efficient AST Traversal
- **Recursive functions** should short-circuit when possible
- **Pattern matching** should handle most common cases first
- **Debug traces** should be conditional (`#if debug_pipeline_analysis`)

### Memory Management
- **Avoid deep copying** of AST nodes during analysis
- **Reuse analysis results** where possible
- **Clean up** temporary data structures

## 🧪 Testing Pipeline Analysis

### Debug Trace System
**Enable comprehensive tracing**:
```bash
haxe -D debug_pipeline_analysis build.hxml
```

**Trace Output**:
```
[PipelineAnalyzer] Checking variable reference: socket in TCall(...)
[PipelineAnalyzer] Variable reference result: true
[PipelineAnalyzer] ✓ PATTERN DETECTED
```

### Test Cases Coverage
**Essential test scenarios**:
- Simple sequential assignments
- Mixed pipeline/non-pipeline statements
- Terminal operations with various argument patterns
- Complex nested expressions with variable references
- Edge cases: shadowing, scoping, multiple variables

## 🔧 Integration with Main Compiler

### Initialization Pattern
```haxe
// In ElixirCompiler.hx
class ElixirCompiler {
    var pipelineAnalyzer: PipelineAnalyzer;
    
    override function setupCompiler() {
        pipelineAnalyzer = new PipelineAnalyzer(this);
    }
}
```

### Delegation Pattern
```haxe
public function containsVariableReference(expr: TypedExpr, variableName: String): Bool {
    return pipelineAnalyzer.containsVariableReference(expr, variableName);
}
```

## 📚 Related Documentation

- **[PipelineOptimizer.hx](../../src/reflaxe/elixir/helpers/PipelineOptimizer.hx)** - Pipeline compilation and code generation
- **[COMPILATION_FLOW.md](COMPILATION_FLOW.md)** - Overall compilation pipeline
- **[AST_CLEANUP_PATTERNS.md](AST_CLEANUP_PATTERNS.md)** - AST processing best practices
- **[DEBUG_XRAY_SYSTEM.md](DEBUG_XRAY_SYSTEM.md)** - Debugging pipeline analysis

## 🎯 Future Enhancements

### Advanced Pattern Detection
- **Conditional pipelines**: If-else chains that could use pipelines
- **Nested pipelines**: Pipelines within function arguments
- **Cross-function pipelines**: Variables passed between functions

### Performance Optimization
- **Caching analysis results** for repeated expressions
- **Parallel analysis** for independent statement groups
- **Lazy evaluation** of expensive analysis operations

---

This guide provides the foundation for understanding and extending pipeline analysis in Reflaxe.Elixir. The goal is always generating idiomatic Elixir code that leverages the language's functional programming strengths.