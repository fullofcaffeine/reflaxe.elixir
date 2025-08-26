# Product Requirements Document: Haxe→Elixir Compiler 1.0 Architecture Refactor

## Executive Summary

This PRD outlines the critical architectural refactoring required to bring the Haxe→Elixir compiler to production-ready 1.0 status. The compiler must be Turing-complete for Haxe, generate idiomatic hand-written quality Elixir code, and enable developers to write complex Elixir applications using Haxe's superior type system.

**Success Criterion**: The todo-app example must compile fully (both Haxe and Elixir stages), run without errors, and demonstrate a modern, responsive web GUI using Phoenix LiveView's best features through Haxe's type-safe abstraction layer.

## 1. Problem Statement

### Current State (BROKEN)
The compiler suffers from severe architectural debt that prevents it from reaching production quality:

1. **Duplicate Compilation Paths**: Multiple compilers handle the same constructs (loops, functions, patterns)
2. **Circular Dependencies**: Components call each other in unpredictable ways
3. **Monolithic Files**: Single files exceeding 4,000 lines (2x the maximum limit)
4. **Unclear Responsibilities**: Overlapping functionality across multiple compilers
5. **Maintenance Nightmare**: Changes in one area break unrelated functionality

### Impact
- **Development Velocity**: Slowed by 70% due to architectural complexity
- **Bug Introduction**: Every fix risks breaking something else
- **Onboarding**: New developers cannot understand the codebase
- **Quality**: Generated Elixir code has inconsistencies and bugs
- **Production Readiness**: Cannot ship 1.0 with this technical debt

## 2. Goals & Objectives

### Primary Goal
**Achieve 1.0 production readiness** where the compiler is Turing-complete for Haxe and generates idiomatic, almost hand-written Elixir code suitable for complex production applications.

### Success Metrics
- ✅ Todo-app compiles fully (Haxe → Elixir → Running Phoenix app)
- ✅ Generated code passes as hand-written Elixir in code review
- ✅ All compiler files under 2,000 lines (ideal: 500-1,500 lines)
- ✅ Single compilation path per language construct
- ✅ Zero circular dependencies
- ✅ 100% test coverage for core compilation paths
- ✅ Modern, responsive Phoenix LiveView UI working perfectly

### Non-Goals
- Performance optimization (defer to 1.1)
- Advanced macro features (defer to 1.2)
- Cross-platform targets beyond Elixir

## 3. Architectural Issues to Fix

### Issue 1: Multiple Loop Compilation Paths

**Current State**:
```
- LoopCompiler.hx: 4,235 lines (MASSIVE - 2x over limit)
- WhileLoopCompiler.hx: 764 lines  
- ControlFlowCompiler.hx: 2,929 lines (over limit)
- All have overlapping compileWhileLoop() and compileForLoop() methods
```

**Root Cause**: Organic growth without architectural planning led to feature duplication.

**Solution**: Unify into single loop compilation pipeline with clear separation of concerns.

### Issue 2: Confusing Compilation Flow

**Current State**:
```
ElixirCompiler creates:
  → LoopCompiler (4,235 lines)
  → WhileLoopCompiler (764 lines)  
  → ExpressionDispatcher creates:
      → ControlFlowCompiler (2,929 lines)
          → Calls back to LoopCompiler! (CIRCULAR!)
```

**Root Cause**: No clear architectural boundaries or data flow design.

**Solution**: Linear, predictable compilation flow with no circular dependencies.

### Issue 3: Violation of Core Principles

**Current Violations**:
- **NOT Simple**: 3 different compilers for loops
- **NOT Predictable**: Unclear which compiler handles which construct
- **NOT Maintainable**: Files over 4,000 lines
- **NOT Self-Describable**: Overlapping responsibilities

**Solution**: Each compiler has ONE clear responsibility, documented and enforced.

## 4. Proposed Architecture

### Phase 1: Unify Loop Compilation (Week 1)

**Objective**: Create single source of truth for loop compilation.

**Deliverables**:
1. Create `UnifiedLoopCompiler` (~1,500 lines max)
   - Consolidate all loop compilation logic
   - Single entry point for all loop types
   - Clear delegation to specialized helpers

2. Delete redundant compilers:
   - Merge WhileLoopCompiler → UnifiedLoopCompiler
   - Extract overlapping code from ControlFlowCompiler

3. Document compilation flow:
   - Clear data flow diagram
   - Responsibility matrix
   - Decision tree for construct handling

### Phase 2: Break Down Monolithic Files (Week 2)

**Objective**: No file exceeds 2,000 lines.

**LoopCompiler (4,235 lines) → Split into**:
```
CoreLoopCompiler.hx (~800 lines)
  - Basic for/while/do-while loops
  - Standard iteration patterns
  - Loop variable management

ArrayLoopOptimizer.hx (~600 lines)
  - Array building detection
  - List comprehension optimization
  - Efficient enumeration patterns

LoopTransformations.hx (~600 lines)
  - Recursive function generation
  - Tail call optimization
  - Complex pattern transformations

LoopPatternDetector.hx (~500 lines)
  - Pattern recognition
  - Optimization opportunity detection
  - AST analysis for loop structures
```

**ControlFlowCompiler (2,929 lines) → Split into**:
```
ConditionalCompiler.hx (~800 lines)
  - if/else chains
  - Ternary operators
  - Guard clauses

SwitchCompiler.hx (~700 lines)
  - Pattern matching
  - Exhaustiveness checking
  - Default case handling

ExceptionCompiler.hx (~600 lines)
  - try/catch/finally
  - Error propagation
  - Elixir error conventions
```

### Phase 3: Simplify Control Flow (Week 3)

**Current (Complex)**:
```
ElixirCompiler → ExpressionDispatcher → ControlFlowCompiler → LoopCompiler → WhileLoopCompiler
                     ↑                          ↓
                     └──────────────────────────┘ (CIRCULAR!)
```

**Proposed (Simple)**:
```
ElixirCompiler → ControlFlowRouter → ConditionalCompiler
                                   → SwitchCompiler
                                   → UnifiedLoopCompiler → Optimizers (when needed)
                                   → ExceptionCompiler
```

### Phase 4: Clear Responsibilities (Week 4)

**Responsibility Matrix**:

| Compiler | Responsibility | Max Lines | Dependencies |
|----------|---------------|-----------|--------------|
| ControlFlowRouter | Dispatch to specialized compilers | 300 | None |
| ConditionalCompiler | if/else/ternary ONLY | 800 | None |
| SwitchCompiler | switch/pattern match ONLY | 700 | PatternDetector |
| UnifiedLoopCompiler | for/while/do-while ONLY | 1,500 | LoopOptimizers |
| ExceptionCompiler | try/catch/finally ONLY | 600 | None |

**Enforcement Rules**:
- Each compiler handles EXACTLY its designated constructs
- No compiler may reference another at the same level
- Dependencies flow DOWN only (no circular refs)
- Every public method must have WHY/WHAT/HOW documentation

## 5. Implementation Plan

### Week 1: Foundation
- [ ] Create UnifiedLoopCompiler base structure
- [ ] Migrate WhileLoopCompiler functionality
- [ ] Document new architecture
- [ ] Update test suite

### Week 2: Extraction
- [ ] Extract CoreLoopCompiler from LoopCompiler
- [ ] Extract ArrayLoopOptimizer patterns
- [ ] Extract LoopTransformations
- [ ] Extract LoopPatternDetector
- [ ] Split ControlFlowCompiler

### Week 3: Integration
- [ ] Wire up new compilation flow
- [ ] Remove old compilers
- [ ] Update ElixirCompiler references
- [ ] Fix compilation path routing

### Week 4: Validation
- [ ] Full test suite passes
- [ ] Todo-app compiles without errors
- [ ] Todo-app runs with full functionality
- [ ] Performance benchmarks
- [ ] Documentation complete

## 6. Testing Strategy

### Unit Tests
- Each compiler tested in isolation
- 100% coverage of public methods
- Edge cases documented and tested

### Integration Tests
- Full compilation pipeline tests
- Todo-app as primary integration test
- Complex language constructs validated

### E2E Validation (Todo-App Requirements)
The todo-app serves as our production readiness benchmark:

**Functional Requirements**:
- ✅ Full CRUD operations for todos
- ✅ Real-time updates via LiveView
- ✅ Responsive, modern UI
- ✅ Client-side interactivity
- ✅ Server-side state management

**Technical Requirements**:
- ✅ Compiles with zero warnings
- ✅ Generated Elixir is idiomatic
- ✅ Type safety throughout
- ✅ Phoenix best practices followed
- ✅ LiveView features fully utilized

**Quality Bar**:
- Generated code indistinguishable from hand-written
- Performance comparable to native Elixir
- Maintainable and debuggable output

## 7. Success Criteria

### Compiler Architecture
- [ ] All files under 2,000 lines
- [ ] No circular dependencies
- [ ] Single compilation path per construct
- [ ] 50% code reduction through deduplication
- [ ] Clear, documented responsibilities

### Todo-App Benchmark
- [ ] Haxe compilation succeeds
- [ ] Elixir compilation succeeds
- [ ] Application starts without errors
- [ ] All features work correctly
- [ ] UI is responsive and modern
- [ ] LiveView real-time updates work
- [ ] Type safety maintained throughout

### Code Quality
- [ ] Generated Elixir passes code review as "hand-written"
- [ ] No machine-generated artifacts (arg0, arg1, etc.)
- [ ] Proper Elixir idioms and patterns
- [ ] Clean, readable, maintainable output

## 8. Risks & Mitigations

### Risk 1: Breaking Existing Functionality
**Mitigation**: Comprehensive test suite, incremental refactoring, snapshot testing

### Risk 2: Scope Creep
**Mitigation**: Strict adherence to PRD, defer non-critical improvements

### Risk 3: Integration Complexity
**Mitigation**: Parallel implementation, gradual cutover, feature flags

## 9. Definition of Done

The compiler reaches 1.0 when:

1. **Architecture**: Clean, maintainable, documented architecture with no technical debt
2. **Functionality**: Turing-complete Haxe compilation to idiomatic Elixir
3. **Quality**: Generated code indistinguishable from hand-written
4. **Validation**: Todo-app fully functional as modern Phoenix LiveView application
5. **Documentation**: Complete architectural and usage documentation
6. **Testing**: 100% test coverage of critical paths

## 10. Timeline

**Total Duration**: 4 weeks

- Week 1: Loop compilation unification
- Week 2: File extraction and modularization
- Week 3: Control flow simplification
- Week 4: Integration, testing, and todo-app validation

## Appendix A: File Size Analysis

**Current State**:
```
LoopCompiler.hx:        4,235 lines ❌ (2.1x over limit)
ControlFlowCompiler.hx: 2,929 lines ❌ (1.5x over limit)
ElixirCompiler.hx:      10,661 lines ❌❌❌ (5.3x over limit!)
PatternMatchingCompiler.hx: 866 lines ✅
FunctionCompiler.hx:    1,832 lines ⚠️
```

**Target State**:
```
All files: < 2,000 lines (ideal: 500-1,500)
```

## Appendix B: Architectural Principles

1. **Single Responsibility**: One compiler, one job
2. **Open/Closed**: Extensible through composition, not modification
3. **Dependency Direction**: Dependencies flow downward only
4. **Documentation First**: WHY/WHAT/HOW for every component
5. **Test Coverage**: No code without tests
6. **Idiomatic Output**: Generated code must pass human review

---

**This PRD will be used as the foundation for task planning in Shrimp, with the todo-app serving as our North Star for 1.0 readiness.**