<p align="center">
  <img src="assets/haxir-logo.png" alt="Haxir logo" width="280" />
</p>

# Reflaxe.Elixir (aka Haxir)

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.7+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

**Haxe -> Elixir compiler for Phoenix/LiveView projects.**
Write application code in Haxe and compile to conventional Elixir shapes for the BEAM ecosystem.

> [!WARNING]
> **Stability**: the project is currently pre-1.0 (`v0.x`) and actively evolving.
> Some features remain experimental/opt-in (for example source mapping, migrations `.exs` emission, `fast_boot`).
> See [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md) and [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).

## Why Reflaxe.Elixir

Reflaxe.Elixir is for teams that want Phoenix/OTP runtime behavior, while authoring with stronger compile-time feedback.

- **Keep standard Elixir/Phoenix runtime**: generated code follows normal module/function/tuple/map conventions.
- **Add a typed authoring layer**: catch shape mismatches (assigns, params, tagged results) before runtime.
- **Improve large refactors**: typed Haxe APIs and compiler checks help keep changes coherent across modules.
- **Build ergonomic abstractions**: Haxe macros/typing can encode reusable authoring patterns without changing your BEAM deployment model.

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

### How this differs from Gleam (briefly)

Gleam is a strong typed BEAM language with its own language/runtime story.
Reflaxe.Elixir takes a different approach:

- You author in Haxe and compile to Elixir.
- You integrate directly with Phoenix/LiveView/Ecto through typed extern surfaces.
- You can reuse Haxe tooling/macros and keep cross-target options where they make sense.

## Current Support (v0.x pre-1.0)

### Stable (documented subset)

- Phoenix integration (LiveView/controllers/templates/routers) for documented paths
- HEEx-oriented template authoring modes (`tsx`, `balanced`, `metal`)
- Ecto schemas/changesets/typed query surfaces
- OTP patterns (GenServer/Supervisor/Registry)
- Mix integration (`mix compile.haxe`, watcher workflows)

### Experimental / opt-in

- Source mapping (`.ex.map`, `mix haxe.source_map`)
- Migration `.exs` emission
- `fast_boot`

For exact boundaries, use:
- [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md)
- [Support Matrix](docs/06-guides/SUPPORT_MATRIX.md)
- [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md)

## Quick Start

### Start here

If you're new to this stack, begin with:
- [Start Here](docs/01-getting-started/START_HERE.md)
- [Quickstart](docs/06-guides/QUICKSTART.md)

### Install with lix (recommended)

```bash
npx lix scope create

# Install latest GitHub release tag
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
npx lix install "github:fullofcaffeine/reflaxe.elixir#${REFLAXE_ELIXIR_TAG}"

# Download project-pinned Haxe deps
npx lix download
```

### Minimal `build.hxml`

```hxml
-lib reflaxe.elixir
-cp src_haxe
-main my_app_hx.Main

-D reflaxe_runtime
-D no-utf16
-D elixir_output=lib/my_app_hx
-D app_name=MyApp

-dce full
```

Important compiler flag note:
- Do **not** use `-D analyzer-optimize` when targeting Elixir.
- See [Compiler Flags Guide](docs/01-getting-started/compiler-flags-guide.md).

### New Phoenix app (greenfield)

Use the guided flow:
- [Phoenix New App Guide](docs/06-guides/PHOENIX_NEW_APP.md)

For gradual adoption in an existing Phoenix codebase:
- [Phoenix Gradual Adoption](docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md)

### Todo app smoke (repo)

```bash
npm run qa:sentinel
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 120
```

## Example (LiveView)

Haxe:

```haxe
import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef CounterAssigns = { count: Int };

@:native("MyAppWeb.CounterLive")
@:liveview
class CounterLive {
  public static function mount(params: Term, session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
    // Phoenix callbacks receive Socket<T>. Convert once to LiveSocket<T> to use assign helpers.
    var liveSocket: LiveSocket<CounterAssigns> = socket;
    return Ok(liveSocket.assign(_.count, 0));
  }
}
```

Notes:
- `socket` in LiveView callbacks is `Socket<TAssigns>` (the Phoenix callback shape). `LiveSocket<TAssigns>` is a Haxe helper wrapper on top of it.
- `var liveSocket: LiveSocket<CounterAssigns> = socket;` is an implicit compile-time conversion so you can call helper methods like `assign(...)`; it does not create a second runtime socket.
- `_.count` can look odd at first because `_` usually means “unused variable.” Here, `_` is a macro marker.
- Why the API looks like this: Haxe has no built-in “field reference literal” for typedef fields, so `LiveSocket.assign` uses `_.field` as a compact compile-time selector.
- What you get from it: the compiler validates the field name, converts to Phoenix atom style, and emits `assign(socket, :count, value)`. `_` does not exist at runtime.
- Phoenix-style bulk assigns are available as `assign({ ... })`, which emits `assign(socket, %{...})`.
- Typed-key APIs (`assignKey`/`assignNewKey`/`updateKey`) are optional advanced mode with `var keys = phoenix.AssignKeys.of(MyAssigns)`.
  Use default `assign(_.field, value)` / `assign({ ... })` for shortest code; use typed keys when you want explicit key tokens in APIs.
  Tiny comparison:
  `var keys = phoenix.AssignKeys.of(CounterAssigns);`
  `return Ok(liveSocket.assignKey(keys.count, 0));`
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

- [Haxe](https://haxe.org)
- [Reflaxe](https://github.com/SomeRanDev/reflaxe)
- [Elixir](https://elixir-lang.org)
- [Phoenix](https://phoenixframework.org)
- [lix](https://github.com/lix-pm/lix.client)
