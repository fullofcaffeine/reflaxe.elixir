# Phoenix (Existing App) — Gradual Adoption Guide

This guide shows how to integrate Reflaxe.Elixir into an **existing** Phoenix app so you can gradually move modules to Haxe while keeping the rest of your codebase in Elixir.

The core idea: **compile Haxe modules into their own Elixir namespace** first (`MyAppHx.*`), call them from Elixir, and only later replace/rename modules when you’re ready.

Important: this “Haxe namespace” is controlled by your Haxe packages + `-D elixir_output` (for example `src_haxe/my_app_hx/*` → `lib/my_app_hx/*` → `MyAppHx.*`).
`-D app_name` should still match your Phoenix app module (for example `-D app_name=MyApp`) so Phoenix/Ecto integrations can derive framework modules correctly.

When you are ready for app-native output, `-D elixir_output=lib` is fine: that
is normal Phoenix in-place mode. The generated module names and paths should then
look like handwritten Phoenix code (`MyApp.*` / `MyAppWeb.*` under
`lib/my_app/**` / `lib/my_app_web/**`), not like Haxe source buckets mirrored to
`lib/server/**` or `lib/shared/**`. See the
[Phoenix Output Model](../05-architecture/PHOENIX_OUTPUT_MODEL.md).

For a concrete copy-paste walkthrough with a domain module, an Elixir call path, a Haxe-authored LiveView, and tests, start with `docs/06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md`.

## What You Need

- Elixir 1.14+
- Node.js 16+
- Haxe 4.3.7+ (installed on your PATH)

## 1) Add `lix` and the Haxe libraries

From your Phoenix project root:

```bash
npm init -y
npm install --save-dev lix
npx lix scope create
```

Install Reflaxe.Elixir as a Haxe library:

```bash
# If this fails (no `curl` / GitHub rate limit), pick a tag from the Releases page and set it manually.
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
npx lix install "github:fullofcaffeine/reflaxe.elixir#${REFLAXE_ELIXIR_TAG}"
npx lix download
```

Notes:
- Prefer `haxe ...` (your local Haxe toolchain).
- If `haxe` is not on your PATH, use the repo shim: `./node_modules/.bin/haxe ...` (provided by `lix` + `.haxerc`).

## 2) Add `src_haxe/` and a `build.hxml`

### Option A (recommended): scaffold via Mix

If you already added the Mix dependency from **Step 4** (so the tasks are available), you can scaffold the boilerplate:

```bash
# Minimal scaffold (gradual adoption)
mix haxe.gen.project --force

# Phoenix-friendly scaffold (typed LiveView example + HXX)
mix haxe.gen.project --phoenix --basic-modules --force
```

This writes `src_haxe/<app>_hx/**`, `build.hxml`, `package.json` + `.haxerc` (unless `--skip-npm`), updates `mix.exs`,
and adds the generated output dir to `.gitignore`.

If you pass `--phoenix`, it also scaffolds an esbuild-friendly Haxe client JS build:

- Adds `build-client.hxml` (Genes) that outputs to `assets/js/_hx_app_tmp.js`
- Ensures a stable import path at `assets/js/hx_app.js` (published via promotion)
- Patches `assets/js/app.js` so `LiveSocket` merges hooks from `window.Hooks`
- Adds a dev watcher using `mix haxe.watch --promote ...` to avoid transient esbuild `--watch` resolution errors
- Adds `.gitignore` entries for `assets/js/_hx_app_tmp.js*` and `assets/js/hx_app.js*` so client build artifacts don’t churn diffs

If you want to apply only the Phoenix client JS wiring (without the rest of the project scaffolding), use:

```bash
mix haxe.phoenix.scaffold
```

If you use this option, you can skip to **Step 5**.

#### Which Generator Should I Use?

There are two “scaffolding” entrypoints because they solve two different user stories:

- **Existing Elixir/Phoenix app (in-place)**: Use Mix tasks.
  - `mix haxe.gen.project` adds server-side plumbing (`build.hxml`, `src_haxe/**`, `mix.exs` compiler config).
  - `mix haxe.phoenix.scaffold` adds client-side plumbing for LiveView hooks (Genes + esbuild watch safety).
- **Greenfield app (create a new project folder)**: Use the Haxe project generator (`haxe --run Run create ...`).
  - It shells out to the canonical Phoenix Mix generator (`mix phx.new`) to create a real Phoenix app,
    then layers the same Haxe integration on top.

Both flows converge on the same Phoenix client scaffolding behavior: `mix haxe.phoenix.scaffold`.

#### Fail-Fast vs Warn-Only

`mix haxe.phoenix.scaffold` is **strict by default**:

- If it cannot find the expected Phoenix shapes (for example a `watchers:` list in `config/dev.exs`, or a recognizable `LiveSocket` hooks shape in `assets/js/app.js`), it raises.
- This avoids silently generating “half wired” projects that only fail later in confusing ways.

If you have a heavily customized Phoenix template and want the task to do a best-effort patch, use:

```bash
mix haxe.phoenix.scaffold --warn-only
```

This emits loud warnings and skips patches it cannot apply safely.

### Option B: manual setup

Create:

```
src_haxe/
build.hxml
```

Minimal `build.hxml` (server-side Haxe→Elixir):

```hxml
-lib reflaxe.elixir
-cp src_haxe

-D reflaxe_runtime
-D no-utf16

# Keep generated Elixir isolated during gradual adoption
-D elixir_output=lib/my_app_hx

# Application module prefix
-D app_name=MyApp
-dce full

# Entrypoint Haxe class (package.ClassName). Adjust to your app:
--main my_app_hx.Main
```

Notes:
- When you use `-lib reflaxe.elixir`, the library already runs `--macro reflaxe.elixir.CompilerInit.Start()` for you.
- If you vendor the compiler sources manually (no `-lib`), then you must add the `--macro ...Start()` line yourself.

Why `elixir_output=lib/my_app_hx`?
- It keeps generated Elixir isolated during gradual adoption (`lib/my_app_hx/**` by default).
- It avoids accidentally generating into your existing `lib/my_app/**` namespace.

## 3) Add a first Haxe module (called from Elixir)

Create `src_haxe/my_app_hx/Main.hx`:

```haxe
package my_app_hx;

@:module
class Main {
  public static function main(): Void {}
}
```

Then create `src_haxe/my_app_hx/Greeter.hx`:

```haxe
package my_app_hx;

@:module
class Greeter {
  public static function hello(name: String): String {
    return 'Hello, ${name}!';
  }
}
```

Compile:

```bash
haxe build.hxml
```

Now call it from Elixir (anywhere in your Phoenix app):

```elixir
MyAppHx.Greeter.hello("Phoenix")
```

## 4) Integrate with Mix (so `mix compile` compiles Haxe)

Add Reflaxe.Elixir as a dev/test dependency so your project has the Mix tasks:

```elixir
# mix.exs
defp deps do
  [
    # Compiler + Mix tasks (build-time only)
    # Replace <RELEASE_TAG> with the tag you installed via lix (see Step 1)
    {:reflaxe_elixir, github: "fullofcaffeine/reflaxe.elixir", tag: "<RELEASE_TAG>", runtime: false}
  ]
end
```

If you *only* want the compiler dependency in dev/test, you can add `only: [:dev, :test]` — but then you must
compile Haxe output before building a production release (so CI/build still has the generated `.ex` files).

Then add the Haxe compiler to your compilers list:

```elixir
# mix.exs
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      hxml_file: "build.hxml",
      source_dir: "src_haxe",
      target_dir: "lib/my_app_hx",
      watch: Mix.env() == :dev
    ]
  ]
end
```

Now:

```bash
mix deps.get
mix compile
```

Useful commands:

```bash
mix compile.haxe --force
mix haxe.errors
mix haxe.source_map --list-maps
```

Full reference: `docs/04-api-reference/MIX_TASKS.md`.

## 5) Gradually move Phoenix modules (Controllers / LiveViews)

You can author Phoenix-facing modules in Haxe and wire them into your existing Elixir router.

For LiveView, the important part is the **public surface** (function names/arity + assigns shape). In Haxe you typically generate:

- `mount/3`
- `handle_event/3`
- `handle_info/2`
- `render/1`

Then route to the generated module from your Elixir router, for example:

```elixir
live "/counter", MyAppWeb.CounterLive
```

See a production-grade example authored in Haxe:

- `examples/todo-app/src_haxe/server/live/TodoLive.hx`

## 6) Calling existing Elixir code from Haxe (typed externs)

Use `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md` as the canonical workflow. This section is the quick-start version.

When you want to call a hand-written Elixir module from Haxe, define a typed extern:

```haxe
@:native("MyApp.SomeElixirModule")
extern class SomeElixirModule {
  static function do_work(input: String): String;
}
```

Avoid `__elixir__()` in application code. If a Phoenix-specific helper is missing, prefer adding it to `std/phoenix/**` (typed extern/shim) and reusing it across apps.

For strict-mode behavior and escape-hatch tradeoffs, continue in `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`.

## 7) Deployment (build-time compilation)

Haxe is needed at **build time**, not at runtime.

Use `docs/06-guides/PRODUCTION_DEPLOYMENT.md` for a production checklist and suggested CI/Docker patterns.
