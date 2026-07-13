<p align="center">
  <img src="assets/haxir-logo.png" alt="Haxir logo" width="170" />
</p>

<h1 align="center">Reflaxe.Elixir</h1>

<p align="center">
  <strong>Write typed Haxe. Ship reviewable Elixir.</strong><br />
  Bring Haxe to the BEAM, or add typed Haxe gradually to an existing Elixir app.
</p>

<p align="center">
  <a href="https://github.com/fullofcaffeine/reflaxe.elixir/releases"><img alt="Release" src="https://img.shields.io/github/v/release/fullofcaffeine/reflaxe.elixir" /></a>
  <a href="https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml/badge.svg" /></a>
  <a href="https://haxe.org"><img alt="Haxe 4.3.7" src="https://img.shields.io/badge/Haxe-4.3.7-orange" /></a>
  <a href="https://elixir-lang.org"><img alt="Elixir 1.14+" src="https://img.shields.io/badge/Elixir-1.14%2B-purple" /></a>
  <a href="LICENSE"><img alt="GPL-3.0 license" src="https://img.shields.io/badge/license-GPL--3.0-2563eb" /></a>
</p>

<p align="center">
  <a href="docs/01-getting-started/WHY_REFLAXE_ELIXIR.md">Why Reflaxe.Elixir?</a> ·
  <a href="#try-it">Try it</a> ·
  <a href="#phoenixhx">PhoenixHx</a> ·
  <a href="docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md">Gradual adoption</a> ·
  <a href="examples/README.md">Examples</a> ·
  <a href="docs/README.md">Docs</a>
</p>

**Reflaxe.Elixir** compiles typed Haxe into `.ex` source for the normal Mix and BEAM pipeline.
**PhoenixHx** adds typed Phoenix, LiveView, Ecto, and OTP authoring while Phoenix remains the runtime.

**For Elixir developers:** add static types, closed domain states, typed Phoenix boundaries, and
compile-time DSL checks one module or feature at a time. Generated and hand-written Elixir coexist
through ordinary module/function contracts.

**For Haxe developers:** use Haxe as the primary language for BEAM services and Phoenix applications
while keeping Mix, Hex packages, Elixir interop, OTP operations, and standard deployment. Functional,
Elixir-flavored Haxe maps closest to direct target code; covered portable and imperative forms keep
their behavior through explicit lowering. Haxe is a build dependency, not a second production VM.

> [!IMPORTANT]
> **Pre-1.0:** suitable for controlled pilots inside documented, pinned paths, not a general stability
> promise. See [Production Readiness](docs/06-guides/PRODUCTION_READINESS.md), the
> [independent 1.0 review](docs/08-roadmap/1.0-production-readiness-review.md),
> [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md), and
> [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).

## Why It Exists

- **Type the risky boundaries.** Check assigns, params, routes, results, schemas, changesets, child
  specs, and existing Elixir calls before generated code reaches Mix.
- **Adopt in either direction.** Add one typed island to an Elixir app, or author a larger bounded
  context in Haxe while Phoenix and the BEAM remain the platform.
- **Keep the output recognizable.** Prefer normal modules, functions, maps, tuples, pattern matches,
  `Enum`, Phoenix, Ecto, and OTP calls whenever Haxe semantics can be preserved.
- **Build typed project DSLs.** Use Haxe macros, metadata, algebraic enums, and structural types to
  remove duplicated strings and invalid framework combinations.
- **Share selected behavior.** Compile a deliberately portable domain layer to Elixir and JavaScript;
  target-specific Phoenix and browser code stays at the edges.
- **Keep normal operations.** Format, test, inspect, profile, and deploy the resulting Elixir with
  ordinary Mix and BEAM tools.

```text
Haxe / HXX -> Reflaxe.Elixir + PhoenixHx -> ordinary .ex / ~H -> Mix -> BEAM
```

Reflaxe.Elixir has one compiler pipeline and two authoring styles: **Typed Elixir-first** favors
BEAM/Phoenix-native APIs and direct output; **portable stdlib-first** prioritizes cross-target Haxe
semantics. They are source-design choices, not separate backends. See
[Authoring Styles](docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md).

## See The Output

These are checked excerpts from executable examples. The links contain the complete imports, types,
build files, and canonical generated output.

### Elixir-first Haxe stays direct

[`SearchDomain.hx`](examples/13-elixir-first-liveview/src_haxe/live/SearchDomain.hx) uses typed
Elixir APIs and Haxe's typed `Result`:

```haxe
var normalized = ElixirString.trim(query);
var needle = ElixirString.downcase(normalized);
var visible = Enum.filter(catalog,
  item -> item != null &&
    ElixirString.contains(ElixirString.downcase(item), needle));
return Ok({query: normalized, visible: visible, result_count: visible.length});
```

```elixir
normalized = String.trim(query)
needle = String.downcase(normalized)

visible =
  Enum.filter(catalog, fn item ->
    not Kernel.is_nil(item) and String.contains?(String.downcase(item), needle)
  end)

{:ok, %{query: normalized, visible: visible, result_count: length(visible)}}
```

The externs become direct `String` and `Enum` calls, `Result` becomes `{:ok, value}` / `{:error, reason}`,
and the structural record becomes a map. See the
[reviewed output](test/quality/handwritten-output/generated/elixir-first-liveview/elixir_first_liveview/search_domain.ex).

### Imperative Haxe can lower functionally

This portable [`Transcript.render`](examples/16-portable-chat-domain/src_haxe/shared/chat/Transcript.hx)
uses a normal Haxe loop and `Array.push`:

```haxe
var lines = [];
for (message in history) {
  lines.push(MessageRules.format(message));
}
return lines;
```

The compiler proves that it is a fresh, ordered, one-value projection and emits:

```elixir
Enum.map(history, fn message ->
  PortableChatDomain.MessageRules.format(message)
end)
```

More complex mutation uses explicit immutable rebinding or reducers so behavior is preserved. See
[Imperative to Functional Lowering](docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md) and the
[reviewed output](test/quality/handwritten-output/generated/portable-chat-domain/portable_chat_domain/transcript.ex).

## PhoenixHx

PhoenixHx is a build-time typed authoring layer, not a replacement web runtime. LiveViews use typed
`Socket<TAssigns>` and callback result types. Haxe parses inline HXX and type-checks assigns and
embedded expressions before emitting Phoenix `~H`; strict options also check registered components,
slots, hooks, and events. This excerpt is from the checked
[`SearchLive`](examples/13-elixir-first-liveview/src_haxe/live/SearchLive.hx):

```haxe
return <p data-testid="result-count">
  ${assigns.result_count} result(s)
</p>;
```

```elixir
~H"""
<p data-testid="result-count">
  {@result_count} result(s)
</p>
"""
```

Phoenix still compiles the resulting HEEx, and there is no separate template runtime. The same example's typed
[`final routes` DSL](examples/13-elixir-first-liveview/src_haxe/ElixirFirstLiveviewRouter.hx) emits a
normal [`Phoenix.Router`](examples/13-elixir-first-liveview/lib/elixir_first_liveview_web/router.ex),
including pipelines, scopes, and `live_session`. See [Phoenix Integration](docs/02-user-guide/PHOENIX_INTEGRATION.md)
and the complete
[`SearchLive` output](test/quality/handwritten-output/generated/elixir-first-liveview/elixir_first_liveview_web/search_live.ex).

## Native First, Compatibility When Required

The compiler tries, in order: proven native lowering such as `Int` operators and `Enum.map`; direct
typed Elixir/Phoenix/Ecto/OTP APIs; Haxe stdlib overrides backed by `String`, `Map`, `:crypto`, and
other BEAM primitives; then explicit compatibility lowering or small helpers when semantics differ.
Special floats, unresolved numeric values, and arbitrary Haxe `throw` values are examples of the last case.

Correctness wins when source and target semantics differ. Today the two core helper modules are kept
in generated builds even when a particular application has no call site for one of them; generated
calls remain selective, but module inclusion is not yet fully demand-driven. This is tracked footprint
work, not an application mode. Normal applications do not use `-D reflaxe_runtime`; see
[`reflaxe_runtime` And Generated Helpers](docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md).

## Start Where It Pays

| Goal | Start here |
| --- | --- |
| Compile the smallest Haxe modules | [`01-simple-modules`](examples/01-simple-modules/) |
| Bring a Haxe service or library to the BEAM | [`02-mix-project`](examples/02-mix-project/) |
| Add one feature to an existing Phoenix app | [Gradual Adoption Tutorial](docs/06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md) |
| Author typed LiveViews or call hand-written Elixir | [`13-elixir-first-liveview`](examples/13-elixir-first-liveview/) |
| Share selected browser/server domain logic | [`16-portable-chat-domain`](examples/16-portable-chat-domain/) |
| Explore the full reference app | [`todo-app`](examples/todo-app/) |
| Install a verified release package | [Installation](docs/01-getting-started/installation.md) |

No all-at-once rewrite is required.

## Reflaxe.Elixir And Gleam

Reflaxe.Elixir fits best when generated Elixir, Phoenix integration, gradual adoption, Haxe macros,
or existing Haxe/JavaScript sharing matter. Gleam favors a smaller immutable language and mature 1.x
ecosystem. Read the [honest comparison](docs/01-getting-started/WHY_REFLAXE_ELIXIR.md#reflaxeelixir-and-gleam).

## Try It

```bash
git clone https://github.com/fullofcaffeine/reflaxe.elixir.git
cd reflaxe.elixir
npm install
npm run test:quick
```

For application use, install and checksum a pinned release ZIP rather than depending on a source
checkout. Continue with [Installation](docs/01-getting-started/installation.md) and
[Start Here](docs/01-getting-started/START_HERE.md).

## Evidence And Maturity

CI covers full codegen snapshots and negative cases, Haxe-authored ExUnit semantics, selected upstream
stdlib fixtures, strict generated-Elixir compilation, runtime examples, source/package parity,
reproducible release artifacts, and Phoenix browser smoke.

That evidence supports the documented subset, not arbitrary Haxe programs. The 1.0 gate currently
tracks known semantic defects, complete Mix invalidation, fail-closed generated-file ownership, OTP
lifecycle scope, licensing, a frozen support contract, and external install/upgrade/rollback evidence.

## Explore

| Topic | Guide |
| --- | --- |
| Product thesis and tradeoffs | [Why Reflaxe.Elixir?](docs/01-getting-started/WHY_REFLAXE_ELIXIR.md) |
| Setup and first application | [Start Here](docs/01-getting-started/START_HERE.md) |
| Elixir-friendly Haxe | [Writing Idiomatic Haxe](docs/02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md) |
| Portable vs Elixir-first source design | [Authoring Styles](docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md) |
| Native lowering and compatibility helpers | [`reflaxe_runtime` And Generated Helpers](docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md) |
| Phoenix, LiveView, Ecto, and API references | [Documentation Index](docs/README.md) |
| Supported versions and sharp edges | [Support Matrix](docs/06-guides/SUPPORT_MATRIX.md) |
| Contributor architecture and tests | [Contributing](docs/10-contributing/contributing.md) |

## Development

```bash
npm test
```

Compiler changes must preserve source/package behavior, runtime semantics, generated-output quality,
examples, and browser QA. See [Testing Infrastructure](docs/03-compiler-development/TESTING_INFRASTRUCTURE.md).

## License

[GPL-3.0](LICENSE). Generated applications can include support code from this repository; review
[Licensing & Distribution](docs/06-guides/LICENSING_AND_DISTRIBUTION.md) before commercial distribution.
