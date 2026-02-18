# Reflaxe.Elixir Examples

This directory contains progressive examples demonstrating Haxe→Elixir compilation using Reflaxe.Elixir.

## 📁 Example Projects

### 1. [01-simple-modules](./01-simple-modules/)
**Difficulty**: Beginner  
**Features**: Basic module compilation, type mapping, simple functions  
**Use Case**: Getting started with Reflaxe.Elixir basics

### 2. [02-mix-project](./02-mix-project/)  
**Difficulty**: Beginner  
**Features**: Mix integration, multiple modules, ExUnit testing  
**Use Case**: Understanding Mix build pipeline integration

### 3. [03-phoenix-app](./03-phoenix-app/)
**Difficulty**: Intermediate  
**Features**: Phoenix endpoint/router/controller authored in Haxe, JSON responses  
**Use Case**: Minimal Phoenix web app with typed module-level router DSL and controller actions

### 4. [04-ecto-migrations](./04-ecto-migrations/)
**Difficulty**: Intermediate  
**Features**: `@:migration` DSL compilation + opt-in runnable `.exs` emission (`build-migrations.hxml`)  
**Use Case**: Author migrations in Haxe and generate Ecto-executable files

### 5. [05-heex-templates](./05-heex-templates/)
**Difficulty**: Intermediate  
**Features**: HXX template authoring, HEEx lowering, component-style markup (intentional legacy/balanced migration demo)  
**Use Case**: Template migration patterns and HXX authoring

### 6. [06-user-management](./06-user-management/)
**Difficulty**: Advanced  
**Features**: CRUD-style flow, LiveView, GenServer skeleton, Ecto schemas/changesets, strict TSX templates  
**Use Case**: Typed Phoenix app patterns in one compact example

### 7. [07-protocols](./07-protocols/)
**Difficulty**: Intermediate  
**Features**: @:protocol, @:impl annotations, polymorphic dispatch  
**Use Case**: Type-safe polymorphic behavior with compile-time validation

### 8. [08-behaviors](./08-behaviors/)
**Difficulty**: Advanced  
**Features**: @:behaviour, @:use annotations, callback contracts, GenServer integration  
**Use Case**: Compile-time behavior contracts with OTP integration and optional callbacks

### 9. [09-phoenix-router](./09-phoenix-router/)
**Difficulty**: Intermediate  
**Features**: Router DSL, route helpers, LiveDashboard routing  
**Use Case**: Type-safe Phoenix routing from Haxe

### 10. [10-option-patterns](./10-option-patterns/)
**Difficulty**: Intermediate  
**Features**: Option patterns and ergonomics  
**Use Case**: Practical Option usage on the Elixir target

### 11. [11-domain-validation](./11-domain-validation/)
**Difficulty**: Advanced  
**Features**: Domain validation patterns, typed constraints  
**Use Case**: Modeling rich domain logic in Haxe for the BEAM

### 12. [12-phoenix-chat](./12-phoenix-chat/)
**Difficulty**: Intermediate  
**Features**: LiveView + PubSub + Presence, tiny client hook (Genes), strict TSX templates  
**Use Case**: Real-time chat patterns in a small, focused Phoenix example

### 13. [13-elixir-first-liveview](./13-elixir-first-liveview/)
**Difficulty**: Intermediate  
**Features**: Typed Elixir-first LiveView, strict mode, typed boundary decoding, Result-based domain flow  
**Use Case**: Use Haxe as typed Elixir with minimal portability-first constraints

### 14. [14-abstraction-lab](./14-abstraction-lab/)
**Difficulty**: Intermediate  
**Features**: `@:protocol`, `@:impl`, `@:behaviour`, `@:use`, typed wrappers over low-level Elixir runtime APIs  
**Use Case**: Author reusable Haxe abstractions that compile to native Elixir contract/process module shapes

### 15. [15-phoenix-chat-haxe-first](./15-phoenix-chat-haxe-first/)
**Difficulty**: Intermediate  
**Features**: Haxe-authored `@:application`, module-level `@:router`, LiveView + PubSub + Presence, tiny client hook (Genes)  
**Use Case**: Haxe-first Phoenix chat where app/router/live/presence are authored in Haxe

### 16. [todo-app](./todo-app/)
**Difficulty**: Advanced  
**Features**: Full Phoenix LiveView app, Ecto, Playwright E2E  
**Use Case**: End-to-end reference app (recommended for Phoenix/LiveView)

### 17. [test-integration](./test-integration/)
**Difficulty**: Intermediate  
**Features**: Mix compiler task testing, build pipeline validation  
**Use Case**: Testing Haxe→Elixir compilation in Mix projects

## Authoring Style Matrix

Reflaxe.Elixir supports two authoring styles on one compiler pipeline. This matrix shows how the examples lean.

| Example | Style | Why |
| --- | --- | --- |
| `01-simple-modules` | Portable-first | Core Haxe module patterns with minimal framework coupling. |
| `02-mix-project` | Portable-first | Mix integration around reusable domain-oriented modules. |
| `03-phoenix-app` | Elixir-first | Minimal Phoenix app wiring via typed Phoenix extern surfaces. |
| `04-ecto-migrations` | Elixir-first | Ecto migration APIs are inherently target-native. |
| `05-heex-templates` | Hybrid | Legacy/balanced HXX migration patterns plus Phoenix templates. |
| `06-user-management` | Hybrid | Phoenix/Ecto integration plus broader app flow abstractions. |
| `07-protocols` | Elixir-first | Focused on BEAM protocol/dispatch shapes. |
| `08-behaviors` | Elixir-first | OTP behavior contracts and callback surfaces. |
| `09-phoenix-router` | Elixir-first | Typed Phoenix router DSL and controller wiring. |
| `10-option-patterns` | Portable-first | Domain Result/Option modeling independent of Phoenix runtime. |
| `11-domain-validation` | Portable-first | Parse-don't-validate domain types that can remain target-agnostic. |
| `12-phoenix-chat` | Hybrid (intentional) | Haxe feature logic + hand-authored Phoenix scaffold for incremental adoption. |
| `13-elixir-first-liveview` | Elixir-first | Typed LiveView app flow with strict-mode discipline and boundary decoding. |
| `14-abstraction-lab` | Elixir-first | Framework-agnostic abstraction patterns: protocols, behaviours, and typed process boundaries. |
| `15-phoenix-chat-haxe-first` | Elixir-first | Haxe-authored `@:application` + module-level `@:router` + LiveView/Presence in one server-first workflow. |
| `todo-app` | Hybrid (intentional) | Full app canary: portable shared domain + extensive Phoenix/Ecto/OTP integration. |
| `test-integration` | N/A | Compiler/Mix integration verification harness. |

## 🧩 HXX Mode Policy

- Default for examples: strict TSX mode (`-D hxx_mode=tsx`) and inline markup authoring.
- Legacy `hxx('...')` templates are only allowed in explicitly labeled migration demos.
- Current intentional non-TSX demo: `examples/05-heex-templates/` (see its README rationale).
- CI guardrail: `npm run guard:examples-hxx-mode` prevents legacy marker regressions outside demo paths.

## 🚀 Quick Start

Choose an example based on your experience level:

If you’re new to Haxe and/or Phoenix, start with: `docs/01-getting-started/START_HERE.md` (repo root).

### For Beginners
Start with [01-simple-modules](./01-simple-modules/):
```bash
cd examples/01-simple-modules
haxe compile-all.hxml
```

### For Mix Integration
Try [02-mix-project](./02-mix-project/):
```bash
cd examples/02-mix-project
mix deps.get
mix compile
mix test
```

### For Phoenix Development  
Explore [03-phoenix-app](./03-phoenix-app/):
```bash
cd examples/03-phoenix-app
mix deps.get
mix compile
mix phx.server
```

## 📚 Learning Path

1. **Start**: 01-simple-modules - Basic compilation
2. **Learn**: 02-mix-project - Mix integration  
3. **Build**: 03-phoenix-app - Minimal Phoenix server + typed router
4. **Abstractions**: 07-protocols, 08-behaviors, 14-abstraction-lab
5. **Choose style**: 10-option-patterns (portable-first) or 13-elixir-first-liveview (typed Elixir-first)
6. **Extend**: 04-ecto-migrations, 05-heex-templates, 09-phoenix-router
7. **Master**: 06-user-management + todo-app

## 🧪 Running Examples

Each example can be compiled independently:

```bash
# For simple Haxe compilation
haxe build.hxml

# For Mix-integrated projects  
mix deps.get
mix compile
mix test
mix phx.server  # If Phoenix app
```

### Automated Testing

All examples are automatically tested for compilation health:

```bash
# Compile-check all examples at once
npm run test:examples

# Run comprehensive test suite (includes examples)  
npm test

# Validate specific example
cd examples/[example-name]
haxe build.hxml
```

### Continuous Integration

Examples are tested in CI/CD on every commit to ensure:
- ✅ All examples compile successfully
- ✅ Generated Elixir code is syntactically valid
- ✅ No compilation warnings or errors
- ✅ Documentation consistency maintained
- ✅ Build configurations are correct

Notes:
- The heavyweight end-to-end `todo-app/` is validated by the dedicated **QA Sentinel** workflow (`.github/workflows/sentinel.yml`) which boots Phoenix in the background and runs Playwright smoke specs.
- The `Examples (Elixir WAE)` CI job validates the tutorial examples under `--warnings-as-errors` (sharded for runtime) and skips `todo-app/`, `test-integration/`, and `lix-installation/` to keep runtime bounded (those are covered elsewhere).

## 📖 Common Patterns

### Annotations
- `@:schema` - Define Ecto schemas
- `@:changeset` - Create changeset functions  
- `@:liveview` - Generate Phoenix LiveView modules
- `@:genserver` - Create OTP GenServer modules
- `@:migration` - Define database migrations (experimental)
- `@:router` + module-level `routes` - Define typed Phoenix routes
- `@:query` - Build type-safe Ecto queries

### Compilation
All examples use project lix dependencies:
```hxml
-lib reflaxe.elixir
-lib reflaxe
-D reflaxe_runtime
```

## 🛠 Requirements

- **Haxe**: 4.3.7+ (install the compiler; dependencies are managed via lix)
- **Elixir**: 1.14+
- **Phoenix**: 1.7+ (for Phoenix examples)
- **PostgreSQL**: For Ecto examples

## 💡 Development Workflow

1. **Edit** Haxe source in `src_haxe/` directories
2. **Compile** with `haxe build.hxml`  
3. **Generated** Elixir appears in `lib/` directories
4. **Test** with standard Elixir/Phoenix tools

---

**Next Steps**: Start with [01-simple-modules](./01-simple-modules/) and work your way through the examples!
