# Interop (Escape Hatches): Calling Elixir from Haxe

Reflaxe.Elixir is designed for **pure Haxe → idiomatic Elixir**. When you need to integrate with existing Elixir/Erlang libraries, use **externs** and **typed boundary types**.

> Application code should **not** use `untyped` or `__elixir__()` injections. If something is missing, add/extend an extern (preferred) or implement it in a shared library layer.

## 1) Map Haxe code to existing Elixir modules with `@:native`

The core interop mechanism is `@:native("Module.Name")` on `extern` classes/functions.

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
import elixir.ElixirMap;
import elixir.types.Term;

function getQuery(params: Term): String {
    var q: Term = ElixirMap.get(params, "query");
    return q != null ? Std.string(q) : "";
}
```

## 3) Don’t use `untyped` / `__elixir__()` in applications

`untyped __elixir__()` is reserved for:
- Standard library implementations (`std/*.cross.hx`, framework shims)
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

## 4) Common patterns

### Phoenix LiveView params
- Keep params typed (`typedef`) for ergonomic field access.
- Use `Term` only for truly polymorphic fields (e.g. a field that can be `"a,b,c"` **or** `["a","b","c"]`).

See:
- `docs/07-patterns/quick-start-patterns.md` (LiveView skeleton)
- `examples/todo-app/src_haxe/server/live/TodoLive.hx` (real-world typed params + assigns)

### Ecto changesets
- Prefer `@:changeset([...], [...])` for the common case (cast + validate_required).
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
