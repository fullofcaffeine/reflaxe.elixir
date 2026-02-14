<p align="center">
  <img src="assets/haxir-logo.png" alt="Haxir logo" width="280" />
</p>

# Reflaxe.Elixir (aka Haxir)

[![Version](https://img.shields.io/badge/version-1.17.0-blue)](https://github.com/fullofcaffeine/reflaxe.elixir/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml)
[![Haxe](https://img.shields.io/badge/Haxe-4.3.7+-orange)](https://haxe.org)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org)

**Haxe -> Elixir compiler for Phoenix/LiveView projects.**
Write application code in Haxe and compile to conventional Elixir shapes for the BEAM ecosystem.

> [!WARNING]
> **Stability**: the documented subset is considered stable in `v1.x`.
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

### How this differs from Gleam (briefly)

Gleam is a strong typed BEAM language with its own language/runtime story.
Reflaxe.Elixir takes a different approach:

- You author in Haxe and compile to Elixir.
- You integrate directly with Phoenix/LiveView/Ecto through typed extern surfaces.
- You can reuse Haxe tooling/macros and keep cross-target options where they make sense.

## Current Support (v1.x)

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
  public static function mount(_params: Term, _session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
    var liveSocket: LiveSocket<CounterAssigns> = socket;
    return Ok(liveSocket.assign(_.count, 0));
  }
}
```

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
- [Phoenix Integration](docs/02-user-guide/PHOENIX_INTEGRATION.md)
- [API Index](docs/04-api-reference/API_INDEX.md)
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
