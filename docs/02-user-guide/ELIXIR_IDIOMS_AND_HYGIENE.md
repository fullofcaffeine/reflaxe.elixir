# Elixir Idioms & Hygiene (Codegen Conventions)

This guide documents **small but important** conventions Reflaxe.Elixir applies so the generated Elixir:

- is idiomatic and readable
- avoids common compiler warnings
- preserves Haxe semantics in an immutable, expression-oriented target

If you’re looking for construct-by-construct mappings (classes, enums, types, control flow), also see:
`docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md`.

## Naming: snake_case + module casing

### Variables and functions

Haxe typically uses `camelCase`. Elixir idiomatically uses `snake_case`.

Reflaxe.Elixir normalizes:

- local variables and function parameters → `snake_case`
- function names → `snake_case`

Example:

```haxe
public static function parseNumber(input: String): Int { ... }
```

Generates (shape):

```elixir
def parse_number(input) do
  ...
end
```

### Reserved keywords (and backtick escapes)

Elixir has reserved keywords like `when`, `end`, `do`, `fn`, `case`, etc.
If a generated identifier would collide with a reserved keyword, Reflaxe.Elixir appends a trailing underscore:

- `when` → `when_`
- `` `end` `` (Haxe escaped identifier) → `end_`

This keeps the output valid Elixir without requiring awkward names in Haxe.

Example (Haxe):

```haxe
var when = 1;
var `end` = 2;
```

Generated (shape):

```elixir
when_ = 1
end_ = 2
```

### Name collisions after snake_case

Sometimes two different Haxe names normalize to the same `snake_case` identifier (for example `userID` and `user_id`,
or `HTTPServer` and `HttpServer`).

When that would produce invalid Elixir (shadowing/collision in the same scope), the compiler will disambiguate names
in a predictable way. You may see suffixes or other small adjustments in generated code to keep every binding unique.

Tip: if you care about “perfectly clean” output, avoid defining two identifiers that normalize to the same
`snake_case` name in the same scope.

### Modules

Haxe packages and class names become Elixir module namespaces:

- `my.app.UserService` → `My.App.UserService`
- `MyThing` stays `MyThing` (module casing is preserved/normalized)

Use `@:native("My.App.UserService")` when you need an exact module name.

## Unused variables: automatic underscore-prefixing

Elixir warns on unused variables and parameters. The idiomatic way to silence this is a leading underscore (`_var`).

Reflaxe.Elixir performs **usage analysis** and automatically prefixes unused binders in the generated Elixir:

- unused local variables → `_var_name = ...`
- unused function/callback parameters → `def f(_arg) do ... end`
- unused pattern binders:
  - `case`/`with` throwaway slots prefer wildcard `_` when safe
  - binders that carry pattern semantics stay named (`_name`)

This means:

- You **do not** need to write leading underscores in Haxe to get warning-free Elixir.
- You **can** still use `_foo` in Haxe to explicitly communicate “intentionally unused”; the compiler preserves it.

Example (Haxe):

```haxe
var upperResult = ResultTools.map(result, s -> s.toUpperCase());
// upperResult intentionally unused
```

Generated (shape):

```elixir
_upper_result = ResultTools.map(result, fn s -> String.upcase(s) end)
```

### Wildcards vs “unused named” binders

- `_` is treated as the Elixir wildcard and is preserved as-is.
- `_name` is treated as an intentionally-unused named variable and is preserved (or generated) as `_name`.

Generated policy for readability + semantics:

- Function/callback parameters use `_name` so signatures stay easy to read.
- Pattern slots in `case`/`with`/`receive` use `_` when that slot is a pure discard.
- The compiler keeps `_name` in patterns when wildcarding would change matching behavior (for example repeated binders or alias binders).

Example:

```haxe
switch (result) {
  case Ok(value): true;
  case Error(reason): false;
}
```

```elixir
case result do
  {:ok, _} -> true
  {:error, _} -> false
end
```

When a named binder is required to keep pattern behavior (for example repeated binders that must match),
generated code keeps an underscored name such as `{:pair, _x, _x}`.

### Special case: Phoenix `assigns`

Phoenix function components and `~H` templates expect the parameter to be named `assigns`.
Even if it’s unused, the compiler keeps it as `assigns` (it will not be rewritten to `_assigns`).

## Statement calls: bare by default

Elixir evaluates expressions in a block from top to bottom. A function or macro call therefore does not need a
wildcard match just because its return value is unused.

Haxe:

```haxe
import elixir.Process;

var worker = Process.self();
Process.send(worker, "refresh");
Process.monitor(worker);
```

Generated Elixir (shape):

```elixir
worker = Process.self()
Process.send(worker, "refresh")
Process.monitor(worker)
```

The same rule applies to Phoenix router macros such as `plug`, `live`, and `get`, and to Ecto schema and migration
DSL calls. A bare call still runs and keeps normal Elixir exception behavior. When it is the final expression, its
value is also the function's return value.

You may still see `_ = expression` where the compiler intentionally needs an Elixir wildcard match or must make a
discarded non-call value explicit. It is not the default representation of an effectful statement.

## Enums: tagged tuples everywhere

Reflaxe.Elixir represents Haxe enums as **tagged tuples**, so pattern matching is uniform:

- zero-argument constructor → `{:red}` (1-tuple)
- constructor with N args → `{:rgb, r, g, b}` (N+1 tuple)

Example (Haxe):

```haxe
enum Color {
  Red;
  Rgb(r:Int, g:Int, b:Int);
}
```

Generated usage (shape):

```elixir
{:red}
{:rgb, r, g, b}
```

### `Option<T>` and `Result<T, E>` (recommended idioms)

Two enums are used pervasively in the stdlib and Phoenix surfaces:

- `Option<T>`:
  - `Some(v)` → `{:some, v}`
  - `None` → `{:none}`
- `Result<T, E>`:
  - `Ok(v)` → `{:ok, v}`
  - `Error(e)` → `{:error, e}`

These shapes are intentionally “Elixir-native”:
- they work well with `case`, guards, and pipelines
- they’re compatible with typical OTP-style return conventions

## Nullability: `null` becomes `nil`

`null` in Haxe becomes `nil` in Elixir. Prefer `Option<T>` when you want the type system to force handling.

## Data shapes: lists + maps

### Arrays are lists

`Array<T>` compiles to an Elixir list (`[...]`). Many familiar operations become `Enum.*` calls:

- `array.map(f)` → `Enum.map(array, f)`
- `array.filter(f)` → `Enum.filter(array, f)`
- `array.contains(x)` → `Enum.member?(array, x)`

This is implemented in `std/elixir/_std/Array.hx` and is designed to read like hand-written Elixir.

### Anonymous structures are maps (atom keys)

Haxe anonymous structures / typedef “records” compile to Elixir maps with atom keys:

```haxe
var user = { name: "Alice", age: 42 };
```

Shape:

```elixir
user = %{:name => "Alice", :age => 42}
```

Field reads and updates use idiomatic Elixir map syntax:

- `user.name` (read)
- `%{user | name: "Bob"}` (update)

### Class instances are map-backed (no mutation)

Reflaxe.Elixir models “instances” as immutable map-backed values. Instance methods become module functions that take
the instance as an explicit first parameter (often named `struct` in generated code).

Shape:

```elixir
defmodule Point do
  def new(x_param, y_param) do
    struct = %{:x => nil, :y => nil}
    struct = %{struct | x: x_param}
    struct = %{struct | y: y_param}
    struct
  end

  def distance(struct, other) do
    ...
  end
end
```

If your Haxe code relies heavily on mutating fields, consider refactoring toward returning updated values (functional
style), which maps naturally onto Elixir.

#### Field assignment lowers to map updates

Haxe-style field assignment compiles to immutable map update syntax.

Example (shape):

```elixir
struct = %{struct | x: new_x}
```

### Atom keys vs string keys

- Haxe anonymous structures compile to maps with **atom keys** (e.g. `%{:name => "Alice"}`).
- If you need string keys (common for JSON-ish payloads), use an explicit `Map<String, T>` / dynamic map and the
  generated code will use string keys where appropriate.

## Interop naming: `?`/`!` functions via `@:native`

Many Elixir APIs use `?` / `!` suffixes (`member?`, `fetch!`, `get_in`, etc.). Those aren’t valid Haxe identifiers.

Use `@:native` on externs to call them precisely:

```haxe
extern class Enum {
  @:native("member?")
  static function member<T>(list:Array<T>, value:T):Bool;
}
```

This keeps your Haxe code typed and avoids raw Elixir injection.

Example (`!` function):

```haxe
import elixir.ElixirMap;

// Calls `Map.fetch!/2` under the hood.
var value = ElixirMap.fetchBang(myMap, key);
```

## Control flow: expressions + preservation helpers

### Binding semantics in generated patterns

This section explains a generated-code detail that comes from ordinary Haxe comparisons against an already-known local.

Example Haxe source:

```haxe
var expectedStatus = status;
var label = (status == expectedStatus) ? "same" : "other";
```

When lowered to expression-oriented Elixir, a common shape is a `case` comparison with pinning.
In Elixir patterns, `^name` means "match the existing value", while plain `name` creates/rebinds a pattern variable.

During lowering, you may see a shadow-prone intermediate form that is normalized to the final safe shape:

```elixir
# Plain pattern variable: binds a new value in pattern position
expected_status = status
case status do
  expected_status -> :same
  _ -> :other
end

# Compiler-emitted shape: pin matches the existing local
expected_status = status
case status do
  ^expected_status -> :same
  _ -> :other
end
```

`^expected_status` preserves the comparison intent from Haxe. Without `^`, the branch pattern would bind a new value.

Reflaxe.Elixir runs late hygiene passes to pin existing bindings where needed, so generated pattern code preserves
intent and avoids accidental shadowing.

If you want strict "assign once" behavior in Haxe source, use `final` (enforced by Haxe typing). There is currently no
global Reflaxe.Elixir mode that forbids all rebinding in generated Elixir.

### Reassignment pipelines → `|>`

When the compiler sees a contiguous sequence like `x = f(x, ...)` then `x = g(x, ...)`, it may collapse it into a pipe:

```elixir
x = x |> f(...) |> g(...)
```

This is a readability optimization only; it doesn’t change semantics.

### Haxe-authored pipe chains with `>>`

Use `reflaxe.elixir.Pipe` when a boundary value is being narrowed through a few
small, typed steps and the code reads better left-to-right. This is especially
useful for Phoenix params, JSON-ish terms, and domain ID parsing.

Haxe cannot parse Elixir's literal `|>` operator, so PhoenixHx uses `>>` as a
typed authoring helper:

```haxe
using reflaxe.elixir.Pipe;

var resourceId:Null<ResourceId> = params.pipe()
  >> (p -> ElixirMap.get(p, "resource_id"))
  >> Params.stringFromTerm
  >> ResourceIds.fromParam;
```

This is not a runtime protocol object and it does not invent a Phoenix API. The
compiler lowers the chain to ordinary calls or straight-line rebinding. A
typical generated shape is:

```elixir
value = params
value = Map.get(value, "resource_id")
value = PhoenixHx.Params.string_from_term(value)
value = ResourceIds.from_param(value)
value
```

The same boundary read can be written several ways. Pick the lightest shape that
keeps the intent obvious.

Imperative Haxe is often best when you want names for each boundary step:

```haxe
var raw = ElixirMap.get(params, "resource_id");
var text = Params.stringFromTerm(raw);
var resourceId = ResourceIds.fromParam(text);
```

Nested calls are compact, but become harder to scan as the chain grows:

```haxe
var resourceId = ResourceIds.fromParam(
  Params.stringFromTerm(
    ElixirMap.get(params, "resource_id")
  )
);
```

Without a `using` import, start the typed chain with `Pipe.of(...)`:

```haxe
import reflaxe.elixir.Pipe;

var resourceId:Null<ResourceId> = Pipe.of(params)
  >> (p -> ElixirMap.get(p, "resource_id"))
  >> Params.stringFromTerm
  >> ResourceIds.fromParam;
```

With `using reflaxe.elixir.Pipe`, the closest Haxe spelling to Elixir `|>` is
`value.pipe() >> step`:

```haxe
using reflaxe.elixir.Pipe;

var resourceId:Null<ResourceId> = params.pipe()
  >> (p -> ElixirMap.get(p, "resource_id"))
  >> Params.stringFromTerm
  >> ResourceIds.fromParam;
```

The raw Elixir equivalent would be:

```elixir
resource_id =
  params
  |> Map.get("resource_id")
  |> PhoenixHx.Params.string_from_term()
  |> ResourceIds.from_param()
```

Each `>>` stage must be unary (`T -> U`), so the Haxe compiler rejects wrong
arity or incompatible step types before the code reaches Elixir. If Haxe cannot
infer the final type from the assignment or return position, call `.value()` to
unwrap the last `Pipe<T>` explicitly.

Do not use this for every function call. Plain locals or a direct helper such as
`Params.getString(params, "name")` are simpler for one-off reads. If the pipe
adds lines, hides a good helper, or makes a single operation look more abstract,
leave the code direct. Reach for a pipe when the dataflow is the point: a
runtime boundary term becomes a typed app value through several named
transformations.

### `switch` → `case` (expression-preserving)

Haxe `switch` is an expression; Elixir `case` is also an expression, but compilation sometimes needs
temporary variables to preserve evaluation order and “return from inside” behavior.

Example Haxe source that may trigger helper shapes:

```haxe
var label = switch (status) {
  case Pending: "waiting";
  case Processing(progress): 'processing ${progress}%';
  case Done(result): result;
}
```

Why this exists: the compiler must preserve Haxe expression semantics exactly, even when Elixir needs extra
plumbing bindings to represent the same flow safely.

You may see compiler-generated helpers such as:

- `_g` / `g` scratch variables (for expression plumbing)
- `Enum.reduce_while(..., :__reflaxe_no_return__, fn ... -> ... end)` patterns
- `{:__reflaxe_return__, value}` sentinels when a `return` must escape an internal loop

These are intentional and exist to keep Haxe semantics correct in Elixir’s immutable model.

### `break` / `continue` in loops

When Haxe uses `break` / `continue`, compilation may introduce `throw`/`catch` inside
`Enum.reduce_while` to emulate structured loop control flow without mutable state.

Example Haxe source:

```haxe
var found = -1;
for (i in 0...items.length) {
  if (items[i] == null) continue;
  if (items[i] == target) {
    found = i;
    break;
  }
}
```

Why this exists: Elixir has no direct mutable loop + `break`/`continue` construct, so the compiler encodes
those exits with reduction state and structured throws/catches.

In those cases you’ll often see patterns like:

- `Enum.reduce_while(..., acc, fn _, acc -> ... end)`
- `throw({:break, acc})` / `throw({:continue, acc})`
- `catch :throw, {:break, break_state} -> ...`

## Static fields: process-local state (avoid for application data)

Haxe `static var` is mutable. To preserve semantics, static storage is implemented using process-local storage
(you may see `Process.get/put` in generated code).

This is correct for “compiler/runtime needs”, but for application state prefer BEAM-native patterns (GenServer state,
LiveView assigns, ETS, etc.).

## Interop escape hatches

When you need exact Elixir code, use the supported injection surfaces (documented here):

- `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`

These are powerful but should be used sparingly; prefer typed externs and stdlib helpers when possible.
