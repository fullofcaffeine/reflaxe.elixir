# Phoenix (Existing App) — Gradual Adoption Guide

This guide shows how to integrate Reflaxe.Elixir into an **existing** Phoenix app so you can gradually move modules to Haxe while keeping the rest of your codebase in Elixir.

The core idea: **compile Haxe modules into their own Elixir namespace** first (`MyAppHx.*`), call them from Elixir, and only later replace/rename modules when you’re ready.

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
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.1.0
npx lix download
```

Notes:
- Prefer `haxe ...` (your local Haxe toolchain) or `npx lix run haxe ...` if `haxe` is not on your PATH.
- Avoid `npx haxe ...` (the npm package) — it may not work on macOS arm64.

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

If you use this option, you can skip to **Step 5**.

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

# Application module prefix (prevents collisions with Elixir built-ins like `Application`)
-D app_name=MyAppHx
-dce full

# Define a stable entrypoint:
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
    {:reflaxe_elixir, github: "fullofcaffeine/reflaxe.elixir", tag: "v1.1.0", runtime: false}
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

When you want to call a hand-written Elixir module from Haxe, define a typed extern:

```haxe
@:native("MyApp.SomeElixirModule")
extern class SomeElixirModule {
  static function do_work(input: String): String;
}
```

Avoid `__elixir__()` in application code. If a Phoenix-specific helper is missing, prefer adding it to `std/phoenix/**` (typed extern/shim) and reusing it across apps.

## 7) Deployment (build-time compilation)

Haxe is needed at **build time**, not at runtime.

Use `docs/06-guides/PRODUCTION_DEPLOYMENT.md` for a production checklist and suggested CI/Docker patterns.
