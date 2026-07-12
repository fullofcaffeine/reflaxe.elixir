<p align="center">
  <img src="assets/haxir-logo.png" alt="Haxir logo" width="280" />
</p>

# Reflaxe.Elixir (aka Haxir)

[![Release](https://img.shields.io/github/v/release/fullofcaffeine/reflaxe.elixir)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.7+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

**[Haxe](https://haxe.org) -> [Elixir](https://elixir-lang.org) compiler for the BEAM ecosystem, with first-class [Phoenix](https://phoenixframework.org)/[LiveView](https://www.phoenixframework.org/liveview) support.**
Write application code in Haxe and compile to conventional Elixir shapes for pure Elixir/OTP services and Phoenix applications.

> [!WARNING]
> **Stability**: Reflaxe.Elixir is on the pre-1.0 (`v0.x`) release line.
> Breaking changes to documented stable surfaces use minor releases until an explicitly reviewed stable graduation.
> Some features remain experimental/opt-in; see [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md) and [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).

Immutable Git tags identify released versions. The
[release policy manifest](release/manifest.json) contains only release-line approvals; it is not a
second mutable version file. See [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).
Normal publication is the final job of the same `main` CI run: it can tag only that run's exact
`github.sha` after compiler, package, examples, dogfood, QA, and security gates succeed. There is no
manual normal-release bypass. See [Releasing](docs/10-contributing/RELEASING.md).

## Why Reflaxe.Elixir

Reflaxe.Elixir is for teams that want standard Elixir/OTP runtime behavior, while authoring with stronger compile-time feedback.

- **Keep standard Elixir runtime semantics**: generated code follows normal module/function/tuple/map conventions.
- **Add a typed authoring layer**: catch shape mismatches (assigns, params, tagged results) before runtime.
- **Improve large refactors**: typed Haxe APIs and compiler checks help keep changes coherent across modules.
- **Build ergonomic abstractions**: Haxe macros/typing can encode reusable authoring patterns without changing your BEAM deployment model.
- **Use it with or without Phoenix**: works for pure Elixir/OTP codebases and Phoenix apps.

Elixir's failure model is still the foundation (supervision, process isolation, let-it-crash where appropriate).
The typed layer helps you decide more deliberately what should crash, what should return data, and where boundaries should be explicit.

## Build Higher-Level Abstractions (Haxe + Elixir)

These abstractions should earn their place. The question is not "can Haxe do this?", but "does this reduce drift, duplication, or unsafe boundaries compared to direct Haxe->Elixir authoring without this extra layer?"

| Haxe authoring surface | Direct Haxe->Elixir baseline | Edge over that baseline | Example |
| --- | --- | --- | --- |
| Module-level `final routes = [...]` | Hand-maintained route/controller wiring in direct modules | Typed route declarations reduce path/action drift during refactors | [`examples/09-phoenix-router`](examples/09-phoenix-router/README.md) |
| `@:schema` + `@:changeset` | Manually keeping schema/changeset field surfaces aligned | Typed field/params surfaces catch boundary mismatches earlier | [`examples/06-user-management`](examples/06-user-management/README.md) |
| `TypedQueryLambda` | Ad-hoc query composition with repeated field assumptions | Typed query lambdas keep predicates aligned with source model shapes | [`examples/todo-app`](examples/todo-app/README.md) |
| `@:protocol` / `@:impl` / `@:behaviour` | Repeated contract maintenance across implementation modules | One typed contract surface, multiple implementations, less signature drift | [`examples/14-abstraction-lab`](examples/14-abstraction-lab/README.md) |
| Typed wrappers over Elixir externs (for example `elixir.Kernel`) | Repeated low-level guard/send/type-check boilerplate | Centralized boundary helpers with explicit typed call surfaces | [`examples/14-abstraction-lab`](examples/14-abstraction-lab/README.md) |

For a focused walkthrough of these patterns in one place, see [`examples/14-abstraction-lab`](examples/14-abstraction-lab/README.md).

Tradeoff: you add a compile step and should still read generated Elixir for hot paths and debugging. If an abstraction does not remove real duplication or drift, direct Haxe->Elixir modules are usually the simpler choice.

### How this differs from [Gleam](https://gleam.run) (briefly)

Gleam is a strong typed BEAM language with its own language/runtime story.
Reflaxe.Elixir takes a different approach:

- You author in Haxe and compile to Elixir.
- You integrate directly with Phoenix/[LiveView](https://www.phoenixframework.org/liveview)/Ecto through typed extern surfaces.
- You can reuse Haxe tooling/macros and keep cross-target options where they make sense.

## Current Support

### Documented stable tier (pre-1.0 policy)

- Phoenix integration ([LiveView](https://www.phoenixframework.org/liveview)/controllers/templates/routers) for documented paths
- HEEx-oriented inline markup authoring (`return <div>...</div>`) with strict `tsx` mode as the default path for new code; legacy `balanced` string templates and `metal` raw-HEEx escapes are documented in [HXX Syntax & Comparison](docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md)
- Ecto schemas/changesets/typed query surfaces
- OTP patterns (GenServer/Supervisor/Registry)
- Mix integration (`mix compile.haxe`, watcher workflows) and client hook builds with [Genes](https://github.com/benmerckx/genes)

### Experimental / opt-in

- Source mapping (`.ex.map`, `mix haxe.source_map`)
- Migration `.exs` emission
- `fast_boot`

For exact boundaries, use:
- [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md)
- [Support Matrix](docs/06-guides/SUPPORT_MATRIX.md)
- [Stdlib Support Matrix](docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md)
- [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md)

## Quick Start

### Start here

If you're new to this stack, begin with:
- [Start Here](docs/01-getting-started/START_HERE.md)
- [Quickstart](docs/06-guides/QUICKSTART.md)

### Install with [Lix](https://github.com/lix-pm/lix.client) (recommended)

```bash
npx lix scope create

# Install the Reflaxe-built package from the latest GitHub release
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"

# Download project-pinned Haxe deps
npx lix download
```

To verify the package bytes before installation, download the ZIP and its release-owned checksum
from the same immutable release:

```bash
PACKAGE="reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"
RELEASE_URL="https://github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}"
curl -fL -o "$PACKAGE" "$RELEASE_URL/$PACKAGE"
curl -fL -o "$PACKAGE.sha256" "$RELEASE_URL/$PACKAGE.sha256"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum --check "$PACKAGE.sha256"
else
  shasum -a 256 --check "$PACKAGE.sha256"
fi
```

The check must report `OK`. Lix then fetches that same immutable release asset in the install
command above. Maintainers additionally verify GitHub's signed release and asset attestations; see
[Releasing](docs/10-contributing/RELEASING.md#consumer-verification).

The release zip is the normal consumer package. Reflaxe builds it from the checked-in target stdlib
sources and includes the generated `.cross.hx` files required by a single `-lib reflaxe.elixir`.
The `www.github.com` host is intentional: it lets Lix treat the file as a generic immutable HTTPS
archive instead of misclassifying the release URL as a GitHub source-repository dependency.
Each new release also publishes a `.sha256` sidecar, and the ZIP embeds its exact version, tag, and source
commit. The release job builds the complete package twice and requires byte-identical output before
it tags that already-tested source commit. GitHub first creates a draft, uploads both approved files,
then publishes them as an immutable release with a signed release attestation. A reviewer-gated
repair workflow may finish an interrupted draft for an existing tag; it cannot choose a branch,
derive a version, create or move a tag, or replace mismatched bytes.

### Working from a source checkout

Use this only when developing the compiler itself or testing an unreleased change:

```bash
REFLAXE_ELIXIR_CHECKOUT=/absolute/path/to/reflaxe.elixir
npx lix dev reflaxe.elixir "$REFLAXE_ELIXIR_CHECKOUT"
"$REFLAXE_ELIXIR_CHECKOUT/scripts/dev/configure-source-checkout-hxml.sh" . "$REFLAXE_ELIXIR_CHECKOUT"
npx lix download
```

The helper gives the external project the same scoped classpaths used by this repository. Do not use
a raw `lix dev` or `haxelib dev` entry by itself: source `_std` overrides must be visible before Haxe
starts typing. See [Source checkout vs release package](docs/01-getting-started/SOURCE_VS_PACKAGE_LAYOUT.md)
for a beginner-friendly explanation of why the layouts differ and how output parity is tested.

### Minimal `build.hxml`

```hxml
-lib reflaxe.elixir
-cp src_haxe
-main my_app_hx.Main

-D no-utf16
-D elixir_output=lib/my_app_hx
-D app_name=MyApp

-dce full
```

Important compiler flag note:
- `-lib reflaxe.elixir` supplies the target marker and compiler initialization;
  application HXML files do not need `-D reflaxe_runtime`.
- Do **not** use `-D analyzer-optimize` when targeting Elixir.
- See [Compiler Flags Guide](docs/01-getting-started/compiler-flags-guide.md#reflaxe_runtime-compiler-development-context)
  for the compiler-development convention and source/package contract.

### New Phoenix app (greenfield)

Use the guided flow:
- [Phoenix New App Guide](docs/06-guides/PHOENIX_NEW_APP.md)

For gradual adoption in an existing Phoenix codebase:
- [Phoenix Gradual Adoption](docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md)

### Pure Elixir / OTP (no Phoenix)

Start from the Mix-based examples and author regular Elixir modules in Haxe:
- [Examples Index](examples/README.md)
- [`examples/02-mix-project`](examples/02-mix-project/)

### Todo app smoke (repo)

```bash
npm run qa:sentinel
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 120
```

## Example (LiveView)

Haxe:

```haxe
import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef CounterAssigns = { count: Int };

@:liveview
class CounterLive {
  public static function mount(params: Term, session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
    return Ok(socket.assign(_.count, 0));
  }
}
```

Notes:
- With `-D app_name=MyApp`, `@:liveview class CounterLive` derives the normal Phoenix module
  `MyAppWeb.CounterLive` and output path `lib/my_app_web/counter_live.ex`.
- Use class-level `@:native("MyAppWeb.SomeExactModule")` only as an exact interop escape hatch
  when the derived Phoenix name is not the module you need.
- `socket` in LiveView callbacks is `Socket<TAssigns>` (the Phoenix callback shape), and you can call assign helpers on it directly (`socket.assign(...)`).
- `LiveSocket<TAssigns>` is still available as an explicit wrapper when you prefer pipe-style chaining or helper signatures that use `LiveSocket`.
- `_.count` can look odd at first because `_` usually means “unused variable.” Here, `_` is a macro marker.
- Why the API looks like this: Haxe has no built-in “field reference literal” for typedef fields, so `LiveSocket.assign` uses `_.field` as a compact compile-time selector.
- What you get from it: the compiler validates the field name, converts to Phoenix atom style, and emits `assign(socket, :count, value)`. `_` does not exist at runtime.
- Phoenix-style bulk assigns are available as `assign({ ... })`, which emits `assign(socket, %{...})`.
- Typed-key APIs (`assignKey`/`assignNewKey`/`updateKey`) are optional advanced mode with `var keys = phoenix.AssignKeys.of(MyAssigns)`.
  Use default `assign(_.field, value)` / `assign({ ... })` for shortest code; use typed keys when you want explicit key tokens in APIs.
  Tiny comparison:
  `var keys = phoenix.AssignKeys.of(CounterAssigns);`
  `return Ok(socket.assignKey(keys.count, 0));`
- In Haxe, write callback args naturally (`params`, `session`). If they are unused, generated Elixir is automatically normalized to `_params`, `_session`.
- API deep dive: `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`

Generated Elixir shape:

```elixir
defmodule CounterLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end
end
```

More examples:
- [Examples Index](examples/README.md)
- [Phoenix Chat Tutorial](docs/06-guides/PHOENIX_CHAT_TUTORIAL.md)
- [Functional Patterns](docs/07-patterns/FUNCTIONAL_PATTERNS.md)

## Documentation

Start at [docs/README.md](docs/README.md).

### Recommended links

- [Installation](docs/01-getting-started/installation.md)
- [Writing Idiomatic Haxe for Elixir](docs/02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md)
- [Elixir Idioms & Hygiene](docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md)
- [Haxe->Elixir Mappings](docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md)
- [Interop With Existing Elixir](docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md)
- [Phoenix Integration](docs/02-user-guide/PHOENIX_INTEGRATION.md)
- [API Index](docs/04-api-reference/API_INDEX.md)
- [LiveSocket Assign API](docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md)
- [Mix Tasks](docs/04-api-reference/MIX_TASKS.md)
- [Elixir Injection Guide](docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md)
- [Troubleshooting](docs/06-guides/TROUBLESHOOTING.md)

## Contributing

- [Contributing Guide](docs/10-contributing/contributing.md)
- [Compiler Testing Infrastructure](docs/03-compiler-development/TESTING_INFRASTRUCTURE.md)
- [Development Workflow](docs/01-getting-started/development-workflow.md)

## License

GPL-3.0 - see [LICENSE](LICENSE).

## Links

- [Haxe](https://haxe.org/)
- [Reflaxe](https://github.com/SomeRanDev/reflaxe)
- [Elixir](https://elixir-lang.org/)
- [Phoenix](https://www.phoenixframework.org/)
- [Lix](https://github.com/lix-pm/lix.client)
- [Genes](https://github.com/benmerckx/genes)
