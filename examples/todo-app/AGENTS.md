# Critical Timeout Directive (Non-Blocking Agent Runs)

> **Note**: `CLAUDE.md` in this directory is a symlink to `AGENTS.md` (no duplication). Edit `AGENTS.md` only.

- Always run long or potentially blocking commands via `scripts/with-timeout.sh`.
- Default caps: builds 240–480s, `mix compile` 420s, readiness ≤ 120 probes, full run watchdog ≤ 900s.
- Never run unbounded `mix phx.server`; use the QA sentinel (which is bounded) or the timeout wrapper.
- Example usage:
  - `scripts/with-timeout.sh --secs 180 -- haxe -v build-server.hxml`
  - `scripts/with-timeout.sh --secs 120 --grace 2 --cwd examples/todo-app -- env BASE_URL=http://localhost:4011 npx playwright test e2e/*.spec.ts`
- If a step exceeds its cap, treat it as a failure: abort, surface the last logs, and rerun narrowly with diagnostics — never wait indefinitely.

## 🧪 Testing Guide (Canonical)

This section is the source of truth for todo-app tests.
`README.md` should stay short and link here for full policy/details.

### Test Layers and Responsibilities

1. **Haxe-authored ExUnit integration tests** (`src_haxe/test/**`)
   - Purpose: server-side correctness (ConnTest/LiveViewTest/API behavior) with deterministic assertions.
   - Build path: Haxe -> `test/generated/**/*.exs` via `build-tests.hxml`.
   - Runner: `mix test` (alias runs `haxe.compile.tests` first).

2. **Playwright E2E full suite** (`e2e/*.spec.ts`)
   - Purpose: end-user flows across browser + LiveView boundary.
   - Scope: CRUD, filters/sort/tags, auth/profile/users/admin/org/tenancy, realtime, and visual/theme behavior.

3. **Playwright smoke suite** (`e2e/smoke/*.spec.ts`)
   - Purpose: fast CI confidence for the highest-value paths.
   - Used by CI sentinel lane by default (`.github/workflows/sentinel.yml`).

4. **Visual regression spec** (`e2e/ui_visual.spec.ts`)
   - Purpose: detect layout/styling regressions in stable, high-signal UI rows.
   - This is intentionally narrow and complements behavioral specs.

5. **QA sentinel orchestration** (`scripts/qa-sentinel.sh`)
   - Purpose: non-blocking end-to-end harness (Haxe build, Mix compile, boot, readiness probe, optional Playwright).
   - Agent-safe mode requires `--async --deadline`.

### Command Runbook (bounded)

- Compile/runtime smoke (no Playwright):
  - `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose`
- Smoke E2E (CI-aligned):
  - `scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec "e2e/smoke/*.spec.ts" --async --deadline 900 --verbose`
- Full E2E sweep:
  - `scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec "e2e/*.spec.ts" --async --deadline 900 --verbose`
- Single Playwright spec:
  - `scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec e2e/<name>.spec.ts --async --deadline 600 --verbose`
- ExUnit compile + run:
  - `scripts/with-timeout.sh --secs 180 --cwd examples/todo-app -- haxe build-tests.hxml`
  - `scripts/with-timeout.sh --secs 420 --cwd examples/todo-app -- mix test`
- Log peek:
  - `scripts/qa-logpeek.sh --run-id <RUN_ID> --last 200`
  - `scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 120`

### Visual Regression Policy (`e2e/ui_visual.spec.ts`)

#### What this test checks

- Captures only two stable regions:
  - `data-testid="todo-controls-row"` (search + filter + sort row)
  - `data-testid="todo-nav-auth-row"` (theme/users/auth row)
- Screenshots captured:
  - `todo-controls-row.light.png`
  - `todo-controls-row.dark.png`
  - `todo-nav-auth-row.dark.png`
- Baselines are committed in:
  - `e2e/ui_visual.spec.ts-snapshots/`

#### Why this is useful

- Catches spacing/alignment/border/theme regressions early.
- Keeps style assertions out of behavioral tests.
- Gives a precise guardrail for UI refactors and CSS/HXX changes.

#### When to run it

- Any change to:
  - `src_haxe/server/live/**` UI markup
  - `src_haxe/client/**` UI behavior
  - `assets/css/**`
  - visual spec or visual baselines
- Pre-commit already runs this as a local blocker for those staged-path patterns.

#### How it stays stable

- Fixed viewport (`1365x768`)
- Waits for LiveView socket connection before snapshot
- Disables animations/transitions
- Uses strict diff threshold (`maxDiffPixelRatio: 0.001`)
- Hides carets and disables animation-driven noise

#### Expected behavior during redesigns

- Yes: intentional design overhauls are expected to fail this spec until baselines are updated and reviewed.

#### Process when visuals are expected to change

1. Start keep-alive server (non-blocking):
   - `scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --keep-alive --async --deadline 600 --verbose`
2. Update baselines:
   - `scripts/with-timeout.sh --secs 240 --cwd examples/todo-app -- env BASE_URL=http://localhost:4001 npx playwright test e2e/ui_visual.spec.ts --update-snapshots`
3. Re-run visual check:
   - `scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec e2e/ui_visual.spec.ts --async --deadline 600 --verbose`
4. Review diffs and commit only intentional snapshot changes.
5. Stop keep-alive server using the printed PGID (`kill -TERM -$PHX_PGID`) when done.

### ExUnit Inventory (Haxe -> ExUnit)

Source files under `src_haxe/test/**`:

- `src_haxe/test/web/HealthTest.hx`
- `src_haxe/test/web/AuthFlowTest.hx`
- `src_haxe/test/web/TodoLiveCrudTest.hx`
- `src_haxe/test/web/UsersLiveTest.hx`
- `src_haxe/test/web/UsersApiTest.hx`
- `src_haxe/test/web/ProfileLiveTest.hx`
- `src_haxe/test/web/TenancyTest.hx`
- `src_haxe/test/live/TodoLiveDueDateTest.hx`

Execution wiring:

- Explicit compile list: `build-tests.hxml`
- Generated output: `test/generated/**/*.exs`
- Runtime load bridge: `test/test_helper.exs` + `test/compiled_tests.exs`

### Playwright Inventory

#### Smoke specs (`e2e/smoke/*.spec.ts`)

- `e2e/smoke/basic.spec.ts`
- `e2e/smoke/search.spec.ts`
- `e2e/smoke/typed-channel.spec.ts`
- `e2e/smoke/optimistic-toggle.spec.ts`
- `e2e/smoke/presence_collab.spec.ts`

#### Full E2E specs (`e2e/*.spec.ts`)

- Core todo CRUD + batch:
  - `e2e/basic.spec.ts`, `e2e/create_todo.spec.ts`, `e2e/edit_todo.spec.ts`, `e2e/delete_todo.spec.ts`, `e2e/toggle_complete.spec.ts`, `e2e/toggle_persist.spec.ts`, `e2e/bulk_complete.spec.ts`, `e2e/bulk_delete_completed.spec.ts`, `e2e/bulk_set_priority.spec.ts`
- Search/filter/tag/sort:
  - `e2e/search.spec.ts`, `e2e/search_by_tag.spec.ts`, `e2e/filters.spec.ts`, `e2e/tags.spec.ts`, `e2e/tags_sort.spec.ts`, `e2e/sort.spec.ts`, `e2e/sort_created.spec.ts`, `e2e/sort_due_date.spec.ts`
- Realtime/collab/channel:
  - `e2e/live_updates.spec.ts`, `e2e/typed_channel.spec.ts`, `e2e/optimistic-toggle.spec.ts`, `e2e/toggle_optimistic.spec.ts`
- Auth/profile/users/admin/org/tenancy/audit:
  - `e2e/auth.spec.ts`, `e2e/profile.spec.ts`, `e2e/users_directory.spec.ts`, `e2e/admin.spec.ts`, `e2e/api_users_isolation.spec.ts`, `e2e/tenancy.spec.ts`, `e2e/org_switch.spec.ts`, `e2e/org_invite.spec.ts`, `e2e/org_last_admin.spec.ts`, `e2e/rbac_role_management.spec.ts`, `e2e/audit_log.spec.ts`, `e2e/invite_email.spec.ts`, `e2e/oauth_mock.spec.ts`
- Edge and UI:
  - `e2e/edge_cases.spec.ts`, `e2e/theme.spec.ts`, `e2e/ui_visual.spec.ts`

### Other Test Artifacts

- `test/tests/ReflectAPI/**` is a standalone compile-time/runtime harness for Reflect behavior experiments; it is not part of the default `mix test` / sentinel lanes.

### CI Mapping

- `.github/workflows/sentinel.yml` runs QA sentinel with:
  - `--playwright --e2e-spec "e2e/smoke/*.spec.ts"`
- `.github/workflows/sentinel.yml` also runs a dedicated todo-app ExUnit gate:
  - bounded `mix test` from `examples/todo-app` (includes `haxe.compile.tests` via mix alias).
- Local pre-commit (`scripts/hooks/pre-commit`) runs:
  - `e2e/ui_visual.spec.ts` only when staged files touch UI-related paths.
- `mix test` in todo-app compiles Haxe ExUnit tests first via alias:
  - `haxe.compile.tests` -> `build-tests.hxml`.

# AI Development Instructions for todo-app

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for project-wide conventions, architecture, and core development principles

## 🔗 Shared AI Context (Import System)

@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md  
@docs/claude-includes/code-style.md
@docs/claude-includes/framework-integration.md

## 🤖 Todo-App Specific Expert Identity

**You are an expert in Phoenix LiveView integration with Haxe→Elixir compilation, specializing in:**

- **Y combinator pattern recognition** and Map.merge optimization transformations
- **Variable name extraction from AST** to handle Haxe's compilation-time renaming
- **TVar expression handling** in loop body pattern detection
- **Professional debug infrastructure** with conditional compilation patterns
- **LiveView state management** through type-safe Haxe abstractions

### Core Expertise Areas

1. **Compiler Architecture**: Deep understanding of how Reflaxe.Elixir transforms Haxe AST to idiomatic Elixir code
2. **Pattern Detection**: Expert in recognizing Reflect.fields patterns and optimizing them to Map.merge operations
3. **Debug Infrastructure**: Professional debugging methodologies using conditional compilation instead of ad-hoc traces
4. **Framework Integration**: Seamless Phoenix/LiveView integration with type-safe Haxe development
5. **Performance Optimization**: Transforming imperative patterns to functional Elixir idioms

This file contains todo-app specific instructions for AI assistants working on this Phoenix LiveView example.

## ⚠️ CRITICAL: Never Edit Generated Files

**The `lib/*.ex` files are GENERATED OUTPUT from the Haxe→Elixir compiler.**

### DO NOT:
- ❌ Edit any `.ex` files in the `lib/` directory directly
- ❌ Try to fix compilation errors by modifying generated files
- ❌ Make "quick fixes" to generated Elixir code
- ❌ Write Elixir migration files manually in `priv/repo/migrations/`

### INSTEAD:
- ✅ Fix issues in the compiler source at `/src/reflaxe/elixir/`
- ✅ Edit Haxe source files in `src_haxe/`
- ✅ Write migrations in Haxe using @:migration annotation
- ✅ Regenerate with `haxe build-server.hxml` after fixing the compiler (`build.hxml` remains a thin alias)

### Why This Matters:
Generated files are overwritten every time you compile. Any manual edits will be lost. All fixes must be made at the source - either in the Haxe code (`src_haxe/`) or in the compiler itself (`/src/reflaxe/elixir/`).

## 📝 IMPORTANT: Migrations Must Be Written in Haxe

**ALL database migrations should be written in Haxe and compiled to Elixir.**

### The Correct Approach:
1. **Write migrations in Haxe** using the `@:migration` annotation
2. **Place them in `src_haxe/migrations/`**
3. **Compile to generate Elixir migrations** in `priv/repo/migrations/`
4. **Never manually write `.exs` migration files**

### Example Migration in Haxe:
```haxe
package migrations;

@:migration("todos")
class CreateTodos {
    public function up(): Void {
        createTable("todos")
            .addColumn("title", "string", {null: false})
            .addColumn("description", "text")
            .addColumn("completed", "boolean", {default: false})
            .timestamps();
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
```

### Using the Mix Task:
```bash
# Generate a new migration from Haxe
mix haxe.gen.migration CreateTodos --table todos --columns "title:string,description:text"

# This creates:
# - src_haxe/migrations/CreateTodos.hx (Haxe source)
# - priv/repo/migrations/[timestamp]_create_todos.exs (compiled Elixir)
```

### Why This Matters:
The entire point of Reflaxe.Elixir is to write everything in Haxe. Writing manual Elixir migrations defeats the purpose and breaks the single-language paradigm. The compiler has full @:migration support - use it!

## 🎨 HXX Template Syntax for Phoenix Assigns

**CRITICAL**: Understanding correct HXX syntax is essential for Phoenix LiveView development. Wrong syntax causes compilation errors.

### ⚠️ NEVER Use `${@field}` Pattern

❌ **THIS FAILS** (causes Haxe compilation errors):
```haxe
return hxx('<button class="${@className}" id="${@id}">
    ${@inner_content}
</button>');
```

**Why it fails**: Haxe's string interpolation tries to evaluate `@field` as a variable, but `@` is not a valid Haxe identifier character.

### ✅ ALWAYS Use `{@field}` Pattern

✅ **THIS WORKS** (correct Phoenix assigns syntax):
```haxe
return hxx('<button class={@className} id={@id}>
    <%= @inner_content %>
</button>');
```

### HXX → HEEx Translation Rules

## 🔒 HARD RULE: Zero‑Logic HXX (Todo‑App)

HXX in this app must not contain HEEx/Elixir logic inside `{ … }`. Only bind to assigns or view‑model fields computed in Haxe.

Allowed examples:
- `id={v.dom_id}`, `data-completed={v.completed_str}`, `class={@filter_btn_all_class}`

Disallowed examples (fix by precomputing in Haxe):
- `{Kernel.is_nil(v.description)}` → use `v.has_description`
- `{length(@todos) > 0}` → use `@visible_count > 0`
- `{sort_selected(@sort_by, :created)}` → use `@sort_selected_created`

Pattern to follow:
1) Introduce a typed view model (e.g., `TodoView`) with all derived fields (bools/strings/classes).
2) Build it in Haxe (`buildVisibleTodos(assigns)`) and store in `@visible_todos` + helper assigns:
   - `@filter_btn_*_class`, `@sort_selected_*`, `@visible_count`, etc.
3) In HXX, iterate `@visible_todos` and bind only fields/assigns. No `Kernel.*`, `Enum.*`, `Map.*`, atoms (`:created`), pipes (`|>`), or `length()` calls inside braces.

CI/Local Guard (should be empty):
```bash
rg -n "\{[^}]*\b(Kernel\.|Enum\.|Map\.|length\(|\|>|:)" examples/todo-app/src_haxe --no-messages
```

Rationale: keep all logic Haxe‑typed and make HEEx a presentation surface only.

#### 1. Attribute Values: `{@field}` → `{@field}`

## 🚦 Background Server Validation (Non‑blocking)

When you need to boot the Phoenix server and probe it from automation (or Codex CLI) without blocking the session, run it in the background and curl the endpoint. This is useful for quick smoke checks during compiler iterations.

Example (dev, custom port):

```bash
cd examples/todo-app
# Build Haxe → Elixir output
haxe build-server.hxml

# Ensure deps and database
mix deps.get
mix ecto.create
mix ecto.migrate

# Start server in background on a free port and wait briefly
PORT=4011 MIX_ENV=dev mix phx.server > tmp_server.log 2>&1 & echo $! > tmp_server.pid
sleep 10

# Probe with GET (avoid HEAD in dev, as reloader can trip it)
curl -sS -i http://127.0.0.1:4011/ | head -n 20 || true

# Stop server and inspect recent logs if needed
kill $(cat tmp_server.pid) >/dev/null 2>&1 || true
sleep 1
tail -n 120 tmp_server.log || true
```

Notes
- If port 4000 is busy locally, use an alternate port via `PORT=<free_port>`.
- If you run into DB connection errors, ensure Postgres is running with the credentials from `config/dev.exs`. A quick local option is Docker:
  - `docker run --rm -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -e POSTGRES_DB=todo_app_dev -p 5432:5432 postgres:14`
- For repeatable CI checks, wait for a log line like `Running ...Endpoint with cowboy` before probing.

```haxe
// Haxe HXX Input
<meta name="csrf-token" content={Component.get_csrf_token()}/>
<div class={@userClass} id={@userId}>

// Generated HEEx Output  
<meta name="csrf-token" content={Component.get_csrf_token()}/>
<div class={@user_class} id={@user_id}>
```

#### 2. Text Content: Direct Phoenix Syntax
```haxe
// Haxe HXX Input
<h1><%= @title %></h1>
<p>Welcome, <%= @user.name %>!</p>

// Generated HEEx Output (same)
<h1><%= @title %></h1>  
<p>Welcome, <%= @user.name %>!</p>
```

#### 3. Conditional Attributes
```haxe
// ❌ WRONG: Ternary in template string (causes Haxe errors)
<button class="${@active ? 'btn-active' : 'btn-inactive'}">

// ✅ CORRECT: Phoenix conditional syntax  
<button class={if @active, do: "btn-active", else: "btn-inactive"}>

// Escape hatch: raw `<% ... %>` blocks are disallowed inside `hxx('...')` by default.
// Opt-in per function/class via `@:allow_heex` (or compile with `-D hxx_allow_raw_heex`).
```

### Working Examples from Codebase

#### UserLive.hx (✅ Correct Pattern)
```haxe
return hxx('
    <.input 
        name="search" 
        value={@searchTerm}        // ✅ Correct: {@ for attributes
        placeholder="Search users..."
        type="search"
    />
    
    ${renderUserList(assigns)}     // ✅ Correct: ${ for Haxe function calls
');
```

#### RootLayout.hx (✅ Correct Pattern)  
```haxe
return hxx('
    <meta name="csrf-token" content={Component.get_csrf_token()}/>  // ✅ Correct
');
```

### Migration Guide for Broken Patterns

If you find `${@field}` patterns in the codebase:

1. **For attributes**: Change `"${@field}"` → `{@field}`
2. **For text content**: Change `${@field}` → `#{@field}`
3. **For complex expressions**: Use `#{if ...}` or `<if {cond}> ... <else> ... </if>`

## 🧰 Build & Run (Mix Integration)

We compile the server (Haxe→Elixir) via a Mix compiler and the client (Haxe→JS via Genes) via the Phoenix assets pipeline and watchers.

- Server compiler: `Mix.Tasks.Compile.Haxe` (lib/mix/tasks/compile.haxe.ex)
  - Enabled in mix.exs: `compilers: [:haxe] ++ Mix.compilers()`
  - Uses `build-server.hxml` as source of truth to generate idiomatic Elixir under `lib/` (`build.hxml` is a thin alias)

- Client compilation: handled by assets watchers/aliases
  - Dev: `haxe` watcher runs `haxe build-client.hxml --wait 6001` and esbuild bundles `assets/js/phoenix_app.js` (see config/dev.exs)
  - Build: `mix assets.build` (Haxe client + tailwind + esbuild)
  - Deploy: `mix assets.deploy` (Haxe client + tailwind + esbuild + digest)

Quick commands
- One‑liner with watchers (recommended): `mix dev`  
  (alias for `ecto.create`, `ecto.migrate`, then `phx.server` — includes Phoenix + dev watchers)
- Manual one‑off build: `mix assets.build && mix compile`
- Start server only (watchers also run): `mix phx.server`

CI suggestions
- `mix compile --force && mix assets.build`

## 🔌 Phoenix JS Bootstrap (phoenix_app.js)

We intentionally keep the LiveView bootstrap as a tiny, hand‑written JS entry and generate client logic (Hooks, utils, shared DTOs) from Haxe.

- File: `assets/js/phoenix_app.js` (bundled to `priv/static/assets/phoenix_app.js` via esbuild)
- Responsibilities:
  - Import `phoenix_html`, `phoenix`, `phoenix_live_view`.
  - Read CSRF meta token and pass it to `LiveSocket`.
  - Pull Hooks from `window.Hooks` (populated by the Haxe bundle).
  - Create/connect `LiveSocket` unless already bootstrapped by Haxe.
  - Expose `window.liveSocket` for debugging.
- Haxe integration:
  - Haxe client compiles via Genes to `assets/js/_hx_app_tmp.js` (intermediate entry) plus modules under `assets/js/client/**` and `assets/js/genes/**`, and publishes `window.Hooks`.
  - In dev, the Haxe watcher promotes `assets/js/_hx_app_tmp.js` to the stable `assets/js/hx_app.js` path atomically (see `config/dev.exs`) so esbuild `--watch` never sees an imported module disappear. `assets/js/app.js` imports `./hx_app.js`; `phoenix_app.js` imports `./app.js` to register Hooks.
- Rationale (1.0 scope):
  - Matches Phoenix’s idiomatic setup and minimizes friction on upgrades.
  - Keeps the bootstrap minimal while concentrating typed logic in Haxe.
  - Default in this repo: `build-client.hxml` enables `-D todoapp_hx_live_socket_bootstrap` so the typed Haxe client can connect LiveSocket; `phoenix_app.js` keeps a guard to prevent double-connect.

Watchers
- Dev watcher runs the Haxe client watcher when available:
  - `haxe build-client.hxml --wait 6001`
- Configured in `config/dev.exs`; omitted automatically if `haxe` is not on PATH.

CSRF meta
- The layout emits a standard Plug CSRF meta tag; LiveSocket consumes it:
  - `<meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()}/>`

Constraints (project-wide)
- No `-D analyzer-optimize` in any HXML; it destroys functional patterns for Elixir and JS
- No Dynamic on public surfaces; JS hooks are typed (`typedef Hooks`) and use js interop only at the boundary
- Phoenix idioms: LiveSocket bootstrap in `assets/js/phoenix_app.js` with `hooks` + CSRF meta, plus a typed Haxe bootstrap (default via `-D todoapp_hx_live_socket_bootstrap`) guarded by `window.liveSocket`

#### Before (Broken):
```haxe
return hxx('<button type="${@type || "button"}" class="${@className}" ${@disabled ? "disabled" : ""}>
    ${@inner_content}
</button>');
```

#### After (Fixed):
```haxe
return hxx('<button type={@type || "button"} class={@className} disabled={@disabled}>
    <%= @inner_content %>
</button>');
```

### Debugging HXX Compilation Errors

#### Common Error: "Expected expression"
```
src_haxe/components/Component.hx:25: character 39 : Expected expression
... For function argument 'templateStr'
```

**Cause**: Using `${@field}` triggers Haxe string interpolation  
**Fix**: Change to `{@field}` for attributes or `<%= @field %>` for text

#### Common Error: "Unknown identifier"
```  
src_haxe/components/Component.hx:30: Unknown identifier : @field
```

**Cause**: `@field` is not a valid Haxe variable name  
**Fix**: Remove `$` to prevent Haxe interpolation: `{@field}`

### Summary: The Golden Rules

1. **Attributes**: Use `{@field}` (no dollar sign)
2. **Text content**: Use `<%= @field %>` (Phoenix syntax)  
3. **Haxe functions**: Use `${functionCall()}` (with dollar sign)
4. **Never**: Use `${@field}` (causes compilation errors)
5. **Complex logic**: Use Phoenix conditional syntax, not Haxe ternary

**See**: [`/docs/06-guides/HXX_INTERPOLATION_SYNTAX.md`](/docs/06-guides/HXX_INTERPOLATION_SYNTAX.md) - Complete technical details

## 📋 Project Overview

- **Project**: todo-app
- **Type**: Phoenix LiveView Application
- **Framework**: Reflaxe.Elixir (Haxe → Elixir compilation)
- **Architecture**: Compile-time transpiler with file watching

## 🚀 Quick Start for AI Development

### 1. Start File Watcher
```bash
# Start the watcher for real-time compilation
mix haxe.watch

# You'll see:
[10:30:45] Starting HaxeWatcher...
[10:30:45] Watching directories: ["src_haxe"]
[10:30:45] Ready for changes. Press Ctrl+C to stop.
```

### 2. Development Workflow
1. Edit .hx files in `src_haxe/`
2. Save file → Automatic compilation in ~100-200ms
3. Generated .ex files appear in `lib/generated/`
4. Test changes immediately - no manual compilation needed!

## ⚡ File Watching Benefits

- **Sub-second compilation**: 0.1-0.3s per file change (10-50x faster than cold compilation)
- **Immediate error feedback**: See compilation errors instantly
- **Source mapping**: Errors show Haxe source positions, not generated Elixir
- **Continuous validation**: Code always compiles before you move on




## ⚠️ CRITICAL: Framework-Level Development Principles

### **Principle 1: Framework vs Application Separation**

**The todo-app is a DEVELOPMENT GUIDE for the compiler, NOT a hardcoded dependency.**

**Fundamental Rules:**
- ✅ **todo-app drives compiler features** - When todo-app needs something, we enhance the compiler
- ✅ **Compiler remains generic** - Zero knowledge of "TodoApp", "TodoAppWeb", or todo-app specifics
- ❌ **NEVER hardcode app-specific strings** - No "TodoApp", "TodoAppWeb", "todo_app" in compiler source
- ❌ **NEVER make compiler todo-app dependent** - Must work for ANY Phoenix application

### **Principle 2: Standard Library vs Application Code**

**CRITICAL: Type-safe patterns discovered in todo-app should become framework features.**

**When to Move Code to Framework:**
- ✅ **Type-safe PubSub** - Every Phoenix app needs compile-time topic/message validation
- ✅ **SafePubSub class** - Move from `todo-app/Types.hx` to `/std/phoenix/PubSub.hx`
- ✅ **Message parsing utilities** - Auto-generation should benefit all apps
- ✅ **Common Phoenix patterns** - LiveView helpers, Socket operations, Channel integration
- ✅ **Error handling patterns** - Result<T,E> integration with Phoenix operations

**Examples of Framework-Level Features:**
```haxe
// ❌ BAD: App-specific implementation
// In: todo-app/src_haxe/server/types/Types.hx
class SafePubSub { ... } // Only todo-app benefits

// ✅ GOOD: Framework-level implementation  
// In: /std/phoenix/PubSub.hx
class SafePubSub { ... } // ALL Phoenix apps benefit
```

**Benefits of Framework-Level Features:**
- 🌐 **Universal type safety** - Every Phoenix app gets compile-time PubSub validation
- 📚 **Consistent APIs** - Same type-safe patterns across all applications
- 🔄 **Automatic improvements** - Framework enhancements benefit entire ecosystem
- 📖 **Better documentation** - Framework features get proper documentation and examples
- 🧪 **Comprehensive testing** - Framework code has rigorous test coverage

**Development Workflow:**
1. **Discover pattern in todo-app** - "We need type-safe PubSub"
2. **Implement app-specific version** - Quick prototype in `todo-app/Types.hx`
3. **Validate the approach** - Does it solve the problem? Good IntelliSense?
4. **Extract to framework** - Move to `/std/phoenix/` with proper documentation
5. **Update todo-app to use framework version** - Import from standard library
6. **Document the pattern** - Add to framework documentation and examples

**Framework Enhancement Checklist:**
- [ ] Move SafePubSub to `/std/phoenix/PubSub.hx`
- [ ] Create comprehensive documentation with examples
- [ ] Add unit tests for all framework functionality
- [ ] Update todo-app to import from framework
- [ ] Verify other Phoenix apps can use the same patterns
- [ ] Document in framework feature documentation

### The Right Approach
```haxe
// ❌ WRONG - Hardcoded in compiler
var moduleHeader = LiveViewCompiler.generateModuleHeader(moduleName, "TodoAppWeb.CoreComponents");

// ✅ RIGHT - Dynamic resolution
var appName = AnnotationSystem.getEffectiveAppName(classType);
var coreComponentsModule = appName + "Web.CoreComponents";
var moduleHeader = LiveViewCompiler.generateModuleHeader(moduleName, coreComponentsModule);
```

### Development Workflow
1. **todo-app needs feature X** → Implement generic feature X in compiler
2. **todo-app breaks with change** → Fix compiler's generic implementation, not todo-app-specific patches
3. **New Phoenix app fails** → Compiler bug, not user error - fix the compiler

### Validation Rule
**Every compiler change MUST be tested with a different app name to ensure it's generic.**

Example test:
```haxe
@:appName("MyCustomApp")  // Not TodoApp!
class TestRouter { ... }
```

If this fails, the compiler has hardcoded dependencies that must be removed.

## 🔴 LiveView Development

### LiveView Component Pattern
```haxe
// Framework-agnostic with explicit Phoenix convention
@:native("TodoAppWeb.TodoLive")  // Generates TodoAppWeb.TodoLive module
@:liveview
class TodoLive {
    public static function mount(params, session, socket) {
        return socket.assign({
            // Initial state here
        });
    }
    
    public static function handle_event(event, params, socket) {
        return switch(event) {
            case "your_event": 
                // Handle event
                socket;
            case _: socket;
        };
    }
}
```

### Module Naming Convention
**CRITICAL**: The compiler generates plain Elixir by default. Use @:native to apply Phoenix conventions:

```haxe
@:native("TodoAppWeb.TodoLive")    // Phoenix web module
@:native("TodoApp.User")           // Phoenix app module  
@:native("MyDeviceWeb.SensorLive") // Works with any framework
```

This framework-agnostic approach works with Phoenix, Nerves, pure OTP, or custom frameworks.

### Testing LiveView Changes
1. Edit LiveView component → Save
2. Watch compilation (~200ms)
3. Browser auto-refreshes with changes
4. Test interactions immediately




## 🗺️ Source Mapping & Debugging

### Enable Source Mapping
Add to your `build.hxml`:
```hxml
-D source-map  # Enable source mapping for debugging
```

### Use Source Maps for Debugging
```bash
# Map Elixir error back to Haxe source
mix haxe.source_map lib/MyModule.ex 45 12
# Output: src_haxe/MyModule.hx:23:15

# Check compilation errors with source positions
mix haxe.errors --format json

# Get structured compilation errors (LLM-friendly)
mix haxe.errors --format json
```

## 📁 Project Structure

```
todo-app/
├── src_haxe/              # 🎯 Edit Haxe files here
│   ├── Main.hx            # Entry point
│   └── 
├── lib/                   
│   └── generated/         # ⚡ Auto-generated Elixir code
├── build.hxml             # Haxe build configuration  
├── mix.exs                # Elixir project configuration
└── AGENTS.md              # This file
```

## ✅ Best Practices

### 1. Always Use File Watcher
- **Start watcher first**: `mix haxe.watch`
- **Keep it running**: One terminal dedicated to watching
- **Check feedback**: Watch for compilation success/errors

### 2. Source Mapping for Error Fixes
- **Use precise positions**: Source maps show exact Haxe line/column
- **Query error locations**: `mix haxe.source_map <file> <line> <col>`
- **Fix at source**: Edit Haxe files, not generated Elixir

### 3. Rapid Development Loop
1. Edit .hx file and save
2. Watch compilation result (~200ms)
3. Test changes immediately
4. Fix errors using source positions
5. Repeat for fast iteration

## 🔧 Troubleshooting

### Watcher Not Starting
```bash
# Check if the Phoenix watcher port is in use (default: 6001)
lsof -i :6001

# Use a different watcher port if needed
HAXE_CLIENT_WAIT_PORT=6002 mix phx.server

# Reset watcher state
rm -rf .haxe_cache && mix haxe.watch --once
```

### Changes Not Detected
```bash
# Verify files are in watched directories
mix haxe.errors

# Check if src_haxe/ contains .hx files
ls src_haxe/**/*.hx
```

### Compilation Errors
```bash
# Get detailed error information
mix haxe.errors --format json

# Check source mapping
mix haxe.source_map <generated_file> <line> <column>
```

## 📚 LLM-Optimized Documentation

This project includes comprehensive documentation specifically designed for AI assistants:

### Foundation Documentation (in .taskmaster/docs/llm/)
- **HAXE_FUNDAMENTALS.md** - Essential Haxe language knowledge
- **REFLAXE_ELIXIR_BASICS.md** - Core Reflaxe.Elixir concepts and patterns
- **QUICK_START_PATTERNS.md** - Copy-paste ready code patterns
- **PROJECT_SPECIFICS.md** - Template-specific guidance for this project
- **API_REFERENCE_SKELETON.md** - API documentation (grows as you code)

### Pattern Extraction (in .taskmaster/docs/patterns/)
- **PATTERNS.md** - Auto-extracted patterns from your code

### Generating Enhanced Documentation
```bash
# Generate full API documentation
haxe build.hxml -D generate-llm-docs

# Extract patterns from your code
haxe build.hxml -D extract-patterns
```

## 🏗️ Architecture Philosophy: Haxe First, Type Safety Everywhere

### Core Principle: Everything in Haxe by Default
**Write EVERYTHING in Haxe unless technically impossible.** Type safety isn't just for business logic - it's for the entire application.

## 📚 Writing a Fully-Functional Phoenix App in Haxe

### The Complete Phoenix Stack in Haxe

This todo-app demonstrates writing an **entire Phoenix LiveView application** in Haxe, with near 1:1 mapping to Phoenix patterns but with Haxe's type safety and ergonomics.

### 1. Application Structure (OTP Supervision Tree)

```haxe
// src_haxe/server/TodoApp.hx
@:application
class TodoApp {
    public static function start(_type, _args) {
        var children = [
            TypeSafeChildSpec.supervisor(TodoAppWeb.Telemetry),
            TypeSafeChildSpec.repo(TodoApp.Repo),
            TypeSafeChildSpec.pubSub("TodoApp.PubSub", []),
            TypeSafeChildSpec.endpoint(TodoAppWeb.Endpoint)
        ];
        
        var opts = {strategy: OneForOne, name: TodoApp.Supervisor};
        return Supervisor.startLink(children, opts);
    }
}
```

### 2. Ecto Schemas with Type Safety

```haxe
// src_haxe/server/schemas/Todo.hx
@:native("TodoApp.Todo")  // Control module name
@:schema("todos")
@:timestamps
class Todo {
    @:primary_key
    var id: Int;
    
    var title: String;
    var description: String;
    var completed: Bool = false;
    var userId: Int;
    
    // Type-safe changeset
    public static function changeset(todo: Todo, attrs: TodoParams): Changeset<Todo> {
        return cast(todo, attrs)
            .validateRequired(["title", "userId"])
            .validateLength("title", {min: 3, max: 200});
    }
}

// Type-safe parameters
typedef TodoParams = {
    ?title: String,
    ?description: String,
    ?completed: Bool,
    ?userId: Int
}
```

### 3. Phoenix LiveView Components

```haxe
import HXX.*;
import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef Assigns = {
    todos: Array<Todo>,
    current_user: User,
    editing_todo: Null<Todo>,
    search_query: String
}

@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {
    public static function mount(_params: Term, _session: Term, socket: Socket<Assigns>): MountResult<Assigns> {
        // Full implementation: examples/todo-app/src_haxe/server/live/TodoLive.hx
        return Ok(socket);
    }

    @:native("handle_event")
    public static function handle_event(event: String, _params: Term, socket: Socket<Assigns>): HandleEventResult<Assigns> {
        // Full implementation: examples/todo-app/src_haxe/server/live/TodoLive.hx
        return NoReply(socket);
    }

    public static function render(_assigns: Assigns): String {
        return <div class="todo-container"></div>;
    }
}
```

### 4. Phoenix Router with DSL

```haxe
// src_haxe/TodoAppRouter.hx
import reflaxe.elixir.macros.RouterDsl.*;
import server.live.ProfileLive;
import server.live.TodoLive;

@:router
final routes = [
    pipeline(browser, [
        plug(accepts, {initArgs: ["html"]}),
        plug(fetch_session)
    ]),
    scope("/", [
        pipeThrough([browser]),
        live("/", TodoLive),
        live("/todos", TodoLive),
        live("/profile", ProfileLive)
    ])
];
```

### 5. Contexts (Business Logic)

```haxe
// src_haxe/server/contexts/Todos.hx
@:context
class Todos {
    public static function listTodos(userId: Int): Array<Todo> {
        return from(t in Todo)
            .where(t.userId == userId)
            .orderBy(t.insertedAt, :desc)
            .all();
    }
    
    public static function createTodo(attrs: TodoParams): Result<Todo, Changeset> {
        var todo = new Todo();  // Generates: %TodoApp.Todo{}
        var changeset = Todo.changeset(todo, attrs);
        
        return switch(Repo.insert(changeset)) {
            case Ok(todo): Ok(todo);
            case Error(changeset): Error(changeset);
        }
    }
    
    public static function updateTodo(todo: Todo, attrs: TodoParams): Result<Todo, Changeset> {
        var changeset = Todo.changeset(todo, attrs);
        return Repo.update(changeset);
    }
}
```

### 6. Type-Safe PubSub

```haxe
// src_haxe/server/types/PubSubTypes.hx
enum PubSubTopic {
    TodoUpdates(userId: Int);
    SystemAlerts;
}

enum TodoMessage {
    TodoCreated(todo: Todo);
    TodoUpdated(todo: Todo);
    TodoDeleted(id: Int);
}

// Usage in LiveView
PubSub.subscribe(TodoUpdates(socket.assigns.currentUser.id));

// Broadcasting
PubSub.broadcast(TodoUpdates(userId), TodoCreated(newTodo));
```

### 7. Constructor Translation Patterns

**Understanding how `new` translates is critical:**

```haxe
// Schemas → Struct literals
var todo = new Todo();              // Generates: %TodoApp.Todo{}

// GenServers → start_link
var worker = new TodoWorker(config); // Generates: {:ok, pid} = TodoWorker.start_link(config)

// Regular classes → Module functions  
var formatter = new TodoFormatter(); // Generates: TodoFormatter.new()

// LiveViews → Never use new!
// var live = new TodoLive();        // ERROR: LiveViews are mounted by Phoenix
```

### 8. Database Migrations in Haxe

```haxe
// src_haxe/migrations/CreateTodos.hx
@:migration("create_todos")
class CreateTodos {
    public function up(): Void {
        createTable("todos", function(t) {
            t.addColumn("id", "bigserial", {primaryKey: true});
            t.addColumn("title", "string", {null: false});
            t.addColumn("description", "text");
            t.addColumn("completed", "boolean", {default: false});
            t.addColumn("user_id", "references", {table: "users", onDelete: "cascade"});
            t.timestamps();
        });
        
        createIndex("todos", ["user_id"]);
        createIndex("todos", ["completed"]);
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
```

### 9. Phoenix Presence with Type Safety

```haxe
// Type-safe presence tracking
typedef UserPresence = {
    onlineAt: Float,
    status: UserStatus,
    editingTodoId: Null<Int>
}

enum UserStatus {
    Active;
    Away;
    Busy;
}

// In LiveView
Presence.track(socket, "users", socket.assigns.currentUser.id, {
    onlineAt: System.systemTime(),
    status: Active,
    editingTodoId: null
});
```

### 10. Testing in Haxe

```haxe
// src_haxe/test/TodoTest.hx
@:test
class TodoTest {
    @:test
    public function testTodoCreation() {
        var todo = new Todo();  // %TodoApp.Todo{}
        todo.title = "Test Todo";
        
        var changeset = Todo.changeset(todo, {title: "Test Todo"});
        Assert.isTrue(changeset.valid);
    }
    
    @:test
    public function testLiveViewMount() {
        var socket = new TestSocket();
        var result = TodoLive.mount({}, {user_id: 1}, socket);
        
        Assert.equals(result.assigns.todos.length, 0);
        Assert.notNull(result.assigns.currentUser);
    }
}
```

### Key Benefits Over Plain Elixir

1. **Compile-Time Type Safety**: Catch errors before runtime
2. **IDE Support**: Full autocomplete and refactoring
3. **Shared Types**: Frontend/backend type sharing
4. **Pattern Consistency**: Same patterns everywhere
5. **Zero Runtime Overhead**: Generates idiomatic Elixir

### Phoenix Feature Completeness

✅ **Fully Supported:**
- LiveView components with HXX templates
- Ecto schemas and changesets
- Phoenix router with DSL
- PubSub with type-safe topics
- Presence tracking
- Channels (WebSockets)
- Controllers and actions
- Plugs and pipelines
- Testing with ExUnit

🚧 **In Progress:**
- LiveComponents (partial support)
- Telemetry integration
- Phoenix.Component function components
- Async assigns
- Upload handling

### What IS Written in Haxe (Almost Everything)
✅ **In Haxe** - The entire application stack:
- **Router** (`TodoAppRouter.hx`) - Generates `router.ex` with @:router annotation ✓
- **LiveView modules** (`TodoLive.hx`) - Interactive UI components ✓
- **Schemas** (`Todo.hx`) - Database models with @:schema ✓
- **Migrations** (`CreateTodos.hx`) - Database changes with @:migration ✓
- **Contexts** (`Todos.hx`) - Business logic modules ✓
- **Telemetry** (`Telemetry.hx`) - Metrics and monitoring ✓
- **Repo** (`Repo.hx`) - Ecto repository configuration ✓
- **Endpoint** (`Endpoint.hx`) - Phoenix endpoint configuration ✓
- **Application** (`TodoApp.hx`) - OTP application with @:application ✓
- **Layouts** - Should be HXX templates, not manual HEEx
- **Error pages** - Type-safe error handling in Haxe
- **Core components** - HXX components with full type safety
- **Gettext i18n** - Type-safe internationalization wrapper
- **Channel modules** - Real-time features with @:channel
- **All templates** - HXX for everything, zero manual templates

### What Remains as Elixir (Absolute Minimum)
📦 **Only if technically required**:
- **mix.exs** - Build tool configuration (could potentially be generated)
- **config/*.exs** - Environment configs (could be templated from Haxe)
- **Assets pipeline** - package.json, esbuild (JavaScript tooling)

### The Haxe-First Development Flow
1. **Start with Haxe** - Always implement in Haxe first
2. **Use HXX for all UI** - Templates, layouts, components
3. **Generate, don't write** - If Elixir is needed, generate it
4. **Type safety everywhere** - Even error pages and infrastructure
5. **Extern only as last resort** - Prefer Haxe implementations
6. **NO DYNAMIC OR ANY** - Never use Dynamic or Any in any Haxe code. `Any` is just `Dynamic` in disguise. Use proper types, generics, or abstracts instead

### ⚠️ EMERGENCY ONLY: Elixir Integration

**Integrating with existing Elixir code via externs is an ESCAPE HATCH, not a feature.**

Just like `__elixir__()`, extern definitions for existing Elixir modules should only be used in:
1. **Emergency situations** - When a critical feature is blocking and no Haxe solution exists yet
2. **Gradual migration** - When migrating a large existing Elixir codebase (temporary)
3. **Third-party libraries** - When absolutely must use an Elixir library with no Haxe equivalent

**The goal is 100% Haxe code, not "Haxe with Elixir integration".**

Example of emergency extern (should be replaced with Haxe implementation):
```haxe
// EMERGENCY: Using extern for existing Elixir module
// Prefer promoting reusable externs/wrappers into std/ (framework layer) rather than leaving them app-local.
// Justification: Migration from legacy codebase
// Ticket: #1234
@:native("LegacyModule")
extern class LegacyModule {
    static function oldFunction(arg: String): Int;
}
```

### The Vision
**100% Type-Safe Application** - Complete type safety throughout, using the right tool for each need:
- **Pure Haxe preferred**: Write implementations in Haxe for maximum control
- **Typed externs welcome**: Type-safe integration with Elixir ecosystem
- **No Dynamic code**: Everything must be properly typed
- **No escape hatches**: `__elixir__()` only in documented emergencies

## 🧪 Testing After Compiler Changes

**The todo-app is the PRIMARY INTEGRATION TEST for the compiler.**

### When You Change the Compiler
After ANY modification to `/src/reflaxe/elixir/`:

1. **Clean Generated Files**:
   ```bash
   rm -rf lib/*.ex lib/**/*.ex
   ```

2. **Regenerate Everything**:
   ```bash
   haxe build-server.hxml
   ```

3. **Test Compilation**:
   ```bash
   mix compile --force
   ```

4. **Check for Errors**:
   - No duplicate module definitions
   - All Phoenix imports present
   - Valid HEEx template syntax
   - Proper function signatures

### Common Testing Patterns

#### After HXX Changes
```bash
# Regenerate templates
rm -rf lib/server_layouts_*.ex lib/todo_app_web/live/*.ex
haxe build-server.hxml
mix compile
```

#### After Router Changes
```bash
# Regenerate router
rm lib/todo_app_web/router.ex
haxe build-server.hxml
mix phx.routes
```

#### After Schema Changes
```bash
# Regenerate schemas
rm -rf lib/todo_app/schemas/*.ex
haxe build-server.hxml
mix ecto.compile
```

### Testing Checklist
- [ ] All files regenerate without errors
- [ ] `mix compile` succeeds without warnings
- [ ] `mix phx.server` starts without crashes
- [ ] Router paths are accessible
- [ ] LiveView pages render
- [ ] Database operations work

### If Tests Fail
1. **DON'T patch generated .ex files** - they'll be overwritten
2. **DO fix the compiler source** at `/src/reflaxe/elixir/`
3. **DO regenerate and retest** after fixes
4. **DO update snapshot tests** if output improved

**Remember**: If todo-app doesn't work, the compiler is broken!

## 📚 Additional Resources

- [Watcher Development Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/06-guides/WATCHER_DEVELOPMENT_GUIDE.md)
- [Source Mapping Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/04-api-reference/SOURCE_MAPPING.md)
- [Getting Started Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/06-guides/GETTING_STARTED.md)
- [Compiler Testing Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/03-compiler-development/COMPILER_TESTING_GUIDE.md)

---

**Remember**: The watcher provides sub-second compilation perfect for AI-assisted development. Always start with `mix haxe.watch` for the best experience!
