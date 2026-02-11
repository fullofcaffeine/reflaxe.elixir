# Atom Type (elixir.types.Atom)

Reflaxe.Elixir provides `elixir.types.Atom` as a **type-safe, zero-cost** way to represent Elixir atoms in Haxe.

## What It Is

- `Atom` is an `abstract Atom(String)` that **compiles to an Elixir atom** (e.g. `:ok`), not a string.
- Use it to make intent explicit and prevent accidentally passing `"ok"` where an atom is required.

Reference implementation: `std/elixir/types/Atom.hx`.

## When To Use Atom

- Elixir APIs that accept atoms for options: `:temporary_assigns`, `:compress`, etc.
- Result/status atoms: `:ok`, `:error`, `:noreply`, `:stop`.
- Enum-like option sets, best modeled as `enum abstract` over `Atom`.

## Basic Usage

```haxe
import elixir.types.Atom;

var ok: Atom = "ok";        // generates :ok
var error: Atom = "error";  // generates :error
```

Compiles to:

```elixir
ok = :ok
error = :error
```

## Enum Abstract Pattern

Prefer an `enum abstract` over `Atom` when the API takes a fixed set of atoms.

```haxe
import elixir.types.Atom;

enum abstract TimeUnit(Atom) to Atom {
  var Second = "second";
  var Millisecond = "millisecond";
  var Microsecond = "microsecond";
}
```

Compiles to atom values consumed by Elixir APIs, for example:

```elixir
:second
:millisecond
:microsecond
```

## Safety Notes (Important)

- Atoms are not garbage-collected on the BEAM.
- Do not create atoms from untrusted or unbounded user input.
- Prefer strings for user-provided keys and values, and only use `Atom` for **known, finite** sets.
