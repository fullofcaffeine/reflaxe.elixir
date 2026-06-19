# Haxe Float Special Values on BEAM

This document defines the target contract for Haxe `Float` special values on
Reflaxe.Elixir.

Status: implemented and full-suite hardened. Tagged special values exist,
compiler numeric operators route through the HaxeFloat helper, and the upstream
`Math.unit.hx` runtime spec is enabled. IEEE byte paths round-trip through
`Bytes`, `BytesBuffer`, `Input`, `Output`, and `FPHelper`. JSON, Haxe
serialization, template stringification, and finite-native Erlang math
boundaries understand the tagged special-value representation.

## Authoring Profile Scope

This contract is primarily for the **portable stdlib-first** lane.

Portable Haxe code expects Haxe `Float`, `Math`, `Std.parseFloat`,
serialization, JSON, and byte APIs to behave like Haxe across targets. On BEAM,
that requires an explicit HaxeFloat compatibility layer because Elixir does not
provide native NaN/Infinity terms.

Typed Elixir-first code can often avoid this layer. If a module deliberately
uses BEAM-native externs and finite Elixir numbers, it should follow the native
Elixir contract: invalid math domains may raise, native externs may require
finite floats, and direct `:math.*` calls should not pretend to accept Haxe
special values.

The compiler still needs HaxeFloat because one project can mix both styles:
portable domain modules may produce Haxe special floats, while Phoenix/Ecto/OTP
edge modules may prefer native BEAM semantics. Boundaries between the two should
classify, encode, or reject special values explicitly instead of silently
coercing them.

## Problem

Haxe exposes IEEE-style `Float` special values:

- `Math.NaN`
- `Math.POSITIVE_INFINITY`
- `Math.NEGATIVE_INFINITY`

BEAM/Elixir does not reliably expose these as ordinary terms. Operations such
as `0 / 0`, `:math.sqrt(-1)`, and `:math.log(0)` raise before a value exists,
and parsers such as `Float.parse("NaN")` do not produce native NaN values.

The old Reflaxe.Elixir approximation used maximum finite floats for infinities
and `0.0 / 0.0` for NaN. That is not faithful:

- `1.7976931348623157e308` is a valid finite float, not infinity.
- `Math.isFinite(1.7976931348623157e308)` must be true.
- `Math.NaN` must be constructible without raising.
- IEEE byte encoding must distinguish max finite, infinity, and NaN.

## Decision

Use native BEAM numbers for finite values and tagged sentinels only for special
values:

```elixir
@type special ::
        {Reflaxe.Elixir.HaxeFloat, :nan}
        | {Reflaxe.Elixir.HaxeFloat, :positive_infinity}
        | {Reflaxe.Elixir.HaxeFloat, :negative_infinity}

@type t :: number() | special()
```

The Haxe-facing runtime helper is `Reflaxe.Elixir.HaxeFloat`.

This is a hybrid representation:

- Finite integer/float operations stay cheap and native where the compiler can
  prove no Haxe special-value semantics are involved.
- NaN and infinities are explicit values that can be pattern-matched and carried
  through `Dynamic`, arrays, maps, callbacks, serializers, and JSON printers.
- The compiler lowers Haxe Float-like operators through a central numeric
  builder so sentinels never reach native BEAM arithmetic or native ordered
  comparison.

Do not use max-finite stand-ins. Do not stop at a Math-only helper. Do not box
every finite float.

## Runtime Invariant

Tagged special values must not be passed directly to:

- native `+`, `-`, `*`, `/`, or remainder
- native ordered comparison
- `:math.*`
- Elixir float bitstring segments
- externs that require native finite BEAM floats

Any such boundary must classify, unwrap, encode, or reject the value first.

## Arithmetic Rules

`Reflaxe.Elixir.HaxeFloat` owns the special-value table.

Required behavior:

| Operation | Result |
| --- | --- |
| arithmetic with NaN | NaN |
| `+Infinity + -Infinity` | NaN |
| same-sign infinity addition | same infinity |
| same-sign infinity subtraction | NaN |
| `Infinity * 0` | NaN |
| infinity multiplication | sign from operands |
| `Infinity / Infinity` | NaN |
| finite nonzero divided by zero | signed infinity |
| zero divided by zero | NaN |
| finite divided by infinity | signed zero |
| unary `-` | swaps infinities; NaN remains NaN |
| equality with NaN | always false |
| inequality with NaN | always true |
| ordered comparison with NaN | always false |
| infinity ordering | `-Infinity < finite < +Infinity` |

Finite overflow should become signed infinity rather than leaking an
`ArithmeticError`.

Signed zero must be handled with IEEE bit inspection where sign matters.
Comparison cannot determine signed-zero sign.

## Compiler Ownership

Float special values are a compiler-wide numeric semantics feature, not a Math
module quirk.

The target design adds a central numeric lowering owner:

```text
src/reflaxe/elixir/ast/builders/NumericOpBuilder.hx
```

That builder should own:

- Float-like arithmetic
- Float-like equality and inequality
- Float-like ordered comparison
- unary Float negation
- prefix/postfix increment and decrement arithmetic
- compound assignment arithmetic
- string coercion involving Float-like values
- preserving native Int and bitwise fast paths

`BinaryOpBuilder`, `AssignmentBuilder`, and direct numeric lowering in
`ElixirASTBuilder` should delegate through this layer instead of emitting
native BEAM operators when a value may contain Haxe Float specials.

Equality must be conservative. A tagged NaN tuple is reflexively equal under
BEAM term equality, so Haxe `==` and `!=` must call the helper when either side
is Float-like or potentially `Dynamic`.

## Guard Policy

Remote helper calls cannot appear in Elixir guards.

Guard-safe Float checks must inline primitive classification, for example:

```elixir
is_float(value) or
  (is_tuple(value) and tuple_size(value) == 2 and
     elem(value, 0) == Reflaxe.Elixir.HaxeFloat and
     elem(value, 1) in [:nan, :positive_infinity, :negative_infinity])
```

Float arithmetic and ordered comparisons must not be lifted into `when`
clauses. They belong in an `if`, `case`, or `cond` body unless a dedicated
guard-safe rewrite exists.

## Stdlib Surfaces

The implementation must update these source-of-truth areas:

- `std/Math.cross.hx`: runtime-backed special constants and Math functions.
- `std/Std.cross.hx`: `parseFloat`, `string`, and type checks.
- `std/Type.cross.hx`: `Type.typeof` must classify HaxeFloat before generic
  tuples/enums.
- `src/reflaxe/elixir/ElixirTyper.hx`: Haxe `Float` typespecs should include native
  numbers plus the tagged special tuple. Today this is emitted as an inline union
  because the generated runtime helper does not yet emit an Elixir `@type t`.
- `src/reflaxe/elixir/CompilerInit.hx`: retain the runtime helper until runtime
  dependency registration can be made conditional.
- `src/reflaxe/elixir/ast/builders/CallExprBuilder.hx`: remove or redirect
  `Std.parseFloat` and Float type intrinsics to the shared runtime semantics.
- `src/reflaxe/elixir/ast/builders/ExceptionBuilder.hx`: Float catches must
  recognize native finite floats and HaxeFloat specials.

## IEEE Byte Policy

Haxe `Bytes`, `BytesBuffer`, `Input`, `Output`, and `FPHelper` promise IEEE
single/double encoding. BEAM must not decode arbitrary special float bit
patterns as native floats.

Decode integer bits first:

- all-one exponent plus zero fraction -> signed infinity
- all-one exponent plus nonzero fraction -> NaN
- finite patterns -> native BEAM float

Encode tagged specials to canonical IEEE values:

| Value | f64 little-endian | f32 little-endian |
| --- | --- | --- |
| `+Infinity` | `000000000000f07f` | `0000807f` |
| `-Infinity` | `000000000000f0ff` | `000080ff` |
| canonical quiet NaN | `000000000000f87f` | `0000c07f` |

NaN payloads are decoded semantically and re-encoded as a canonical quiet NaN.
Payload identity is not exposed by Haxe APIs today.

## JSON and Serialization

`JsonPrinter` classifies semantically. Non-finite floats serialize as JSON
`null`, matching Haxe's stdlib behavior. This applies at the top level, inside
arrays/objects, and after a replacer callback returns a special value.

`Serializer` and `Unserializer` recognize tagged specials and use Haxe's
standard wire tags:

- `k` -> NaN
- `p` -> positive infinity
- `m` -> negative infinity

`Template` renders tagged specials through `HaxeFloat.toString`, and numeric
template literals parse through the same Haxe-compatible longest-prefix parser.

## Current Boundary

The runtime now supports Haxe `Math` special-value behavior through
`Reflaxe.Elixir.HaxeFloat`, `Math.unit.hx` is enabled in the upstream unitstd
manifest, and IEEE byte paths encode/decode Haxe special floats without passing
special bit patterns to native BEAM float segments.

Implemented byte-path coverage includes:

- canonical f32/f64 encodings for NaN and infinities
- alternate NaN payload decode with canonical NaN re-encode
- signed-zero preservation
- max-finite values remaining finite
- stream round-trips through `BytesInput` and `BytesOutput`
- JSON `null` output for non-finite floats
- Haxe serializer/unserializer `k` / `p` / `m` round-trips
- template rendering and numeric parsing for special values
- clear finite-native diagnostics at `elixir.ErlangMath` boundaries

Future work should focus on additional native extern boundaries discovered by
examples or downstream libraries.

Any implementation that touches this area must add runtime tests, not only
generated-code snapshots.
