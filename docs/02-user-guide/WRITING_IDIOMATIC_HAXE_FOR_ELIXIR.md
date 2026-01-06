# Writing Idiomatic Haxe for Elixir

This guide is about **how to write Haxe that compiles into clean, idiomatic Elixir** with minimal surprises.
It complements:

- `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md` (construct-by-construct mappings)
- `docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md` (codegen conventions and hygiene rules)

## 1) Prefer explicit data + pattern matching

Elixir code shines when the “shape” of data is obvious and matchable.
In Haxe, prefer enums + `switch` over nested `if` chains.

```haxe
enum Auth {
  Anonymous;
  SignedIn(userId:Int);
}

static function greeting(auth:Auth):String {
  return switch (auth) {
    case Anonymous: "Hello!";
    case SignedIn(userId): 'Welcome back user ${userId}!';
  }
}
```

This compiles to a `case` over tagged tuples such as `{:anonymous}` and `{:signed_in, user_id}`.

## 2) Use `Option<T>` / `Result<T, E>` instead of `null` / exceptions

Elixir is dynamically typed, so compile-time safety comes mostly from **explicit success/failure types**.

- Use `Option<T>` for “might be missing”.
- Use `Result<T, E>` for “might fail with an error”.

These compile to idiomatic Elixir tuples:

- `Some(v)` → `{:some, v}`
- `None` → `{:none}`
- `Ok(v)` → `{:ok, v}`
- `Error(e)` → `{:error, e}`

They compose well with `switch` and the provided `OptionTools` / `ResultTools` helpers.

## 3) Embrace immutability (especially for arrays)

In the Elixir target:

- `Array<T>` is an Elixir list (`[...]`)
- `Map<K, V>` is an Elixir map

Prefer functional operations:

```haxe
var numbers = [1, 2, 3, 4, 5];
var doubled = numbers.map(n -> n * 2);
var evens = numbers.filter(n -> n % 2 == 0);
```

This typically becomes `Enum.map/2`, `Enum.filter/2`, etc.

### Loops are fine, but `break`/`continue` are heavier

Haxe loops compile correctly, but `break`/`continue` may lower to more elaborate Elixir constructs
to preserve Haxe semantics. For “simple iteration”, prefer `map/filter/fold/each` style.

## 4) Avoid static mutable state for “global” data

Haxe `static var` is mutable; Elixir is immutable. To preserve semantics, static state is implemented
via process-local storage (you’ll see `Process.get/put` helpers in the generated code).

For application state, prefer BEAM-native patterns:

- LiveView assigns for UI state
- GenServer state for long-lived processes
- ETS for shared in-memory tables (when appropriate)

## 5) Don’t write snake_case or `_unused` names in Haxe (unless you want to)

Reflaxe.Elixir applies Elixir hygiene automatically:

- `camelCase` → `snake_case`
- unused binders get an underscore prefix in Elixir (`_var_name`)

So the usual Haxe style is fine; you can still use leading underscores in Haxe to communicate intent.

## 6) Interop the “Elixir way”: externs + `@:native`

Prefer typed externs (the `std/` surfaces) over raw code injection.

When you need an exact Elixir function name that isn’t a valid Haxe identifier (like `member?` or `fetch!`),
use `@:native` on an extern:

```haxe
extern class Enum {
  @:native("member?")
  static function member<T>(list:Array<T>, value:T):Bool;
}
```

Likewise, use `@:native("My.App.Module")` when you need an exact module name.

## 7) For Phoenix/HXX: turn on strict typing (opt-in)

If you’re building Phoenix apps, enable strict HXX typing in your app so templates behave more like TSX:

- strict dot-component resolution
- typed `:let` and slot tags
- typed `phx-*` event names / hook names (where enabled)

See:
- `docs/06-guides/STRICT_MODE.md`
- `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`

## What to read next

- `docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md` (what the compiler auto-normalizes)
- `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md` (full mapping reference)
- `docs/07-patterns/FUNCTIONAL_PATTERNS.md` (Option/Result patterns in practice)

