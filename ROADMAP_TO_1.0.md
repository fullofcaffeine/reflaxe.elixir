# Roadmap to Reflaxe.Elixir 1.0 - Breaking the Circle

## Executive Summary

Based on Codex's architectural assessment and current test failures, we're experiencing a fundamental architectural issue: **lack of proper symbol tables and hygiene passes**. This causes the whack-a-mole pattern of fixes breaking other things.

**Current State**: 166 failing tests, primarily due to variable naming inconsistencies
**Root Cause**: No single source of truth for variable bindings
**Solution**: Implement a minimal IR layer with proper symbol resolution

## The Circle We're In

We keep fixing symptoms, not causes:
- Fix underscore prefixing → breaks variable references
- Fix pattern names → breaks body references
- Fix enum extraction → breaks other patterns
- Each "fix" creates new issues because we lack a coherent symbol system

## Breaking Out: The Three-Milestone Path

### Milestone 0: Immediate Stabilization (1-2 days)
**Goal**: Stop the bleeding, get to a consistent state

#### M0.1: Disable Automatic Underscore Prefixing ✅ DONE
- Removed all automatic underscore prefixing
- Accept Elixir warnings temporarily
- Prioritize correctness over warnings

#### M0.2: Fix Pattern Variable Extraction (IN PROGRESS)
**Current Issue**: Pattern has `{:some, value}` but body references `v`
**Fix**: Use actual pattern variable names from Haxe source, not canonical names
- Line 5903-5909 in ElixirASTBuilder.hx needs fixing
- Should use extractedParams when available, not canonicalNames

#### M0.3: Make Binder/Body Consistent
- When transformer removes `v = g`, update references to use pattern variable
- Add variable renaming map to transformer
- Apply renames when filtering redundant assignments

#### M0.4: Add Stabilization Flag
```bash
-D elixir.stabilization_mode=true  # Disable all clever transforms
```

#### M0.5: Validate Todo-App
- Ensure todo-app compiles and runs
- This is our integration test baseline

**Expected Result**: Tests compile without undefined variable errors, even if output isn't perfect

### Milestone 1: Core IR Implementation (1 week)
**Goal**: Establish proper symbol tables and single source of truth

#### M1.1: Design Minimal IR Types
```haxe
enum IRExpr {
    IRModule(name: String, defs: Array<IRDef>);
    IRDef(name: String, params: Array<Symbol>, body: IRExpr);
    IRCase(expr: IRExpr, clauses: Array<IRClause>);
    IRPattern(pattern: IRPattern, bindings: Array<Symbol>);
    IRVar(symbol: Symbol);
    // ... minimal set for core functionality
}

class Symbol {
    public var id: Int;
    public var suggestedName: String;
    public var scope: Scope;
    public var isUsed: Bool;
}
```

#### M1.2: Implement Symbol Table
- Every variable gets a Symbol with unique ID
- Pattern binders create symbols
- Body references use same symbols
- No more string-based variable resolution

#### M1.3: Add Hygiene Pass
```haxe
class HygienePass {
    function computeFinalNames(ir: IRExpr): Map<Symbol, String> {
        // Compute usage per scope
        // Apply underscore prefixes
        // Handle shadowing
        // Escape reserved words
        // Return final name mapping
    }
}
```

#### M1.4: Lower Haxe to IR
- Convert TypedExpr → IR with proper symbols
- Pattern matches bind symbols directly
- No more temp variable heuristics

**Expected Result**: <50 failing tests, no undefined variable errors

### Milestone 2: Re-enable Features (3-4 days)
**Goal**: Turn optimizations back on with proper foundation

#### M2.1: Re-enable Underscore Prefixing
- Use hygiene pass for proper unused detection
- Apply consistently across patterns and bodies

#### M2.2: Re-enable Transforms
- Comprehension optimization
- Pattern match optimization
- String interpolation
- All backed by IR, not string manipulation

#### M2.3: Add Reserved Word Escaping
- Part of hygiene pass
- Handle Elixir keywords properly

**Expected Result**: Todo-app fully functional, <10 failing tests

### Milestone 3: Production Hardening (3-4 days)
**Goal**: Fix remaining issues, ensure stability

#### M3.1: Phoenix/Presence/Ecto Edge Cases
- Handle all framework-specific patterns
- Ensure idiomatic output

#### M3.2: Standard Library Polish
- All stdlib generates idiomatic code
- No reduce_while for simple iterations

#### M3.3: Final Test Suite Pass
- All tests green
- Todo-app production ready

**Expected Result**: 0 failing tests, production-ready compiler

## Why This Will Work

1. **Addresses Root Cause**: Symbol table eliminates variable mismatch issues
2. **Incremental Progress**: Each milestone is independently valuable
3. **No More Whack-a-Mole**: With proper IR, fixes don't cascade
4. **Clear Success Metrics**: Test count provides objective progress

## Timeline Estimate

- **M0**: 1-2 days (stabilization)
- **M1**: 5-7 days (IR implementation)
- **M2**: 3-4 days (re-enable features)
- **M3**: 3-4 days (hardening)

**Total: ~2-3 weeks to stable 1.0**

## Current Blockers

1. **No Symbol Table**: Using strings for variable names
2. **Multiple Detection Paths**: Pattern detection in multiple places
3. **No Hygiene Pass**: Underscore prefixing is ad-hoc
4. **Mixed Concerns**: Builder does transformations
5. **String Manipulation**: Instead of AST operations

## Success Criteria for 1.0

- [ ] 0 compilation failures in test suite
- [ ] Todo-app runs without warnings
- [ ] Generated code is idiomatic Elixir
- [ ] No undefined variable errors
- [ ] Consistent variable naming
- [ ] Phoenix patterns work correctly

## Technical Debt to Address

1. ElixirASTBuilder.hx is 10,000+ lines (needs modularization)
2. No separation between building and transformation
3. Ad-hoc pattern detection throughout
4. String-based variable resolution
5. No proper testing of intermediate representations

## Recommendation

**Stop patching symptoms. Implement M0 for immediate stability, then focus entirely on M1 (IR layer).** The IR implementation will collapse most issues because they all stem from the same root cause: lack of proper symbol resolution.

Without the IR layer, we'll keep walking in circles. With it, the path to 1.0 is clear and achievable.