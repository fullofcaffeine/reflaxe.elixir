# Writing Idiomatic Haxe for Elixir

This guide is about **how to write Haxe that compiles into clean, idiomatic Elixir** with minimal surprises.
It complements:

- `docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md` (construct-by-construct mappings)
- `docs/02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md` (codegen conventions and hygiene rules)
- `docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md` (how mutation becomes immutable Elixir, including tradeoffs)
- `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md` (portable vs Elixir-first authoring choices)

## Quick Do / Don’t

Do:

- Prefer **enums + `switch`** for control flow (great Elixir `case` output).
- Prefer **`Option<T>` / `Result<T, E>`** when the caller controls expected absence or failure.
- Prefer a standard collection operation when it describes the whole job, such as `items.contains(value)`.
- Treat “instances” as **immutable values** (return updated values rather than mutating).
- Prefer **typed externs + `@:native`** over raw injection for interop.

Don’t (unless you’re intentionally taking on more complex lowering):

- Don’t lean on heavy `break`/`continue` loop control for core logic (it compiles, but gets more elaborate).
- Don’t rely on large amounts of **static mutable state** for application data (prefer GenServer/ETS/assigns).
- Don’t pre-emptively write snake_case or `_unused` names in Haxe “for Elixir” (the compiler handles hygiene).

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

## 2) Choose an error contract that matches the caller

An error contract tells a caller which outcomes to expect and handle.

- Use `Option<T>` when a missing value is normal and the caller must choose what to do.
- Use `Result<T, E>` when an operation can succeed or return an expected error.

These compile to idiomatic Elixir tuples:

- `Some(v)` → `{:some, v}`
- `None` → `{:none}`
- `Ok(v)` → `{:ok, v}`
- `Error(e)` → `{:error, e}`

They work well with `switch` and the provided `OptionTools` / `ResultTools` helpers.

Nullable values and exceptions are also valid when they state the intended contract.
For example, a lookup can return `Null<User>` when “not found” is a normal target API result.
A required lookup can raise an exception when a missing record means that the function cannot honor its contract.

Do not change one error contract to another only for style. Each contract tells the caller something different.

## 3) Prefer a standard collection operation when it states the whole job

A membership check asks one question: does this array contain this value?
The todo app previously answered that question with a mutable Boolean and a complete loop:

```haxe
function containsKey(keys:Array<String>, key:String):Bool {
	var found = false;
	for (candidate in keys) {
		if (candidate == key)
			found = true;
	}
	return found;
}
```

The standard Haxe operation states the intent directly at the call site:

```haxe
if (!previousKeys.contains(key)) {
	recordJoin(key);
}
```

Reflaxe.Elixir generates the ordinary Elixir membership operation:

```elixir
if not Enum.member?(previous_keys, key) do
  record_join(key)
end
```

`Enum.member?/2` returns `true` when the collection contains the requested value.
The typed Haxe call also rejects a value of the wrong type before the app runs.

This guidance does not mean that loops are bad. The compiler already converts many safe loops into operations such as `Enum.map` and `Enum.count`.
Use a named operation when it describes the entire job more clearly than the loop.

## 4) Prefer explicit immutable flows (especially today)

In the current Elixir output:

- `Array<T>` is an Elixir list (`[...]`)
- `Map<K, V>` is an Elixir map

Prefer functional operations:

```haxe
var numbers = [1, 2, 3, 4, 5];
var doubled = numbers.map(n -> n * 2);
var evens = numbers.filter(n -> n % 2 == 0);
```

This typically becomes `Enum.map/2`, `Enum.filter/2`, etc.

This guidance is both idiomatic and a practical way to avoid the current
shared-alias gap. It does not redefine ordinary Haxe `Array`/`Map` mutators as
value-semantic: when two variables alias one mutable Haxe collection, the
pinned Haxe contract may require both to observe a write, while current
list/map rebinding updates only one. Managed collection semantics are accepted
but not shipped. See [Known Limitations](../06-guides/KNOWN_LIMITATIONS.md).

### Loops are fine, but `break`/`continue` are heavier

Haxe loops compile correctly, but `break`/`continue` may lower to more elaborate Elixir constructs
to preserve Haxe semantics. For “simple iteration”, prefer `map/filter/fold/each` style.

## 5) Avoid static mutable state for “global” data

Haxe `static var` is mutable; Elixir is immutable. To preserve semantics, static state is implemented
via process-local storage (you’ll see `Process.get/put` helpers in the generated code).

For application state, prefer BEAM-native patterns:

- LiveView assigns for UI state
- GenServer state for long-lived processes
- ETS for shared in-memory tables (when appropriate)

## 6) Don’t write snake_case or `_unused` names in Haxe (unless you want to)

Reflaxe.Elixir applies Elixir hygiene automatically:

- `camelCase` → `snake_case`
- unused binders get an underscore prefix in Elixir (`_var_name`)

So the usual Haxe style is fine; you can still use leading underscores in Haxe to communicate intent.

## 7) Interop the “Elixir way”: externs + `@:native`

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

## 8) For Phoenix/HXX: turn on strict typing (opt-in)

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
