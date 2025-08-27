# Product Requirements Document: Reflaxe.Elixir 1.0
## The Path to Idiomatic, Maintainable, and Complete Haxe→Elixir Transpilation

---

## Executive Summary

**⚠️ CRITICAL: Test infrastructure is currently broken, blocking ALL development. Phase 0 must be completed IMMEDIATELY before any other work can proceed.**

This PRD outlines the systematic evolution of Reflaxe.Elixir from its current state (v0.8) to a production-ready v1.0 release. The focus is on architectural simplification, idiomatic code generation, complete standard library support, and robust immutability handling while maintaining zero regressions through comprehensive testing.

### Vision Statement
**Transform Reflaxe.Elixir into the definitive solution for cross-platform development with Elixir, generating code so idiomatic that Elixir developers can't distinguish it from hand-written code.**

### Core Principles
1. **Test-First Development**: No feature work until tests are passing
2. **Zero Regressions**: Every change validated through comprehensive testing
3. **Idiomatic Output**: Generated Elixir indistinguishable from expert-written code
4. **SOLID Engineering**: Maintain clean architecture while simplifying
5. **Incremental Progress**: Small, tested, committed steps toward the goal

### Timeline Overview
- **Phase 0: IMMEDIATE** - Fix test infrastructure (BLOCKING)
- **Phase 1: Week 1-2** - Architecture simplification
- **Phase 2: Week 3-6** - Standard library completion
- **Phase 3: Week 7-8** - Immutability paradigm bridge
- **Phase 4: Week 9-10** - Framework integration excellence
- **Phase 5: Week 11-12** - Developer experience
- **Phase 6: Week 13-14** - Performance & optimization
- **Total: 14 weeks to 1.0** (assuming Phase 0 completed immediately)

---

## Current State Analysis

### Test Infrastructure Issues (CRITICAL - BLOCKING ALL DEVELOPMENT)
**Last Updated**: January 2025 - Current test suite status: 25/76 passing

#### 🔴 Critical Blockers
1. **Parallel Test Runner Timeout** - `npm test` never completes due to 10-second timeout
2. **RouterBuildMacro Test Failures** - 5 router tests missing stdlib file generation
3. **Missing compile.hxml Files** - 49 test directories (not 5!) lacking configuration
4. **Arrays Test Failure** - Output mismatch with intended
5. **InjectionDebug Test** - No intended output baseline created

#### Test Execution Status
- **Sequential Tests**: Work but slow (`npm run test:sequential`)
- **Parallel Tests**: Timeout after 2 minutes (`npm test` - DEFAULT BROKEN)
- **Workaround**: Must use sequential runner, taking 5+ minutes

### Technical Debt Inventory
1. **Test Infrastructure Broken** - Parallel runner timeout prevents normal development flow
2. **Unnecessary compileExpression override** causing injection bugs
3. **Over-engineered ExpressionDispatcher** adding complexity without clear value
4. **Orphaned g_array variables** in enum pattern matching
5. **Incomplete standard library** implementation
6. **Inconsistent mutability handling** between Haxe and Elixir paradigms
7. **Monolithic ElixirCompiler.hx** (2,956 lines)

### Architectural Issues
- **Fighting Reflaxe**: Override patterns that interfere with framework features
- **Excessive Delegation**: 5+ function calls for simple expression compilation
- **Unclear Separation**: Some helpers too small, some too large
- **Missing Documentation**: Many functions lack WHY/WHAT/HOW documentation

### What's Working Well
- ✅ Phoenix/LiveView integration
- ✅ Pattern matching compilation
- ✅ Ecto schema generation
- ✅ HXX template compilation
- ✅ Basic OTP patterns
- ✅ Test infrastructure (snapshot testing)

---

## Roadmap to 1.0

### Phase 0: EMERGENCY - Fix Test Infrastructure (IMMEDIATE - BLOCKING ALL WORK)
**Goal**: Restore ability to run tests so development can proceed
**Timeline**: Must be fixed BEFORE any other work begins

#### 0.1 Fix Parallel Test Runner Timeout (CRITICAL PATH)
- [ ] **IMMEDIATE**: Increase ParallelTestRunner timeout from 10s to 30s (line 466)
- [ ] Test that `npm test` completes successfully
- [ ] Document timeout configuration for future adjustments
- [ ] Consider making timeout configurable via environment variable

**Quick Fix**:
```bash
# Edit test/ParallelTestRunner.hx line 466
# Change: final TIMEOUT = 10.0; 
# To:     final TIMEOUT = 30.0;
npm test  # Should now complete
```

**Commit**: `fix(test): increase parallel runner timeout for Elixir compilation`

#### 0.2 Fix RouterBuildMacro Test Failures
- [ ] Investigate why stdlib files aren't being generated
- [ ] Fix file generation for: std_types.ex, enum_value.ex, haxe_CallStack.ex
- [ ] Ensure all 5 RouterBuildMacro tests pass
- [ ] Document the root cause for future prevention

**Commit**: `fix(compiler): restore stdlib file generation for router tests`

#### 0.3 Clean Up Test Infrastructure
- [ ] Remove or fix 49 directories missing compile.hxml
- [ ] Create intended output for InjectionDebug test
- [ ] Fix arrays test output mismatch
- [ ] Ensure sequential AND parallel test runners work

**Testing Validation**:
```bash
npm test                          # Parallel - Must complete in <3 min
npm run test:sequential           # Sequential - Must pass 76/76
cd examples/todo-app && mix compile  # Must compile
```

**Commit**: `fix(tests): complete test infrastructure restoration`

### Phase 1: Architecture Simplification (Week 1-2)
**Goal**: Align with Reflaxe idioms while maintaining functionality
**Prerequisite**: Phase 0 must be 100% complete

#### 1.1 Remove Harmful Override
- [ ] Delete compileExpression override in ElixirCompiler
- [ ] Verify all tests still pass
- [ ] Test todo-app thoroughly
- [ ] Document why override was removed

**Commit**: `refactor(compiler): remove unnecessary compileExpression override`

---

#### 1.2 Absorb ExpressionDispatcher
- [ ] Move routing logic into compileExpressionImpl
- [ ] Maintain helper compiler delegation for complex cases
- [ ] Inline simple cases (TConst, TLocal)
- [ ] Update all debug traces

**Testing Protocol**:
```bash
npm test                          # Full suite
npm run test:parallel             # Performance check
git diff --stat                  # Verify code reduction
```

**Commit**: `refactor(architecture): merge ExpressionDispatcher into main compiler`

#### 1.3 Consolidate Simple Helpers
- [ ] Merge LiteralCompiler into main compiler
- [ ] Merge OperatorCompiler into main compiler
- [ ] Keep complex helpers separate (PatternMatching, LiveView, etc.)
- [ ] Document rationale for each decision

**Commit**: `refactor(helpers): consolidate simple expression compilers`

---

### Phase 2: Standard Library Completion (Week 3-6)
**Goal**: Full Haxe stdlib support with idiomatic Elixir generation

#### 2.1 Core Types Enhancement
- [ ] Complete Array → List translation with all methods
- [ ] Map implementation with proper immutability
- [ ] StringBuf → IO.iodata optimization
- [ ] Date/DateTime full compatibility
- [ ] Math module completion

**Testing for each type**:
```bash
# Create comprehensive test
echo "test/tests/stdlib/TypeName/" 
# Test Haxe API
npx haxe test/Test.hxml test=stdlib/TypeName
# Verify idiomatic output
cat test/tests/stdlib/TypeName/out/main.ex
```

**Commit**: `feat(stdlib): complete core type implementations`

#### 2.2 Dual API Pattern Implementation
- [ ] Haxe-compatible API (cross-platform)
- [ ] Elixir-native API (platform-specific)
- [ ] Seamless interop between both
- [ ] Documentation for dual usage

Example:
```haxe
// Haxe way
var list = [1, 2, 3];
list.map(x -> x * 2);

// Elixir way
var list = [1, 2, 3];
list.elixir_map(&(&1 * 2));  // Generates: Enum.map(list, &(&1 * 2))
```

**Commit**: `feat(stdlib): implement dual API pattern for collections`

#### 2.3 IO and File System
- [ ] File operations with proper error handling
- [ ] Process spawning and management
- [ ] Network abstractions
- [ ] Stream processing

**Commit**: `feat(stdlib): complete IO and filesystem support`

---

### Phase 3: Immutability Paradigm Bridge (Week 7-8)
**Goal**: Seamless translation of mutable Haxe patterns to immutable Elixir

#### 3.1 State Threading Enhancement
- [ ] Automatic variable rebinding detection
- [ ] Struct update optimization
- [ ] Loop variable transformation
- [ ] Accumulator pattern generation

**Example transformation**:
```haxe
// Haxe (mutable)
var sum = 0;
for (i in array) {
    sum += i;
}

// Generated Elixir (immutable)
sum = Enum.reduce(array, 0, fn i, sum -> sum + i end)
```

**Commit**: `feat(immutability): enhance state threading for loops`

#### 3.2 Mutable Collection Patterns
- [ ] Array.push → list concatenation
- [ ] Map mutations → Map.put chains
- [ ] Object field updates → struct updates
- [ ] Reference type handling

**Testing**:
```bash
# Create mutation pattern tests
test/tests/immutability/
# Verify idiomatic transformations
npm test -- test=immutability
```

**Commit**: `feat(immutability): handle mutable collection patterns`

#### 3.3 Advanced Patterns
- [ ] Builder pattern → with clauses
- [ ] Singleton pattern → GenServer
- [ ] Observer pattern → PubSub
- [ ] Iterator pattern → Stream

**Commit**: `feat(patterns): translate OOP patterns to functional equivalents`

---

### Phase 4: Framework Integration Excellence (Week 9-10)
**Goal**: First-class support for Elixir ecosystem

#### 4.1 Phoenix Enhancements
- [ ] Complete LiveView lifecycle
- [ ] Phoenix.Component support
- [ ] Presence tracking
- [ ] Channel abstractions
- [ ] PubSub patterns

**Testing with todo-app**:
```bash
cd examples/todo-app
# Add each feature
npx haxe build-server.hxml
mix test
mix phx.server
# Manual testing of feature
```

**Commit**: `feat(phoenix): complete Phoenix framework integration`

#### 4.2 Ecto Advanced Features
- [ ] Multi-tenant queries
- [ ] Custom types
- [ ] Embedded schemas
- [ ] Transactions
- [ ] Migrations DSL

**Commit**: `feat(ecto): advanced database features`

#### 4.3 OTP Patterns
- [ ] GenServer complete
- [ ] Supervisor trees
- [ ] GenStage
- [ ] Tasks and Agents
- [ ] Registry

**Commit**: `feat(otp): complete OTP behavior support`

---

### Phase 5: Developer Experience (Week 11-12)
**Goal**: Make Reflaxe.Elixir a joy to use

#### 5.1 Error Messages
- [ ] Clear compilation errors
- [ ] Helpful suggestions
- [ ] Source mapping
- [ ] Stack trace translation

**Commit**: `feat(dx): improve error messages and debugging`

#### 5.2 Documentation
- [ ] Complete API documentation
- [ ] Pattern cookbook
- [ ] Migration guide from Haxe
- [ ] Video tutorials

**Commit**: `docs: comprehensive documentation suite`

#### 5.3 Tooling
- [ ] VS Code extension
- [ ] Mix task integration
- [ ] Project templates
- [ ] Code generators

**Commit**: `feat(tooling): developer productivity tools`

---

### Phase 6: Performance & Optimization (Week 13-14)
**Goal**: Generate performant Elixir code

#### 6.1 Compilation Performance
- [ ] Reduce compilation time by 50%
- [ ] Incremental compilation
- [ ] Parallel processing
- [ ] Cache optimization

**Benchmark**:
```bash
time npm test                    # Baseline
# After optimizations
time npm test                    # Should be 50% faster
```

**Commit**: `perf(compiler): optimize compilation performance`

#### 6.2 Generated Code Quality
- [ ] Tail recursion optimization
- [ ] Pattern matching efficiency
- [ ] Reduce intermediate variables
- [ ] Stream processing where applicable

**Commit**: `perf(codegen): optimize generated Elixir code`

---

## Testing Strategy

### Test Pyramid
```
         /\
        /E2E\        (todo-app, examples)
       /------\
      /  Mix   \     (runtime validation)
     /----------\
    /  Snapshot  \   (output comparison)
   /--------------\
  /   Unit Tests   \ (helper functions)
```

### Testing Protocol for Every Change

1. **Before Change**:
```bash
npm test > baseline.txt
cd examples/todo-app && mix test
```

2. **After Change**:
```bash
npm test > current.txt
diff baseline.txt current.txt  # Only intentional changes
cd examples/todo-app && mix test
mix phx.server  # Manual smoke test
```

3. **Before Commit**:
```bash
npm test                        # All pass
npm run test:examples           # All examples work
cd examples/todo-app && mix test && mix dialyzer
```

### Regression Test Requirements

Every bug fix MUST include:
1. Test case demonstrating the bug
2. Fix implementation
3. Test passing after fix
4. Documentation of root cause

---

## Commit Standards

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Test addition/modification
- `docs`: Documentation only
- `style`: Code style/formatting
- `chore`: Maintenance tasks

### Example Commit
```
refactor(compiler): remove unnecessary compileExpression override

The override was causing interference with Reflaxe's built-in injection
mechanism. DirectToStringCompiler already handles this correctly.

- Removed compileExpression override from ElixirCompiler
- All tests pass (76/76)
- todo-app compiles and runs correctly
- Reduces call stack depth by 1 level

Fixes: #__elixir__-injection-bug
```

---

## Success Metrics

### Test Infrastructure Metrics (PHASE 0 - IMMEDIATE)
- [ ] **npm test completes in <3 minutes** (currently: times out)
- [ ] **76/76 tests passing** (currently: 25/76)
- [ ] **Parallel test runner functional** (currently: broken)
- [ ] **0 missing compile.hxml files** (currently: 49)

### Quantitative Metrics
- [ ] 100% of Haxe stdlib methods supported
- [ ] 0 regression test failures
- [ ] <3s compilation time for todo-app
- [ ] <3000 lines in ElixirCompiler.hx
- [ ] 100% of examples compile and run

### Qualitative Metrics
- [ ] Generated code review: "looks hand-written"
- [ ] Elixir developers can maintain generated code
- [ ] Clear upgrade path from 0.x to 1.0
- [ ] Positive developer feedback

---

## Risk Mitigation

### Identified Risks

1. **Architecture Changes Break Existing Code**
   - Mitigation: Comprehensive test suite before changes
   - Mitigation: Incremental refactoring
   - Mitigation: Feature flags for experimental changes

2. **Performance Degradation**
   - Mitigation: Benchmark before/after each phase
   - Mitigation: Profile compilation hotspots
   - Mitigation: Parallel test execution

3. **Idiomatic vs Compatible Trade-offs**
   - Mitigation: Dual API pattern
   - Mitigation: Configuration options
   - Mitigation: Clear documentation of differences

4. **Scope Creep**
   - Mitigation: Strict phase boundaries
   - Mitigation: Feature freeze during refactoring
   - Mitigation: Defer nice-to-haves to 1.1

---

## Definition of Done for 1.0

### Compiler Requirements
- [ ] All 76+ tests passing
- [ ] No known critical bugs
- [ ] Architecture simplified per plan
- [ ] Documentation complete

### Standard Library
- [ ] Core types fully implemented
- [ ] Collections with dual APIs
- [ ] IO operations complete
- [ ] Date/Time handling

### Framework Support
- [ ] Phoenix LiveView complete
- [ ] Ecto full integration
- [ ] OTP patterns supported
- [ ] Mix tasks available

### Developer Experience
- [ ] Clear error messages
- [ ] Source maps working
- [ ] VS Code extension
- [ ] Project templates

### Performance
- [ ] <3s todo-app compilation
- [ ] <100ms incremental builds
- [ ] Memory usage <500MB

---

## Timeline Summary

```
Weeks 1-2:   Fix critical bugs, establish testing
Weeks 3-4:   Architecture simplification
Weeks 5-8:   Standard library completion
Weeks 9-10:  Immutability paradigm bridge
Weeks 11-12: Framework integration excellence
Weeks 13-14: Developer experience
Weeks 15-16: Performance optimization
Week 17:     1.0 Release preparation
```

**Total Duration**: 17 weeks (~4 months)

---

## Appendix A: Current Bug List

1. ❌ 49 false positive "Missing compile.hxml" errors
2. ❌ Orphaned g_array variables in enum patterns
3. ❌ 5 missing compile.hxml files in examples
4. ✅ __elixir__ injection in void contexts (FIXED)

## Appendix B: Architecture Decisions

### To Keep
- Helper compilers for complex features (Pattern matching, LiveView, etc.)
- Snapshot testing infrastructure
- Dual API pattern for stdlib

### To Remove
- compileExpression override
- ExpressionDispatcher routing layer
- Unnecessary abstraction layers

### To Add
- Regression test suite
- Performance benchmarks
- Source mapping
- Developer tools

## Appendix C: Testing Checklist

For every PR:
- [ ] npm test passes
- [ ] examples compile
- [ ] todo-app runs
- [ ] No performance regression
- [ ] Documentation updated
- [ ] Regression test added (if bug fix)
- [ ] Commit message follows standards

---

## Conclusion

Reflaxe.Elixir 1.0 represents a mature, production-ready transpiler that generates idiomatic Elixir code while preserving Haxe's type safety and cross-platform capabilities. By following this PRD's systematic approach—with emphasis on testing, incremental progress, and architectural simplification—we will deliver a tool that serves as the bridge between Haxe's powerful type system and Elixir's elegant functional paradigm.

**The journey to 1.0 is not just about features, but about crafting a tool that developers trust and enjoy using.**