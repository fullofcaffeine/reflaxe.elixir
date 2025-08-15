# PRD: Vision Alignment - LLM Leverager for Cross-Platform Development

**Version**: 1.0  
**Date**: 2025-08-15  
**Status**: Draft  
**Author**: AI Assistant (Claude)  

## Executive Summary

### Vision Statement
Transform Reflaxe.Elixir into an **LLM leverager for deterministic cross-platform development** that enables developers to write business logic once in Haxe and deploy it anywhere, while generating idiomatic target code that looks hand-written rather than machine-generated.

### Core Goals
1. **Write Once, Deploy Anywhere**: Business logic written in Haxe compiles to idiomatic code across JS, Python, Elixir, and other targets
2. **LLM Productivity Multiplier**: Provide deterministic vocabulary that reduces hallucinations and enables rapid boilerplate generation
3. **Type Safety Without Vendor Lock-in**: Compile-time type checking while maintaining freedom to switch runtimes
4. **Idiomatic Code Generation**: Generated code passes human review as "natural" rather than "machine-generated"

### Strategic Differentiators
- **vs Gleam**: Multi-target capability (not BEAM-only) with stronger Phoenix integration
- **vs TypeScript**: Multiple runtime targets, not just JavaScript
- **vs Pure Elixir**: Compile-time type safety with cross-platform code sharing
- **vs Manual Polyglot**: Deterministic compilation reduces errors and maintenance burden

## Current State Analysis

### ✅ What's Working Well

#### 1. Phoenix/Elixir Integration Excellence
- **LiveView**: Complete real-time component compilation with socket management
- **Ecto**: Full schema, changeset, query, and migration DSL support
- **OTP Patterns**: GenServer, supervision trees, behavior implementations
- **Router DSL**: Type-safe route generation with @:route annotations

#### 2. Proven Compilation Architecture
- **178 passing tests** demonstrate stability and completeness
- **Annotation-driven design** (@:liveview, @:ecto, @:genserver) is intuitive
- **Helper pattern** works well for framework-specific compilation
- **Source maps** provide debugging capabilities unique among Reflaxe targets

#### 3. Real-World Validation
- **Todo app compiles and runs** successfully in Phoenix
- **Production-ready features** across 17 major feature areas
- **Mix integration** with file watching and incremental compilation

### ❌ Critical Gaps Against Vision

#### 1. Non-Idiomatic Code Generation ⚠️ **BLOCKS LLM ADOPTION**
```elixir
# CURRENT: Machine-generated appearance
def greet(arg0) do
  "Hello, " <> arg0 <> "!"
end

# REQUIRED: Human-written appearance  
def greet(name) do
  "Hello, " <> name <> "!"
end
```
**Impact**: Generated code immediately identifiable as machine-generated, reducing professional adoption

#### 2. Incomplete Standard Library ⚠️ **BLOCKS CROSS-PLATFORM**
**Missing Core Types**:
- `Array.hx` - Array operations → Enum module mapping
- `Map.hx` - HashMap/TreeMap → Elixir map operations
- `Date.hx` - DateTime → Calendar module integration
- `Math.hx` - Mathematical operations → :math module
- `Reflect.hx` - Runtime reflection → Elixir metaprogramming
- `Type.hx` - Type inspection and manipulation

**Impact**: Cannot write truly cross-platform code, blocking "write once, deploy anywhere" vision

#### 3. No Testing Framework Integration ⚠️ **BLOCKS PROFESSIONAL USE**
**Missing**: ExUnit extern definitions and test compilation support
**Impact**: Cannot write type-safe tests in Haxe, forcing developers to switch languages for testing

#### 4. Insufficient LLM Documentation ⚠️ **BLOCKS AI LEVERAGE**
**Issues**: 
- Many methods lack JSDoc documentation
- No transformation pattern documentation
- Missing examples and usage patterns
**Impact**: LLMs cannot effectively understand and extend the compiler

### 🔧 Technical Debt

#### 1. Excessive Dynamic Usage
- 35 files contain Dynamic types
- Some lack justification comments
- Reduces type safety benefits

#### 2. Parameter Name Loss
- Haxe parameter names not preserved during compilation
- Results in generic arg0/arg1 parameters

## Requirements

### R1: Idiomatic Code Generation (Priority: CRITICAL)
**Requirement**: Generated Elixir code must be indistinguishable from hand-written code

#### R1.1 Parameter Name Preservation
- **MUST** preserve original Haxe parameter names in generated functions
- **SHOULD** add fallback comments when names cannot be preserved
- **Example**: `def greet(name)` not `def greet(arg0)`

#### R1.2 Documentation Generation
- **MUST** convert Haxe JSDoc to Elixir @doc and @spec
- **SHOULD** include usage examples and patterns
- **MUST** preserve all documentation metadata

#### R1.3 Paradigm Bridge Comments
- **MUST** add explanatory comments for non-idiomatic patterns
- **Example**: `# Recursive pattern simulates Haxe's imperative loop`
- **SHOULD** help Elixir developers understand generated code patterns

### R2: Complete Standard Library (Priority: HIGH)
**Requirement**: Full Haxe standard library implementation for cross-platform development

#### R2.1 Core Types Implementation
- **MUST** implement Array, Map, Date, Math, Reflect, Type, Std
- **MUST** use Extern + Runtime pattern like StringTools
- **MUST** ensure cross-platform API compatibility
- **MUST** generate idiomatic Elixir module implementations

#### R2.2 I/O and System Operations
- **MUST** implement Sys, File, FileSystem with proper error handling
- **SHOULD** integrate with Elixir's File and Path modules
- **MUST** maintain consistent API across all Haxe targets

#### R2.3 String and Collection Operations
- **MUST** complete StringTools implementation
- **MUST** provide Regex support with Elixir patterns
- **SHOULD** handle Unicode properly

### R3: ExUnit Testing Framework (Priority: HIGH)
**Requirement**: Type-safe testing in Haxe compiling to ExUnit

#### R3.1 ExUnit Extern Definitions
```haxe
@:native("ExUnit.Case")
extern class TestCase {
    public static function test(name: String, callback: () -> Void): Void;
    public static function describe(description: String, callback: () -> Void): Void;
    public static function setup(callback: () -> Dynamic): Void;
}

@:native("ExUnit.Assertions") 
extern class Assert {
    public static function assert(value: Bool): Void;
    public static function assertEqual<T>(expected: T, actual: T): Void;
    public static function assertMatch(pattern: Dynamic, value: Dynamic): Void;
    public static function assertRaise(exception: Class<Dynamic>, fn: () -> Void): Void;
}
```

#### R3.2 Test Compilation Support
- **MUST** support @:test annotation for test modules
- **MUST** generate proper ExUnit module structure
- **SHOULD** support @:async annotation for concurrent tests
- **MUST** integrate with Mix test runner

### R4: LLM-Optimized Documentation (Priority: MEDIUM)
**Requirement**: Every method documented for AI comprehension

#### R4.1 JSDoc Coverage
- **MUST** document all public methods with purpose, parameters, returns, examples
- **MUST** include transformation patterns for compiler methods
- **SHOULD** add @see references for related methods
- **MUST** structure docs for AI comprehension

#### R4.2 Architecture Documentation
- **MUST** document compilation patterns and design decisions
- **SHOULD** explain paradigm bridges and transformation strategies
- **MUST** provide cross-platform development guides

### R5: Quality Standards (Priority: ONGOING)
**Requirement**: Minimize Dynamic usage and maintain type safety

#### R5.1 Dynamic Usage Governance
- **MUST** justify all Dynamic usage with comments
- **SHOULD** replace with proper types where possible
- **MUST** document acceptable Dynamic usage patterns

#### R5.2 Code Generation Quality
- **MUST** generate @spec annotations for all functions
- **SHOULD** include helpful error messages
- **MUST** follow Elixir naming conventions

## Architecture Decisions

### AD1: Enhanced Helper Pattern (APPROVED)
**Decision**: Continue with Enhanced Helper pattern rather than Sub-Compiler pattern

**Rationale**:
1. **Framework Focus**: Elixir development is heavily framework-oriented (Phoenix/Ecto/OTP)
2. **LLM Friendliness**: Simpler architecture easier for AI agents to understand
3. **Domain Specificity**: Our helpers are framework-specific, not just language features
4. **Proven Success**: Current approach already works well for Phoenix applications
5. **Maintenance**: Fewer files and simpler coordination

**Enhancements**:
- Add cross-files for standard library (like Reflaxe.GO)
- Maintain comprehensive JSDoc documentation
- Focus on idiomatic code generation

### AD2: Extern + Runtime Pattern for Standard Library (APPROVED)
**Decision**: Use StringTools pattern for all standard library implementations

**Rationale**:
1. **Predictable**: Clear separation between interface and implementation
2. **Performant**: Native Elixir implementations are optimal
3. **Maintainable**: Easy to update implementations without changing interfaces
4. **Idiomatic**: Generates natural Elixir code

### AD3: Documentation-First Development (NEW)
**Decision**: Prioritize LLM-optimized documentation throughout development

**Rationale**:
1. **AI Leverage**: Well-documented code enables LLM assistance
2. **Knowledge Transfer**: Comprehensive docs reduce onboarding time
3. **Quality Assurance**: Documentation forces clear thinking about APIs
4. **Vision Alignment**: Supports LLM leverager strategic goal

## Success Metrics

### M1: Code Quality Metrics
- [ ] Generated Elixir code passes human code review as "natural"
- [ ] Parameter names are meaningful, not arg0/arg1
- [ ] All functions have proper @doc and @spec annotations
- [ ] Generated code follows Phoenix/Elixir conventions exactly

### M2: Cross-Platform Capability
- [ ] Can compile and run Haxe standard library test suite
- [ ] Same business logic compiles to JS, Python, and Elixir
- [ ] Shared validation logic works across frontend/backend
- [ ] Todo app demonstrates cross-platform business logic

### M3: LLM Integration Success
- [ ] LLMs can understand and extend compiler from documentation alone
- [ ] Generated boilerplates are production-ready
- [ ] AI agents can contribute meaningfully to development
- [ ] Documentation enables rapid feature addition

### M4: Phoenix Integration Excellence
- [ ] Todo app looks like idiomatic Phoenix application
- [ ] Generated LiveView components follow Phoenix conventions
- [ ] Ecto schemas and changesets indistinguishable from hand-written
- [ ] Performance comparable to hand-written Phoenix apps

### M5: Testing Capability
- [ ] Can write comprehensive test suites in Haxe
- [ ] Tests compile to idiomatic ExUnit code
- [ ] Test execution integrates seamlessly with Mix
- [ ] Coverage reporting works correctly

## Implementation Roadmap

### Phase 1: Critical Code Quality (Week 1)
**Goal**: Make generated code look hand-written

1. **Fix Parameter Naming**
   - Extract original parameter names from Haxe AST
   - Update ElixirCompiler function compilation methods
   - Add fallback comments when names unavailable

2. **Add Idiomatic Comments**
   - Identify non-idiomatic patterns
   - Add explanatory comments for paradigm bridges
   - Document transformation decisions

3. **Improve Documentation Generation**
   - Convert JSDoc to @doc and @spec
   - Preserve all documentation metadata
   - Include examples and usage patterns

### Phase 2: ExUnit Integration (Week 2)
**Goal**: Enable type-safe testing in Haxe

1. **Create ExUnit Externs**
   - Define TestCase and Assert classes
   - Add comprehensive test API coverage
   - Include async testing support

2. **Test Compilation Support**
   - Implement @:test annotation
   - Generate proper ExUnit module structure
   - Integrate with Mix test runner

### Phase 3: Standard Library Implementation (Week 3-4)
**Goal**: Enable true cross-platform development

1. **Core Types** (Week 3)
   - Array.hx → Enum module mapping
   - Map.hx → Elixir map operations
   - Date.hx → Calendar integration
   - Math.hx → :math module

2. **Advanced Types** (Week 4)
   - Reflect.hx → Metaprogramming
   - Type.hx → Type inspection
   - Std.hx → Standard utilities
   - Complete StringTools

3. **System Operations**
   - Sys.hx → System module
   - File operations → File/Path modules
   - Error handling integration

### Phase 4: Documentation Excellence (Week 5)
**Goal**: Optimize for LLM understanding and extension

1. **Comprehensive JSDoc**
   - Document all public methods
   - Include transformation patterns
   - Add cross-references and examples

2. **Architecture Documentation**
   - Create COMPILER_PHILOSOPHY.md
   - Document design decisions
   - Explain paradigm bridges

### Phase 5: Dynamic Cleanup (Ongoing)
**Goal**: Maximize type safety

1. **Audit Dynamic Usage**
   - Review all 35 files with Dynamic
   - Replace with proper types where possible
   - Add justification comments

2. **Quality Standards**
   - Establish Dynamic usage guidelines
   - Document acceptable patterns
   - Regular code reviews

## Risk Assessment

### High Risk: Parameter Name Extraction Complexity
**Risk**: Haxe's variable renaming may make parameter name preservation difficult
**Mitigation**: Implement fallback comments when original names unavailable

### Medium Risk: Standard Library Scope Creep
**Risk**: Haxe standard library is extensive, may be overwhelming
**Mitigation**: Prioritize most commonly used types first, implement incrementally

### Low Risk: LLM Documentation Maintenance
**Risk**: Documentation may become outdated as code evolves
**Mitigation**: Integrate documentation updates into development workflow

## Conclusion

This PRD outlines the transformation of Reflaxe.Elixir from a functional but basic transpiler into a strategic LLM leverager for deterministic cross-platform development. The focus on idiomatic code generation, complete standard library support, and comprehensive documentation will enable developers to write business logic once and deploy it anywhere while maintaining the quality and readability expected in professional software development.

The enhanced helper pattern architecture, combined with the extern + runtime implementation strategy, provides a solid foundation for achieving these goals while maintaining the framework-focused approach that has proven successful with Phoenix integration.

Success will be measured not just by technical capability, but by the ability to generate code that looks hand-written and to provide LLMs with the deterministic vocabulary needed to accelerate cross-platform development.