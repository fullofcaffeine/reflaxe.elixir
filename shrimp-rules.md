# Development Guidelines

## Project Overview

### Core Architecture
- **Project Type**: Haxe→Elixir macro-time transpiler (NOT a runtime library)
- **Main Compiler**: src/reflaxe/elixir/ElixirCompiler.hx (currently 3000+ lines - VIOLATES size limit)
- **Helper Pattern**: src/reflaxe/elixir/helpers/*.hx for specialized compilation
- **Generated Output**: lib/*.ex files are GENERATED - NEVER edit directly
- **Integration Test**: examples/todo-app/ serves as primary compiler validation

## Critical Workflows

### Compiler Modification Workflow
1. Modify files in src/reflaxe/elixir/*.hx ONLY
2. Execute `npm test` immediately after changes
3. Clean todo-app: `cd examples/todo-app && rm -rf lib/*.ex lib/**/*.ex`
4. Regenerate: `npx haxe build-server.hxml`
5. Verify compilation: `mix compile --force`
6. Test runtime: `mix phx.server`

### Snapshot Test Workflow
1. Create test in test/tests/FEATURE_NAME/
2. Run specific test: `make -C test test-FEATURE_NAME`
3. Review output in out/ directory
4. Accept if correct: `make -C test update-intended TEST=FEATURE_NAME`
5. Verify all tests: `npm test`

## File Modification Rules

### Files to Modify
- **Compiler Source**: src/reflaxe/elixir/*.hx
- **Helper Compilers**: src/reflaxe/elixir/helpers/*.hx
- **Test Sources**: test/tests/*/Main.hx
- **Haxe Sources**: examples/todo-app/src_haxe/*.hx
- **Standard Library**: std/**/*.hx

### Files NEVER to Modify
- **Generated Elixir**: lib/*.ex, lib/**/*.ex
- **Build Output**: out/*.ex, intended/*.ex (except via update-intended)
- **Mix Config**: mix.exs, config/*.exs (unless adding dependencies)

### File Coordination Requirements
- Modifying ElixirCompiler.hx → Update dependent helper compilers
- Adding new helper → Register in ElixirCompiler.hx constructor
- Changing AST processing → Update ExpressionDispatcher.hx
- Modifying HXX compilation → Regenerate all LiveView components
- Fixing loop patterns → Test with test/tests/simple_for_loop/

## Architecture Rules

### File Size Limits
- **Maximum**: 2000 lines per file
- **Target**: 200-500 lines for helpers
- **Current Violations**: ElixirCompiler.hx (3000+ lines) - MUST be refactored

### Helper Compiler Pattern
- Create in src/reflaxe/elixir/helpers/
- Constructor accepts ElixirCompiler reference
- Single responsibility per helper
- Register in ElixirCompiler constructor
- Use delegation from main compiler

### AST Processing Rules
- Process TypedExpr until final string generation
- Never convert to strings early
- Use recursive AST traversal
- Apply transformations at AST level
- Generate strings only in return statements

## Testing Requirements

### Mandatory Test Validation
- Run `npm test` after EVERY compiler change
- Todo-app MUST compile without errors
- Todo-app MUST run with `mix phx.server`
- All snapshot tests MUST pass
- Fix broken tests immediately - never skip

### Test Creation Rules
- New features require snapshot test in test/tests/
- Test name matches feature being tested
- Include edge cases in test
- Document expected behavior in Main.hx
- Update intended output after verification

## Prohibited Actions

### NEVER Do These
- **❌ Edit generated .ex files** - Fix in compiler source
- **❌ Use string concatenation (+) in #if macro blocks** - Use interpolation or array.join()
- **❌ Hardcode app names** - No "TodoApp", "TodoAppWeb" in compiler
- **❌ Apply band-aid fixes** - Fix root causes only
- **❌ Use untyped/Dynamic** - Unless with written justification
- **❌ Skip testing** - Always run npm test
- **❌ Create files over 2000 lines** - Extract to helpers
- **❌ Use post-processing** - Fix generation at source
- **❌ Keep dead code** - Delete unused functions immediately
- **❌ Ignore test failures** - Fix before proceeding

## Current Critical Issues

### HIGH PRIORITY Bugs
1. **Array push in if expressions** - Assignments don't escape if scope in ConditionalCompiler.hx
2. **Variable shadowing warnings** - Generated code has shadowed variables
3. **FileSystem dependency missing** - HaxeWatcher requires sys.FileSystem

### Technical Debt
1. **ElixirCompiler.hx size** - 3000+ lines, needs extraction to helpers
2. **MigrationDSL string generation** - Should use AST transformation
3. **Duplicate Enum generation** - Multiple helpers generate same patterns

## Debugging Patterns

### XRay Debug Traces
```haxe
#if debug_feature_name
trace("[XRay FeatureName] Operation start");
trace('[XRay FeatureName] Input: ${input}');
#end
```

### Debug Compilation Flags
- Enable traces: `-D debug_feature_name`
- Macro stack traces: `-D eval-stack`
- Pattern matching debug: `-D debug_pattern_matching`
- Expression variants: `-D debug_expression_variants`

## Documentation Standards

### Class Documentation Pattern
```haxe
/**
 * CLASS_NAME: Purpose
 * 
 * WHY: Problem being solved
 * WHAT: Responsibilities
 * HOW: Implementation approach
 * EDGE CASES: Known limitations
 */
```

### Function Documentation Requirements
- Document WHY the function exists
- Explain WHAT it transforms
- Describe HOW it processes AST
- List EDGE CASES handled

## Framework Integration

### Annotation-Based Compilation
- Use @:native for module naming
- Use @:liveview for Phoenix LiveView
- Use @:schema for Ecto schemas
- Use @:migration for database migrations
- Use @:router for Phoenix routers
- Never detect framework from code patterns

### Phoenix Naming Conventions
- @:native("AppNameWeb.ModuleName") for web modules
- @:native("AppName.ModuleName") for app modules
- Generate snake_case file names
- Place in conventional Phoenix directories

## AI Decision Rules

### When Encountering Compilation Errors
1. Check if error is in generated .ex file
2. Trace back to compiler source that generated it
3. Fix in compiler, never in generated file
4. Regenerate and verify fix
5. Add snapshot test for regression prevention

### When Adding New Features
1. Check if helper compiler exists for feature type
2. Create new helper if over 100 lines of code
3. Add comprehensive WHY/WHAT/HOW documentation
4. Create snapshot test before implementation
5. Verify todo-app still compiles

### When Refactoring
1. Verify current tests pass first
2. Extract to helper if file over 2000 lines
3. Maintain exact same output
4. Run full test suite after each extraction
5. Test todo-app compilation and runtime

## Immediate Action Items

### Fix These First
1. **Array push in if expressions** - Modify ConditionalCompiler.hx to handle assignments
2. **Run npm test** - Ensure all current tests pass
3. **Test todo-app** - Must compile and run successfully

### Then Address
1. Extract ElixirCompiler.hx helpers to reduce size
2. Fix variable shadowing in generated code
3. Add FileSystem dependency for HaxeWatcher