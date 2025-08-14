# Test Infrastructure Documentation

## Overview
Reflaxe.Elixir uses a snapshot-based testing approach where we compile Haxe code and compare the generated Elixir output against expected "intended" files.

## Test Directory Structure

```
test/
├── TestRunner.hx          # Main test orchestrator
├── Test.hxml             # Entry point configuration
└── tests/
    └── test_name/
        ├── compile.hxml   # Test compilation config
        ├── Main.hx        # Test source code
        ├── intended/      # Expected output files
        │   ├── Main.ex
        │   ├── _GeneratedFiles.json
        │   └── *.ex       # Other generated Elixir files
        └── out/           # Actual generated output
            ├── Main.ex
            ├── _GeneratedFiles.json
            └── *.ex       # Other generated Elixir files
```

## Key Files Explained

### `_GeneratedFiles.json`
**Purpose**: Metadata file created by Reflaxe to track compilation state and generated files.

**Structure**:
```json
{
  "filesGenerated": [    // List of all files generated in this compilation
    "Main.ex",
    "StdTypes.ex",
    ...
  ],
  "id": 1,               // Build ID that increments on each compilation
  "wasCached": false,    // Whether compilation used cached results
  "version": 1           // Metadata format version
}
```

**Important Notes**:
- The `id` field increments on every compilation, making direct comparison problematic
- Our test runner ignores the `id` field when comparing files
- This file helps Reflaxe track what was generated and manage incremental compilation

### `*.ex.map` Files
Source map files that map generated Elixir code back to original Haxe source locations. Used for debugging and error reporting.

### Test Configuration Files

#### `compile.hxml`
Each test has its own compilation configuration:
```hxml
-cp ../../../src/          # Path to compiler source
-lib reflaxe               # Include Reflaxe library
-main Main                 # Entry point class
-D reflaxe_runtime         # Enable runtime flag
-D reflaxe-output=out/     # Output directory
-D elixir_output=out/      # Elixir-specific output
--macro reflaxe.elixir.CompilerInit.Start()  # Initialize compiler
```

## Test Execution Flow

1. **Compilation Phase**:
   - TestRunner.hx reads test directory
   - Executes `haxe compile.hxml` for each test
   - Generates Elixir files in `out/` directory

2. **Comparison Phase**:
   - Compares each file in `out/` with corresponding file in `intended/`
   - Special handling for `_GeneratedFiles.json` (ignores `id` field)
   - Reports differences

3. **Update Mode**:
   - Run with `update-intended` flag to accept new output as correct
   - Copies `out/` files to `intended/` directory

## Running Tests

### Basic Commands
```bash
# Run all tests
npm test

# Run specific test
haxe test/Test.hxml test=arrays

# Update expected output for a test
haxe test/Test.hxml test=arrays update-intended

# Show detailed output
haxe test/Test.hxml test=arrays show-output
```

### Test Flags
- `test=NAME` - Run only the specified test
- `update-intended` - Update expected output with current generation
- `show-output` - Display compilation output and details
- `no-details` - Skip detailed diff output

## Common Test Scenarios

### Adding a New Test
1. Create directory `test/tests/your_test_name/`
2. Add `Main.hx` with test code
3. Create `compile.hxml` with compilation settings
4. Run test to generate `out/` directory
5. If output is correct, run with `update-intended`

### Fixing Compiler Bugs
1. Run failing test to see differences
2. Fix compiler code
3. Re-run test to verify fix
4. Update intended output if changes are correct

### Handling _GeneratedFiles.json Changes
The `id` field in `_GeneratedFiles.json` increments on each build. The test runner automatically ignores this field during comparison to prevent false failures.

## Test Types

### 1. Snapshot Tests (Primary)
- Compare generated Elixir against expected output
- Most tests follow this pattern
- Located in `test/tests/*/`

### 2. Mix Integration Tests
- Test that generated Elixir actually runs
- Located in `test/mix_tests/`
- Run with `MIX_ENV=test mix test`

### 3. Example Tests
- Real-world usage examples that also serve as tests
- Located in `examples/*/`
- Each has its own compilation and verification

## Troubleshooting

### Test Keeps Failing on _GeneratedFiles.json
- The `id` field increments on each compilation
- TestRunner.hx should ignore this field automatically
- If not working, check the `normalizeContent` function in TestRunner.hx

### Output Directory Missing
- Run the test compilation: `cd test/tests/TEST_NAME && haxe compile.hxml`
- This generates the `out/` directory

### Need to Debug Generated Code
- Use `show-output` flag to see compilation details
- Check `.ex.map` files for source mapping
- Look for compiler traces in stdout

## Best Practices

1. **Keep Tests Focused**: Each test should validate specific compiler features
2. **Update Intended Carefully**: Always verify generated code is correct before updating
3. **Document Test Purpose**: Add comments in Main.hx explaining what's being tested
4. **Test Edge Cases**: Include error conditions and boundary cases
5. **Maintain Test Isolation**: Tests should not depend on each other

## File Comparison Logic

The TestRunner uses the following comparison strategy:

1. **Normalize Content**: Convert line endings, trim whitespace
2. **Special File Handling**:
   - `_GeneratedFiles.json`: Remove `id` field before comparison
   - Source maps: Compare structure, not exact positions
3. **Report Differences**: Show which files differ and provide diffs

This infrastructure ensures our compiler generates consistent, correct Elixir code across all supported Haxe features.