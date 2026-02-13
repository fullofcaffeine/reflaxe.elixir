# 13 - Elixir-First LiveView (Typed Haxe)

This example shows a **typed Elixir-first** authoring style: use Haxe as a typed host language while leaning on Phoenix/Elixir extern APIs directly.

## What this example demonstrates

- `@:liveview` module authored in Haxe, compiled to idiomatic Phoenix LiveView callbacks.
- Typed boundary decoding from `Term` using `elixir.Kernel` type guards.
- Domain flow modeled with `haxe.functional.Result` (`Ok`/`Error`).
- Search logic implemented with Elixir extern surfaces (`elixir.Enum`, `elixir.ElixirString`).

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
mix compile
mix test
mix phx.server
```

Open `http://localhost:4000/`.

## Haxe source map

- `examples/13-elixir-first-liveview/src_haxe/ElixirFirstLiveview.hx` - OTP application entrypoint
- `examples/13-elixir-first-liveview/src_haxe/ElixirFirstLiveviewRouter.hx` - typed router with `HttpMethod.LIVE`
- `examples/13-elixir-first-liveview/src_haxe/live/SearchLive.hx` - LiveView callbacks and render
- `examples/13-elixir-first-liveview/src_haxe/live/SearchDomain.hx` - pure domain logic
- `examples/13-elixir-first-liveview/test_haxe/live/SearchDomainTest.hx` - Haxe-authored ExUnit tests

## Style notes (almost no stdlib)

This example keeps app logic close to Elixir/Phoenix APIs:

- Prefer `elixir.*` / `phoenix.*` surfaces at integration boundaries.
- Keep boundary terms explicit and decode early.
- Use `Result` for explicit success/error flow.

It still uses basic Haxe language constructs (types, enums/results, functions), but avoids portability-first patterns where a BEAM-native API is clearer.
