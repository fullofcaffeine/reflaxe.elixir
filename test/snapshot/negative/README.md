# Negative Tests

This directory contains tests that are **expected to fail compilation**. These tests validate that the compiler properly rejects invalid code and provides helpful error messages.

## Purpose

Negative tests ensure:
- **Type safety enforcement**: Invalid type usage is caught at compile-time
- **Error message quality**: Error messages are clear and helpful
- **Framework constraint validation**: Phoenix/Ecto patterns are correctly enforced

## Test Structure

Each negative test should:
1. **Contain intentionally invalid code** - Type mismatches, invalid attributes, etc.
2. **Document expected errors** - Comments explaining what should fail
3. **Test a specific validation** - Each test focuses on one category of errors

## Running Negative Tests

**These tests SHOULD fail compilation. That's success!**

To verify a negative test:
```bash
# Compilation should fail with specific error messages
npx haxe test/snapshot/negative/TestName/compile.hxml
# Expected: Compilation error with helpful message
```

To update the expected error output:
1. Run the test and capture the error
2. Save the error message as documentation
3. Verify the error message is clear and actionable

## Current Negative Tests

### HXXTypeSafetyErrors
- **Location**: `test/snapshot/negative/HXXTypeSafetyErrors/`
- **Purpose**: Validates HXX template type safety
- **Expected Errors**:
  - Invalid attribute types (string where bool expected)
  - Missing required attributes
  - Type mismatches in element properties

## Adding New Negative Tests

When adding a negative test:
1. Create test directory in `test/snapshot/negative/`
2. Add Main.hx with intentionally invalid code
3. Document expected errors in code comments
4. Add entry to this README explaining the test

## Testing Philosophy

**Negative tests are as important as positive tests.** They ensure the compiler protects developers from common mistakes and provides a great error message experience.
