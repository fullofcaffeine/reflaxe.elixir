# Compiler Development Best Practices

This document consolidates proven compiler development patterns and best practices for Reflaxe.Elixir, distilled from real implementation experience.

**See also**: [`COMPILER_PATTERNS.md`](COMPILER_PATTERNS.md) for detailed implementation patterns and lessons learned.

## Core Development Principles

### ⚠️ CRITICAL: Always Check What Exists First
**ALWAYS CHECK WHAT EXISTS FIRST** - This is a fundamental development principle:

✅ **Before creating anything new**:
- **Search for existing implementations** - Use Grep, Glob, LS tools to find similar functionality
- **Check test directories** - Look for existing tests before creating new ones (`test/tests/`)
- **Review standard library** - Check `std/` for existing types, helpers, and patterns
- **Examine examples** - Look at `examples/` for similar use cases
- **Check documentation** - Review `documentation/` for established patterns

❌ **Never duplicate work**:
- Don't create new tests when existing ones can be updated
- Don't implement features that already exist
- Don't create new directories when existing structure works
- Don't reinvent abstractions that are already available

**Why This Matters**:
- Prevents duplicate code and conflicting implementations
- Maintains consistency across the codebase
- Saves development time and reduces maintenance burden
- Builds on existing tested and proven patterns
- Ensures architectural coherence

**Example**:
```
❌ BAD: Create test/tests/option_idiomatic/ without checking
✅ GOOD: Find existing test/tests/option_type/ and update it
```

### ⚠️ CRITICAL: Honesty About Performance Characteristics
**NEVER make false claims about performance** - Be accurate about runtime vs compile-time behavior:

✅ **Be honest about**:
- **Runtime validation costs** - Acknowledge validation overhead exists
- **Memory allocations** - Don't claim "zero-cost" when creating Result objects
- **Function call overhead** - Method calls have costs vs direct operations
- **Actual compilation targets** - What the code actually becomes

❌ **Never claim**:
- "Zero-cost abstraction" unless truly compile-time only
- "No runtime overhead" when validation exists
- Performance benefits without evidence

**Example**:
```haxe
// ❌ BAD: "Zero-cost abstraction: compiles to plain Int with no runtime overhead"
// ✅ GOOD: "Runtime safety: validates values to maintain invariants with minimal overhead"
```

### ⚠️ CRITICAL: Test Infrastructure Rule
**NEVER define test infrastructure types in application code**
- **Test types** (Conn, Changeset<T>, LiveView, etc.) belong in the standard library at `/std/phoenix/test/` and `/std/ecto/test/`
- **Applications** should import from standard library: `import phoenix.test.Conn` NOT `typedef Conn = Dynamic`
- **This ensures**: consistency, reusability, proper maintenance, and type safety across all projects
- **Example**: `import ecto.Changeset; var changeset: Changeset<User>` NOT `var changeset: Dynamic`

### ⚠️ CRITICAL: No Simplifications or Workarounds for Testing
**NEVER simplify code just to make tests pass or to bypass compilation issues.**

❌ **Don't**:
- Comment out problematic code "temporarily" 
- Return dummy values to avoid compilation errors
- Skip proper error handling to make tests pass
- Use placeholder values instead of fixing root causes
- Disable features to work around bugs

✅ **Instead**:
- **Fix the root cause** of compilation errors
- **Implement proper error handling** with meaningful messages
- **Address the underlying architectural issue** causing the problem
- **Write comprehensive tests** that validate the actual expected behavior
- **Document why** a particular approach was chosen over alternatives

**Example of Wrong Approach**:
```haxe
// ❌ BAD: Working around Supervisor.startLink compilation error
return {status: "ok", pid: null}; // Simplified for testing
```

**Example of Right Approach**:
```haxe
// ✅ GOOD: Fix the Supervisor extern definition to make startLink work properly
return Supervisor.startLink(children, opts);
```

**Why This Matters**:
- Workarounds mask real problems and create technical debt
- They make the system unreliable in production environments
- They prevent proper learning about the system's architecture
- They lead to incomplete implementations that fail in edge cases

**When You Encounter a Blocker**:
1. **Investigate the root cause** - understand why it's failing
2. **Fix the underlying issue** - don't work around it
3. **Test the proper solution** - ensure it works as intended
4. **Document the learning** - explain what was fixed and why

### ⚠️ CRITICAL: Dual-API Philosophy for Standard Library
**Every standard library type MUST provide BOTH cross-platform AND native APIs** - Give developers maximum flexibility:

✅ **Dual-API Pattern**:
- **Haxe Standard API** - Cross-platform methods following Haxe conventions
- **Elixir Native API** - Platform-specific methods familiar to Elixir/Phoenix developers
- **Conversion Methods** - Easy bridging between Haxe and Elixir types
- **Developer Choice** - Use either or both APIs as needed

**Implementation Example**:
```haxe
class Date {
    // === Haxe Standard Library API (Cross-Platform) ===
    public function getTime(): Float { }        // Returns milliseconds
    public function getMonth(): Int { }         // 0-based (0-11)
    public static function now(): Date { }      // Current time
    
    // === Elixir Native API Extensions ===
    public function add(amount: Int, unit: TimeUnit): Date { }      // Elixir-style
    public function diff(other: Date, unit: TimeUnit): Int { }      // Elixir-style
    public function toIso8601(): String { }                         // Elixir feature
    public function beginningOfDay(): Date { }                      // Phoenix/Timex
    public function compare(other: Date): ComparisonResult { }      // Elixir-style
    public function truncate(precision: TimePrecision): Date { }    // Elixir feature
    
    // === Conversion Methods ===
    public function toNaiveDateTime(): elixir.NaiveDateTime { }
    public function toElixirDate(): elixir.Date { }
    public static function fromNaiveDateTime(dt: elixir.NaiveDateTime): Date { }
}
```

**Benefits**:
- **Cross-Platform Code**: Write once, run anywhere using Haxe methods
- **Platform Power**: Access full Elixir/BEAM capabilities when needed
- **Gradual Migration**: Teams can migrate from pure Elixir gradually
- **Familiar APIs**: Elixir developers can use methods they know
- **No Compromise**: Full type safety with maximum flexibility

**Implementation Guidelines**:
1. **Always implement full Haxe interface first** - Ensures cross-platform compatibility
2. **Add native methods as extensions** - Don't break the Haxe contract
3. **Use Haxe naming conventions** - `camelCase` for all methods to maintain consistency
4. **Provide conversion methods** - Seamless interop between type systems
5. **Document both APIs clearly** - Mark cross-platform vs platform-specific
6. **Match Elixir functionality** - Methods should behave like their Elixir counterparts

**Why This Matters**:
- Maximizes adoption by supporting both communities
- Enables true write-once/run-anywhere when needed
- Provides escape hatches for platform-specific optimization
- Supports gradual adoption and migration paths
- Maintains type safety while offering flexibility

## Compiler Implementation Patterns

### 1. Never Leave TODOs in Production Code
- **Rule**: Fix issues immediately, don't leave placeholders
- **Why**: TODOs accumulate technical debt and indicate incomplete implementation
- **Example**: Don't write `// TODO: Need to substitute variables` - implement the substitution

### 2. Pass TypedExpr Through Pipeline as Long as Possible
- **Rule**: Keep AST nodes (TypedExpr) until the very last moment before string generation
- **Why**: AST provides structural information for proper transformations
- **Anti-pattern**: Converting to strings early then trying to manipulate strings
- **Correct**: Store `conditionExpr: TypedExpr` alongside `condition: String`

### 3. Apply Transformations at AST Level, Not String Level
- **Rule**: Use recursive AST traversal for variable substitution and transformations
- **Why**: String manipulation is fragile and error-prone
- **Implementation**: `compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String)`
- **Benefits**: Type-safe, handles nested expressions, catches edge cases

### 4. Variable Substitution Pattern
- **Problem**: Lambda parameters need different names than original loop variables
- **Solution**: 
  1. Find source variable in AST using `findLoopVariable(expr: TypedExpr)`
  2. Apply recursive substitution with `compileExpressionWithSubstitution()`
  3. Generate consistent lambda parameter names (`"item"`)
- **Result**: `numbers.map(n -> n * 2)` → `Enum.map(numbers, fn item -> item * 2 end)`

### 5. Context-Aware Compilation
- **Rule**: Use context flags to track compilation state for different behavior
- **Implementation**: `isInLoopContext` flag to determine variable substitution
- **Why**: Same code needs different treatment in different contexts
- **Example**: Variable substitution only applies inside loops, not in function parameters

### 6. Avoid Hardcoded Variable Lists
- **Anti-pattern**: Maintaining hardcoded lists like `["i", "j", "item", "id"]`
- **Solution**: Use function-based detection with `isCommonLoopVariable()` and `isSystemVariable()`
- **Benefits**: More maintainable, extensible, and accurate detection

### 7. Documentation String Generation
- **Rule**: Preserve multi-line intent from JavaDoc to generate proper @doc heredocs
- **Fix**: Track `wasMultiLine` during cleaning to force proper formatting
- **Escape properly**: Never use unsafe template strings for documentation content
- **Result**: Professional, idiomatic Elixir documentation that matches language conventions

### 8. Pattern Detection for Optimization
- **Pattern**: Detect function call patterns like `item(v)` to generate direct references
- **Example**: `array.map(transform)` → `Enum.map(array, transform)` not `fn item -> item(v) end`
- **Implementation**: Use regex patterns to detect and optimize common cases
- **Why**: Generate cleaner, more efficient target code

### 9. Avoid Ad-hoc Fixes - Implement General Solutions
- **Rule**: Never add function-specific workarounds (e.g., "if calling Supervisor.startLink, do X")
- **Principle**: Always solve the root cause that benefits all similar use cases
- **Goal**: The compiler should generate correct idiomatic Elixir for any valid Haxe code
- **Example**: Don't special-case Supervisor child specs; fix how all objects with atom keys compile
- **Why**: Ad-hoc fixes create technical debt, mask architectural issues, and don't scale

### 10. Prefer Simple Solutions Over Clever Ones
- **Rule**: Choose straightforward implementations over complex, "clever" solutions
- **Example**: Removed __AGGRESSIVE__ marker system in favor of always doing variable substitution
- **Principle**: Simple code is easier to understand, debug, and maintain
- **Test**: If explaining the code takes more than 30 seconds, it's probably too complex
- **Benefits**: Fewer bugs, easier onboarding for new developers, reduced maintenance overhead
- **Guideline**: Optimize for code clarity first, performance second (unless performance is critical)

### 11. Always Review Recent Work Before Major Changes
- **Rule**: Before implementing new features or significant refactors, check what's been done recently
- **Process**: Read TASK_HISTORY.md, recent commit messages, and documentation updates
- **Purpose**: Understand the current direction, avoid duplicating work, and build on recent insights
- **Key Questions**: What patterns were just established? What approaches were tried and rejected?
- **Example**: Before adding new atom key detection, review recent atom key work to avoid repeating mistakes
- **Documentation**: Check for new architectural decisions, patterns, or best practices
- **Why**: Ensures consistency, prevents regression, and leverages recent learning and discoveries

### 12. JavaScript Generation Philosophy: Separation of Concerns
- **Rule**: Focus exclusively on Haxe→Elixir compilation; use standard Haxe JS compiler for JavaScript output
- **Custom JS Only When**: Features don't exist in standard Haxe (e.g., async/await) or require specific Phoenix integration
- **Benefits**: Reduced maintenance burden, clear project scope, better compatibility with JS tooling
- **Implementation**: Delegate to Haxe's mature JS compiler unless absolutely necessary for custom features
- **Future**: Consider Genes compiler migration while maintaining separation principle
- **See**: [`JS_GENERATION_PHILOSOPHY.md`](JS_GENERATION_PHILOSOPHY.md) - Complete philosophical guide

## Development Workflow Guidelines

### Examples as Compiler Quality Gates
- **todo-app**: Tests dual-target compilation, LiveView, Ecto integration
- **Test suite**: Validates basic language features and edge cases  
- **Real-world patterns**: Drive compiler to handle complex scenarios
- **Production readiness**: Examples must compile cleanly for v1.0 quality

### Compiler-Example Development Feedback Loop Rules
✅ **Example fails to compile**: This is compiler feedback, not user error
✅ **Generated .ex files invalid**: Fix the transpiler, don't patch files
✅ **Type system errors**: Improve type generation logic in compiler
❌ **Never manually edit generated files**: They get overwritten on recompilation
❌ **Don't work around compiler bugs**: Fix the root cause in transpiler source

### When Working on Examples (todo-app, etc.)
→ **Remember**: Examples are **compiler testing grounds** - failures reveal compiler bugs
→ **Don't Patch Generated Files**: Never manually fix .ex files - fix the compiler source instead
→ **Feedback Loop**: Example development IS compiler development - they improve each other
→ **Workflow**: Example fails → Find compiler bug → Fix compiler → Example works better

## Modern Haxe Development Guidelines

### JavaScript Code Injection
❌ **Deprecated (Haxe 4.1+)**:
```haxe
untyped __js__("console.log({0})", value);  // Shows deprecation warning
```

✅ **Modern (Haxe 4.1+)**:
```haxe
js.Syntax.code("console.log({0})", value);  // Clean, no warnings
```

### Type-Safe DOM Element Casting
❌ **Unsafe Pattern**:
```haxe
var element = cast(e.target, js.html.Element);  // No type checking
```

✅ **Safe Pattern**:
```haxe
var target = e.target;
if (target != null && js.Syntax.instanceof(target, js.html.Element)) {
    var element = cast(target, js.html.Element);  // Type-safe casting
    // Use element safely
}
```

### Development Rules
1. **ALWAYS check existing implementations first** - Before starting any task, search for existing implementations, similar patterns, or related code in the codebase to avoid duplicate work
2. **Verify task completion status** - Check if the task is already done through existing files, examples, or alternative approaches before implementing from scratch
3. **Check deprecation warnings** - Never ignore Haxe compiler warnings about deprecated APIs
4. **Reference modern docs** - Use https://api.haxe.org/ for Haxe 4.3+ patterns
5. **Use reference folder** - Check `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/haxe/std/js/` for modern implementations
6. **Type safety first** - Always use `js.Syntax.instanceof()` before casting DOM elements
7. **Performance APIs** - Use `PerformanceNavigationTiming` instead of deprecated `PerformanceTiming`

## Dynamic Type Usage Guidelines ⚠️

**Dynamic should be used with caution** and only when necessary:
- ✅ **When to use Dynamic**: Catch blocks (error types vary), reflection operations, external API integration
- ✅ **Always add justification comment** when using Dynamic to explain why it's necessary
- ❌ **Avoid Dynamic when generics or specific types work** - prefer type safety
- 📝 **Example of proper Dynamic usage**:
  ```haxe
  } catch (e: Dynamic) {
      // Dynamic used here because Haxe's catch can throw various error types
      // Converting to String for error reporting
      EctoErrorReporter.reportSchemaError(className, Std.string(e), pos);
  }
  ```

## Quality Standards and Testing

### Mandatory Testing Protocol ⚠️ CRITICAL
**EVERY compiler change MUST be validated through the complete testing pipeline.**

#### After ANY Compiler Change
1. **Run Full Test Suite**: `npm test` - ALL tests must pass (snapshot + Mix + generator)
2. **Test Specific Feature**: `haxe test/Test.hxml test=feature_name`
3. **Update Snapshots When Improved**: `haxe test/Test.hxml update-intended`
4. **Validate Runtime**: `MIX_ENV=test mix test`
5. **Test Todo-App Integration**:
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex
   npx haxe build-server.hxml
   mix compile --force
   ```

#### Testing Requirements
❌ **NEVER**:
- Commit without running full test suite
- Consider a fix complete without todo-app compilation
- Skip tests "just for a small change"
- Ignore test failures as "unrelated"
- Use workarounds instead of fixing root causes
- Leave issues behind even if not the focus of current task

✅ **ALWAYS**:
- Run `npm test` after EVERY compiler modification
- Verify todo-app compiles as integration test
- Update snapshots when output legitimately improves
- Fix broken tests before moving to new features
- Fix ALL issues discovered, not just the primary one
- Complete proper solutions, never temporary patches

### Todo-App as Integration Benchmark
The todo-app in `examples/todo-app` serves as the **primary integration test**:
- Tests Phoenix framework integration
- Validates HXX template compilation
- Ensures router DSL functionality
- Verifies Ecto schema generation
- Confirms LiveView compilation

**If todo-app doesn't compile, the compiler is broken - regardless of unit tests passing.**

### Quick Test Commands Reference
```bash
npm test                                    # Full suite (mandatory before commit)
haxe test/Test.hxml test=name              # Specific snapshot test
haxe test/Test.hxml update-intended        # Accept new output
MIX_ENV=test mix test                      # Runtime validation
cd examples/todo-app && mix compile        # Integration test
```

### Test Type Matrix
| What You're Testing | Test Type | When to Use |
|-------------------|-----------|-------------|
| **New compiler feature** | Snapshot test | Testing AST → Elixir transformation |
| **Build macro validation** | Compile-time test | Testing warnings/errors from DSLs |
| **Build system integration** | Mix test | Testing generated code runs in BEAM |
| **Framework integration** | Example test | Testing real-world usage patterns |

**⚠️ CRITICAL RULE**: Never remove test code to fix failures - fix the underlying compiler issue instead.

## Handling Unoptimized AST Patterns

### Understanding Reflaxe's AST Constraints

**FUNDAMENTAL CONSTRAINT**: Reflaxe compilers receive unoptimized TypedExpr AST from Haxe because we bypass the optimizer via `manualDCE: true`. This architectural decision means we must handle dead code patterns that Haxe would normally eliminate.

### Common Unoptimized AST Patterns

#### 1. Orphaned Enum Parameter Extraction
**Pattern**: Haxe generates TEnumParameter for ALL enum destructuring, even when unused.
```haxe
// Haxe switch case (empty body, parameter unused)
case Repo(config): // No-op

// Generated unoptimized AST creates:
TEnumParameter(e, ef, 0) // Extracts 'config'
TLocal(g)                 // References extracted value
// But 'g' is never used!
```

**Detection Strategy**:
```haxe
private function isOrphanedParameterExtraction(e: TypedExpr, ef: EnumField, index: Int): Bool {
    // Identify patterns where parameters are extracted but never used
    // Check enum field name and parameter index
    // Return true if this is a known orphaned pattern
}
```

**Mitigation Approach**:
- **Option 1**: Return safe defaults (`"g = nil"`) instead of orphaned operations
- **Option 2**: Skip both TEnumParameter and TLocal expressions in block compilation
- **Option 3**: Track variable usage and eliminate at generation time

#### 2. Redundant Variable Assignments
**Pattern**: Temporary variables created for expressions that could be inlined.
```haxe
// Unoptimized AST might generate:
var _temp1 = someValue;
var _temp2 = _temp1;
return _temp2;

// Instead of:
return someValue;
```

#### 3. Dead Conditional Branches
**Pattern**: Both branches of conditionals compiled even when one is provably dead.
```haxe
if (true) {
    // This executes
} else {
    // This is dead code but still in AST
}
```

### Multi-Layer Mitigation Strategy

**BEST PRACTICE**: Use coordinated detection and mitigation across multiple compiler components:

1. **Detection Layer** (Specialized Compilers):
   - Identify patterns at the source
   - Make local decisions about handling
   - Return safe alternatives

2. **Coordination Layer** (ControlFlowCompiler):
   - Skip redundant expression sequences
   - Coordinate between multiple compilers
   - Maintain compilation context

3. **Documentation Layer**:
   - Document each pattern discovered
   - Create test cases for validation
   - Update ADRs with decisions

### Implementation Guidelines

✅ **DO**:
- Detect patterns at AST level, not string level
- Coordinate across compiler components
- Document why patterns occur
- Create test cases for each pattern
- Measure compilation time impact

❌ **DON'T**:
- Use post-processing string filters
- Make assumptions without verification
- Skip documentation of patterns
- Ignore performance implications
- Break compilation semantics

### Testing Orphaned Pattern Handling

```bash
# Create test case for orphaned pattern
mkdir test/tests/orphaned_enum_params
vim test/tests/orphaned_enum_params/Main.hx

# Add switch with unused parameters
# Run test to see generated output
haxe test/Test.hxml test=orphaned_enum_params

# Verify no undefined variables in output
grep "undefined variable" test/tests/orphaned_enum_params/out/*.ex
```

### Performance Considerations

- **Detection Overhead**: Pattern matching adds ~1-2ms per file
- **Acceptable Trade-off**: Correctness over micro-optimization
- **Monitor Growth**: Track patterns to prevent detection explosion
- **Consider Caching**: Cache detection results for repeated patterns

### Future Improvements

1. **Pattern Database**: Centralize orphaned pattern definitions
2. **Automated Detection**: Develop heuristics for automatic detection
3. **Compiler Flag**: Optional AST cleanup levels
4. **Upstream Contribution**: Share patterns with other Reflaxe compilers

**See Also**:
- [`AST_CLEANUP_PATTERNS.md`](AST_CLEANUP_PATTERNS.md) - Comprehensive pattern documentation
- [`ADR-001-handling-unoptimized-ast.md`](../05-architecture/ADR-001-handling-unoptimized-ast.md) - Architectural decision record
- [`COMPILATION_PIPELINE_ARCHITECTURE.md`](COMPILATION_PIPELINE_ARCHITECTURE.md) - Pipeline understanding

**⚠️ CRITICAL RULE**: Never remove test code to fix failures - fix the underlying compiler issue instead.

## Reference Resources

### Documentation System
- [`COMPILER_PATTERNS.md`](COMPILER_PATTERNS.md) - Detailed implementation patterns and lessons learned
- [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md) - Critical testing rules and methodologies
- [`documentation/architecture/TESTING.md`](architecture/TESTING.md) - Technical testing infrastructure
- [`PARADIGM_BRIDGE.md`](paradigms/PARADIGM_BRIDGE.md) - Understanding imperative→functional transformations
- [`DEVELOPER_PATTERNS.md`](guides/DEVELOPER_PATTERNS.md) - Best practices and patterns

### External Resources
- **Haxe API Documentation**: https://api.haxe.org/ - For type system, standard library, and language features
- **Haxe Manual**: https://haxe.org/manual/ - **CRITICAL**: For any advanced feature, always consult the official manual
- **Haxe Code Cookbook**: https://code.haxe.org/ - Modern patterns and best practices
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Reflaxe patterns, Phoenix examples, Haxe source

**Principle**: Always reference existing working code and official documentation rather than guessing or assuming implementation details.