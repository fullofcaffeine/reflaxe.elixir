# Compiler Refactoring PRD: From Monolith to Modular Architecture

**Date**: January 2025  
**Status**: Active Development  
**Priority**: Critical - Technical Debt Emergency

## Executive Summary

The Reflaxe.Elixir compiler faces a critical architectural crisis with ElixirASTBuilder.hx reaching 11,137 lines - a 10x violation of maintainability standards. A previous modularization attempt (commit ecf50d9d, September 2025) failed catastrophically, deleting 4,382 lines of modular builders and causing functionality regressions that persist today. This PRD defines a pragmatic, incremental path forward using transformation passes while preventing further degradation.

## Problem Statement

### Current Crisis
1. **ElixirASTBuilder.hx**: 11,137 lines (should be <1,000 lines)
   - 191 switch statements
   - Multiple responsibilities mixed
   - Impossible to navigate or debug
   - Every change causes conflicts

2. **Failed Modularization Legacy** (September 2025)
   - Deleted files totaling 4,382 lines:
     - ModuleBuilder.hx (1,492 lines) 
     - LoopBuilder.hx (448 lines)
     - PatternMatchBuilder.hx (388 lines)
     - ArrayBuilder.hx (386 lines)
     - ControlFlowBuilder.hx (375 lines)
     - ExUnitCompiler.hx (345 lines)
     - CallExprBuilder.hx (322 lines)
     - ClassBuilder.hx (451 lines)
   - Lost functionality:
     - @:application handling (recovered via transformation pass)
     - @:repo handling (recovered via transformation pass)
     - Other unknown regressions likely remain

3. **Architectural Violations**
   - Single Responsibility Principle: One file does everything
   - Open/Closed Principle: Can't extend without modifying
   - Testing: Cannot unit test a monolithic file
   - Performance: Compilation slower due to file size

## Discovery Timeline

### Session Analysis (January 2025)

1. **Initial Issue**: TodoApp.Application module empty, Phoenix server fails
2. **Root Cause Discovery**: Functions missing from TypedExpr due to DCE
3. **Temporary Fix**: Added @:keep metadata to force function retention
4. **Deeper Investigation**: Found commit ecf50d9d deleted critical functionality
5. **Pattern Recognition**: Multiple annotation handlers (@:application, @:repo) lost in failed refactoring
6. **Current Solution**: Restoration via transformation passes in ElixirASTTransformer

### Key Insights

1. **Transformation Passes Work**: Successfully restored functionality via applicationTransformPass and repoTransformPass
2. **Incremental is Essential**: Big-bang refactoring failed; incremental approach succeeds
3. **Testing is Critical**: Each extraction must maintain full test suite
4. **Metadata Flow**: Using ElixirMetadata through the pipeline enables clean transformations

## Solution Architecture

### Core Principle: Stop the Bleeding, Then Heal

**Phase 1: Immediate Stabilization (NOW)**
- ✅ PROHIBITION: Zero additions to ElixirASTBuilder.hx
- ✅ All new features via transformation passes
- ✅ Document in AGENTS.md to prevent violations
- ✅ Fix critical todo-app functionality

**Phase 2: Transformation Pass Architecture (CURRENT)**
- Use ElixirASTTransformer for all enhancements
- Create specialized transformers in `ast/transformers/`
- Leverage metadata flow for context passing
- Each pass has single responsibility

**Phase 3: Gradual Extraction (FUTURE)**
- Extract logical sections incrementally
- Each extraction <500 lines
- Full test validation per extraction
- Target: Reduce ElixirASTBuilder to <2,000 lines

## Technical Approach

### 1. Transformation Pass Pattern (Proven Working)

```haxe
// In ElixirASTTransformer.hx
public static function specificTransformPass(ast: ElixirAST): ElixirAST {
    switch(ast.def) {
        case EModule(name, attrs, body) if (ast.metadata?.isSpecific == true):
            // Transform based on metadata
            return transformedAST;
        default:
            return ast;
    }
}
```

**Benefits**:
- Clean separation of concerns
- Testable in isolation
- No modification to builder
- Metadata-driven decisions

### 2. Metadata Flow System

```haxe
typedef ElixirMetadata = {
    ?isApplication: Bool,
    ?isRepo: Bool,
    ?isLiveView: Bool,
    ?parentModule: String,
    ?isException: Bool,
    // ... extensible for new features
}
```

**Flow**: ElixirCompiler → ElixirASTBuilder → ElixirASTTransformer → ElixirASTPrinter

### 3. Specialized Transformers

Location: `src/reflaxe/elixir/ast/transformers/`

- **AnnotationTransforms.hx**: Framework annotations (@:repo, @:application, etc.)
- **BehaviorTransforms.hx**: OTP behaviors and callbacks
- **PatternTransforms.hx**: Pattern matching optimizations
- **IdiomaticTransforms.hx**: Elixir idiom transformations

## Implementation Roadmap

### Immediate Actions (Week 1)

1. **Fix TypeSafeChildSpec** ✅
   - Generate proper child spec maps
   - Enable Phoenix server startup
   - Validate todo-app functionality

2. **Document Patterns** ✅
   - Create this PRD
   - Update AGENTS.md enforcement rules
   - Document transformation pass patterns

3. **Audit Lost Functionality**
   - Review deleted builders for missing features
   - Create test cases for each
   - Implement via transformation passes

### Short Term (Weeks 2-4)

1. **Complete Annotation Coverage**
   - @:genserver transformation
   - @:channel transformation  
   - @:presence transformation
   - @:schema enhancements

2. **Extract Critical Helpers**
   - VariableTracking → VariableCompiler.hx
   - PatternDetection → PatternAnalyzer.hx
   - LoopOptimization → LoopOptimizer.hx

3. **Test Infrastructure**
   - Regression tests for each transformation
   - Integration tests for todo-app
   - Performance benchmarks

### Medium Term (Months 2-3)

1. **Modular Builder Architecture**
   ```
   ast/builders/
   ├── CoreBuilder.hx (<500 lines)
   ├── ExpressionBuilder.hx (<500 lines)
   ├── PatternBuilder.hx (<500 lines)
   ├── TypeBuilder.hx (<500 lines)
   └── BuilderOrchestrator.hx (<200 lines)
   ```

2. **Incremental Migration**
   - One builder at a time
   - Full test suite after each
   - Rollback capability

3. **Documentation**
   - Architecture diagrams
   - Builder interaction patterns
   - Extension guidelines

## Success Metrics

### Technical Metrics
- [ ] ElixirASTBuilder.hx < 2,000 lines
- [ ] No file > 500 lines (except main compiler)
- [ ] 100% test coverage maintained
- [ ] Compilation time improved by 30%

### Functional Metrics
- [ ] todo-app fully functional
- [ ] All Phoenix patterns supported
- [ ] No regression from current functionality
- [ ] New features easier to add

### Quality Metrics
- [ ] Clear separation of concerns
- [ ] Each module single responsibility
- [ ] Comprehensive documentation
- [ ] No TODO comments in production

## Risk Mitigation

### Risk 1: Regression During Extraction
**Mitigation**: 
- Incremental extraction with immediate testing
- Feature flags for new builders
- Maintain parallel implementations during transition

### Risk 2: Lost Functionality Discovery
**Mitigation**:
- Comprehensive audit of deleted builders
- Test-driven recovery of features
- User feedback integration

### Risk 3: Performance Degradation
**Mitigation**:
- Benchmark before/after each change
- Profile compilation bottlenecks
- Optimize critical paths

## Lessons Learned

### From Failed Modularization (September 2025)

1. **Big-Bang Refactoring Fails**
   - Attempted to extract everything at once
   - Lost critical functionality
   - Abandoned incomplete

2. **Testing Gaps Kill Refactoring**
   - No regression tests for annotations
   - Missing integration tests
   - Silent failures discovered months later

3. **Metadata is Key**
   - Clean way to pass context
   - Enables transformation passes
   - Maintains separation of concerns

### From Current Recovery (January 2025)

1. **Transformation Passes Work**
   - Successfully restored lost functionality
   - Clean architecture
   - Testable components

2. **Incremental Wins**
   - Small changes with validation
   - Continuous improvement
   - Lower risk

3. **Documentation Prevents Recurrence**
   - AGENTS.md enforcement works
   - PRDs provide clarity
   - Git history invaluable

## Enforcement Rules

### Absolute Prohibitions

1. **NO additions to ElixirASTBuilder.hx** - Zero tolerance
2. **NO big-bang refactoring** - Incremental only
3. **NO untested extractions** - Full validation required
4. **NO feature without tests** - TDD mandatory

### Required Practices

1. **New features via transformation passes**
2. **Document in nearest AGENTS.md**
3. **Test before/after extraction**
4. **Benchmark performance impact**

## Appendix: Technical Details

### Current File Size Analysis

```
ElixirASTBuilder.hx: 11,137 lines
- Switch statements: 191
- Functions: ~150
- Responsibilities: 15+
- Complexity: Unmeasurable
```

### Target Architecture

```
Total lines across all builders: <3,000
- Each specialized builder: <500 lines
- Orchestrator: <200 lines
- Clear interfaces between modules
- Testable components
```

### Transformation Pass Inventory

**Working**:
- applicationTransformPass
- repoTransformPass
- liveViewTransformPass
- endpointTransformPass
- stringInterpolationPass

**Needed**:
- genServerTransformPass
- channelTransformPass
- presenceTransformPass
- schemaEnhancementPass
- idiomaticOptimizationPass

## Conclusion

The Reflaxe.Elixir compiler stands at a critical juncture. The monolithic ElixirASTBuilder.hx represents severe technical debt that impedes development, causes bugs, and blocks new features. However, the successful recovery from the failed modularization attempt proves that incremental transformation passes work.

By following this PRD's incremental approach - stopping new additions, using transformation passes, and gradually extracting functionality - we can achieve a maintainable, extensible, and performant compiler architecture without repeating past failures.

The path forward is clear: Stop the bleeding, use proven patterns, and refactor incrementally with comprehensive testing.

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Next Review**: February 2025