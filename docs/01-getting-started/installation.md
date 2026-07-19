# Installation And Setup

Use the immutable release package when building an application. Clone the repository only when
developing the compiler or testing an unreleased change.

**⚠️ Having trouble with tests or compilation?** See the troubleshooting section below.

## Prerequisites

### Required Software
- **Node.js 22.14.0+** - For the supported lix/package tooling path and npm scripts
- **Elixir 1.14+** - For Phoenix/Ecto ecosystem and generated code testing
- **Git** - Required for compiler contributors and some dependency sources
- **Neko runtime on Linux** - Required by the `haxelib` executable bundled with Haxe 4 toolchains installed through lix. On Ubuntu/Debian, install it with `sudo apt-get install neko`.

### Installation Check
```bash
# Verify prerequisites
node --version    # Should be 22.14.0 or higher
elixir --version  # Should be 1.14.0 or higher
git --version     # Any recent version
```

## Application Installation (Recommended)

Create or enter your application workspace, then install the latest Reflaxe-built package through
Lix:

```bash
npm install --save-dev lix
npx lix scope create

REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
PACKAGE="reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"
RELEASE_URL="https://github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}"
```

### Verify The Package

For a reproducible or security-sensitive installation, verify the versioned ZIP before asking Lix to
install the same immutable asset:

```bash
curl -fL -o "$PACKAGE" "$RELEASE_URL/$PACKAGE"
curl -fL -o "$PACKAGE.sha256" "$RELEASE_URL/$PACKAGE.sha256"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum --check "$PACKAGE.sha256"
else
  shasum -a 256 --check "$PACKAGE.sha256"
fi
```

The command must report `OK`. Each package embeds its exact version, release tag, and source commit;
maintainers additionally verify GitHub's hosted digest and signed immutable-release attestation. See
[Releasing](../10-contributing/RELEASING.md#consumer-verification).

### Install With Lix

After the optional verification step, install the same immutable asset:

```bash
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/${PACKAGE}"
npx lix download
```

The `www.github.com` host is intentional: it keeps the release ZIP on Lix's generic
immutable-archive path instead of treating the URL as a source repository dependency.

### Why Lix And GitHub Releases

Reflaxe.Elixir uses **Lix as the project dependency manager** instead of asking users to install
the compiler globally from the Haxelib registry. The primary application install is a versioned,
Reflaxe-built ZIP from GitHub Releases:

```text
versioned GitHub Release ZIP
        ↓  npx lix install <immutable URL>
haxe_libraries/reflaxe.elixir.hxml
        ↓  npx lix download
project-local, reproducible compiler input
```

This is a better fit for this project because:

- `haxe_libraries/*.hxml` is committed, so dependency changes are ordinary reviewed Git changes;
- a project can pin a release archive, Git tag, or exact commit instead of following global state;
- different projects can use different Haxe/compiler/library versions on the same machine;
- `npx lix download` reconstructs the checked-in dependency state and reuses Lix's local cache;
- unreleased fixes can be consumed from an exact pushed Git SHA without publishing an unrelated
  registry release.

For example, PhoenixHX browser builds pin Genes to one fetchable commit:

```hxml
# @install: lix --silent download "gh://github.com/fullofcaffeine/genes-ts#<exact-sha>" into genes-ts/<version>/github/<exact-sha>
```

Lix is not a new library format and does not make Haxelib incompatible. It can consume Haxelib
packages, GitHub/GitLab repositories, and immutable HTTP archives. Reflaxe.Elixir's GitHub release
asset is deliberately a built Haxelib-style package because that is the correct flattened compiler
layout. We continue to test Haxelib package installation, but GitHub Releases plus Lix are the
recommended distribution path for this project. Some third-party dependencies may still come from
Haxelib.org through Lix; applications do not need to install Reflaxe.Elixir itself from the Haxelib
server.

See the [Lix project documentation](https://github.com/lix-pm/lix#readme) for its scoped dependency
model and supported source schemes, and
[Source Checkout vs Release Package Layout](SOURCE_VS_PACKAGE_LAYOUT.md) for why this compiler needs
a built release artifact rather than a raw source archive.

Continue with the [Quickstart](../06-guides/QUICKSTART.md),
[Phoenix New App](../06-guides/PHOENIX_NEW_APP.md), or
[Gradual Adoption](../06-guides/PHOENIX_GRADUAL_ADOPTION.md) guide.

## Compiler Checkout Setup

### 1. Clone Repository
```bash
git clone https://github.com/fullofcaffeine/reflaxe.elixir.git
cd reflaxe.elixir
```

### 2. Install Haxe Development Environment

#### Install lix Package Manager
```bash
# Install all Node.js dependencies (including lix)
npm install
```

This automatically installs:
- **lix** - Modern Haxe package manager
- **Local project dependencies** for build orchestration

#### Verify lix Installation
```bash
# Check lix is available
npx lix --version

# Check Haxe is available
haxe --version

# If `haxe` is not on your PATH, use the project-local shim (provided by `lix` + `.haxerc`):
./node_modules/.bin/haxe --version
```

**Expected Output:**
```
Haxe Compiler 4.3.7
```

### 3. Install Haxe Dependencies
```bash
# Download the pinned toolchain + libraries (per `.haxerc` + `haxe_libraries/*.hxml`)
npx lix download
```

This ensures the compiler/test/example dependencies are available (for example `tink_macro`, `tink_parse`, and other `tink_*` libs).

### 4. Install Elixir Dependencies
```bash
# Install Phoenix, Ecto, and other Elixir dependencies
mix deps.get
```

### 5. Verify Complete Installation
```bash
# Run comprehensive test suite
npm test
```

This should complete without failures.

### 6. Source Mapping (Experimental)

Reflaxe.Elixir has a source mapping design (to map generated `.ex` back to `.hx`), but it is
currently **experimental** and not fully wired end‑to‑end in the AST pipeline.

See `docs/04-api-reference/SOURCE_MAPPING.md` for the current status and next steps.

## Understanding the Setup

### Why Lix Instead Of Global Haxe And Global Haxelib State?

**❌ Traditional Haxe Installation Problems:**
- Global Haxe versions cause "works on my machine" issues
- Different projects need different Haxe versions
- Library version conflicts between projects
- Manual dependency management

**✅ lix Package Manager Benefits:**
- **Project-specific Haxe versions** defined in `.haxerc`
- **Locked dependency versions** in `haxe_libraries/`
- **Exact GitHub commits/releases plus pinned Haxelib sources** when appropriate
- **Zero global conflicts** between projects

### Key Files Created by Setup

#### `.haxerc`
```json
{
  "version": "4.3.7",
  "resolveLibs": "scoped"
}
```
Pins the Haxe compiler version and enables scoped library resolution for `lix`.

#### `haxe_libraries/*.hxml`
Pins Haxe library versions and classpaths for reproducible builds (managed by `lix`).

#### `package.json` Scripts
```json
{
  "scripts": {
    "test": "npm test",
    "test:quick": "npm run test:quick",
    "test:examples": "npm run test:examples"
  }
}
```

## Using Haxe After Installation

### Use `haxe` (system or project-local)

This repo uses lix to manage the Haxe toolchain (via `.haxerc`) and Haxe **libraries** (via `haxe_libraries/*.hxml`).
Use either a normal `haxe` install on your PATH or the lix-provided shim at `./node_modules/.bin/haxe`.

```bash
# ✅ Correct
haxe build.hxml
haxe --version

# ✅ Also correct (lix shim)
./node_modules/.bin/haxe build.hxml
./node_modules/.bin/haxe --version
```

### Compilation Examples
```bash
# Compile a simple example
cd examples/01-simple-modules
haxe BasicModule.hxml

# Run full tests
npm test
```

### Source Mapping (Experimental)

Reflaxe.Elixir’s source mapping design (mapping generated `.ex` back to `.hx`) is currently
**experimental** and not yet fully wired end‑to‑end in the AST pipeline.

See `docs/04-api-reference/SOURCE_MAPPING.md` for the current status and next steps.

### Development Workflow

#### With File Watching (Recommended)
```bash
# 1. Start file watcher
mix haxe.watch

# 2. Make changes to Haxe files
vim src_haxe/MyModule.hx
# Files automatically recompile

# 3. Debug compile errors
mix haxe.errors --format json
```

#### Manual Compilation
```bash
# 1. Make changes to compiler
vim src/reflaxe/elixir/ElixirCompiler.hx

# 2. Test Haxe compiler changes
npm run test:quick

# 3. Test generated Elixir code integration
npm run test:mix

# 4. Full validation
npm test
```

## Project Structure Overview

```
reflaxe.elixir/
├── .haxerc                     # Haxe version specification
├── package.json                # npm dependencies and scripts  
├── mix.exs                     # Elixir dependencies and config
├── haxe_libraries/             # lix-managed Haxe dependencies
├── src/reflaxe/elixir/         # Compiler source code
├── std/                        # Phoenix/Elixir type definitions
├── test/                       # Snapshot tests for compiler
├── examples/                   # Working example applications
│   ├── todo-app/              # Main Phoenix LiveView example
│   └── simple-modules/        # Basic compilation examples
└── docs/                      # Complete documentation (you are here!)
```

## Troubleshooting

### Common Issues

#### Issue: `haxe: command not found`
**Solution:** Install Haxe and/or add it to your PATH.
```bash
# Preferred
haxe --version

# Project-local shim (provided by `lix` + `.haxerc`)
./node_modules/.bin/haxe --version
```

#### Issue: `Unknown identifier: reflaxe`
**Solution:** Run lix download to install dependencies
```bash
npx lix download
```

#### Issue: Tests failing on fresh install
**Solution:** Verify all prerequisites and run setup in order
```bash
# Complete setup sequence
npm install
npx lix download
mix deps.get
npm test
```

#### Issue: "Library reflaxe.elixir is not installed"
**Solution:** This is a self-referential library issue. See [Troubleshooting Guide](../06-guides/TROUBLESHOOTING.md) for detailed solutions.

#### Issue: "classpath src/ is not a directory"
**Solution:** Path resolution issue with test setup. This occurs when test configurations reference incorrect paths. Verify you're in the correct directory and all paths in `.hxml` files are accurate.

#### Issue: `Error: ENOENT: no such file or directory, open '.haxerc'`
**Solution:** Ensure you're in the project root directory
```bash
# Check you're in the right directory
ls .haxerc          # Should exist
pwd                 # Should end with /reflaxe.elixir
```

#### Issue: No source maps generated
**Solution:** Source mapping is currently experimental; `.ex.map` files are not emitted by default builds yet.
See `docs/04-api-reference/SOURCE_MAPPING.md`.

#### Issue: Source map positions incorrect
**Solution:** Source mapping is currently experimental; if you’re working on it, start from
`docs/04-api-reference/SOURCE_MAPPING.md` and add integration coverage under `test/snapshot/core/source_map_validation/`.

### Getting Help

#### Check Installation Status
```bash
# Verify each component
node --version      # Node.js
npx lix --version   # lix package manager
haxe --version      # Haxe (project toolchain)
mix --version       # Elixir/Mix
```

#### Reinstall Dependencies
```bash
# Re-download the toolchain + libraries (lix cache)
npx lix download
# If your lix cache is corrupted, remove it and retry:
# rm -rf ~/haxe

# Clean reinstall Elixir dependencies  
mix deps.clean --all
mix deps.get

# Verify with tests
npm test
```

## Project Structure Understanding

```
reflaxe.elixir/
├── .haxerc                     # Haxe version specification
├── package.json                # npm dependencies and scripts
├── mix.exs                     # Elixir dependencies and config
├── haxe_libraries/             # lix-managed Haxe deps (pinned via *.hxml)
├── src/reflaxe/elixir/         # Haxe→Elixir compiler source
├── std/                        # Elixir extern definitions
├── test/                       # Haxe compiler tests
├── examples/                   # Working examples
└── node_modules/               # npm dependencies (including lix)
```

## Architecture Summary

Reflaxe.Elixir uses a **dual-ecosystem architecture**:

### 🔧 Haxe Side (npm + lix)
- **Purpose:** Develop and test the compiler itself
- **Tools:** lix (Haxe toolchain) + snapshot test runner under `test/`
- **Command:** `npm run test:quick`

### ⚡ Elixir Side (mix)
- **Purpose:** Test and run generated code
- **Tools:** Phoenix, Ecto, ExUnit, and the Elixir/OTP runtime. See the
  [OTP Support Contract](../04-api-reference/OTP_SUPPORT_CONTRACT.md) for the exact compiler-supported subset.
- **Command:** `npm run test:mix`

### 🚀 Integration (npm orchestration)
- **Purpose:** Validate end-to-end workflow
- **Command:** `npm test` (runs both ecosystems)

This setup ensures that both the compiler development and generated code quality are thoroughly validated.

## Next Steps

After successful installation:

1. **[Quickstart Tutorial](../06-guides/QUICKSTART.md)** - Build your first Haxe→Elixir project in 5 minutes
2. **[Source and Package Layout](SOURCE_VS_PACKAGE_LAYOUT.md)** - Understand consumer and compiler-checkout layout conventions
3. **[Development Workflow](development-workflow.md)** - Learn day-to-day development practices
4. **[Phoenix Integration](../02-user-guide/PHOENIX_INTEGRATION.md)** - Build Phoenix applications with Haxe

## Additional Resources

- **[User Guide](../02-user-guide/)** - Complete application development documentation
- **[Troubleshooting Guide](../06-guides/TROUBLESHOOTING.md)** - Comprehensive problem-solving reference
- **[API Reference](../04-api-reference/)** - Technical reference for annotations and APIs
- **[Compiler Development](../03-compiler-development/)** - For contributors to the compiler itself

---

**Ready to code?** Continue to [Quickstart Tutorial](../06-guides/QUICKSTART.md) for your first Haxe→Elixir project.
