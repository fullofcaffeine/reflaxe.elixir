# Todo-App Cowboy/OTP Toolchain Notes

The todo-app (`examples/todo-app`) pins parts of the Cowboy stack to keep the example
bootable and CI-friendly on the supported Elixir/OTP matrix.

## Why there are overrides in `examples/todo-app/mix.exs`

The todo-app depends on Phoenix (HTTP server via Cowboy). Under some environments (notably
when using isolated `MIX_BUILD_ROOT` build roots), the Erlang dependency toolchain can
fail to resolve `-include_lib("cowlib/include/*.hrl")` during `mix deps.compile cowboy`,
even though `cowlib` is present.

To keep the reference app reliable:

- `examples/todo-app/mix.exs` pins:
  - `plug_cowboy`
  - `cowboy`
  - `cowlib`
  - `ranch`

## QA Sentinel mitigation (CI + bounded local runs)

The QA sentinel (`scripts/qa-sentinel.sh`) runs the todo-app in an isolated build root for
non-blocking validation. To avoid `rebar3` include path races and toolchain quirks, the
sentinel:

- Compiles deps in the default `_build/` root, then mirrors them into the per-run build root.
- Creates a minimal `deps/cowlib/rebar.config` when missing to ensure `include/` is on the
  Erlang include path during compilation.

If you hit Cowboy/cowlib compilation issues locally, the most reliable reproduction/diagnosis
path is running the sentinel (bounded, non-blocking) rather than starting `mix phx.server`
directly:

```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4011 --playwright --async --deadline 900 -v
```

## Historical note

Prior investigation notes were previously stored under `docs/09-history/` but are now kept in
git history to keep the working tree focused and current.

