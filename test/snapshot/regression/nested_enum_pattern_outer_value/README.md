# Match an inner pattern against the value of the outer pattern

A Haxe author can match a pattern inside a pattern:

```haxe
return switch admit(expected, actual) {
  case Err(Stale(wanted, _)): wanted == expected;
  case _: false;
};
```

Haxe names both the whole result and the value inside `Err` `_g`. The first
Elixir form is correct, because the inner `g` hides the outer one:

```elixir
g = admit(expected, actual)
case g do
  {:err, g} ->
    case g do
      {:stale, wanted, _} -> wanted == expected
```

The pass `CaseTupleBinderUnshadow` renames such a binder to `value`, so the two
names differ. It did not rename the reads in the clause body. The inner `case g`
then tested the whole result again, the clause never matched, and the function
returned `false` for a stale digest.

The pass now renames the reads of the binder together with the binder.

`runtime.exs` checks a stale, an equal and a malformed digest natively.

Run the snapshot with `make -C test test-regression__nested_enum_pattern_outer_value`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

Limit: when the clause binds the same name again, or already uses `value`, the pass
leaves the clause unchanged. This fixture does not cover those cases.
