# Test Suite Update Plan for Reflaxe.Elixir v1.0

## Executive Summary
**Total Tests**: 219  
**Estimated Failures**: 200+ (based on sample analysis)  
**Root Cause**: Compiler improvements generating different (better) code than old intended outputs  
**Goal**: Update all intended outputs to match new idiomatic code generation

## Pattern Categories and Priority Matrix

### Priority 1: Standard Library Files (HIGH IMPACT)
These files appear in nearly every test, multiplying their patterns across the suite.

#### Files to Fix First:
- `haxe/Log.ex` - Uses IO.inspect → Now Log.trace with metadata
- `string_tools.ex` - String concatenation → Should use interpolation
- `haxe/ds/balanced_tree.ex` - reduce_while patterns → Should use recursion
- `Array.ex` - Various array operations
- `haxe/io/Bytes.ex` - Binary operations

#### Pattern Issues:
1. **Logging Changes**:
   - OLD: `IO.inspect(value)`
   - NEW: `Log.trace(value, %{:file_name => "...", :line_number => N, ...})`
   
2. **String Operations**:
   - OLD: `"Hello " <> name <> ", age: " <> age`
   - NEW: `"Hello #{name}, age: #{age}"`

### Priority 2: Loop Transformations (VERY HIGH FREQUENCY)
Affects ~40% of all tests

#### Pattern Issues:
1. **Simple Iteration**:
   - OLD: `for item <- list do ... end`
   - CURRENT: `Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {...}, ...)`
   - TARGET: `Enum.each(list, fn item -> ... end)` or comprehensions

2. **Indexed Iteration**:
   - OLD: `for {item, i} <- Enum.with_index(list)`
   - CURRENT: Complex reduce_while with index tracking
   - TARGET: `Enum.with_index(list) |> Enum.each(fn {item, i} -> ... end)`

3. **While Loops**:
   - CURRENT: `Enum.reduce_while(Stream.iterate...)` with complex state
   - TARGET: Recursive functions or appropriate Enum operations

### Priority 3: Variable Naming (AFFECTS ALL TESTS)
Infrastructure and temporary variables

#### Pattern Issues:
1. **Generated Variables**:
   - CURRENT: `g`, `g1`, `g2`, `g3` in generated code
   - TARGET: Meaningful names (`index`, `accumulator`, `temp`) or underscores

2. **Unused Parameters**:
   - CURRENT: `case {:enum, value} -> value` (value might be unused)
   - TARGET: `case {:enum, _value} ->` (prefix with underscore)

3. **Infrastructure Variables**:
   - Fixed in session but needs validation across all tests
   - `_g2`, `_g3` properly tracked now

### Priority 4: Pattern Matching (MEDIUM FREQUENCY)
Affects ~30% of tests, especially enum-heavy code

#### Pattern Issues:
1. **Enum Destructuring**:
   - CURRENT: `elem(tuple, 0) == :tag` followed by `elem(tuple, 1)`
   - TARGET: `{:tag, value}` direct pattern matching

2. **Case Expressions**:
   - CURRENT: Nested if-else chains
   - TARGET: Clean case or cond expressions

### Priority 5: Module and Function Names (LOW FREQUENCY)
Naming convention improvements

#### Pattern Issues:
1. **Implementation Modules**:
   - CURRENT: `Email_Impl_`
   - TARGET: `Email` (cleaner names)

2. **Function Names**:
   - Snake_case conversion working correctly
   - Some edge cases with acronyms

## Test Categories by Directory

### Core Tests (`test/snapshot/core/`)
- **Count**: ~80 tests
- **Primary Issues**: Loops, Log.trace, variable naming
- **Priority**: HIGH (fundamental language features)

### Standard Library Tests (`test/snapshot/stdlib/`)
- **Count**: ~20 tests
- **Primary Issues**: All stdlib patterns multiply across other tests
- **Priority**: HIGHEST (fix these first)

### Phoenix Tests (`test/snapshot/phoenix/`)
- **Count**: ~20 tests
- **Primary Issues**: Framework-specific patterns mostly OK
- **Special Cases**: 
  - `js_async_await` - Generates JavaScript (not a failure)
  - `HXXTypeSafetyErrors` - Expected to fail (negative test)

### Ecto Tests (`test/snapshot/ecto/`)
- **Count**: ~15 tests
- **Primary Issues**: Schema generation, changeset patterns
- **Priority**: MEDIUM

### OTP Tests (`test/snapshot/otp/`)
- **Count**: ~10 tests
- **Primary Issues**: Supervisor patterns, GenServer
- **Priority**: MEDIUM

### Regression Tests (`test/snapshot/regression/`)
- **Count**: ~40 tests
- **Primary Issues**: Various patterns from bug fixes
- **Priority**: LOW (update after main tests)

## Implementation Strategy

### Phase 1: Standard Library (Days 1-2)
1. Update stdlib file generation in compiler
2. Fix Log.trace, string interpolation, basic patterns
3. Update intended outputs for stdlib tests
4. Verify multiplier effect across all tests

### Phase 2: Loop Transformations (Day 3)
1. Implement LoopTransformationPass in compiler
2. Convert reduce_while patterns to idiomatic Enum/comprehensions
3. Update loop test intended outputs
4. Validate performance implications

### Phase 3: Variable Naming (Day 4)
1. Enhance VariableCompiler intelligence
2. Eliminate g/g1/g2 variables
3. Proper underscore prefixing for unused vars
4. Update all affected test outputs

### Phase 4: Pattern Matching (Day 5)
1. Improve enum pattern matching
2. Direct destructuring instead of elem()
3. Update enum and pattern test outputs

### Phase 5: Bulk Updates (Days 6-7)
1. Systematically update remaining tests
2. Category by category validation
3. Final pass for edge cases

## Validation Criteria

### Per-Test Validation:
- [ ] Compilation succeeds
- [ ] Elixir syntax valid
- [ ] Output is idiomatic
- [ ] No unnecessary complexity
- [ ] Correct semantics preserved

### Global Validation:
- [ ] 95%+ tests passing
- [ ] Todo-app compiles without warnings
- [ ] No runtime errors in generated code
- [ ] Performance benchmarks maintained

## Special Considerations

### Tests That Should NOT Be Updated:
1. **Negative Tests** (expected to fail):
   - `HXXTypeSafetyErrors`
   - Any test with "Error" in name

2. **JavaScript Tests** (different output):
   - `js_async_await` (generates .js not .ex)
   - Other frontend tests

3. **Bootstrap Tests**:
   - May have special requirements
   - Validate carefully

## Metrics and Progress Tracking

### Success Metrics:
- Test pass rate: Target 95%+
- Todo-app warnings: Target 0
- Compilation time: Maintain or improve
- Code quality: All output idiomatic

### Progress Tracking:
- [ ] Stdlib tests updated (0/20)
- [ ] Core tests updated (0/80)
- [ ] Phoenix tests updated (0/20)
- [ ] Ecto tests updated (0/15)
- [ ] OTP tests updated (0/10)
- [ ] Regression tests updated (0/40)
- [ ] Other tests updated (0/34)

## Risk Mitigation

### Potential Risks:
1. **Breaking Changes**: Some "improvements" might break user code
   - Mitigation: Careful semantic validation
   
2. **Performance Regression**: New patterns might be slower
   - Mitigation: Benchmark critical paths
   
3. **Edge Cases**: Unusual patterns might not transform correctly
   - Mitigation: Comprehensive test coverage

### Rollback Strategy:
- Git commits for each phase
- Ability to revert specific transformations
- Feature flags for gradual rollout

## Next Steps

1. ✅ This analysis complete
2. → Create idiomatic pattern reference library
3. → Begin stdlib fixes
4. → Implement transformation passes
5. → Systematic test updates

---

*Generated: 2024-09-28*  
*Compiler Version: Approaching v1.0*  
*Total Work Estimate: 7-10 days*