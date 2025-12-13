# Todo‑App / Cowboy Toolchain Issue Report (Elixir 1.18.3, OTP 27)

## 1. Project and Environment Overview

**Repo:** `haxe.elixir` — a Haxe→Elixir compiler (Reflaxe.Elixir) plus example apps, especially `examples/todo-app`, which serves as the reference end‑to‑end (E2E) test.

### Architecture (high‑level)

- Compiler is fully **AST‑based**:
  - TypedExpr → ElixirAST → transforms → printed Elixir.
  - Core pipeline in `src/reflaxe/elixir/ast` (Builder, Transformer, Printer).
- Server build for `examples/todo-app` is split into micro‑passes:
  - `build-server-passA1.hxml` … `build-server-passF.hxml` to keep each pass bounded and cache‑friendly.
- QA layers:
  1. Haxe snapshot tests (no runtime).
  2. Todo‑app integration via **QA sentinel** (`scripts/qa-sentinel.sh`):  
     Haxe build → `mix deps.get` → `mix compile` → boot Phoenix → readiness probe → `GET /` → optional Playwright.
  3. App‑level tests:
     - Haxe‑authored ExUnit (compiled to Elixir) for LiveView/ConnTest.
     - Playwright E2E specs in `examples/todo-app/e2e/*.spec.ts`.

### Toolchain on this machine

```text
Erlang/OTP 27 [erts-15.2.7]
Elixir 1.18.3 (compiled with Erlang/OTP 27)
```

### Todo‑app dependencies (from `examples/todo-app/mix.lock`)

Key runtime deps:

- `phoenix 1.7.21`
- `plug_cowboy 2.7.4`
- `cowboy 2.14.2`
- `cowlib 2.16.0`
- `ranch 2.2.0`
- Standard Ecto / telemetry / Phoenix stack.

All commands in this session are run under strict caps using `scripts/with-timeout.sh`. Nothing is allowed to run indefinitely.

---

## 2. What Already Works (Compiler + Haxe Side)

These pieces are in good shape and close to 1.0 quality.

### 2.1 AST‑only pipeline

- Elixir code generation never uses string concatenation; everything goes through `ElixirAST`.
- The pipeline is:
  - Haxe TypedExpr → ElixirAST (Builder)
  - ElixirAST → multiple transform passes (Transformer)
  - ElixirAST → string code (Printer)
- Transform passes are modular and documented, with hxdoc expectations.

### 2.2 Fast‑profile builds are warning‑free and fast

Under `scripts/with-timeout.sh` caps:

- **Root completion build**:
  - Command: `scripts/with-timeout.sh --secs 60 -- haxe completion.hxml`
  - Behavior:
    - Finishes quickly (<1s).
    - Grepping logs for `Warning` shows no compiler/std‑origin warnings.

- **Fast boot LiveView snapshot**:
  - Path: `test/snapshot/phoenix/liveview_fast_boot_gating/compile.hxml`
  - Command:  
    `scripts/with-timeout.sh --secs 60 --cwd test/snapshot/phoenix/liveview_fast_boot_gating -- env HAXE_USE_SERVER=0 haxe compile.hxml`
  - Behavior:
    - Compiles fast.
    - Zero Haxe warnings.

- **Todo‑app server Haxe micro‑passes A1..E**:
  - Each of:
    - `build-server-passA1.hxml`, `build-server-passA2.hxml`, `build-server-passA3.hxml`, `build-server-passB.hxml`, `build-server-passC.hxml`, `build-server-passD.hxml`, `build-server-passE.hxml`
  - Run via:
    - `scripts/with-timeout.sh --secs 10 --cwd examples/todo-app -- env HAXE_USE_SERVER=0 haxe <that-pass>.hxml`
  - Behavior:
    - All complete under the cap.
    - Known warnings (e.g., `@:extern` with bodies, deprecated attributes in `examples/todo-app/src_haxe/server/i18n/Gettext.hx`) were fixed by converting them to proper `extern` declarations without bodies.

### 2.3 Transform performance instrumentation

- `ElixirASTTransformer` has timing instrumentation:
  - `#if hxx_instrument_sys` wraps each pass and the total pipeline.
  - Emits lines like:
    - `[PassTiming] name=<passName> ms=<elapsed>`
    - `[PassTiming] name=ElixirASTTransformer.total ms=<elapsed>`
- On representative runs:
  - Individual passes report `ms=0` (rounded) for many modules.
  - `ElixirASTTransformer.total` per module is typically in the range 4–12ms.
  - For modules that finish before timeouts, the AST transformer is not a bottleneck.

### 2.4 Project rules and constraints

From AGENTS/PRDs and .claude rules:

- **No app‑specific heuristics**:
  - Transforms must not key off todo‑app names like `todo`, `toggle_todo`, variable names, or app‑specific literals.
  - Allowed shape‑based or metadata‑based decisions only.

- **No band‑aids**:
  - No arbitrary limits slapped on loops just to avoid hangs.
  - No skipping “problematic” nodes as a workaround.
  - No post‑processing string hacks to fix generated code.

- **No editing generated `.ex`**:
  - Behavior changes must go through:
    - Compiler Haxe (src/reflaxe/elixir/**),
    - Std Haxe sources (`std/_std`, `std/*.cross.hx`),
    - Or canonical runtime `.ex` where explicitly documented.

- **No new `Dynamic`**:
  - Public surfaces should remain typed; `Dynamic` is only allowed at well‑documented boundaries.

- **File size limits**:
  - No source file >2000 LOC.
  - If a file approaches that limit, extract helpers/modules.

- **QA sentinel as runtime gate**:
  - Any runtime‑affecting change must be validated via:
    - Haxe snapshot + ExUnit where applicable, **and**
    - A QA sentinel run for the todo‑app (bounded, non‑blocking).

We also updated Shrimp (internal planner) to reflect a clear 1.0 path based on these principles.

---

## 3. What’s Broken Now: Cowboy on OTP 27

### 3.1 Reproducing the failure

In `examples/todo-app`, after a full reset:

```bash
# Ensure fresh deps/build
scripts/with-timeout.sh --secs 60 --cwd examples/todo-app -- rm -rf _build deps
scripts/with-timeout.sh --secs 60 --cwd examples/todo-app -- mix deps.get

# Try to compile cowboy alone under caps
scripts/with-timeout.sh --secs 60 --cwd examples/todo-app -- mix deps.compile cowboy --force
```

Output (trimmed to key lines):

```text
===> Analyzing applications...
===> Compiling cowboy
src/cowboy_tls.erl:16:2: Warning: behaviour ranch_protocol undefined

===> Compiling src/cowboy_http.erl failed
src/cowboy_http.erl:{168,14}: can't find include lib "cowlib/include/cow_inline.hrl"; Make sure cowlib is in your app file's 'applications' list
src/cowboy_http.erl:{169,14}: can't find include lib "cowlib/include/cow_parse.hrl"; Make sure cowlib is in your app file's 'applications' list
src/cowboy_http.erl:544:11: undefined macro 'IS_TOKEN/1'
src/cowboy_http.erl:690:74: undefined macro 'IS_WS/1'

src/cowboy_http.erl:524:6: function parse_method/4 undefined
src/cowboy_http.erl:678:4: function parse_hd_name/4 undefined

src/cowboy_http.erl:549:1: Warning: function parse_uri/3 is unused
src/cowboy_http.erl:566:1: Warning: function parse_uri_authority/3 is unused
src/cowboy_http.erl:570:1: Warning: function parse_uri_authority/5 is unused
src/cowboy_http.erl:595:1: Warning: function parse_uri_path/5 is unused
src/cowboy_http.erl:605:1: Warning: function parse_uri_query/6 is unused
src/cowboy_http.erl:614:1: Warning: function skip_uri_fragment/6 is unused

** (Mix) Could not compile dependency :cowboy, "/Users/fullofcaffeine/.mix/elixir/1-18/rebar3 bare compile --paths /Users/fullofcaffeine/workspace/code/haxe.elixir/examples/todo-app/_build/dev/lib/*/ebin" command failed.
```

We also explicitly installed fresh `rebar3` and Hex:

```bash
mix local.rebar --force
mix local.hex  --force
```

The failure still occurs.

### 3.2 Additional observations

1. **`cowlib` compiles successfully**

```bash
scripts/with-timeout.sh --secs 60 --cwd examples/todo-app -- mix deps.compile cowlib --force
```

This completes, and `_build/dev/lib/cowlib` contains:

- `ebin/*.beam` including `cow_http.beam`, etc.
- `include/cow_inline.hrl`
- `include/cow_parse.hrl`
- `cowlib.app`

So cowlib itself is fine.

2. **`cowboy_http.erl` includes standard cowlib headers**

`deps/cowboy/src/cowboy_http.erl` contains:

```erlang
-include_lib("cowlib/include/cow_inline.hrl").
-include_lib("cowlib/include/cow_parse.hrl").
```

These are standard includes used across cowboy versions. The corresponding files do exist in cowlib’s include directory, yet rebar3 complains it “can’t find include lib”.

3. **Toolchain path**

The failing command is:

```text
/Users/fullofcaffeine/.mix/elixir/1-18/rebar3 bare compile \
  --paths /Users/fullofcaffeine/workspace/code/haxe.elixir/examples/todo-app/_build/dev/lib/*/ebin
```

So Mix is letting rebar3 drive the `cowboy` compilation against `_build/dev/lib/*`.

### 3.3 What we tried and explicitly *rejected* as permanent fixes

We experimented (temporarily) with:

- Creating `deps/cowlib/rebar.config` with:

  ```erlang
  {erl_opts, [{i, "include"}]}.
  ```

- Tweaking `deps/cowboy/rebar.config` and `deps/cowboy/src/cowboy_http.erl` to include cowlib headers via direct `-include` and add extra include paths, etc.

However:

- `mix deps.get` will happily overwrite any changes in `deps/`.
- The project rules (AGENTS, PRDs) explicitly forbid “band‑aid” hacks in deps sources for 1.0.
- Any such tweak would not be a stable, portable fix for other developers or CI.

Therefore, those experiments were discarded. We consider them **out of scope** for a real 1.0 solution.

---

## 4. Impact on QA Sentinel and Playwright

QA sentinel for todo‑app runs (simplified):

```bash
scripts/qa-sentinel.sh \
  --app examples/todo-app \
  --port 4001 \
  --env e2e \
  --async \
  --deadline 600 \
  --playwright \
  --e2e-spec e2e/*.spec.ts
```

This does:

1. Haxe build (using micro‑passes or a fast hxml).
2. `mix deps.get`.
3. `mix compile` (which includes deps compile when needed).
4. Start Phoenix (background).
5. Readiness probe.
6. `GET /` and log scan.
7. Playwright tests (if `--playwright` specified).

In this environment:

- Sentinel consistently fails at step 2–3 (Mix deps/compile) because `cowboy` cannot compile.
- Phoenix never starts; readiness probes and `GET /` never succeed.
- Playwright tests never run.

All sentinel and logpeek calls are bounded with `with-timeout.sh` and `--deadline` to honor the “no hanging” requirement. Failures are immediate and deterministic: the cowboy error is the blocker.

---

## 5. Constraints We Must Respect for a 1.0‑Quality Fix

Any solution must respect these hard constraints:

1. **No compiler/App coupling**
   - Compiler transforms cannot be made “aware” of todo‑app specifics.
   - No detection of literal names like `todo`, `toggle_todo`, `presenceSocket`, etc.

2. **No band‑aids**
   - No arbitrary limits just to “stop it from hanging”.
   - No “if it fails, skip this node” logic.
   - No `String.replace` post‑processing of generated Elixir as a fix.

3. **No editing generated `.ex`**
   - All behavior changes must go through:
     - Compiler (src/reflaxe/elixir/**),
     - Std Haxe code (`std/_std`, `std/*.cross.hx`),
     - Or documented canonical runtime `.ex` if such exist.

4. **No ad‑hoc hacks in `deps/` for 1.0**
   - We cannot rely on editing `deps/cowboy` or `deps/cowlib` as the fix — Hex will overwrite those changes and they are not maintainable.

5. **No new `Dynamic` usage**
   - Maintain typed surfaces in std and compiler; use `Dynamic` only at explicitly documented integration boundaries.

6. **File size and modularity**

   - No source file >2000 LOC.
   - Extract helpers and separate modules instead of stuffing more into large files.

7. **QA sentinel as verification**
   - For todo‑app (the 1.0 reference app), any claim of “fixed” must be supported by:
     - Bounded Haxe builds (pass A..F).
     - Successful `mix deps.get`, `mix deps.compile`, `mix compile`.
     - A green QA sentinel run (including Playwright specs) under caps.

8. **Environment/toolchain fixes are legitimate**
   - It *is* acceptable to:
     - Pin `plug_cowboy` / `cowboy` / `cowlib` versions in `mix.exs`.
     - Document supported Elixir/OTP + dep matrices.
     - Require CI/dev to use those versions.
   - Those changes are part of a proper 1.0 solution, not hacks.

---

## 6. Desired Outcome and What We Need from GPT‑5 Pro

### 6.1 Desired end state

On a clean environment that respects the project’s directives, we want:

- **Compiler 1.0:**
  - AST‑only pipeline.
  - Zero Haxe warnings for:
    - Core compiler/std builds,
    - `completion.hxml`,
    - Fast_boot LiveView snapshots,
    - Todo‑app Haxe server passes A..F.
  - Bounded transform and macro/HXX performance; no pathological passes on TodoLive or related modules.
  - No app‑specific compiler heuristics.

- **Todo‑app 1.0 E2E:**
  - Haxe server build A..F passes under strict `with-timeout.sh` caps.
  - `mix deps.get`, `mix deps.compile`, `mix compile` succeed under caps.
  - QA sentinel + Playwright flow completes with:
    - Phoenix booting.
    - Readiness probes passing.
    - `GET /` working.
    - All Playwright specs passing.

- **CI:**
  - Runs the **exact same** bounded sentinel + Playwright flow.
  - Treats any Haxe/Mix warnings or QA failures as hard failures.

### 6.2 What we need GPT‑5 Pro to do

Given this context, the main open problem is **toolchain compatibility** between:

- Elixir 1.18.3,
- OTP 27,
- `plug_cowboy 2.7.4`,
- `cowboy 2.14.2`,
- `cowlib 2.16.0`,
- and the way rebar3 compiles cowboy.

We need GPT‑5 Pro to:

1. **Analyze cowboy/cowlib compatibility with OTP 27:**
   - Determine whether `cowboy 2.14.2` + `cowlib 2.16.0` are officially supported on OTP 27.
   - If not ideal, propose a small, supported version matrix for:
     - `plug_cowboy`,
     - `cowboy`,
     - `cowlib`,
     - on Elixir 1.18.3 / OTP 27 (or advise on a slightly different OTP if absolutely necessary).

2. **Propose a concrete version matrix for 1.0:**
   - Example:
     - Elixir: 1.18.x
     - OTP: 27.x
     - plug_cowboy: X.Y.Z
     - cowboy: A.B.C
     - cowlib: C.D.E
   - Each version should be:
     - Current enough not to be a “dead” stack.
     - Verified to compile on OTP 27 without hacks to `deps/`.

3. **Provide exact `mix.exs` changes:**

   - Precise `deps` entries for `examples/todo-app/mix.exs`, including overrides if needed:

     ```elixir
     {:plug_cowboy, "~> 2.x", override: true}
     {:cowboy, "~> 2.y", override: true}
     {:cowlib, "~> 2.z", override: true}
     ```

   - Any other changes needed (e.g., removing old overrides or constraints).

4. **Provide a verification script for a real dev/CI machine:**

   - Step‑by‑step commands (all bounded by timeouts) to validate:

     ```bash
     # From repo root
     cd examples/todo-app
     rm -rf _build deps
     mix deps.get
     mix deps.compile
     mix compile

     # Haxe server passes A..F (bounded)
     env HAXE_USE_SERVER=0 haxe build-server-passA1.hxml
     # ...
     env HAXE_USE_SERVER=0 haxe build-server-passF.hxml

     # QA sentinel + Playwright
     scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --env e2e \
       --async --deadline 600 --playwright --e2e-spec e2e/*.spec.ts
     ```

   - With clear expectations:
     - All commands exit 0.
     - No warnings from Haxe or Mix attributable to our compiler/std/externs.
     - Sentinel logs show readiness + Playwright success.

5. **Advise how to fold this into PRD + CI:**

   - How to update:
     - `docs/prds/HAXE_ELIXIR_1_0_COMPILER_TODOAPP_PRD.md`,
     - `examples/todo-app/README.md` or architecture docs,
     - CI config (GitHub Actions or equivalent),
   - So that:
     - The toolchain matrix is clearly documented.
     - CI uses the correct Elixir/OTP and cowboy/cowlib versions.
     - The sentinel + Playwright flow is enforced in CI as the 1.0 gate.

This report captures what is already working, exactly where the problem lies (cowboy on OTP 27), the constraints we must uphold, and the desired end state. The key missing piece is an environment‑level, version‑matrix‑based plan for cowboy/cowlib that GPT‑5 Pro can help design. 

