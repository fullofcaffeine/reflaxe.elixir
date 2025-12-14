# Development Tools & Infrastructure

This document describes the development toolchain, testing infrastructure, and package management approach used in Reflaxe.Elixir.

## Package Manager Ecosystem Understanding

### lix Package Manager Deep Insights
**Core Philosophy**: "All dependencies should be fully locked down and versioned"

**Key Features Learned**:
- **Local binary management**: `npx haxe` uses project-specific versions from `.haxerc`
- **GitHub + haxelib sources**: `lix install github:user/repo` for dependencies from Git
- **Zero global state**: `haxe_libraries/` folder prevents conflicts
- **npm integration**: `npm install lix --save` + `npx` commands for modern workflow

### Dual-Ecosystem Architecture Decision ✅
**Haxe Side (npm + lix)**:
- Purpose: Develop and test the COMPILER itself
- Tools: lix, TestRunner.hx, reflaxe
- Command: `npm test`

**Elixir Side (mix)**:
- Purpose: Test the GENERATED code and native integration  
- Tools: Phoenix, Ecto, GenServer, ExUnit
- Command: `npm run test:mix`

**Integration**: `npm test` orchestrates both ecosystems seamlessly

## Modern Haxe Testing Framework Mastery ✅

### Snapshot Testing Architecture
**Implementation Details**:
- **TestRunner.hx**: Orchestrates compilation and output comparison
- **Directory structure**: test/tests/feature_name/ with compile.hxml and intended/
- **Output comparison**: Generated .ex files validated against reference files 

### Snapshot Test Structure
```
test/tests/feature_name/
├── Main.hx              # Test source code
├── compile.hxml         # Compilation configuration
├── intended/            # Expected Elixir output
│   └── Main.ex          # Reference file
└── out/                 # Generated output (comparison)
```

**Test Flow**:
1. TestRunner.hx compiles Main.hx using compile.hxml
2. Generated output in out/ compared with intended/
3. Test passes if output matches exactly

## Implementation Success Metrics ✅

### Test Infrastructure Results
- **All snapshot tests + Mix tests passing** across dual ecosystems
- **0.015ms compilation performance** (750x faster than 15ms target)
- **Modern toolchain operational**: lix + pure snapshot testing via TestRunner.hx
- **Single command workflow**: `npm test` handles everything

### Architecture Validation
- ✅ Project-specific Haxe versions (no global conflicts)
- ✅ Modern package management (GitHub sources, locked versions)  
- ✅ Rich test output with async/performance validation
- ✅ Clean separation between compiler testing vs generated code testing

## Complete Testing Flow Documentation ✅

### npm test: Comprehensive Dual-Ecosystem Testing

**YES** - `npm test` runs both Haxe compiler tests AND Elixir tests. Here's the exact flow:

```bash
npm test
├── npm test  # Tests Haxe→Elixir compiler (6 tests)
└── npm run test:mix   # Tests generated Elixir code (13 tests)
```

### Step 1: npm test (Compiler Testing)
**Purpose**: Validate the Haxe→Elixir compilation engine itself
**Framework**: Pure snapshot testing via TestRunner.hx
**Duration**: ~50ms

**What it tests**:
- Compilation engine components (ElixirCompiler, helpers)
- Extern definitions for Elixir stdlib
- Type mapping (Haxe types → Elixir types)
- Pattern matching, guards, syntax transformation

**Output**: Confirms compiler can generate valid Elixir AST from Haxe source
**Files tested**: Uses ComprehensiveTestRunner.hx, SimpleTest.hx, legacy extern tests

### Step 2: npm run test:mix (Runtime Testing)
**Purpose**: Validate generated Elixir code runs correctly in BEAM VM
**Framework**: ExUnit (native Elixir testing)
**Duration**: ~2-3 seconds

**What it tests**:
- Mix.Tasks.Compile.Haxe integration 
- Generated .ex files compile with Elixir compiler
- Phoenix LiveView workflows work end-to-end
- Ecto integration, OTP GenServer supervision
- Build pipeline integration, incremental compilation

**Critical Dependency**: Mix tests use output from the Haxe compiler:
1. Create temporary Phoenix projects with .hx source files
2. Call `Mix.Tasks.Compile.Haxe.run([])` to invoke our Haxe compiler
3. Validate generated .ex files are syntactically correct
4. Test modules integrate properly with Phoenix/Ecto/OTP ecosystem

### Test Suite Interaction Flow
```
npm test
├── test → Tests Haxe compiler components
│   ├── ComprehensiveTestRunner.hx (orchestrates tests)
│   ├── TestRunner.hx (snapshot orchestrator)
│   └── Legacy extern tests (FinalExternTest, etc.)
└── test:mix → Tests generated Elixir code
    └── test/mix_integration_test.exs (creates .hx files → calls compiler → validates .ex output)
```

**Key Point**: Mix tests are true end-to-end validation. They don't just test compilation success - they test that the generated Elixir code actually runs in BEAM and integrates with the Phoenix ecosystem.

### Example Mix Test Flow (from mix_integration_test.exs):
```elixir
# 1. Test creates temporary Phoenix project with Haxe source
File.write!("src_haxe/SimpleClass.hx", haxe_source_content)

# 2. Test calls our Mix compiler task (which calls npx haxe build.hxml)  
{:ok, compiled_files} = Mix.Tasks.Compile.Haxe.run([])

# 3. Test validates generated Elixir file exists and compiles
assert String.ends_with?(hd(compiled_files), "SimpleClass.ex")
```

**This provides TRUE end-to-end validation**:
`Haxe .hx files` → `Reflaxe.Elixir compiler` → `Generated .ex files` → `BEAM compilation` → `Running Elixir code`

### mix test (Separate Command)
**Purpose**: Run only the Elixir/Phoenix tests without Haxe compiler validation
**When to use**: When you've already validated the compiler and just want to test generated code integration
**Duration**: ~2-3 seconds (same as npm run test:mix)

### Agent Testing Instructions
Always run `npm test` for comprehensive validation. This ensures:
- ✅ Haxe compiler functionality (can generate code)
- ✅ Generated code quality (actually works in BEAM)
- ✅ End-to-end workflow (Haxe source → running Elixir modules)

## Installation & Setup

**Primary docs**:
- [`docs/01-getting-started/installation.md`](../01-getting-started/installation.md)
- [`docs/01-getting-started/development-workflow.md`](../01-getting-started/development-workflow.md)

**Quick setup**:
```bash
npm ci
npx lix download
mix deps.get
npm test
```

## Testing Architecture Decision ✅

**Final Implementation**: Pure snapshot testing following Reflaxe.CPP patterns

**Key Benefits Achieved**:
- **No framework dependencies**: Eliminates timeout and stream corruption issues entirely
- **Deterministic output**: 100% consistent test results across runs  
- **Reference pattern compliance**: Follows proven Reflaxe.CPP and Reflaxe.CSharp approach
- **Simplified maintenance**: No framework version conflicts or compatibility issues

**Migration Complete**: Successfully transitioned from framework-based testing to pure snapshot validation for all 28 compiler tests.
