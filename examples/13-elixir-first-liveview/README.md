# 13 - Elixir-First LiveView (Typed Haxe)

This example shows a **typed Elixir-first** authoring style: use Haxe as a typed host language while leaning on Phoenix/Elixir extern APIs directly.

## What this example demonstrates

- `@:liveview` module authored in Haxe, compiled to idiomatic Phoenix LiveView callbacks.
- Typed boundary decoding from `Term` using `elixir.Kernel` type guards.
- Domain flow modeled with `haxe.functional.Result` (`Ok`/`Error`).
- Search logic implemented with Elixir extern surfaces (`elixir.Enum`, `elixir.ElixirString`).
- LiveView browser boot compiled from Haxe (Genes) with a Phoenix-style JS wrapper.

## Strict mode used here

`build.hxml` enables:

- `-D reflaxe_elixir_strict`

This is the **user-facing strict mode**. It rejects `untyped`, explicit `Dynamic`, and ad-hoc app externs in project-local sources.

This example intentionally does **not** use `-D reflaxe_elixir_strict_examples`.
That flag is a repository policy guard for shipped examples, while `reflaxe_elixir_strict` is what real projects should rely on.

## Run

```bash
cd examples/13-elixir-first-liveview
mix deps.get
mix deps.compile
mix assets.build
mix compile
mix test
mix phx.server
```

Open `http://localhost:4000/`.

## Haxe source map

- `examples/13-elixir-first-liveview/src_haxe/ElixirFirstLiveview.hx` - OTP application entrypoint
- `examples/13-elixir-first-liveview/src_haxe/ElixirFirstLiveviewRouter.hx` - typed router via module-level `final routes`
- `examples/13-elixir-first-liveview/src_haxe/live/SearchLive.hx` - LiveView callbacks and render
- `examples/13-elixir-first-liveview/src_haxe/live/SearchDomain.hx` - pure domain logic
- `examples/13-elixir-first-liveview/src_haxe/client/Boot.hx` - Genes-compiled LiveSocket bootstrap
- `examples/13-elixir-first-liveview/test_haxe/web/SearchLiveIntegrationTest.hx` - Haxe-authored Phoenix LiveView integration tests
- `examples/13-elixir-first-liveview/test_haxe/live/SearchDomainTest.hx` - Haxe-authored ExUnit tests

## Haxe + Mix test integration

- `mix test` runs the alias `haxe.compile.tests`, which executes `haxe build-tests.hxml`.
- `build-tests.hxml` compiles Haxe ExUnit modules into `test/generated/**/*.exs`.
- `test/test_helper.exs` auto-requires those generated `*_test.exs` files before ExUnit runs.

## Haxe + Genes client integration

- `build-client.hxml` compiles `client.Boot` into `assets/js/_hx_app_tmp.js`.
- Mix alias `haxe.compile.client` promotes output to `assets/js/hx_app.js` for stable esbuild imports.
- `assets/js/phoenix_app.js` stays close to Phoenix defaults and imports `./app.js` (which imports `hx_app.js`).
- Layouts load `/assets/phoenix_app.js` using `phx-track-static`.

## Style notes (almost no stdlib)

This example keeps app logic close to Elixir/Phoenix APIs:

- Prefer `elixir.*` / `phoenix.*` surfaces at integration boundaries.
- Keep boundary terms explicit and decode early.
- Use `Result` for explicit success/error flow.

It still uses basic Haxe language constructs (types, enums/results, functions), but avoids portability-first patterns where a BEAM-native API is clearer.
