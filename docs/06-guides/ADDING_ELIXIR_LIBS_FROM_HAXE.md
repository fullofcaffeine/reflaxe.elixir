# Adding Elixir APIs From Haxe (Externs + Wrappers + Tests)

This is the canonical workflow for calling an existing Elixir module from Haxe. The module can come
from your own app, Elixir itself, Phoenix/Ecto/OTP, or a Hex dependency.

If “extern” is new to you, the idea is simple: an extern is a Haxe declaration for code that already
exists. It does not copy or reimplement the Elixir module. It teaches Haxe which calls are allowed,
and the generated `.ex` calls the original module directly.

The workflow keeps application code:

- away from raw target-code strings and `Dynamic` escape hatches
- progressively typed, using `Term` only at genuinely open or not-yet-refined boundaries
- idiomatic in the generated Elixir
- resilient to framework changes

This same workflow also applies when the Elixir module is your own hand-written app code (not only Hex dependencies).

If you are specifically integrating intentionally pure-Elixir modules in your app, read this together with `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`.

## What Works Today

`mix haxe.gen.extern Module.Name` is a **single-module scaffold generator**. It can:

- find an already available Elixir or Erlang module;
- list its exported function names and arities;
- create Haxe-safe names for Elixir `?` and `!` functions; and
- optionally create a wrapper, decoder template, and test pointer.

It does not currently read typespecs or understand a whole resolved Mix dependency. Generated arguments and
results start as `elixir.types.Term`; you must replace those generic types with the real contract
before presenting the layer as precise. The task also does not yet provide package-level ownership or
upgrade handling, so use a clean output path and review `git diff` before keeping a rerun.

The planned dependency-level discovery and generation flow is described in
[Standard Libraries And Packages](../08-roadmap/stdlib-and-package-ecosystem.md). Do not copy the
planned `mix haxe.adopt` command from that roadmap yet; it is not implemented today.

## The Pattern: Thin Extern + Optional Wrapper

1. **Thin extern (extern class)**: a typed surface that maps 1:1 to Elixir module functions.
2. **Wrapper (normal Haxe class)**: an ergonomic API for your app that:
   - chooses better names
   - converts between app types and `elixir.types.Term` when needed
   - centralizes error handling (`Result`, exceptions, etc.)

If you are contributing a generally useful integration, put the extern in `std/elixir/*`, `std/phoenix/*`, or `std/ecto/*`.
Otherwise, keep it app-local under your project’s `src_haxe/`.

Quick compare:

- Thin extern only: best when the native call is already clear and used in few places.
- Extern + wrapper: best when you want app-level naming, boundary decoding, or centralized error handling.

Runnable reference:

- `examples/13-elixir-first-liveview/src_haxe/interop/LegacySlugExtern.hx`
- `examples/13-elixir-first-liveview/src_haxe/interop/LegacySlugBridge.hx`

## App-Local Existing Elixir Module (same pattern)

If your app already has a module like `MyApp.LegacyBilling`, map it exactly the same way:

```bash
mix haxe.gen.extern MyApp.LegacyBilling --package my_app.extern --out src_haxe --wrapper --decoder --test-pointer
```

```haxe
package my_app.extern;

import elixir.ElixirResult;
import elixir.types.Term;

@:native("MyApp.LegacyBilling")
@:unsafeExtern
extern class LegacyBilling {
  @:native("charge")
  static function charge(accountId: String, amountCents: Int): ElixirResult<String, Term>;
}
```

Generated call sites stay direct:

```elixir
MyApp.LegacyBilling.charge(account_id, amount_cents)
```

For app-owned module references that do not expose callable functions to Haxe, use boundary mode:

```bash
mix haxe.gen.extern MyApp.PubSub --boundary --package my_app.infrastructure --out src_haxe
```

It emits the minimal strict-mode marker:

```haxe
package my_app.infrastructure;

@:native("MyApp.PubSub")
@:unsafeExtern
extern class PubSub {}
```

## Step 1: Add The Hex Dependency

In your Phoenix project’s `mix.exs`, add the dependency and fetch it:

```elixir
defp deps do
  [
    {:jason, "~> 1.4"}
  ]
end
```

Then:

```bash
mix deps.get
```

Phoenix already depends on Jason by default, but it is a good example for the extern pattern (bang functions, ok/error tuples, options).

## Step 2: Define A Thin Extern (Typed @:native Surface)

Create an extern module that maps directly onto Elixir.

Rules of thumb:

- Put the Elixir module name on the class: `@:native("Jason")`.
- Put the Elixir function name on each method: `@:native("encode!")`, etc.
- For Elixir bang functions (`foo!/1`), use a normal Haxe identifier like `fooStrict` or `fooBang` and map it via `@:native("foo!")`.

Example (mirrors `std/elixir/Jason.hx`):

```haxe
package my_app.extern;

import elixir.types.Term;
import elixir.ElixirResult;

@:native("Jason")
extern class Jason {
  @:native("encode")
  static function encode(term: Term): ElixirResult<String, Term>;

  @:native("encode!")
  static function encodeStrict(term: Term): String;
}
```

Notes:

- `elixir.types.Term` is the correct “anything” boundary type (prefer it over `Dynamic`).
- For `{ :ok, value } | { :error, reason }` shapes, use `elixir.ElixirResult<T, E>` (see `std/elixir/Jason.hx`).

## Step 3 (Optional): Add An App Wrapper

Your wrapper is where you:

- choose stable names for your app
- convert return types into your preferred error model
- keep Elixir module shapes out of most of your codebase

Example:

```haxe
package my_app.json;

import elixir.types.Term;
import haxe.functional.Result;
import my_app.extern.Jason;

class Json {
  public static function encode(term: Term): Result<String, Term> {
    return Jason.encode(term).match(
      ok -> Result.Ok(ok),
      err -> Result.Error(err)
    );
  }

  public static function encodeStrict(term: Term): String {
    return Jason.encodeStrict(term);
  }
}
```

Prefer `haxe.functional.Result` in new code (it is the canonical Result type for this compiler).

## Step 4: Phoenix/Ecto Surface Example (typed + API-faithful)

The same pattern applies to framework APIs. Keep the extern API-faithful, then add a wrapper only if your app needs a nicer facade.

Example: typed wrapper over `Phoenix.PubSub.broadcast/3`.

```haxe
package my_app.realtime;

import elixir.types.Atom;
import phoenix.Phoenix;

class PubSubBridge {
  // Thin wrapper over the std/phoenix extern surface.
  public static function broadcast(topic: String, event: Atom, payload: elixir.types.Term): Bool {
    Phoenix.PubSub.broadcast(MyApp.PubSub, topic, {event: event, payload: payload});
    return true;
  }
}
```

Notes:

- Prefer existing `std/phoenix/*` and `std/ecto/*` surfaces before creating app-local externs.
- Keep extern names API-faithful (`@:native` for `?`/`!`/Erlang names).
- Use `Term` at truly dynamic boundaries, and decode to typed values immediately after.

## Options, Atoms, And Keyword Lists

Many Elixir functions take keyword options (`[key: value]`).

- Use `elixir.types.Atom` for atoms (see `docs/04-api-reference/ATOM_TYPE.md`).
- Prefer `enum abstract` over `Atom` for fixed option sets.
- For options objects passed to extern calls, use `typedef` with optional fields (see `std/elixir/Jason.hx`).

## Strict Mode Implications

If your project uses strict mode (`docs/06-guides/STRICT_MODE.md`):

- Reusable interop belongs in `std/*` or shared wrappers, not ad-hoc `untyped` app code.
- Prefer `Term` at boundaries, then decode into typed `typedef`/enums.
- Avoid `Dynamic` as a typing escape hatch.

## Testing And CI Expectations

- App-local externs/wrappers: cover behavior with app tests (ConnTest/LiveViewTest in Haxe->ExUnit, plus small Playwright smoke where needed).
- Stdlib additions (`std/elixir/*`, `std/phoenix/*`, `std/ecto/*`): add snapshot tests and run:
  - `npm run test:quick`
  - `npm run test:examples-elixir` (warnings-as-errors gate)

Minimal checklist for each new API surface:

1. Add/extend extern (`std/*` or app-local).
2. Add wrapper only when it improves ergonomics or error handling.
3. Add tests in the correct layer:
   - Snapshot tests for compiler/codegen behavior.
   - Mix/ExUnit for runtime behavior.
   - Example app runtime/Playwright only for integration smoke.
4. Update docs where developers discover the API (this page + one pointer in relevant guide).
5. Run CI-parity commands for touched layers.

## Next Step: Generate Skeletons

If you want to avoid hand-writing boilerplate, use the generator:

- `mix haxe.gen.extern` (see `docs/04-api-reference/MIX_TASK_GENERATORS.md`)
- `mix haxe.gen.extern MyApp.PubSub --boundary` for app-local module-reference markers

For a dependency with several modules, repeat this only for the small set of modules your app needs,
then refine each signature from the dependency's official typespecs and documentation. Automated,
typespec-driven dependency adoption is tracked by Beads epic `haxe.elixir.codex-5np`; the current
generator must not be mistaken for that future dependency-level guarantee.

Related docs:

- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `docs/02-user-guide/ESCAPE_HATCHES.md`
- `docs/04-api-reference/MIX_TASK_GENERATORS.md`
- `docs/06-guides/STRICT_MODE.md`
- `docs/08-roadmap/stdlib-and-package-ecosystem.md`
