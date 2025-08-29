# Product Requirements Document: Intermediate AST Architecture for Reflaxe.Elixir

## Executive Summary

This PRD outlines the refactoring of Reflaxe.Elixir from its current direct-to-string compilation approach to a three-phase semantic compilation pipeline using an Elixir-specific intermediate AST. This architectural change will dramatically improve maintainability, debuggability, and extensibility while preserving all existing functionality.

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

## 3. Technical Architecture

### 3.1 ElixirAST Data Structure

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

### 3.2 Phase 1: ElixirASTBuilder

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

### 3.3 Phase 2: ElixirASTTransformer

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

### 3.4 Phase 3: ElixirPrinter

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

## 4. Migration Strategy

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

## 5. Testing Strategy

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

## 6. Success Criteria

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

## 7. Risks and Mitigation

### Risk: Breaking Changes
**Mitigation**: Feature flag allows parallel development and gradual migration

### Risk: Performance Impact
**Mitigation**: Benchmark continuously, optimize hot paths, consider caching

### Risk: Complexity Increase
**Mitigation**: Clear phase separation, comprehensive documentation, examples

### Risk: Migration Effort
**Mitigation**: Incremental approach, maintain backward compatibility during transition

## 8. Future Opportunities

Once the intermediate AST is in place:
- **Visual AST Inspector**: Debug compilation visually
- **Custom Optimization Passes**: User-defined transformations
- **Multiple Targets**: Same AST could target different Elixir versions
- **Better Error Messages**: Precise source mapping
- **Incremental Compilation**: Cache unchanged AST subtrees
- **Language Server Protocol**: IDE integration with semantic understanding

## 9. Documentation Requirements

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

## 10. Implementation Checklist

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