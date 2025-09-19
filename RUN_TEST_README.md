# run-test.sh - Individual Test Runner

A helper script to run individual snapshot tests without going through the Makefile.

## Usage

```bash
./run-test.sh <test-path>
```

## Examples

```bash
# Run a specific test
./run-test.sh test/snapshot/regression/binary_op_instance_method

# Run a core test
./run-test.sh test/snapshot/core/arrays
```

## How It Works

The script:
1. Stays in the project root directory (avoids relative path issues)
2. Sets up the correct classpath for the test
3. Configures the output directory as `<test-path>/out`
4. Runs the Haxe compiler with the same flags as the Makefile

## Why This Exists

The standard test infrastructure (Makefile) is designed for batch testing. When developing or debugging a single test, this script provides a quick way to compile and check output without:
- Figuring out the correct Make target format
- Dealing with parallel execution complexities
- Changing directories and handling path issues

## Technical Details

The main challenge this script solves is that `reflaxe.elixir.hxml` contains relative paths (`src/` and `std/`) that break when running from test directories. By staying in the project root and using absolute test paths, we maintain proper path resolution.