# Product Requirements Document: Intermediate AST Architecture for Reflaxe.Elixir

## Executive Summary

This PRD outlines the refactoring of Reflaxe.Elixir from its current direct-to-string compilation approach to a three-phase semantic compilation pipeline using an Elixir-specific intermediate AST. This architectural change will dramatically improve maintainability, debuggability, and extensibility while preserving all existing functionality.

### Core Mission

**Create an easy-to-develop and debug Haxe→Elixir compiler that generates beautiful, idiomatic Elixir code.** The compiler should:

1. **Transform imperative Haxe to functional Elixir** when appropriate
2. **Provide flexible abstractions** allowing developers to write:
   - Imperative-style code that compiles to functional Elixir
   - Functional-style code that maps naturally to Elixir
   - Mixed paradigm code that leverages the best of both
3. **Implement Haxe stdlib idiomatically** using Elixir's native capabilities (via externs, @:coreApi, @:native)
4. **Generate code that Elixir developers would write** - not mechanical translations

### Immediate Goal

**Make the todo-app compile and work flawlessly** with all tests passing, generating idiomatic and beautiful Elixir code that showcases the compiler's ability to bridge paradigms elegantly.

## 1. Problem Statement

### Current Architecture Limitations

The current DirectToStringCompiler approach has several critical issues:

1. **Context Management Complexity**: State must be manually threaded through 30+ helper compilers
2. **Debugging Difficulty**: No intermediate representation to inspect or validate
3. **Pattern Recognition Limitations**: String manipulation instead of semantic understanding
4. **Maintenance Burden**: 10,000+ line monolithic files with intertwined concerns
5. **Testing Challenges**: Can't test transformations independently
6. **Extensibility Issues**: Adding new features requires understanding entire codebase

### Specific Bug Example

The recent `topic_to_string` bug exemplifies these issues:
- Context loss when ExpressionDispatcher bypassed main compiler
- TMeta wrapping TSwitch caused nested context management conflicts
- Required complex architectural fixes just to preserve a boolean flag
- 22+ expression types were bypassing proper compilation flow

## 2. Solution Overview

### Three-Phase Compilation Pipeline

```
Phase 1: Analysis (Haxe AST → Elixir AST)
  ├── Pattern detection
  ├── Semantic analysis
  └── Metadata enrichment

Phase 2: Transformation (Elixir AST → Elixir AST)
  ├── Optimization passes
  ├── Idiom conversion
  └── Framework integration

Phase 3: Generation (Elixir AST → String)
  ├── Pure string generation
  ├── Formatting
  └── File output
```

### Key Benefits

1. **Explicit Context**: All metadata lives in the AST, no hidden state
2. **Testable Phases**: Each phase can be tested independently
3. **Semantic Understanding**: Work with Elixir concepts, not strings
4. **Clear Separation**: Analysis, transformation, and generation are distinct
5. **Extensible**: New transformations plug in without affecting others
6. **Debuggable**: Inspect and visualize intermediate AST

## 3. Paradigm Transformation Philosophy

### 3.1 Imperative to Functional Transformation

The compiler should intelligently recognize imperative patterns and transform them to idiomatic functional Elixir:

#### Example Transformations

**Imperative Loop → Functional Enumeration**
```haxe
// Haxe input (imperative)
var result = [];
for (item in items) {
    if (item.isValid()) {
        result.push(item.transform());
    }
}

// Generated Elixir (functional)
result = items
  |> Enum.filter(&valid?/1)
  |> Enum.map(&transform/1)
```

**Mutable State → Immutable Transformation**
```haxe
// Haxe input (mutable)
var total = 0;
for (num in numbers) {
    total += num;
}

// Generated Elixir (immutable)
total = Enum.reduce(numbers, 0, &+/2)
```

**Object Methods → Module Functions**
```haxe
// Haxe input (OOP)
user.getName().toUpperCase().trim()

// Generated Elixir (functional)
user
|> User.get_name()
|> String.upcase()
|> String.trim()
```

### 3.2 Flexible Programming Styles

The compiler should support multiple programming styles, all generating idiomatic Elixir:

#### Imperative-Friendly APIs
```haxe
// Developer writes familiar imperative code
var users = Database.query("SELECT * FROM users");
for (user in users) {
    if (user.age > 18) {
        EmailService.send(user.email, "Welcome!");
    }
}

// Generates idiomatic Elixir
Database.query("SELECT * FROM users")
|> Enum.filter(fn user -> user.age > 18 end)
|> Enum.each(fn user -> 
    EmailService.send(user.email, "Welcome!")
end)
```

#### Functional-First APIs
```haxe
// Developer can also write functional style
users
    .filter(u -> u.age > 18)
    .map(u -> {email: u.email, message: "Welcome!"})
    .forEach(EmailService.send);

// Generates nearly identical Elixir
```

### 3.3 Haxe Standard Library Implementation

The Haxe stdlib should be implemented using Elixir's native capabilities for maximum performance and idiomatic output:

#### Implementation Strategies

1. **@:coreApi for Native Mappings**
```haxe
@:coreApi
class StringTools {
    public static function trim(s: String): String {
        return untyped __elixir__('String.trim($s)');
    }
}
```

2. **@:native for Direct Module Mapping**
```haxe
@:native("Enum")
extern class Enum {
    static function map<T,R>(enumerable: Array<T>, fun: T->R): Array<R>;
    static function filter<T>(enumerable: Array<T>, fun: T->Bool): Array<T>;
}
```

3. **Extern Classes for Elixir Modules**
```haxe
@:native("File")
extern class File {
    @:native("read!")
    static function read(path: String): String;
    
    @:native("write!")
    static function write(path: String, content: String): Void;
}
```

4. **Abstract Types for Idiomatic APIs**
```haxe
abstract Process(Dynamic) {
    @:native("Process.sleep")
    public static function sleep(ms: Int): Void;
    
    @:native("Process.send")
    public static function send(pid: ProcessId, message: Dynamic): Void;
}
```

## 4. Type Safety and Code Quality Principles

### 4.1 Zero Dynamic Policy

**FUNDAMENTAL RULE: Never use Dynamic or untyped unless absolutely justified and documented.**

- **NO Dynamic types**: Replace all Dynamic with proper typed abstracts or enums
- **NO string manipulation**: Use AST operations, not string concatenation
- **NO untyped field access**: Define proper interfaces and types
- **Document exceptions**: Any use of Dynamic must have a comment explaining why

### 4.2 Type-First Design

All compiler components should be strongly typed:

```haxe
// ❌ BAD: String-based, error-prone
function compileExpr(expr: Dynamic): String {
    return switch(Reflect.field(expr, "type")) {
        case "call": "#{" + expr.target + "}.#{" + expr.method + "}";
        default: "";
    }
}

// ✅ GOOD: Type-safe, compiler-verified
function compileExpr(expr: ElixirAST): String {
    return switch(expr.def) {
        case ECall(target, method, args): 
            '${print(target)}.${method}(${args.map(print).join(", ")})';
        default: "";
    }
}
```

### 4.3 String Usage Guidelines

Strings should only be used for:
- **Final output generation** in the printer phase
- **Atom/identifier names** where they represent Elixir symbols
- **Documentation and comments**

Never for:
- **AST manipulation** - Use typed nodes
- **Pattern detection** - Use enum matching
- **Code structure** - Use AST composition

## 5. Developer Experience Goals

### 5.1 Easy Development

- **Clear Error Messages**: Precise source location with helpful suggestions
- **Fast Compilation**: Sub-second incremental compilation
- **IDE Support**: Full autocomplete and type information
- **Documentation**: Comprehensive guides and examples

### 5.2 Easy Debugging

- **AST Visualization**: Inspect intermediate representations
- **Transformation Tracing**: See how code transforms step-by-step
- **Source Mapping**: Map generated Elixir back to Haxe source
- **Debug Output**: Conditional compilation flags for verbose output

### 5.3 Beautiful Output

The generated Elixir should be:
- **Readable**: Clear variable names, proper indentation
- **Idiomatic**: Following Elixir community conventions
- **Efficient**: No unnecessary intermediate variables or operations
- **Maintainable**: Could be handed to an Elixir team if needed

## 6. Technical Architecture

### 6.1 ElixirAST Data Structure

```haxe
// Core AST Definition
enum ElixirASTDef {
    // Modules and Structure
    EModule(name: String, attributes: Array<EAttribute>, body: Array<ElixirAST>);
    EDefmodule(name: String, doBlock: ElixirAST);
    
    // Functions
    EDef(name: String, args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST);
    EDefp(name: String, args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST);
    
    // Pattern Matching
    ECase(expr: ElixirAST, clauses: Array<ECaseClause>);
    ECond(clauses: Array<ECondClause>);
    EMatch(pattern: EPattern, expr: ElixirAST);
    
    // Control Flow
    EIf(condition: ElixirAST, thenBranch: ElixirAST, elseBranch: Null<ElixirAST>);
    EUnless(condition: ElixirAST, body: ElixirAST);
    ETry(body: ElixirAST, rescue: Array<ERescueClause>, catchClauses: Array<ECatchClause>, 
         afterBlock: Null<ElixirAST>);
    
    // Data Structures
    EList(elements: Array<ElixirAST>);
    ETuple(elements: Array<ElixirAST>);
    EMap(pairs: Array<{key: ElixirAST, value: ElixirAST}>);
    EStruct(module: String, fields: Array<{key: String, value: ElixirAST}>);
    
    // Expressions
    ECall(target: ElixirAST, function: String, args: Array<ElixirAST>);
    EPipe(left: ElixirAST, right: ElixirAST);
    EBinary(op: String, left: ElixirAST, right: ElixirAST);
    EUnary(op: String, expr: ElixirAST);
    
    // Literals
    EAtom(value: String);
    EString(value: String);
    EInteger(value: Int);
    EFloat(value: Float);
    EBoolean(value: Bool);
    ENil;
    
    // Variables and Access
    EVar(name: String);
    EField(target: ElixirAST, field: String);
    
    // Special Forms
    EQuote(expr: ElixirAST);
    EUnquote(expr: ElixirAST);
    EMacro(name: String, args: Array<EPattern>, body: ElixirAST);
    
    // Comprehensions
    EFor(generators: Array<EGenerator>, filters: Array<ElixirAST>, body: ElixirAST, 
         into: Null<ElixirAST>);
    
    // Anonymous Functions
    EFn(clauses: Array<EFnClause>);
    
    // Aliases and Imports
    EAlias(module: String, as: Null<String>);
    EImport(module: String, only: Null<Array<String>>);
    EUse(module: String, options: Array<{key: String, value: ElixirAST}>);
    
    // Documentation
    EModuledoc(content: String);
    EDoc(content: String);
    
    // Block Expressions
    EBlock(expressions: Array<ElixirAST>);
    
    // With Expression
    EWith(clauses: Array<EWithClause>, doBlock: ElixirAST, elseBlock: Null<ElixirAST>);
}

// Metadata-Enriched AST Node
typedef ElixirAST = {
    def: ElixirASTDef;
    metadata: ElixirMetadata;
    ?pos: Position;  // Source position for error reporting
}

// Rich Metadata Structure
typedef ElixirMetadata = {
    // Source Information
    ?sourceExpr: TypedExpr;        // Original Haxe expression
    ?sourceLine: Int;               // Line number in Haxe source
    ?sourceFile: String;            // Source file path
    
    // Semantic Information
    ?type: Type;                   // Haxe type information
    ?elixirType: String;           // Inferred Elixir type
    ?purity: Bool;                 // Is expression pure?
    ?tailPosition: Bool;           // Is in tail position?
    
    // Transformation Hints
    ?requiresReturn: Bool;         // Needs explicit return value
    ?requiresTempVar: Bool;        // Needs temporary variable
    ?inPipeline: Bool;            // Part of pipe chain
    ?inComprehension: Bool;       // Inside for comprehension
    
    // Phoenix/Framework Specific
    ?phoenixContext: PhoenixContext;  // LiveView, Router, etc.
    ?ectoContext: EctoContext;        // Schema, Query, etc.
    
    // Optimization Hints
    ?canInline: Bool;             // Can be inlined
    ?isConstant: Bool;            // Compile-time constant
    ?accessPattern: AccessPattern; // How value is accessed
    
    // User Annotations
    ?annotations: Array<String>;   // @:native, @:inline, etc.
}
```

### 6.2 Phase 1: ElixirASTBuilder

```haxe
class ElixirASTBuilder {
    // Converts Haxe TypedExpr to ElixirAST
    public function buildFromTypedExpr(expr: TypedExpr): ElixirAST {
        return switch(expr.expr) {
            case TConst(c): buildConst(c, expr);
            case TLocal(v): buildLocal(v, expr);
            case TFunction(tfunc): buildFunction(tfunc, expr);
            case TCall(e, el): buildCall(e, el, expr);
            case TSwitch(e, cases, edef): buildSwitch(e, cases, edef, expr);
            // ... comprehensive pattern matching
        }
    }
    
    // Pattern detection with metadata
    function buildSwitch(e: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, 
                        edef: Null<TypedExpr>, source: TypedExpr): ElixirAST {
        var metadata: ElixirMetadata = {
            sourceExpr: source,
            requiresReturn: isInReturnContext(source),
            requiresTempVar: needsTempVariable(source)
        };
        
        var caseExpr = buildFromTypedExpr(e);
        var clauses = cases.map(c -> buildCaseClause(c));
        
        return {
            def: ECase(caseExpr, clauses),
            metadata: metadata
        };
    }
}
```

### 6.3 Phase 2: ElixirASTTransformer

```haxe
class ElixirASTTransformer {
    // Transform passes
    public function transform(ast: ElixirAST): ElixirAST {
        ast = idiomTransform(ast);      // Convert to idiomatic patterns
        ast = phoenixTransform(ast);    // Apply Phoenix conventions
        ast = optimizeTransform(ast);   // Optimization passes
        ast = pipeTransform(ast);       // Create pipe chains
        return ast;
    }
    
    // Example: Idiomatic transformation
    function idiomTransform(ast: ElixirAST): ElixirAST {
        return switch(ast.def) {
            case EFor(gens, filters, body, null) if isMapPattern(ast):
                // Transform to Enum.map
                convertToEnumMap(ast);
            case EIf(cond, then, else) if ast.metadata.tailPosition:
                // Transform to case for better pattern matching
                convertToCase(ast);
            default:
                // Recursive transformation
                mapChildren(ast, idiomTransform);
        }
    }
    
    // Pattern-specific transformations
    function handleReturnContext(ast: ElixirAST): ElixirAST {
        if (ast.metadata.requiresTempVar) {
            // Wrap in temp variable assignment
            var tempVar = generateTempVar();
            return {
                def: EBlock([
                    {def: EMatch(EVar(tempVar), ast), metadata: {}},
                    {def: EVar(tempVar), metadata: {}}
                ]),
                metadata: ast.metadata
            };
        }
        return ast;
    }
}
```

### 6.4 Phase 3: ElixirPrinter

```haxe
class ElixirPrinter {
    // Pure string generation - no logic, just formatting
    public function print(ast: ElixirAST): String {
        return switch(ast.def) {
            case EModule(name, attrs, body):
                printModule(name, attrs, body);
            case EDef(name, args, guards, body):
                printDef(name, args, guards, body);
            case ECase(expr, clauses):
                printCase(expr, clauses);
            // ... straightforward printing
        }
    }
    
    // Simple, readable generation
    function printCase(expr: ElixirAST, clauses: Array<ECaseClause>): String {
        var result = 'case ${print(expr)} do\n';
        for (clause in clauses) {
            result += '  ${printPattern(clause.pattern)} -> ${print(clause.body)}\n';
        }
        result += 'end';
        return result;
    }
}
```

## 7. Migration Strategy

### Phase 1: Foundation (Week 1-2)
- [ ] Create ElixirAST data structures
- [ ] Implement basic ElixirASTBuilder for core expressions
- [ ] Build ElixirPrinter for string generation
- [ ] Add feature flag for new architecture
- [ ] Create comprehensive test suite

### Phase 2: Core Features (Week 3-4)
- [ ] Implement pattern matching transformation
- [ ] Add function compilation
- [ ] Handle control flow structures
- [ ] Support data structure literals
- [ ] Validate with snapshot tests

### Phase 3: Advanced Features (Week 5-6)
- [ ] Phoenix annotation processing
- [ ] Ecto schema generation
- [ ] LiveView compilation
- [ ] Macro and quote handling
- [ ] Comprehension transformations

### Phase 4: Optimization (Week 7)
- [ ] Idiom detection and conversion
- [ ] Pipe chain optimization
- [ ] Constant folding
- [ ] Dead code elimination
- [ ] Performance benchmarking

### Phase 5: Cutover (Week 8)
- [ ] Complete parallel testing
- [ ] Documentation update
- [ ] Remove old architecture
- [ ] Clean deprecated code
- [ ] Final validation

## 8. Testing Strategy

### Unit Testing
- Test each phase independently
- Mock AST inputs/outputs
- Validate transformations

### Integration Testing
- Full pipeline testing
- Snapshot comparison with current output
- Performance benchmarks

### Regression Testing
- All existing tests must pass
- Todo-app must compile identically
- No functionality loss

## 9. Success Criteria

### Functional Requirements
- [ ] All existing tests pass
- [ ] Todo-app compiles and runs identically
- [ ] No performance regression (< 15ms compilation time)
- [ ] Generated code remains idiomatic

### Technical Requirements
- [ ] Three distinct compilation phases
- [ ] Intermediate AST is inspectable
- [ ] Each phase independently testable
- [ ] Context passed through AST metadata
- [ ] No global state or side effects

### Quality Requirements
- [ ] Comprehensive documentation
- [ ] 90%+ test coverage
- [ ] Clean separation of concerns
- [ ] No files over 1000 lines
- [ ] All patterns documented

## 10. Risks and Mitigation

### Risk: Breaking Changes
**Mitigation**: Feature flag allows parallel development and gradual migration

### Risk: Performance Impact
**Mitigation**: Benchmark continuously, optimize hot paths, consider caching

### Risk: Complexity Increase
**Mitigation**: Clear phase separation, comprehensive documentation, examples

### Risk: Migration Effort
**Mitigation**: Incremental approach, maintain backward compatibility during transition

## 11. Future Opportunities

Once the intermediate AST is in place:
- **Visual AST Inspector**: Debug compilation visually
- **Custom Optimization Passes**: User-defined transformations
- **Multiple Targets**: Same AST could target different Elixir versions
- **Better Error Messages**: Precise source mapping
- **Incremental Compilation**: Cache unchanged AST subtrees
- **Language Server Protocol**: IDE integration with semantic understanding

## 12. Documentation Requirements

### Architecture Documentation
- [ ] Complete AST specification
- [ ] Phase interaction diagrams
- [ ] Transformation catalog
- [ ] Pattern recognition guide

### Developer Documentation
- [ ] Migration guide from old architecture
- [ ] How to add new transformations
- [ ] Debugging guide for AST
- [ ] Performance tuning guide

### User Documentation
- [ ] No change needed - interface remains the same
- [ ] Release notes explaining improvements

## 13. Implementation Checklist

### Immediate Actions
- [x] Commit current work
- [ ] Create feature flag `use_intermediate_ast`
- [ ] Set up parallel directory structure
- [ ] Create ElixirAST.hx with data structures
- [ ] Implement minimal ElixirASTBuilder
- [ ] Build basic ElixirPrinter
- [ ] Wire up with feature flag

### Week 1 Deliverables
- [ ] Core AST types defined
- [ ] Basic expressions compile
- [ ] Simple function compilation works
- [ ] Snapshot tests comparing output
- [ ] Documentation started

### Success Metrics
- **Maintainability**: 50% reduction in file sizes
- **Debuggability**: AST inspection available
- **Extensibility**: New features in < 100 lines
- **Performance**: No regression from current
- **Quality**: Zero functionality loss

## Appendix A: Detailed AST Specifications

[Full enum definitions and type specifications would go here]

## Appendix B: Transformation Examples

### Example 1: Return Context Handling

**Input Haxe:**
```haxe
function topicToString(topic: Topic): String {
    return switch(topic) {
        case TodoUpdates: "todo:updates";
    }
}
```

**Phase 1 - ElixirAST:**
```haxe
{
    def: EDef("topic_to_string", [EPattern.EVar("topic")], null,
        {
            def: ECase(EVar("topic"), [
                {pattern: EAtom("todo_updates"), guard: null, 
                 body: EString("todo:updates")}
            ]),
            metadata: {requiresReturn: true, requiresTempVar: true}
        }
    ),
    metadata: {}
}
```

**Phase 2 - Transformed:**
```haxe
{
    def: EDef("topic_to_string", [EPattern.EVar("topic")], null,
        EBlock([
            EMatch(EVar("temp_result"), EAtom("nil")),
            EMatch(EVar("temp_result"), 
                ECase(EVar("topic"), [
                    {pattern: EAtom("todo_updates"), 
                     body: EString("todo:updates")}
                ])
            ),
            EVar("temp_result")
        ])
    ),
    metadata: {}
}
```

**Phase 3 - Generated:**
```elixir
def topic_to_string(topic) do
  temp_result = nil
  temp_result = case topic do
    :todo_updates -> "todo:updates"
  end
  temp_result
end
```

## Appendix C: Deprecation Plan

### Files to Remove After Migration
- Current monolithic ElixirCompiler.hx (10,000+ lines)
- String manipulation utilities
- Context management helpers
- Pattern detection via string matching

### Files to Update
- Test harness to support both architectures
- Build configuration for feature flag
- Documentation to reflect new architecture

### Backward Compatibility
- Maintain feature flag for 2 releases
- Provide migration guide for extensions
- Keep old architecture documentation archived

---

**Document Version**: 1.0
**Date**: 2024
**Authors**: Reflaxe.Elixir Team
**Status**: APPROVED - Ready for Implementation