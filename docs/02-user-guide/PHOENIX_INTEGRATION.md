# Phoenix Integration (User Guide)

Reflaxe.Elixir is designed to let you use **Phoenix conventions and APIs** while gaining Haxe’s compile-time type safety. You can adopt it in two ways:

1. **Greenfield** — new Phoenix apps where you author many modules in Haxe.
2. **Gradual adoption** — existing Phoenix apps where you move one module at a time.

For step-by-step setup, start here:

- New app: `docs/06-guides/PHOENIX_NEW_APP.md`
- Existing app: `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`

## Key Principles

- **Phoenix-first**: generated Elixir should look and behave like normal Phoenix code.
- **Typed interfaces**: use typed Haxe externs to call Phoenix/Ecto/Elixir code.
- **No app-specific hacks**: the compiler should not “know about” your app’s domain.
- **Avoid `__elixir__()` in apps**: if an escape hatch is needed, prefer a reusable helper in `std/phoenix/**` (typed extern/shim) instead of per-app injections.

## What You Typically Write in Haxe

You can author any of these in Haxe (incrementally, if desired):

- LiveView modules (`@:liveview`)
- Controllers (`@:controller`)
- Router DSL (`@:router`)
- Ecto schemas/queries/migrations (`@:schema`, query helpers, migrations)
- OTP (GenServers/Supervisors) where it makes sense
- Pure business/domain logic modules (`@:module`)

See working references:

- Minimal Phoenix: `examples/03-phoenix-app/`
- End-to-end LiveView + Ecto: `examples/todo-app/`

## Naming & Module Mapping

Use `@:native("MyAppWeb.SomeModule")` to select the Elixir module name the Haxe class compiles to. This is the primary mechanism for Phoenix-friendly naming.

Example:

```haxe
@:native("MyAppWeb.TodoLive")
@:liveview
class TodoLive {
  // mount/3, handle_event/3, handle_info/2, render/1, etc.
}
```

## Gradual Adoption Pattern (recommended)

If you have an existing Phoenix app, start by generating modules into a separate namespace and call them from Elixir:

- Compile Haxe to `lib/my_app_hx/**`
- Generate modules under `MyAppHx.*` first
- Call from Elixir (`MyAppHx.SomeModule.some_fun(...)`)
- Later, when ready, you can `@:native` into `MyApp.*` / `MyAppWeb.*` and switch routing/delegation

This avoids “big bang” rewrites and keeps diffs easy to review.

## Tooling (Mix)

If your Phoenix app includes `{:reflaxe_elixir, ...}` as a dev/test dependency, you get:

- `mix compile.haxe`
- `mix haxe.watch`
- `mix haxe.errors`
- `mix haxe.source_map`

See: `docs/04-api-reference/MIX_TASKS.md`.

## Deployment

Haxe is required at **build time**, not runtime.

- Production checklist + CI/Docker notes: `docs/06-guides/PRODUCTION_DEPLOYMENT.md`
