# Native BEAM Tuples and Keyword Lists

> **Status:** Supported. Raw tuple-shaped anonymous objects remain the low-level representation;
> `Tuple.of2`–`Tuple.of5`, `Keyword.entry`, and the named `OptionParseResult` view are additive,
> zero-runtime-cost authoring APIs.

Reflaxe.Elixir represents tuples as ordinary BEAM tuples. It does not allocate a Haxe wrapper object
around them. This matters when calling Elixir, Mix, Phoenix, or OTP APIs because those APIs receive
the exact native value they expect.

## The raw syntax remains supported

Haxe does not have a built-in tuple literal. Reflaxe.Elixir therefore recognizes anonymous objects
whose complete field set is a contiguous positional sequence:

```haxe
var status = {_0: "ready", _1: 3};
var label = status._0;
```

Generated Elixir uses a native tuple and a native tuple read:

```elixir
status = {"ready", 3}
label = elem(status, 0)
```

This spelling is intentionally retained. It is compact, fully typed, useful for pattern-oriented or
low-level interop code, and makes the underlying positional representation visible.

### Why the fields are named `_0`, `_1`, and so on

An anonymous-object field in Haxe must be a valid identifier. A decimal number is not an identifier,
so this is not legal Haxe:

```haxe
// Invalid Haxe syntax: `0` cannot be an object-field name.
var pair = {0: "ready", 1: 3};
```

`_0` is a valid identifier. The leading underscore also signals that the field is a positional
carrier rather than an application record field with a business name. It does not become an Elixir
map key: once the compiler proves the complete tuple shape, `_0` becomes tuple position zero, `_1`
becomes position one, and the carrier field names disappear from the generated program.

Two conventions are supported:

- `_0.._N-1` is the zero-based convention used by Elixir-facing externs.
- `_1.._N` is the portable one-based Haxe tuple convention; `_1` still maps to BEAM position zero.

Do not mix the conventions. Fields must be contiguous, and the complete anonymous type must contain
only that positional sequence. A mixed object such as `{_0: "ready", label: "server"}` remains a
normal map-backed anonymous object.

## A map is not a tuple

Haxe already has an indexed map literal:

```haxe
var labels = [0 => "ready", 1 => "busy"];
```

That means a key/value collection. Its generated target value is a BEAM map, conceptually:

```elixir
labels = %{0 => "ready", 1 => "busy"}
```

It cannot safely double as tuple syntax. A map supports lookup by arbitrary keys and does not have a
fixed positional arity; a tuple has ordered positions and is read with `elem/2`. Reinterpreting a map
literal as a tuple based on context would make the same Haxe expression change representation when
its expected type changes. It would also make native map interop unreliable. Reflaxe.Elixir therefore
keeps the distinction explicit:

```text
{_0: "ready", _1: 3}  -> native tuple {"ready", 3}
[0 => "ready", 1 => 3] -> native map %{0 => "ready", 1 => 3}
```

## Construction helpers

Raw positional fields are honest but can obscure intent in ordinary application and tooling code.
The accepted additive API provides forced-inline constructors:

```haxe
import elixir.Tuple;
import elixir.types.Tuple2;

var status:Tuple2<String, Int> = Tuple.of2("ready", 3);
```

The required generated Elixir is still:

```elixir
status = {"ready", 3}
```

`Tuple.of2` through `Tuple.of5` are ordinary Haxe library functions whose bodies construct the same
typed `_0...` carriers. They must be forced inline, so no `Tuple.of2/2` target call, implementation
module, wrapper, boxing, or additional allocation may survive compilation. The existing
`Tuple.make2` through `Tuple.make5` spellings remain source-compatible.

Use the helper when construction intent matters. Use the raw carrier when direct positional syntax,
patterns, or exact interop work is clearer. Both forms describe the same target value.

## Keyword entries

An Elixir keyword list is a list of `{atom, value}` tuples. The accepted Haxe surface names that
protocol directly:

```haxe
import elixir.Keyword;
import elixir.types.KeywordList;
import elixir.types.Term;

var options:KeywordList<Term> = [
  Keyword.entry("package_root", packageRoot),
  Keyword.entry("yes", true),
  Keyword.entry("confirm", confirm)
];
```

Required generated Elixir:

```elixir
options = [
  {:package_root, package_root},
  {:yes, true},
  {:confirm, confirm}
]
```

`Keyword.entry` is not a runtime builder. It is a forced-inline, typed constructor for the same
native two-tuple currently written as `{_0: key, _1: value}`. `KeywordList<T>` remains an ordinary
BEAM list. Use a specific `T` for homogeneous values and `KeywordList<Term>` for heterogeneous Mix or
OTP option lists.

The helper accepts the existing `Atom` type and does not perform runtime atom creation. Literal keys
such as `"yes"` lower to literal atoms under the current `Atom` contract. That contract currently
allows `String` to unify with `Atom`; a runtime string variable is therefore not made safe—or even
guaranteed to become an atom—merely by passing it to `Keyword.entry`. Use reviewed literal or
already-native atom values for keyword keys. This tuple API preserves the existing atom boundary; it
does not claim to redesign it or make untrusted runtime strings safe.

Generic value inference follows the value argument itself. When a keyword value is also a protocol
atom, use a value already typed as `Atom` rather than assuming the surrounding list will retag a
string. `OptionParser` exposes `OptionSwitchTypes.BOOLEAN`, `.STRING`, `.INTEGER`, `.FLOAT`, `.COUNT`,
and `.KEEP` for its supported simple switch definitions:

```haxe
import elixir.Keyword;
import elixir.OptionParser.OptionSwitch;
import elixir.OptionParser.OptionSwitchTypes;

var switches:Array<OptionSwitch> = [
  Keyword.entry("verbose", OptionSwitchTypes.BOOLEAN),
  Keyword.entry("source", OptionSwitchTypes.STRING)
];
```

Complex values remain ordinary expressions. For example:

```haxe
import elixir.Kernel;
import elixir.Keyword;
import elixir.types.KeywordList;
import elixir.types.Term;

static function appOptions(appName:Null<String>):KeywordList<Term> {
  return [
    Keyword.entry(
      "app_name",
      appName == null ? null : Kernel.toString(appName)
    )
  ];
}
```

generates the same direct native structure a careful Elixir author would write:

```elixir
defp app_options(app_name) do
  [
    {:app_name,
     if Kernel.is_nil(app_name) do
       nil
     else
       Kernel.to_string(app_name)
     end}
  ]
end
```

Haxe may introduce a temporary while inlining a helper so a value is still evaluated exactly once.
The compiler removes the resulting anonymous-function scope only when the final AST proves one
direct tuple use and unchanged evaluation order. If a value is used twice, or arguments must be
evaluated before being reordered, the scope is retained. This is intentional: readable output is a
goal, but never at the cost of duplicating a call or changing which call runs first.

## Give established protocols meaningful names

Generic tuple positions are sometimes genuinely positional. Other tuples are public protocols whose
positions have stable meanings. `OptionParser.parse/2`, for example, returns:

```elixir
{parsed_options, remaining_argv, invalid_options}
```

The Haxe view names those positions:

```haxe
import elixir.OptionParser;
import elixir.types.KeywordList;
import elixir.types.Term;

static function parse(
  args:Array<String>,
  parserOptions:KeywordList<Term>
):Array<String> {
  var parsed = OptionParser.parse(args, parserOptions);
  var options = parsed.options;
  var argv = parsed.argv;
  var invalid = parsed.invalid;

  trace(options);
  trace(invalid);
  return argv;
}
```

It must remain a zero-cost view of the same three-tuple. The raw `parsed._0`, `parsed._1`, and
`parsed._2` accessors remain available for compatibility and advanced interop. Named properties are
read-only so they do not imply that a BEAM tuple is a mutable record.

This pattern is deliberately selective. A named view is appropriate only when a stable public
protocol gives each position a durable meaning. Reflaxe.Elixir will not wrap every `Tuple2` in a
universal `first`/`second` abstraction.

## Results and OTP callbacks are separate protocols

Representation sharing does not make every tagged tuple the same API:

- Use `haxe.functional.Result<T, E>` for `{:ok, value}` and `{:error, reason}` flows.
- Use the existing OTP callback result enums for `{:reply, ...}`, `{:noreply, ...}`, and related
  contracts.
- Use `Keyword.entry` for keyword entries.
- Use `Tuple.ofN` or the raw carrier only for genuinely positional/native contracts.

These types preserve legal tags, arities, payload order, and exhaustive Haxe switches. A universal
tagged-tuple helper would discard that useful protocol information.

## Why this design

The design combines three small ideas instead of adding syntax or a compiler subsystem:

1. Keep the existing raw carrier as the transparent, fully supported foundation.
2. Add zero-cost library constructors where `_0`/`_1` obscures construction intent.
3. Add domain-specific named views only where a real protocol gives positions stable names.

This preserves native BEAM terms and old source while improving completion and readability for
Haxe-first developers. It also keeps generated Elixir ordinary and reviewable.

The following alternatives were rejected:

- Treating `[0 => value]` as a tuple would break the meaning and representation of Haxe maps.
- Supporting `{0: value}` would require a Haxe parser fork because numeric object fields are invalid
  Haxe syntax.
- A tuple macro or custom DSL would add compile-time machinery for something a forced-inline function
  can express.
- A universal tuple abstract would add conversion, `Null`, pattern, and package-compatibility risk
  without giving generic positions meaningful names.
- A new compiler AST node or semantic IR is unnecessary because structural native tuple lowering
  already exists.
- Following every abstract's underlying type inside the compiler would violate abstraction and could
  conflict with future representation ownership.

## Zero-cost validation contract

The implementation is guarded with Haxe 4.3.7 source and installed-package fixtures that prove:

- normal, `--no-inline`, and full-DCE compilation emits no helper or implementation module;
- named and forwarded raw reads still become `elem/2`;
- `Null<OptionParseResult>` remains unboxed and usable after a null check;
- source-checkout and independently packaged-library compilation produce the same target shape;
- raw construction, reads, updates, and patterns remain compatible;
- a write to a named read-only property fails at the authored Haxe expression.

The experiment found one narrow compiler boundary worth preserving explicitly. Forced-inline named
getters reached the existing tuple reader, but an automatically forwarded raw write such as
`parsed._0 = options` was otherwise seen as an abstract field and could become an unrelated `_0`
local. `OptionParseResult` therefore carries `@:elixirNativeTupleView`. The tuple classifier follows
only an abstract with that marker, substitutes its type parameters, and then requires the same
complete contiguous `_N` carrier it already requires for raw tuples. This makes old raw writes use
native `put_elem/3` rebinding without teaching the compiler to unwrap arbitrary abstracts.

The marker is a target ABI promise, not general convenience metadata. An unmarked abstract remains
opaque even if its hidden implementation happens to look tuple-shaped. That boundary preserves Haxe
abstraction and leaves future representation decisions explicit.

## Related references

- [Haxe to Elixir mappings](../02-user-guide/HAXE_ELIXIR_MAPPINGS.md#tuple-shaped-anonymous-objects)
- [Compilation flow: anonymous tuple contract](../05-architecture/COMPILATION_FLOW.md#anonymous-tuple-shaped-object-contract)
- [Interop with existing Elixir](../02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md)
