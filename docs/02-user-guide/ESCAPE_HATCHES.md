# Interop (Escape Hatches): Calling Elixir from Haxe

Reflaxe.Elixir is designed for **pure Haxe → idiomatic Elixir**. When you need to integrate with existing Elixir/Erlang libraries, use **externs** and **typed boundary types**.

Start with `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md` for the practical workflow (how to call hand-written Elixir from Haxe). This page is the escape-hatch focused companion.

> Application code should **not** use `untyped` or `__elixir__()` injections. If something is missing, add/extend an extern (preferred) or implement it in a shared library layer.
>
> Canonical workflow (extern + wrapper + testing): `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md` and `docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md`

## 1) Map Haxe code to existing Elixir modules with `@:native`

The core interop mechanism is `@:native("Module.Name")` on `extern` classes/functions.

Tip: generate a starter extern automatically:

```bash
mix haxe.gen.extern Ecto.Changeset --package externs.ecto --out src_haxe/externs
mix haxe.gen.extern MyApp.PubSub --boundary --package my_app.infrastructure --out src_haxe
```

### Example: Erlang `:crypto`

```haxe
import elixir.types.Term;

@:native(":crypto")
extern class Crypto {
    @:native("strong_rand_bytes")
    public static function strongRandBytes(size: Int): Term;

    @:native("hash")
    public static function hash(type: Term, data: String): Term;
}
```

Compiles to call sites like:

```elixir
bytes = :crypto.strong_rand_bytes(size)
digest = :crypto.hash(type, data)
```

Notes:
- `extern` declarations are compile-time only and do not emit Elixir modules.
- `@:native(":crypto")` maps directly to Erlang module calls.

Notes
- Return values from external libraries are often *polymorphic* (different shapes depending on options). Use `elixir.types.Term` for those boundaries.

### Example: Elixir `Enum`

```haxe
@:native("Enum")
extern class ElixirEnum {
    @:native("map")
    public static function map<T, R>(enumerable: Array<T>, fn: T -> R): Array<R>;

    @:native("filter")
    public static function filter<T>(enumerable: Array<T>, fn: T -> Bool): Array<T>;
}
```

Compiles to call sites like:

```elixir
Enum.map(enumerable, fn item -> ... end)
Enum.filter(enumerable, fn item -> ... end)
```

## 2) Use `Term` as the explicit boundary type (never `Dynamic`)

`elixir.types.Term` is the canonical “opaque Elixir term” type.

Use it when:
- Phoenix/Ecto hands you a map with application-defined keys
- A library returns a tuple/map with variant shapes
- You’re dealing with JSON payloads before decoding into a typed structure

Prefer **typed `typedef`s** (optional fields) whenever you can:

```haxe
typedef EventParams = {
    ?query: String,
    ?id: Int
}
```

If you must accept a raw term (e.g. very dynamic payload), decode early:

```haxe
import elixir.types.Term;
import elixir.types.TermDecoder;
import haxe.functional.Result;

function getQuery(params: Term): String {
    // Prefer typed fetch+decode helpers over Map.get. They distinguish missing
    // keys from values that are present but have the wrong shape.
    return switch (TermDecoder.fetchStringKeyAs(params, "query", TermDecoder.asString)) {
        case Ok(q): q;
        case Error(_): "";
    };
}
```

Compiles to shape:

```elixir
case TermDecoder.fetch_string_key(params, "query")
     |> Result.flat_map(&TermDecoder.as_string/1) do
  {:ok, query} -> query
  {:error, _reason} -> ""
end
```

Common recipes:

- Required Phoenix params: `TermDecoder.fetchStringKeyAs(params, "query", TermDecoder.asString)`
- Optional Phoenix params: `TermDecoder.optionalStringKeyAs(params, "page", TermDecoder.asInt)`
- Ecto/struct maps with atom keys: `TermDecoder.fetchAtomKeyAs(changeset, "email", TermDecoder.asString)`
- Elixir result tuples: `TermDecoder.okError(term, TermDecoder.asString, TermDecoder.asString)` returns a decoded `Result<Result<T, E>, TermDecodeError>`, so malformed tuples stay separate from valid `{:error, reason}` domain errors.

## 3) Don’t use `untyped` / `__elixir__()` in applications

`untyped __elixir__()` is reserved for:
- Standard library implementations (`std/elixir/_std/**/*.hx`, framework shims)
- Compiler/macro internals

In apps, prefer:
1) A proper extern wrapper (best)
2) A small shared library module (pure Haxe) + externs for any Elixir calls you need

### Example: prefer externs over injection

Instead of:
```haxe
// ❌ app code should not do this
var now = untyped __elixir__('DateTime.utc_now()');
```

Use the provided extern:
```haxe
import elixir.DateTime.DateTime;

var now = DateTime.utcNow();
```

Compiles to:

```elixir
now = DateTime.utc_now()
```

## 4) Common patterns

### Phoenix LiveView params
- Keep params typed (`typedef`) for ergonomic field access.
- Use `Term` only for truly polymorphic fields (e.g. a field that can be `"a,b,c"` **or** `["a","b","c"]`).

See:
- `docs/07-patterns/quick-start-patterns.md` (LiveView skeleton)
- `examples/todo-app/src_haxe/server/live/TodoLive.hx` (real-world typed params + assigns)

### Ecto changesets
- Prefer `@:changeset([...], [...])` for the common case (**Ecto** `cast` + `validate_required`).
  - This `cast` is **not** a Haxe type cast; it is `Ecto.Changeset.cast/3` (or `/4`), and it exists to:
    - whitelist permitted fields (mass-assignment protection),
    - cast external params (often strings) into your schema field types,
    - populate the changeset `changes` and `errors` for later validation/Repo calls.
  - When you already have trusted, internal, correctly-typed values (not user input), you can often skip `cast`
    and use `Ecto.Changeset.change/2`, `put_change/3`, etc. instead.
- For advanced validation, use `ecto.Changeset<T, P>` helpers.

See:
- `std/ecto/Changeset.hx` (typed builder API)
- `examples/todo-app/src_haxe/server/schemas/Todo.hx` (generated changeset pattern)

## 5) If you really need a missing API

If you hit an Elixir library call that isn’t wrapped yet:
- Add a minimal `extern` in your project, or
- Contribute it to `std/` if it’s generally useful (Phoenix/Ecto/OTP/common Elixir libs).

Keep externs:
- API-faithful (match real Elixir signatures)
- Typed (use generics + `Term` boundaries)
- Documented (WHAT/WHY/HOW + a minimal example)
