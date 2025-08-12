# Snapshot Testing Migration - Lessons Learned

## Date: 2025-01-10

## Key Discovery
The reference Reflaxe compilers (CPP, CSharp) use **snapshot testing** instead of traditional unit testing frameworks. This is the correct approach for testing macro-time transpilers.

## Why Snapshot Testing is Correct for Reflaxe

1. **Macro-time vs Runtime**: Reflaxe compilers run at macro-time during Haxe compilation, not at runtime. Traditional testing frameworks run at runtime when the compiler no longer exists.

2. **Testing What Matters**: We care about the generated output (Elixir code), not the internal state of the compiler. Snapshot testing directly validates the output.

3. **No Framework Dependencies**: Pure Haxe implementation without utest/tink_unittest dependencies.

## Implementation Pattern

### Directory Structure
```
test/
├── TestRunner.hx           # Main test orchestrator
├── Test.hxml               # Test configuration
└── tests/
    ├── liveview_basic/
    │   ├── compile.hxml    # Self-contained compilation config
    │   ├── CounterLive.hx  # Test source
    │   └── intended/       # Expected output
    │       └── CounterLive.ex
    ├── otp_genserver/
    │   ├── compile.hxml
    │   ├── CounterServer.hx
    │   └── intended/
    │       └── CounterServer.ex
    └── ecto_schema/
        ├── compile.hxml
        ├── User.hx
        └── intended/
            └── User.ex
```

### Key Files

1. **TestRunner.hx**: Orchestrates compilation and comparison
   - Compiles test cases using the actual Reflaxe.Elixir compiler
   - Compares output with "intended" files
   - Supports `update-intended` flag to accept current output

2. **compile.hxml**: Self-contained compilation configuration
   ```hxml
   -cp std
   -cp src
   -cp test/tests/[test_name]
   -lib reflaxe
   --macro reflaxe.elixir.CompilerInit.Start()
   MainClass
   ```

3. **Test source files**: Regular Haxe files with annotations
   - No special test framework imports
   - Just use the annotations (@:liveview, @:genserver, @:schema)
   - The compiler generates the output

## Critical Lessons

### 1. Phoenix Extern Classes Are Optional
- The @:liveview annotation works without extending phoenix.LiveView
- Extern classes are only for type safety and IDE support
- The LiveViewCompiler generates all boilerplate based on the annotation

### 2. Each Extern Class Needs Its Own File
- Haxe requires separate files for each class when importing
- Split Phoenix.hx into LiveView.hx, Socket.hx, etc.
- Package structure must match file structure

### 3. Self-Contained compile.hxml Files
- Each test's compile.hxml should be complete
- TestRunner only adds the output directory flag
- Paths in compile.hxml are relative to project root

### 4. The Three-Layer Testing Approach
1. **Compile**: Haxe source → Reflaxe.Elixir → Elixir output
2. **Compare**: Output vs intended files (snapshot testing)
3. **Optional**: Compile generated Elixir with Mix (integration testing)

## Commands

```bash
# Run all tests
haxe test/Test.hxml

# Run specific test
haxe test/Test.hxml test=liveview_basic

# Update intended output (accept current as correct)
haxe test/Test.hxml update-intended

# Update specific test's intended output
haxe test/Test.hxml update-intended test=otp_genserver

# Show compilation output
haxe test/Test.hxml show-output
```

## Migration Status

### Completed
- ✅ TestRunner.hx created based on Reflaxe patterns
- ✅ Test directory structure established
- ✅ LiveView snapshot test created
- ✅ OTP GenServer snapshot test created
- ✅ Ecto Schema snapshot test created

### Pending
- Convert remaining tests to snapshots
- Remove utest/tink_unittest dependencies
- Update CLAUDE.md to reflect new testing strategy
- Update shrimp tasks for new approach

## Why This is Better Than utest

1. **Tests the actual output**: Not mocking or simulating, but running the real compiler
2. **Visual diffs**: Easy to see what changed in the output
3. **Update workflow**: Simple to accept new output when intentional changes are made
4. **No runtime complications**: No issues with macro-time vs runtime
5. **Follows established patterns**: Same approach as successful Reflaxe targets

## Key Insight
Snapshot testing is not a workaround - it's the **correct** approach for testing transpilers. We're testing a transformation (Haxe → Elixir), and the best way to test a transformation is to verify its output.

## Important Rule
**Always refer back to reference Reflaxe compilers** at `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` periodically to ensure our implementation follows established patterns. Both Reflaxe.CPP and Reflaxe.CSharp use the same snapshot testing approach with:
- TestRunner.hx for orchestration
- test/tests/ directory structure
- compile.hxml or Test.hxml per test
- intended/ directories for expected output
- update-intended flag for accepting new output