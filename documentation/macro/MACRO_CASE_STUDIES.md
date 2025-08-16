# Macro Case Studies for Reflaxe.Elixir

## 🎯 Overview

This document presents deep-dive case studies of macro implementations in Reflaxe.Elixir, providing real-world examples of macro architecture, challenges faced, and solutions developed. Each case study preserves the knowledge and insights gained during implementation.

## Table of Contents

1. [Case Study 1: Async/Await Anonymous Function Support](#case-study-1-asyncawait-anonymous-function-support)
2. [Case Study 2: Build Macro Architecture](#case-study-2-build-macro-architecture)
3. [Future Case Studies](#future-case-studies)

## Case Study 1: Async/Await Anonymous Function Support

### Problem Statement

**Goal**: Extend the existing async/await macro system to support @:async metadata on anonymous functions, enabling modern asynchronous programming patterns in Haxe→JavaScript compilation.

**Challenge**: Anonymous functions require different AST transformation than class methods, and the existing system only handled class-level function declarations.

**Requirements**:
- Support `@:async function() { ... }` syntax in variable assignments
- Generate clean JavaScript with Promise.resolve() wrapping
- Avoid double-wrapping Promise types
- Handle both implicit and explicit return types
- Maintain compatibility with existing class method async support

### Technical Context

**Existing System**: The async/await system already handled class methods with @:async metadata:

```haxe
// Already working
@:async
public static function loadData(): Promise<String> {
    var config = Async.await(loadConfig());
    return config.data;
}
```

**New Requirement**: Support anonymous functions:

```haxe
// Needed to work
var loadData = @:async function() {
    var config = Async.await(loadConfig());
    return config.data;
};
```

### Implementation Journey

#### Phase 1: Understanding the Challenge

**Initial Investigation**: Anonymous functions appear in the AST as expressions, not field declarations. The existing build macro only processed Field objects, so it missed anonymous functions in variable assignments.

**Key Insight**: Build macros process classes holistically and can traverse expression trees to find nested patterns. The solution required recursive expression processing.

**AST Structure Discovery**:
```haxe
// Anonymous function in variable assignment
var func = @:async function() { ... };

// AST structure:
EVars([{
    name: "func",
    expr: EMeta({name: ":async"}, EFunction(FAnonymous, {...}))
}])
```

#### Phase 2: Recursive Expression Processing

**Solution Architecture**: Implement two-phase processing:
1. **Field-level processing**: Handle class methods (existing)
2. **Expression-level processing**: Traverse expression trees to find anonymous functions (new)

**Implementation**:
```haxe
public static function build(): Array<Field> {
    var fields = Context.getBuildFields();
    var transformedFields: Array<Field> = [];
    
    for (field in fields) {
        switch (field.kind) {
            case FFun(func):
                if (hasAsyncMeta(field.meta)) {
                    // Phase 1: Transform async class method
                    var transformedField = transformAsyncFunction(field, func);
                    // Phase 2: Process any nested anonymous functions
                    transformedField = processFieldExpressions(transformedField);
                } else {
                    // Phase 2: Process anonymous functions even in non-async methods
                    field = processFieldExpressions(field);
                }
            // Handle other field types...
        }
    }
    
    return transformedFields;
}
```

**Recursive Processing Pattern**:
```haxe
static function processExpression(expr: Expr): Expr {
    return switch (expr.expr) {
        case EMeta(meta, funcExpr) if (isAsyncMeta(meta.name)):
            switch (funcExpr.expr) {
                case EFunction(kind, func):
                    // Transform anonymous async function
                    transformAnonymousAsync(funcExpr, func, meta, expr.pos);
                case _:
                    expr.map(processExpression);
            }
        case _:
            // Recursively process all child expressions
            expr.map(processExpression);
    }
}
```

#### Phase 3: The Promise Type Detection Crisis

**Critical Bug Discovered**: When users wrote explicit return types like `Promise<String>`, the compiler threw double-wrapping errors:

```
Error: String should be js.lib.Promise<String>
... have: js.lib.Promise<String>
... want: js.lib.Promise<js.lib.Promise<...>>
```

**Root Cause Investigation**: The issue was in type detection. Our pattern matching was looking for:
```haxe
case TPath({name: "Promise", pack: ["js", "lib"]}):
    // Don't double-wrap
```

But Haxe's import resolution was giving us:
```haxe
// User writes: Promise<String>
// AST shows: TPath({name: Promise, pack: []})  // Empty pack!
```

**The Breakthrough**: Understanding that Haxe's import system affects AST structure. When `js.lib.Promise` is imported, references to `Promise<T>` appear with empty pack arrays, not full package paths.

**Solution**:
```haxe
case TPath(p) if (p.name == "Promise" && 
                 (p.pack.length == 0 ||  // Imported form
                  (p.pack.length == 2 && p.pack[0] == "js" && p.pack[1] == "lib"))): // Qualified form
    // Handle both imported and qualified Promise types
    return returnType; // Don't double-wrap
```

#### Phase 4: Context-Aware Transformation

**Challenge**: Anonymous functions need different transformation than class methods.

**Class Methods**: Use async IIFE (Immediately Invoked Function Expression):
```javascript
// Generated for class methods
static getData() {
    return (async function() {
        return "data";
    })();
}
```

**Anonymous Functions**: Direct Promise wrapping:
```javascript
// Generated for anonymous functions
var getData = function() {
    return Promise.resolve("data");
};
```

**Implementation**:
```haxe
// Class method transformation
static function transformFunctionBody(expr: Expr, pos: Position): Expr {
    return macro @:pos(pos) {
        return js.Syntax.code("(async function() {0})()", ${wrapInAsyncFunction(transformedBody, pos)});
    };
}

// Anonymous function transformation  
static function transformAnonymousFunctionBody(expr: Expr, pos: Position): Expr {
    var processedExpr = processAwaitInExpr(expr);
    
    return switch (processedExpr.expr) {
        case EReturn(returnExpr):
            if (returnExpr != null) {
                {
                    expr: EReturn(macro @:pos(pos) js.lib.Promise.resolve($returnExpr)),
                    pos: pos
                };
            } else {
                {
                    expr: EReturn(macro @:pos(pos) js.lib.Promise.resolve(null)),
                    pos: pos
                };
            }
        // Handle other cases...
    };
}
```

#### Phase 5: Testing and Validation

**Testing Strategy**: Compiler-level testing with snapshot comparison.

**Test Structure**:
```
test/tests/AsyncAnonymousFunctions/
├── compile.hxml          # Compilation configuration
├── MainMinimal.hx        # Simple test case
├── MainSimple.hx        # Complex test case with explicit types
└── out/main.js          # Generated JavaScript for verification
```

**Test Cases**:
1. **Basic anonymous function** without return type
2. **Explicit return type** to test Promise detection
3. **Nested anonymous functions** in complex expressions
4. **Error cases** to ensure graceful handling

**Verification Process**:
1. Compilation success (no errors)
2. Generated JavaScript inspection
3. Type safety verification (no double-wrapping)
4. Runtime behavior testing

### Key Insights and Learnings

#### 1. Import Resolution Affects AST Structure

**Insight**: Haxe's import resolution fundamentally changes how types appear in the AST.

**Impact**: Type detection logic must account for both imported and qualified forms.

**Lesson**: Never assume AST structure - always test with both imported and qualified type references.

#### 2. Anonymous Functions vs Class Methods Are Fundamentally Different

**Insight**: Anonymous functions require completely different transformation strategies.

**Why**: 
- Different AST placement (expressions vs fields)
- Different execution context
- Different JavaScript generation requirements

**Lesson**: Design separate transformation pipelines rather than trying to force one approach to work for both.

#### 3. Build Macros Are Universal Processors

**Insight**: Build macros applied globally can find and transform patterns anywhere in the code.

**Power**: One macro registration can handle both field-level and expression-level transformations.

**Lesson**: Use recursive expression processing to reach nested patterns that simple field processing would miss.

#### 4. Debugging Macro Transformations Requires Evidence

**Insight**: AST structures can be surprising - assumptions lead to bugs.

**Tools**: Strategic trace statements during development:
```haxe
trace("transformReturnType received: " + returnType);
trace("AST structure: " + expr.expr);
```

**Lesson**: Always verify AST structure with traces before implementing transformation logic.

#### 5. Position Preservation Is Critical

**Insight**: Source positions enable meaningful error messages and debugging.

**Implementation**: Always preserve original positions:
```haxe
{
    expr: EReturn(macro @:pos(pos) js.lib.Promise.resolve($returnExpr)),
    pos: pos  // Preserve original position
};
```

**Lesson**: Position information is as important as the transformation itself.

### Results and Impact

#### Generated JavaScript Quality

**Before**: No anonymous function support

**After**: Clean, efficient JavaScript:
```javascript
var simple = function() {
    console.log("hello");
    return Promise.resolve(null);
};
```

#### Developer Experience

**Before**: Only class methods could use @:async

**After**: Full async/await support everywhere:
```haxe
// Class methods
@:async static function getData(): Promise<String> { ... }

// Anonymous functions
var loadData = @:async function() { ... };

// Event handlers
element.addEventListener("click", @:async function(e) { ... });
```

#### Type Safety

**Before**: Double-wrapping Promise errors in complex scenarios

**After**: Robust type detection handles all import patterns correctly

### Architectural Principles Established

1. **Two-Phase Processing**: Handle both field-level and expression-level transformations
2. **Context-Aware Transformation**: Different strategies for different contexts
3. **Robust Type Detection**: Handle import resolution effects on AST structure
4. **Recursive Expression Processing**: Use `expr.map()` for comprehensive traversal
5. **Position Preservation**: Maintain debugging information throughout transformation
6. **Evidence-Based Development**: Use traces to understand actual AST structure

### Future Applications

This implementation established patterns for:
- **Expression-level macro processing**: Finding patterns in nested expressions
- **Import-aware type detection**: Handling both qualified and imported types
- **Context-sensitive transformations**: Different logic for different contexts
- **Comprehensive testing strategies**: Compiler-level testing with output verification

These patterns are directly applicable to future macro development in Reflaxe.Elixir.

---

## Case Study 2: Build Macro Architecture

### Problem Statement

**Goal**: Design a scalable architecture for build macros that can handle multiple features (async/await, LiveView, Ecto, etc.) without conflicts.

**Challenge**: Multiple macro systems need to process the same classes without interfering with each other.

**Requirements**:
- Global registration for automatic processing
- Extensible for new features
- Minimal performance overhead
- Clear separation of concerns

### Implementation Strategy

#### Global Registration Pattern

**Solution**: Use `Compiler.addGlobalMetadata` for universal coverage:

```haxe
public static function init(): Void {
    Compiler.addGlobalMetadata("", "@:build(reflaxe.js.Async.build())", true, true, false);
}
```

**Benefits**:
- Processes ALL classes automatically
- Finds metadata anywhere in codebase
- No manual application required

#### Processing Pipeline

**Architecture**: Each build macro focuses on its specific concerns:

```haxe
public static function build(): Array<Field> {
    var fields = Context.getBuildFields();
    
    // Only process if this macro's metadata is present
    if (!hasRelevantMetadata(fields)) {
        return fields; // Early exit for performance
    }
    
    return processFields(fields);
}
```

### Key Insights

1. **Stateless Design**: Each class is processed independently
2. **Early Exit Strategy**: Skip processing when not needed
3. **Metadata-Driven**: Only activate when relevant metadata is found
4. **Non-Interference**: Each macro handles its own metadata types

---

## Future Case Studies

### Planned Case Studies

1. **LiveView Build Macro**: Component generation and socket management
2. **Ecto Schema Compilation**: Database model generation with type safety
3. **GenServer State Management**: OTP behavior implementation
4. **HXX Template Processing**: JSX-like syntax compilation to HEEx

### Case Study Template

Each future case study should include:

#### Problem Statement
- Goal and requirements
- Technical challenges
- Context and constraints

#### Implementation Journey
- Phase-by-phase development
- Key decisions and alternatives considered
- Critical breakthroughs and insights

#### Technical Details
- Code examples and patterns
- AST transformations
- Testing strategies

#### Lessons Learned
- Architectural principles discovered
- Common pitfalls and solutions
- Reusable patterns identified

#### Impact and Results
- Performance metrics
- Developer experience improvements
- Future applicability

## Conclusion

These case studies preserve critical knowledge about macro development in Reflaxe.Elixir. The async/await anonymous function implementation established foundational patterns that future macro development can build upon:

**Key Patterns Established**:
- Recursive expression processing for nested pattern detection
- Import-aware type detection for robust type handling
- Context-sensitive transformation for different scenarios
- Comprehensive testing at the compiler level

**Architectural Principles**:
- AST preservation over string manipulation
- Evidence-based development with strategic debugging
- Stateless transformation functions for scalability
- Position preservation for debugging quality

These patterns and principles form the foundation for future macro development, ensuring consistent, reliable, and maintainable implementations across the Reflaxe.Elixir ecosystem.