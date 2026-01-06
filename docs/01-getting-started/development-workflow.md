# Development Workflow Guide

**Day-to-day development practices for building applications and contributing to the compiler.**

## Quick Development Loop

### Standard Workflow
```bash
# 1. Make changes to Haxe source files
vim src_haxe/MyModule.hx

# 2. Compile and test
npm test                    # Full validation (recommended)
npm run test:quick         # Faster subset for quick iterations

# 3. Test specific functionality
haxe build.hxml        # Basic compilation
haxe build.hxml -D source-map  # With debugging support
```

⚠️ **Important**: See [Compiler Flags Guide](compiler-flags-guide.md) for critical information about which optimization flags to avoid (particularly `-D analyzer-optimize`).

### File Watching (Recommended)
```bash
# Start automatic recompilation (todo-app example)
cd examples/todo-app
mix haxe.watch

# Make changes to .hx files → automatic recompilation
# Sub-second compilation times with hot reload
# Perfect for iterative development
```

## Dual-Ecosystem Architecture

Reflaxe.Elixir coordinates two development ecosystems for complete validation:

### 🔧 Haxe Development Side (npm + lix)
**Purpose**: Build and test the Haxe→Elixir compiler itself

- **Package Manager**: `lix` (modern Haxe package manager)
- **Runtime**: `npm` scripts orchestrate the workflow  
- **Dependencies**: Reflaxe framework, tink_unittest
- **Output**: Generated Elixir source code files

```bash
npm install             # Installs lix package manager locally
npx lix download        # Downloads Haxe dependencies (project-specific versions)
haxe TestMain.hxml      # Compile using your Haxe toolchain
# If `haxe` is not on your PATH, use the project-local wrapper:
#   ./node_modules/.bin/haxe TestMain.hxml
```

**Why lix?**
- ✅ **Locked Haxe library versions** (avoids "works on my machine")
- ✅ **GitHub + haxelib sources** (always latest libraries)  
- ✅ **Locked dependency versions** (zero software erosion)
- ✅ **Scoped installs** (keeps Haxe libs out of global state)

### ⚡ Elixir Runtime Side (mix)  
**Purpose**: Test and run the generated Elixir code

- **Package Manager**: `mix` (native Elixir build system)
- **Dependencies**: Phoenix, Ecto, GenServer, LiveView  
- **Output**: Running BEAM applications

```bash
mix deps.get         # Installs Phoenix, Ecto, etc.
mix test             # Tests generated Elixir code and Mix tasks
mix ecto.migrate     # Runs database migrations  
```

**Why mix?**
- ✅ **Native Elixir tooling** (industry standard)
- ✅ **Phoenix integration** (LiveView, router, etc.)
- ✅ **BEAM ecosystem** (OTP, GenServer, supervision trees)

## Testing Strategy

### Comprehensive Testing
```bash
# Test everything (recommended before commits)
npm test

# Snapshot-only run (fastest)
npm run test:quick

# Test Mix tasks + Elixir integration
npm run test:mix

# Compile-check every example under examples/
npm run test:examples

# Todo-app end-to-end build + boot (Phoenix runtime + optional Playwright)
npm run qa:sentinel
```

For details on non-blocking Phoenix validation (async runs, bounded log viewing, Playwright integration), see
[Phoenix E2E & QA Sentinel](../06-guides/PHOENIX_E2E_AND_SENTINEL.md).

### Testing Infrastructure Benefits

#### Modern Stack (tink_unittest)
- **Synchronous testing**: Deterministic test execution
- **Performance validation**: Built-in benchmarking, <15ms targets
- **Clean output**: Clear success/failure reporting
- **Framework-agnostic**: Easy to switch between test frameworks

#### Dual Test Coverage
1. **Haxe Compiler Tests**: Validate the compilation engine itself
2. **Elixir Runtime Tests**: Validate the generated code and Mix integration

### Test Error Interpretation

#### Expected Test Warnings ⚠️
Some errors are **expected** during testing and appear as warnings:

```bash
# Expected in test environment - shows as warning
[warning] Haxe compilation failed (expected in test): Library reflaxe.elixir is not installed
```

**Why this happens:**
- Tests run in isolated environments without full library installation
- Test framework validates compilation behavior, not successful execution
- These warnings indicate the test is working correctly

#### Real Errors ❌
Actual compilation problems show with error symbols:

```bash
# Real error - shows with ❌ symbol
[error] ❌ Haxe compilation failed: src_haxe/Main.hx:5: Type not found : MyClass
```

## Integration Flow

```
Haxe Source Code (.hx files)
     ↓ (npm/lix tools)
Reflaxe.Elixir Compiler  
     ↓ (generates)
Elixir Source Code (.ex files)
     ↓ (mix tools)  
Running BEAM Application
```

## fast_boot vs full_prepasses Profiles

Reflaxe.Elixir uses two compilation profiles that affect **macros** and **AST transformers**:

- `fast_boot` – opt-in “fast profile” for large codebases  
  - Minimal macro work:
    - Macros like `RouterBuildMacro`, `HXX`, and `ModuleMacro` still run, but avoid expensive `Context.getType` / project‑wide scans where possible.
    - Template processing uses memoization and cheap shape checks when enabled.
  - Core semantic transforms only:
    - Phoenix/Ecto/OTP shape‑driven transforms remain active.
    - Ultra‑late cosmetic hygiene passes (naming, underscore promotion, unused assignment cleanup) are skipped when `fast_boot` and `disable_hygiene_final` are defined.
  - Goal: keep cold todo‑app builds bounded and responsive during day‑to‑day work.
  - Implementation:
    - Haxe macros read it via `Context.defined("fast_boot")` and avoid project‑wide scans.
    - The AST pass registry gates selected expensive passes with `#if fast_boot`.
    - It should never be required for correctness; it exists to trade “perfect hygiene” for speed.

- `full_prepasses` / full hygiene – used for compiler/snapshot/CI runs  
  - All macros and transforms are enabled.
  - Hygiene and final sweep passes run to enforce the strictest shape and naming invariants.
  - Intended for full validation, not for tight dev loops.

`fast_boot` is enabled by passing `-D fast_boot` to Haxe. For Mix builds, this repo treats it as opt-in via:

```bash
HAXE_FAST_BOOT=1 mix compile
```

See `lib/haxe_compiler.ex` for the injection point. Legacy todo-app perf/debug HXML experiments are kept in git history and are not required for normal development.

## Haxe Compilation Server Policy

The Haxe compilation server (`haxe --wait`) is **opt-in**:

- Default dev and CI workflows should act as if:

  ```bash
  export HAXE_NO_SERVER=1
  ```

  and should **not** auto‑start the server.

- You may explicitly start and use the server when iterating on the compiler:

  ```bash
  # In a dev shell
  iex -S mix
  iex> {:ok, _} = HaxeServer.start_link([])
  iex> HaxeServer.status()

  # In another shell, reuse the server:
  HAXE_USE_SERVER=1 haxe --connect 6116 examples/todo-app/build-server.hxml

  # When done:
  iex> HaxeServer.stop()
  ```

- QA sentinel and CI use direct `haxe` invocations by default and only opt into the server via environment (`HAXE_USE_SERVER=1`) when explicitly configured. This avoids background high‑CPU processes and keeps build behavior predictable.


## Performance Targets

All compilation features meet <15ms performance requirements:
- **Basic compilation**: 0.015ms ✅
- **Ecto Changesets**: 0.006ms average ✅  
- **Migration DSL**: 6.5μs per migration ✅
- **OTP GenServer**: 0.07ms average ✅
- **Phoenix LiveView**: <1ms average ✅

## Key Development Files

### Configuration Files
- **`package.json`**: npm scripts, lix dependency  
- **`.haxerc`**: Project-specific Haxe version (4.3.7)
- **`haxe_libraries/`**: lix-managed dependencies (tink_unittest, reflaxe)
- **`mix.exs`**: Elixir dependencies (Phoenix, Ecto)

### Testing Files  
- **`test/Test.hxml`**: Snapshot test runner configuration
- **`test/tests/`**: Individual test cases with expected outputs
- **`examples/todo-app/`**: Integration test as real Phoenix application

### Source Code Files
- **`src/reflaxe/elixir/ElixirCompiler.hx`**: Main compiler
- **`src/reflaxe/elixir/helpers/`**: Feature-specific compilers (Changeset, OTP, LiveView, etc.)
- **`std/`**: Phoenix/Elixir type definitions and externs

## Source Mapping (Experimental)

Reflaxe.Elixir has a source mapping design (to map generated `.ex` back to `.hx`), but it is
currently **experimental** and not fully wired end‑to‑end in the AST pipeline.

See `docs/04-api-reference/SOURCE_MAPPING.md` for the current status and next steps.

## Full-Stack Development

### Dual-Target Compilation
Reflaxe.Elixir enables true full-stack development with a single language:

- **Server-side**: Haxe → Elixir (Phoenix LiveView, Ecto, OTP)
- **Client-side**: Haxe → JavaScript with native async/await support

### Development Workflow
1. **Shared Types**: Define data structures in `shared/` directory
2. **Dual Compilation**: Build both targets with type-safe contracts
3. **Live Reload**: Hot reload for both Elixir and JavaScript changes
4. **Type Safety**: Full-stack type guarantees at compile time

**See**: [Quick Start Patterns](../07-patterns/quick-start-patterns.md) for copy‑paste, end‑to‑end patterns.

## Contributing to the Compiler

### Adding New Features
1. **Check existing implementations first** - Search for similar patterns before starting
2. **Plan with documentation** - Update [roadmap](../08-roadmap/) with your feature
3. Create helper compiler in `src/reflaxe/elixir/helpers/`
4. Add annotation support to main `ElixirCompiler.hx`  
5. Write tests using snapshot testing in `test/tests/`
6. **Document thoroughly** - Update guides and examples
7. Run `npm test` to validate (ALL tests must pass)
8. **Mark task complete** - Verify implementation meets requirements

### Adding Tests  
```haxe
// Create snapshot test in test/tests/new_feature/
// src_haxe/TestNewFeature.hx
class TestNewFeature {
    public static function main() {
        trace("Testing new feature");
        
        // Your feature test code here
        var result = MyNewFeature.doSomething();
        trace('Result: $result');
    }
}
```

## Troubleshooting Development Issues

### Haxe Version Issues
```bash
# Check the version this repo expects
cat .haxerc

# Check your installed Haxe
haxe --version

# Reset lix scope
npx lix scope create
npx lix download
```

### Dependency Issues
```bash
# Reset npm dependencies
rm -rf node_modules && npm install

# Reset Haxe dependencies  
rm -rf haxe_libraries && npx lix download

# Reset Elixir dependencies
mix deps.clean --all && mix deps.get
```

### Test Failures
```bash
# Run individual test components
npm run test:haxe     # Snapshot tests only
npm run test:mix      # Elixir/Mix tests only

# Test specific functionality
haxe test/Test.hxml test=feature_name

# Update test snapshots when output improves
haxe test/Test.hxml update-intended
```

### Compilation Issues
```bash
# Clean and rebuild everything
rm -rf lib/*.ex lib/**/*.ex  # Remove generated files
haxe build.hxml              # Regenerate from Haxe
mix compile --force          # Verify Elixir compilation
```

## Best Practices

### Development Workflow
- Prefer `haxe` from a proper Haxe install; if it’s not on your PATH, use the repo shim: `./node_modules/.bin/haxe ...` (provided by `lix` + `.haxerc`).
- **Run full test suite** before committing changes
- **Use source maps** for debugging (`-D source-map`)
- **Test todo-app integration** after compiler changes
- **Update documentation** when adding features

### Code Quality
- **Follow existing patterns** in the codebase
- **Write comprehensive tests** for all new functionality
- **Document architectural decisions** in appropriate guides
- **Maintain performance targets** (see Performance Guide; large modules may require `fast_boot` during iteration)

### Git Workflow
- **Commit frequently** with descriptive messages
- **Test before pushing** to ensure CI/CD success
- **Update changelogs** for user-facing changes
- **Reference issues** in commit messages

## Architecture Benefits

✅ **Modern Haxe tooling** (lix + tink_unittest)  
✅ **Native Elixir integration** (mix + Phoenix ecosystem)
✅ **End-to-end validation** (compiler + generated code)  
✅ **Single command simplicity** (`npm test`)
✅ **Zero global state** (project-specific everything)
✅ **Fast compilation** for typical modules (see `docs/06-guides/PERFORMANCE_GUIDE.md`)

## Next Steps

### For Application Development
- **[Phoenix Integration](../02-user-guide/PHOENIX_INTEGRATION.md)** - Build Phoenix applications
- **[LiveView Architecture](../02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md)** - Real-time UI patterns
- **[ExUnit Testing](../02-user-guide/exunit-testing.md)** - Application testing strategies

### For Compiler Development  
- **[Compiler Architecture](../05-architecture/ARCHITECTURE.md)** - How the compiler works
- **[AST Pipeline](../05-architecture/UNIFIED_AST_PIPELINE.md)** - TypedExpr → ElixirAST → transforms → print
- **[Testing Infrastructure](../03-compiler-development/TESTING_INFRASTRUCTURE.md)** - Snapshot testing system

### For Troubleshooting
- **[Troubleshooting Guide](../06-guides/TROUBLESHOOTING.md)** - Comprehensive problem solving
- **[Performance Guide](../06-guides/PERFORMANCE_GUIDE.md)** - Compilation performance

---

**Ready to build?** Check out [Phoenix Integration](../02-user-guide/PHOENIX_INTEGRATION.md) to start building applications.
## Haxe Compile Server (Automatic & Transparent)

Reflaxe.Elixir uses the Haxe compilation server (`haxe --wait`) to speed up
incremental builds during `mix compile` and `mix phx.server`.

Behavior (no configuration required):

- Auto‑manage: Mix ensures a `haxe --wait` server is available for incremental compilation.
- Reuse (owned): If Mix started the server in this VM, it is reused automatically.
- Relocate (default): If the configured port is already bound, Mix relocates to a free port and starts its own server.
- Attach (opt‑in): If `HAXE_SERVER_ALLOW_ATTACH=1` and the configured port is already bound by a compatible Haxe server, Mix attaches and uses it (no extra server, no port churn).
- Auto‑start: If none is running, Mix starts one in the background.
- Auto‑relocate: If the port is busy, Mix transparently retries on a free port.
- Fallback: If the server cannot be reached, Mix compiles directly (no server) and
  refreshes the server in the background for the next compile.

Defaults and environment variables:

- Default server port: `6116` (aligned with the QA sentinel).
- `HAXE_NO_SERVER=1` — disable the server for the current run (use direct Haxe).
- `HAXE_SERVER_PORT=<port>` — force a specific port (e.g., `6116`).
- `HAXE_SERVER_ALLOW_ATTACH=1` — allow attaching to an externally-started compatible server on the configured port.

Notes:

- The behavior is fully transparent; no flags are needed for normal use.
- The QA sentinel also uses a compile server and falls back to direct compilation
  under strict timeouts. It uses the same default port (`6116`) and relocates when busy.

### Cleanup (if ports keep relocating)

If you repeatedly see messages like:

- `Haxe server port 6116 is in use; relocating to ...`

it usually means a previous Mix VM crashed and left behind stale `haxe --wait` processes.
Clean them up (bounded, repo-local) and retry:

```bash
scripts/haxe-server-cleanup.sh
```
