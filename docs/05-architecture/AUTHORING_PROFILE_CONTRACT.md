# Authoring Profile Contract

Reflaxe.Elixir uses one compiler pipeline for all application code:

```text
Haxe TypedExpr -> ElixirAST -> transformer passes -> Elixir source
```

Portable and Elixir-first are **authoring profiles**, not separate compiler
backends. They describe the source style a module chooses and the tradeoff the
compiler should respect when Haxe portability and BEAM-native shape conflict.

## Contract

| Profile | Source priority | Output priority |
| --- | --- | --- |
| Portable stdlib-first | Preserve Haxe stdlib semantics and cross-target reuse. | Generate idiomatic Elixir whenever doing so does not change Haxe behavior. |
| Typed Elixir-first | Model BEAM/Phoenix/Ecto/OTP concepts directly through typed externs and DSLs. | Generate Elixir that looks close to handwritten framework code. |

Both profiles aim for idiomatic Elixir. Portable code is not an unidiomatic mode;
it simply gives Haxe semantics first claim when there is a real semantic gap.

## Why `metal` is not an application profile

Rust and Go targets may need a project-level "metal" lane because their users
often want explicit control over low-level ownership, allocation, or runtime
binding choices.

Reflaxe.Elixir is different:

- BEAM values are immutable, so mutation-like Haxe code must be lowered through
  explicit rebinding no matter which profile authored it.
- Phoenix/Ecto/OTP integration is better represented with typed Elixir-first
  externs than with raw target syntax.
- Raw HEEx or Elixir injection is a local escape hatch, not a whole-application
  identity.

For this target, `metal` means a local low-level escape hatch such as
`@:hxx_mode("metal")`, `@:allow_heex`, or carefully reviewed compiler/stdlib
`__elixir__()` internals. It does not select a different backend.

## Current implementation model

The current model intentionally avoids `-D reflaxe_elixir_profile=...` as a
code-generation switch.

Profile intent is expressed by normal code shape:

- Portable modules mostly use Haxe stdlib/domain APIs and keep target-specific
  imports at thin boundaries.
- Elixir-first modules import `phoenix.*`, `ecto.*`, `elixir.*`, and typed app
  externs where those surfaces match the BEAM boundary.
- Strictness remains orthogonal through `-D reflaxe_elixir_strict`, HXX strict
  flags, and explicit escape-hatch metadata.

This is enough for mixed apps, where portable domain modules and Elixir-first
Phoenix modules usually live in the same HXML build.

## Future profile declarations

If profile metadata or defines are added later, they should be advisory lint
inputs only. They should answer "what warnings should I get?" rather than
"which compiler backend should run?"

Possible future checks:

- Warn when a declared portable module imports `phoenix.*`, `ecto.*`, `elixir.*`,
  or raw target syntax outside an explicit boundary module.
- Warn when a declared Elixir-first module uses a Haxe pattern that forces bulky
  compatibility lowering where a typed BEAM boundary would be clearer.
- Keep both warnings semantics-preserving: never silently change generated code
  because a profile declaration is present.

## Compatibility risks

- A project-wide profile define is too coarse for normal Phoenix apps because
  those apps often mix portable domain code with Elixir-first framework edges.
- Treating `metal` as an application profile would make HXX template escape
  hatches look like a target-wide programming model.
- Making profile declarations affect code generation would create two semantic
  backends and make CI harder to reason about.
- Portable stdlib features such as Haxe special floats, Haxe serialization, and
  mutable-looking iterator code may require helper modules or heavier lowering.
  That is acceptable when it preserves the Haxe contract.

## CI matrix

The CI model should validate the axes directly instead of introducing profile
jobs:

- Portable runtime behavior: upstream Haxe unitstd specs compiled through the
  Haxe-authored ExUnit lane.
- Elixir-first framework behavior: Phoenix/Ecto/OTP examples, strict example
  compilation, Haxe-authored ExUnit integration tests, and todo-app QA sentinel.
- Generated-shape behavior: snapshot suites for core, stdlib, regression,
  Phoenix, LiveView, Ecto, OTP, ExUnit, and bootstrap categories.
- Escape-hatch safety: HXX strict-mode tests and annotation diagnostics for raw
  HEEx / metal-mode usage.

## Implementation phases

1. Keep the current source-shape model as the default compiler contract.
2. Keep docs and examples explicit about portable vs Elixir-first module
   organization.
3. Add advisory lint metadata only after a real app demonstrates that warnings
   would prevent bugs without creating noise.
4. If lint metadata lands, test it as diagnostics only. Do not use it to select
   a different code-generation engine.

## Related docs

- `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md`
- `docs/04-api-reference/FEATURE_FLAGS.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/02-user-guide/INLINE_MARKUP.md`
- `docs/05-architecture/HAXE_FLOAT_SPECIAL_VALUES.md`
