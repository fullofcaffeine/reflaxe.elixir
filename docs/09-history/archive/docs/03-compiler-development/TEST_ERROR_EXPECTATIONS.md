# Test Error Expectations

This document clarifies which error messages in test output are expected vs unexpected, helping developers understand when to be concerned about errors appearing during test runs.

## Summary

**All error messages that appear during test runs should be clearly marked as expected or should not appear at all.** Confusing error messages that look like failures but are actually expected test behavior should be avoided or clearly marked.

## Recently Fixed Issues

### "Library reflaxe.elixir is not installed" Error (FIXED)

**Previous Behavior**: Tests would show error messages like:
```
[error] ❌ Haxe compilation failed: Compilation failed (exit 1): haxelib path: Error: Cannot process [reflaxe.elixir]: Library reflaxe.elixir is not installed
```

**Status**: ✅ FIXED in commit 77be7bd

**Root Cause**: 
- Tests run in temporary directories with symlinked haxe_libraries
- Haxe was using haxelib instead of lix for library resolution
- The direct haxe binary doesn't understand lix's library management

**Solution**:
1. Use `lix run haxe` instead of direct haxe binary for proper library resolution
2. Pass HAXELIB_PATH environment variable to compilation commands
3. Ensure consistent library resolution between HaxeCompiler and HaxeWatcher

## Expected Errors in Test Output

### 1. FileSystem Warnings
```
[warning] No valid directories to watch: []
[error] Failed to start file watching: :no_valid_directories
```
**Expected**: Yes - Tests deliberately test error conditions with invalid directories

### 2. Compilation Errors in Error Tests
When tests like `mix_integration_test.exs` test error handling, you may see:
```
[error] Haxe compilation failed: <syntax error details>
```
**Expected**: Yes - These tests verify that compilation errors are properly handled

### 3. GenServer Stop Messages
```
[info] HaxeServer stopped
```
**Expected**: Yes - Tests start and stop servers as part of testing

## Unexpected Errors (Should NOT Appear)

### 1. Library Resolution Errors
```
Library reflaxe.elixir is not installed
```
**Expected**: NO - This indicates a configuration problem (now fixed)

### 2. Port Binding Errors
```
** (MatchError) no match of right hand side value: {:error, :eaddrinuse}
```
**Expected**: NO - Indicates port conflicts between tests

### 3. Timeout Errors
```
** (ExUnit.TimeoutError) test timed out after 60000ms
```
**Expected**: NO - Indicates tests are hanging or deadlocked

## Best Practices for Test Error Messages

### For Test Authors

1. **Mark Expected Errors**: If a test intentionally triggers an error, add a comment:
   ```elixir
   # This test intentionally triggers a compilation error to test error handling
   test "handles compilation errors gracefully" do
     # ... test code that triggers error ...
   end
   ```

2. **Use Descriptive Test Names**: Make it clear when a test is testing error conditions:
   ```elixir
   test "returns error when source directory does not exist" do
   ```

3. **Suppress or Redirect Expected Errors**: Consider capturing expected errors instead of letting them pollute test output:
   ```elixir
   capture_log(fn ->
     # Code that generates expected error logs
   end)
   ```

### For Test Infrastructure

1. **Consider Log Levels**: Use appropriate log levels:
   - `debug` for expected diagnostic information
   - `info` for normal operations
   - `warning` for expected edge cases
   - `error` only for actual unexpected errors

2. **Add Context to Errors**: When possible, indicate if an error is expected:
   ```elixir
   Logger.info("Testing error condition - the following error is expected:")
   ```

## Debugging Unexpected Errors

If you see an error in test output and are unsure if it's expected:

1. **Check Test Name**: Is the test specifically testing error handling?
2. **Check Test Status**: Did the test pass despite the error?
3. **Run Single Test**: Run just that test to isolate the error
4. **Check This Document**: Refer to the lists above

## Future Improvements

1. **Structured Test Output**: Consider implementing a test reporter that clearly separates expected vs unexpected errors
2. **Error Annotations**: Add metadata to errors indicating if they're expected
3. **Test Categories**: Separate error-testing tests from normal tests in output

## Related Documentation

- [Self-Referential Library Troubleshooting](SELF_REFERENTIAL_LIBRARY_TROUBLESHOOTING.md)
- [Testing Architecture](architecture/TESTING.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)