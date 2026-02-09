# Adding Elixir (Hex) Libraries From Haxe

This guide shows the recommended, low-friction way to consume Elixir libraries (Hex deps) from Haxe while keeping code:

- typed (no `Dynamic` as a “make it compile” escape hatch)
- idiomatic in the generated Elixir
- resilient to Phoenix template drift

## The Pattern: Thin Extern + Optional Wrapper

1. **Thin extern (extern class)**: a typed surface that maps 1:1 to Elixir module functions.
2. **Wrapper (normal Haxe class)**: an ergonomic API for your app that:
   - chooses better names
   - converts between app types and `elixir.types.Term` when needed
   - centralizes error handling (`Result`, exceptions, etc.)

If you’re contributing a generally useful integration, put the extern in `std/elixir/*` or `std/phoenix/*`. Otherwise, keep it app-local under your project’s `src_haxe/`.

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

Phoenix already depends on Jason by default, but it’s a good example for the extern pattern (bang functions, ok/error tuples, options).

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

## Options, Atoms, And Keyword Lists

Many Elixir functions take keyword options (`[key: value]`).

- Use `elixir.types.Atom` for atoms (see `docs/04-api-reference/ATOM_TYPE.md`).
- Prefer `enum abstract` over `Atom` for fixed option sets.
- For options objects passed to extern calls, use `typedef` with optional fields (see `std/elixir/Jason.hx`).

## Testing And CI Expectations

- App-local externs/wrappers: cover behavior with your app tests (ConnTest/LiveViewTest in Haxe→ExUnit, or small Playwright smoke where it matters).
- Stdlib additions (`std/elixir/*`, `std/phoenix/*`): add snapshot tests and run:
  - `npm run test:quick`
  - `npm run test:examples-elixir` (warnings-as-errors gate)

## Next Step: Generate Skeletons

If you want to avoid hand-writing boilerplate, use the generator:

- `mix haxe.gen.extern` (see `docs/04-api-reference/MIX_TASK_GENERATORS.md`)

