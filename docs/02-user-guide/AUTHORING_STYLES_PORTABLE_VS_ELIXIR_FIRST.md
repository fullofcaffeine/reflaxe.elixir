# Authoring Styles: Portable vs Elixir-First

Reflaxe.Elixir supports two valid ways to author Haxe for the BEAM:

1. **Portable stdlib-first**
2. **Typed Elixir-first**

Both are supported **today**.

## One pipeline, two styles

Reflaxe.Elixir has one semantics-preserving compilation pipeline (TypedExpr -> ElixirAST -> passes -> printer).

These are **authoring styles**, not separate backends.

- You do not switch to a separate “portable mode compiler”.
- You do not switch to a separate “metal mode compiler”.
- You choose how much of your app surface is portability-oriented vs BEAM-native extern-oriented.

See also: `docs/04-api-reference/FEATURE_FLAGS.md`.

## Style A: Portable stdlib-first

Use this when you want maximum cross-target reuse.

Typical characteristics:

- Domain logic uses Haxe stdlib types/APIs.
- Target-specific integrations stay at small boundaries.
- You can often reuse the same domain modules on JS/other targets.

Start here:

- `docs/02-user-guide/PORTING_STDLIB_CODE_JS_TO_ELIXIR.md`
- `docs/06-guides/PORTABLE_CHAT_TUTORIAL.md`
- `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`

## Style B: Typed Elixir-first

Use this when your app is primarily Phoenix/Ecto/OTP and you want BEAM-native shapes in your Haxe source.

Typical characteristics:

- Prefer `phoenix.*`, `ecto.*`, and `elixir.*` extern surfaces.
- Decode `Term` at boundaries early.
- Keep success/error flow explicit with `haxe.functional.Result`.
- Minimize portability constraints in integration-heavy modules.

Start here:

- `examples/13-elixir-first-liveview/README.md`
- `docs/06-guides/STRICT_MODE.md`
- `docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md`

## Strictness profiles

### `-D reflaxe_elixir_strict` (user-facing)

Use this in real projects for Gleam-like guardrails in app code. It rejects:

- `untyped` (including `untyped __elixir__()`)
- explicit `Dynamic`
- ad-hoc app extern classes (except allowed boundary annotations)

### `-D reflaxe_elixir_strict_examples` (repo policy)

This is a repository policy guard for shipped examples.
It keeps examples Haxe-first by rejecting escape-hatch usage in `examples/*/src_haxe/**`.

If you are building an app, prefer `reflaxe_elixir_strict`.

## “Almost no stdlib” Elixir-first rules

When intentionally writing typed Elixir-first code:

- Prefer Elixir/Phoenix/Ecto extern APIs at integration boundaries.
- Keep `Term` boundaries explicit and decode immediately.
- Use `Result`/`Option` for explicit error/absence handling.
- Avoid app-level `untyped __elixir__()` and `Dynamic`.
- Keep portability-first abstractions for pure domain modules only when they add clear value.

## Performance: what to claim safely

It is reasonable to expect that Elixir-first authoring can reduce some lowering complexity for specific code paths.

Do not claim blanket speedups without measurement.

Use:

```bash
haxe build.hxml --times
haxe build.hxml -D macro-times --times
```

For repo-level guidance:

- `docs/06-guides/PERFORMANCE_GUIDE.md`

## Choosing a style per module (recommended)

Most production apps benefit from mixing styles by layer:

- **Domain core**: portable stdlib-first when reuse matters.
- **Phoenix/Ecto/OTP edges**: typed Elixir-first.

This keeps reuse where it pays off, while keeping framework-heavy code idiomatic and explicit.
