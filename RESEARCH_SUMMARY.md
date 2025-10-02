# Infrastructure Variable Substitution - Research Summary

**Date**: January 2, 2025
**Mission**: Deep research into why infrastructure variable substitution fails between TypedExprPreprocessor and AST building
**Status**: ✅ **COMPLETE** - Root cause identified, replan created

---

## Executive Summary

**Root Cause Found**: The preprocessor successfully substitutes infrastructure variables (_g, g, etc.) at TypedExpr level, but SwitchBuilder **re-compiles the switch target expression** through `compileExpressionImpl()`, which processes the ORIGINAL TypedExpr that hasn't been through the preprocessor's substitution map.

**Key Discovery**: Sub-expressions extracted by builders are POINTERS to original TypedExpr nodes. When builders re-compile these pointers, they bypass the preprocessed tree entirely.

---

## Research Methodology

### 1. Codebase Investigation
- ✅ Searched for infrastructure variable patterns (`_g`, `g`, `g1`) in all builders
- ✅ Examined `tempVarRenameMap` usage across builders
- ✅ Traced TSwitch handling from preprocessor → builder → printer
- ✅ Identified SwitchBuilder line 136 as re-compilation point

### 2. Reference Implementation Analysis
- ✅ Studied Reflaxe's `RemoveTemporaryVariablesImpl.hx` pattern
- ✅ Compared with Reflaxe.CSharp architecture (doesn't have this issue)
- ✅ Found that mature Reflaxe compilers don't re-compile in builders

### 3. Architectural Pattern Analysis
```
Preprocessor modifies TypedExpr COPY → Creates new tree with substitutions
           ↓
ElixirASTBuilder extracts sub-expressions → Gets ORIGINAL un-preprocessed nodes
           ↓
SwitchBuilder re-compiles → Sees TLocal(_g) in original node
           ↓
Result: Infrastructure variables reappear in final output
```

---

## Evidence Collected

### Debug Output Analysis
```
[applySubstitutionsRecursively] ✓ Substituting _g (ID: 57730)  # ✅ Preprocessor works
[applySubstitutionsRecursively] ✓ Substituting _g (ID: 57732)  # ✅ Preprocessor works

# But generated code still has:
case _g do  # ❌ Infrastructure variable still present
```

### Test Case Validation
- **Location**: `test/snapshot/regression/infrastructure_variable_substitution/`
- **Expected**: `case (TestPubSub.subscribe("notifications")) do`
- **Actual**: `case _g do` with `elem(_g, 1)` extraction
- **Test Status**: Currently passing (but with wrong intended output - needs update)

### Critical Files Analyzed
1. **TypedExprPreprocessor.hx** (lines 249-301) - Recursive substitution logic ✅ WORKS CORRECTLY
2. **SwitchBuilder.hx** (line 136) - **ROOT CAUSE**: Re-compiles original expression
3. **ElixirCompiler.hx** (lines 1046, 1144, 1314, 1421) - Calls preprocessor correctly
4. **VariableBuilder.hx** - Processes TLocal without checking substitutions

---

## Solution Architecture

### Phase 1: Band-Aid Fix (Immediate)
**Pattern**: Pass substitution context through compilation pipeline

**Implementation**:
1. Add `infraVarSubstitutions: Map<Int, TypedExpr>` to CompilationContext
2. Populate in ElixirCompiler after preprocessor runs
3. Check in SwitchBuilder before re-compiling expressions
4. Check in VariableBuilder for all TLocal references

**Pros**: Quick fix, minimal changes, unblocks development
**Cons**: Band-aid solution, doesn't address root architecture issue

### Phase 2: Proper Fix (Long-term)
**Pattern**: Refactor builders to accept pre-built ElixirAST

**Architecture Change**:
```haxe
// Current (WRONG):
SwitchBuilder.build(e: TypedExpr, ...) {
    var targetAST = context.compiler.compileExpressionImpl(e, false);  // Re-compiles
}

// Fixed (RIGHT):
SwitchBuilder.build(targetAST: ElixirAST, ...) {
    // Uses already-built and preprocessed AST
}
```

**Benefits**:
- Matches Reflaxe architecture patterns
- Preserves ALL preprocessor transformations
- Prevents bypassing compilation pipeline

**Challenges**:
- Requires refactoring all builders
- Need to build AST at ElixirASTBuilder level first
- More extensive testing required

---

## Shrimp Task Plan Created

**Total Tasks**: 5 tasks in dependency order

1. **Phase 1: Implement substitution context band-aid fix** (ID: da37f969...)
   - Add infraVarSubstitutions field to CompilationContext
   - Populate after preprocessor runs
   - Create helper methods

2. **Phase 1: Update SwitchBuilder** (ID: 6eafe44c...)
   - Check substitutions before re-compiling
   - Use substituted expression if available

3. **Phase 1: Update VariableBuilder** (ID: 4241924a...)
   - Check substitutions for ALL TLocal references
   - Comprehensive coverage

4. **Phase 1: Run full test suite** (ID: 19bc04bf...)
   - Validate no regressions
   - Fix any broken tests
   - Verify todo-app compiles

5. **Phase 1: Document band-aid fix** (ID: 40226929...)
   - Update CLAUDE.md files
   - Create Phase 2 architecture plan
   - Add TODO comments in code

---

## Key Insights

### 1. Preprocessor Pattern Works
The TypedExprPreprocessor using `TypedExprTools.map()` for recursive substitution is CORRECT. The problem is NOT in the preprocessor.

### 2. Architecture Mismatch
Builders extracting sub-expressions and re-compiling them is the ROOT architectural flaw. This pattern doesn't match mature Reflaxe compilers.

### 3. Reflaxe Best Practice
Reflaxe's `RemoveTemporaryVariablesImpl` works because:
- It modifies TypedExpr in place
- Returns complete transformed tree
- Builders never re-compile sub-expressions

### 4. Our Deviation
We deviated from Reflaxe patterns by:
- Extracting sub-expressions from preprocessed tree
- Re-compiling them through `compileExpressionImpl()`
- Losing substitution context in the process

---

## Testing Strategy

### Existing Test
- **infrastructure_variable_substitution** test exists ✅
- Currently has WRONG intended output (needs update after fix)
- Will validate the fix automatically

### Additional Tests Needed (Future)
- Nested switch expressions with infrastructure variables
- Infrastructure variables in loop conditions
- Complex expressions with multiple infrastructure variables

---

## Documentation Created

1. **INFRASTRUCTURE_VARIABLE_ROOT_CAUSE.md** ✅
   - Complete root cause analysis
   - Architecture diagrams
   - Solution comparisons
   - Phase 1 & 2 implementation plans

2. **RESEARCH_SUMMARY.md** ✅ (this file)
   - Research methodology
   - Evidence collected
   - Solution architecture
   - Shrimp task plan

3. **Next Steps**: Update CLAUDE.md files after Phase 1 implementation

---

## Timeline Estimate

### Phase 1 (Band-Aid Fix): 4-6 hours
- Task 1: Implement context (1 hour)
- Task 2: Update SwitchBuilder (1 hour)
- Task 3: Update VariableBuilder (1 hour)
- Task 4: Test suite validation (1-2 hours)
- Task 5: Documentation (1-2 hours)

### Phase 2 (Proper Fix): 2-3 weeks
- Architecture refactoring
- All builder updates
- Comprehensive testing
- Integration validation

**Recommendation**: Implement Phase 1 now, schedule Phase 2 for next major refactoring sprint

---

## References

- **Root Cause Document**: `/INFRASTRUCTURE_VARIABLE_ROOT_CAUSE.md`
- **Test Case**: `test/snapshot/regression/infrastructure_variable_substitution/`
- **Reflaxe Reference**: `/haxe.elixir.reference/reflaxe/src/reflaxe/preprocessors/implementations/RemoveTemporaryVariablesImpl.hx`
- **Critical Files**:
  - `src/reflaxe/elixir/preprocessor/TypedExprPreprocessor.hx`
  - `src/reflaxe/elixir/ast/builders/SwitchBuilder.hx`
  - `src/reflaxe/elixir/CompilationContext.hx`

---

## Conclusion

**Research Mission: ✅ COMPLETE**

The infrastructure variable substitution failure has been thoroughly researched and understood. The root cause is a fundamental architecture issue where builders re-compile original TypedExpr nodes, bypassing preprocessor transformations.

**Solution**: A two-phase approach:
1. **Phase 1 (Immediate)**: Pass substitution context through compilation pipeline - band-aid fix
2. **Phase 2 (Long-term)**: Refactor builders to accept pre-built AST - proper architectural fix

**Next Action**: Begin Phase 1 implementation using the Shrimp task plan created.
