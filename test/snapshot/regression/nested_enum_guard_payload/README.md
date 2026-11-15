# Match the inner value of a nested enum pattern with a guard

A guard on a nested pattern makes Haxe rewrite the switch into an `if` on the
constructor index:

```haxe
return switch r {
  case Err(Stale(wanted, _)) if (wanted > 0): wanted + value;
  case Err(Fresh(count)): count + value;
  case _: -1;
};
```

The compiler turns that `if` back into a `case` and binds the `Err` payload in
the pattern. It then also built the payload extraction as a statement. That
extraction is skipped on purpose, because the pattern already binds the value,
but the skipped declaration fell through to the path for an uninitialized
variable and became `g = nil`:

```elixir
{:err, g} ->
  g = nil
  case g do        # later simplified to `case nil do`
```

Every `Err` value took the fallback and returned -1. A skipped initialized
declaration now emits nothing:

```elixir
{:err, g} ->
  case g do
    {:stale, wanted, _} -> if wanted > 0, do: wanted + value, else: -1
```

`expected.stdout` is the output of this program on the Haxe interpreter. It
covers a guard on the first and on the second inner pattern, a guard that
fails, and the outer fallback.

Run the snapshot with `make -C test test-regression__nested_enum_guard_payload`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/nested_enum_guard_payload`.
