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
  <a href="docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md">Gradual adoption</a> ·
  <a href="examples/README.md">Examples</a> ·
  <a href="docs/README.md">Docs</a>
</p>

Reflaxe.Elixir compiles typed Haxe into `.ex` source for the normal Mix and BEAM pipeline.

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
- **Keep the output recognizable.** Emit normal modules, functions, maps, tuples, pattern matches,
  `Enum`, Phoenix, Ecto, and OTP calls when semantics allow.
- **Build typed project DSLs.** Use Haxe macros, metadata, algebraic enums, and structural types to
  remove duplicated strings and invalid framework combinations.
- **Share selected behavior.** Compile a deliberately portable domain layer to Elixir and JavaScript;
  target-specific Phoenix and browser code stays at the edges.
- **Keep normal operations.** Format, test, inspect, profile, and deploy the resulting Elixir with
  ordinary Mix and BEAM tools.

```text
Haxe source -> Haxe typer/macros -> Reflaxe.Elixir -> .ex -> Mix -> BEAM
```

Reflaxe.Elixir has one compiler pipeline and two authoring styles: **Typed Elixir-first** favors
BEAM/Phoenix-native APIs and direct output; **portable stdlib-first** prioritizes cross-target Haxe
semantics. They are source-design choices, not separate backends. See
[Authoring Styles](docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md).

## See The Output

This pair is checked by [`01-simple-modules`](examples/01-simple-modules/).

```haxe
@:module
class BasicModule {
  public static function calculate(x:Int, y:Int, operation:String):Int {
    return switch (operation) {
      case "add": x + y;
      case "subtract": x - y;
      case "multiply": x * y;
      case "divide": y != 0 ? Std.int(x / y) : 0;
      case _: 0;
    };
  }
}
```

```elixir
defmodule BasicModule do
  def calculate(x, y, operation) do
    case operation do
      "add" -> x + y
      "subtract" -> x - y
      "multiply" -> x * y
      "divide" when y != 0 -> div(x, y)
      "divide" -> 0
      _ -> 0
    end
  end
end
```

Correctness wins when Haxe and Elixir semantics differ. Required helpers remain visible, centralized,
and tested instead of being disguised as native syntax.

## Start Where It Pays

| Goal | Start here |
| --- | --- |
| Compile the smallest Haxe modules | [`01-simple-modules`](examples/01-simple-modules/) |
| Bring a Haxe service or library to the BEAM | [`02-mix-project`](examples/02-mix-project/) |
| Add one feature to an existing Phoenix app | [Gradual Adoption Tutorial](docs/06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md) |
| Call hand-written Elixir from typed Haxe | [`13-elixir-first-liveview`](examples/13-elixir-first-liveview/) |
| Share selected browser/server domain logic | [`16-portable-chat-domain`](examples/16-portable-chat-domain/) |
| Explore the full reference app | [`todo-app`](examples/todo-app/) |
| Install a verified release package | [Installation](docs/01-getting-started/installation.md) |

No all-at-once rewrite is required.

## Reflaxe.Elixir And Gleam

This is not a universal “better than Gleam” claim. Reflaxe.Elixir can be the better fit when generated
Elixir, Phoenix macro/DSL integration, module-by-module adoption, Haxe macros, or existing Haxe and
JavaScript sharing are central. Gleam is the safer fit when a small immutable language, a cohesive
Erlang/JavaScript model, mature 1.x stability, and its dedicated ecosystem matter more.

Read the [full comparison](docs/01-getting-started/WHY_REFLAXE_ELIXIR.md#reflaxeelixir-and-gleam),
including tradeoffs and primary sources.

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
