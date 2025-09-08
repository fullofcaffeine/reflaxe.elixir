# Test Command Reference

## Understanding Test Execution

### Current Test Infrastructure Capabilities

1. **Compilation Testing** ✅
   - Compiles Haxe source to Elixir
   - Validates compilation succeeds without errors
   
2. **Output Comparison** ✅
   - Compares generated output with expected `intended/` directory
   - Detects code generation changes
   
3. **Syntax Validation** ✅ (via `validate_elixir.sh`)
   - Validates generated Elixir code compiles
   - Catches syntax errors in generated code

4. **Runtime Execution** ⚠️ (Manual only)
   - Generated code with `main()` doesn't auto-execute
   - Must manually run with helper scripts
   - Future enhancement: Add bootstrap code generation

### Why `main()` Doesn't Auto-Execute

Unlike Java or C, Elixir modules don't automatically call a `main()` function. The generated code defines the function but doesn't invoke it:

```elixir
defmodule Main do
  defp main() do
    # This is defined but never called!
  end
end
```

**Workarounds**:
- Use `./run_test_output.sh` to manually execute tests
- For Phoenix apps: Use `@:application` annotation for OTP bootstrapping
- Future: Compiler should generate bootstrap code for test files

## Running Tests

### Run All Tests
```bash
cd test
make              # Run all tests in parallel
make -j1          # Run tests sequentially
npm test          # Full test suite with validation
```

### Run Single Test
**Note**: Use double underscores (`__`) instead of slashes for nested paths.

```bash
cd test
make single TEST=stdlib__array_cross_operations
make single TEST=core__arrays
make single TEST=phoenix__liveview
```

### Run Test Output with Elixir
After generating test output, you can run it directly:

```bash
cd test
./run_test_output.sh snapshot/stdlib/array_cross_operations

# Or manually:
cd snapshot/stdlib/array_cross_operations/out
elixir -r std.ex -r haxe/log.ex -r main.ex -e "Main.main()"
```

## Updating Tests

### Update Intended Output
When the compiler output changes (improvements), update the expected output:

```bash
cd test/snapshot/stdlib/array_cross_operations
rm -rf intended
cp -r out intended
```

### Update All Tests
```bash
cd test
make update-intended  # Updates all test intended outputs
```

## Validation

### Validate Elixir Syntax
```bash
npm run test:elixir-validate  # Validates all generated Elixir code
```

### Run Tests with Full Validation
```bash
npm run test:with-validation  # Compile + validate syntax
```

## Common Test Paths

| Test Category | Example Path | Make Target |
|--------------|--------------|-------------|
| Core | `core/arrays` | `core__arrays` |
| Standard Library | `stdlib/array_cross_operations` | `stdlib__array_cross_operations` |
| Phoenix | `phoenix/liveview` | `phoenix__liveview` |
| Ecto | `ecto/schemas` | `ecto__schemas` |
| OTP | `otp/genserver` | `otp__genserver` |

## Tips

1. **Path Format**: Always use double underscores (`__`) for make targets
2. **Running Output**: Test outputs are in `out/` directories
3. **Updating Tests**: Only update intended when output is genuinely better
4. **Validation**: Use validation commands to catch runtime issues early