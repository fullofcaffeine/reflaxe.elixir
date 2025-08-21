# Compiler Testing Guide

## Core Principle: No Workarounds, Complete Solutions

**NEVER use workarounds. ALWAYS fix root causes. NEVER leave issues behind.**

This is fundamental to compiler development. Every issue discovered must be properly fixed, even if it wasn't the original focus. Temporary patches, workarounds, and "we'll fix it later" approaches are strictly forbidden.

## Testing Philosophy

The Reflaxe.Elixir compiler uses a multi-layered testing approach:

1. **Snapshot Tests** - Validate AST→Elixir transformation correctness
2. **Mix Tests** - Verify runtime behavior of generated code
3. **Generator Tests** - Ensure Mix tasks work correctly
4. **Integration Tests** - Todo-app must compile and run

### The Todo-App Rule

**If todo-app doesn't compile, the compiler is broken.**

The todo-app in `examples/todo-app` is not just an example - it's the primary integration test. It exercises:
- Phoenix Router DSL
- LiveView compilation
- HXX template generation
- Ecto schema generation
- Phoenix framework patterns
- Real-world application structure

## Mandatory Testing Workflow

### After ANY Compiler Change

```bash
# 1. Run full test suite (MANDATORY)
npm test

# 2. If tests fail, fix ALL issues found
# Never skip "unrelated" failures

# 3. Test todo-app compilation
cd examples/todo-app
rm -rf lib/*.ex lib/**/*.ex
npx haxe build-server.hxml
mix compile --force

# 4. If todo-app fails, the change is incomplete
# Fix the compiler, not the generated code
```

### Testing Commands Reference

#### Full Test Suite
```bash
npm test                    # Runs everything (mandatory before commit)
```

#### Snapshot Testing
```bash
# Run all snapshot tests
haxe test/Test.hxml

# Run specific test
haxe test/Test.hxml test=feature_name

# Show compilation output for debugging
haxe test/Test.hxml test=feature_name show-output

# Update expected output when improvements are made
haxe test/Test.hxml update-intended

# Update specific test
haxe test/Test.hxml test=feature_name update-intended
```

#### Mix Runtime Tests
```bash
# Run all Mix tests
MIX_ENV=test mix test

# Run specific test file
MIX_ENV=test mix test test/specific_test.exs

# Run with trace for debugging
MIX_ENV=test mix test --trace

# Run specific test at line
MIX_ENV=test mix test test/file.exs:42
```

#### Todo-App Integration Testing
```bash
cd examples/todo-app

# Clean and regenerate
rm -rf lib/*.ex lib/**/*.ex
npx haxe build-server.hxml

# Test compilation
mix compile --force

# Test runtime
mix test

# Test server startup
mix phx.server
```

## Common Testing Scenarios

### When Adding a New Feature

1. **Create snapshot test first**:
   ```bash
   # Create test directory
   mkdir -p test/tests/my_feature
   
   # Add compile.hxml
   echo "-cp .
   -lib reflaxe
   -D reflaxe_runtime
   -D elixir_output=out
   -D no-utf16
   --macro reflaxe.elixir.CompilerInit.Start()
   Main" > test/tests/my_feature/compile.hxml
   
   # Create Main.hx with test case
   # Run to generate output
   haxe test/Test.hxml test=my_feature
   
   # Accept as intended
   haxe test/Test.hxml test=my_feature update-intended
   ```

2. **Implement feature in compiler**

3. **Verify tests pass**:
   ```bash
   npm test
   ```

4. **Test in todo-app**:
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex
   npx haxe build-server.hxml
   mix compile
   ```

### When Fixing a Bug

1. **Reproduce in test**:
   ```bash
   # Find or create test that shows the bug
   haxe test/Test.hxml test=bug_case show-output
   ```

2. **Fix in compiler source**

3. **Verify fix**:
   ```bash
   # Test should now pass
   haxe test/Test.hxml test=bug_case
   
   # Update snapshot if output improved
   haxe test/Test.hxml test=bug_case update-intended
   ```

4. **Run full suite**:
   ```bash
   npm test
   ```

5. **Verify todo-app still works**:
   ```bash
   cd examples/todo-app && mix compile
   ```

### When Refactoring

1. **Ensure all tests pass before starting**:
   ```bash
   npm test
   ```

2. **Make refactoring changes**

3. **Run tests frequently during refactoring**:
   ```bash
   npm test
   ```

4. **If ANY test fails, fix immediately**
   - Don't accumulate broken tests
   - Each step should maintain green tests

5. **Final validation with todo-app**:
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex
   npx haxe build-server.hxml
   mix compile --force
   ```

## Testing Rules and Anti-Patterns

### ✅ DO

- Run full test suite after every change
- Fix ALL test failures, not just "related" ones
- Update snapshots when output legitimately improves
- Test todo-app as final validation
- Write tests for new features BEFORE implementing
- Keep tests simple and focused

### ❌ DON'T

- Skip tests for "small changes"
- Use workarounds instead of proper fixes
- Leave failing tests for later
- Patch generated files manually
- Ignore "unrelated" test failures
- Commit with failing tests

## Special Testing Considerations

### HXX Template Testing

After modifying HxxCompiler:
```bash
# Regenerate all templates
cd examples/todo-app
rm -rf lib/server_layouts_*.ex
npx haxe build-server.hxml

# Check for valid HEEx syntax
mix compile

# Verify templates render
mix phx.server
```

### Router DSL Testing

After modifying RouterCompiler:
```bash
# Test router compilation
cd examples/todo-app
rm lib/todo_app_web/router.ex
npx haxe build-server.hxml

# Verify routes
mix phx.routes
```

### Pattern Matching Testing

After modifying pattern matching:
```bash
# Run pattern matching tests
haxe test/Test.hxml test=pattern_matching

# Test in real code
cd examples/todo-app
npx haxe build-server.hxml
mix test
```

## Debugging Test Failures

### Snapshot Test Failures

```bash
# Show what's being generated
haxe test/Test.hxml test=failing_test show-output

# Compare with expected
diff test/tests/failing_test/intended/Main.ex test/tests/failing_test/out/Main.ex

# If new output is correct, update
haxe test/Test.hxml test=failing_test update-intended
```

### Mix Test Failures

```bash
# Run with trace for stack traces
MIX_ENV=test mix test --trace

# Run specific failing test
MIX_ENV=test mix test test/failing_test.exs:42

# Check generated code
cat lib/generated_module.ex
```

### Todo-App Compilation Failures

```bash
# Clean everything
rm -rf lib/*.ex lib/**/*.ex _build deps

# Regenerate with verbose output
npx haxe build-server.hxml -D verbose

# Try compilation with warnings
mix compile --warnings-as-errors

# Check specific error
mix compile 2>&1 | grep -A5 "error:"
```

## Continuous Integration

### GitHub Actions Workflow

Every PR should pass:
```yaml
- name: Run Tests
  run: |
    npm test
    cd examples/todo-app
    npx haxe build-server.hxml
    mix compile --force
    mix test
```

### Pre-Commit Checklist

Before ANY commit:
- [ ] `npm test` passes completely
- [ ] Todo-app compiles without errors
- [ ] No new warnings introduced
- [ ] All discovered issues fixed (not just primary task)
- [ ] Documentation updated if behavior changed

## Test Maintenance

### Keeping Tests Healthy

1. **Remove obsolete tests** - Don't keep tests for removed features
2. **Update snapshots promptly** - When output improves, update immediately
3. **Consolidate duplicate tests** - Merge tests that check the same thing
4. **Document test purpose** - Each test should have clear intent
5. **Keep tests fast** - Slow tests discourage frequent testing

### When to Update Snapshots

Update expected output when:
- Generated code is more idiomatic
- Performance improvements are made
- Bug fixes change output correctly
- Formatting improvements are made

DON'T update just to make tests pass - fix the root cause.

## The Golden Rule

**Every change must leave the compiler in a better state than before.**

This means:
- All tests pass
- Todo-app compiles and runs
- No new issues introduced
- All discovered issues fixed
- Code is cleaner than before

Remember: We're building a production compiler. Quality matters more than speed.