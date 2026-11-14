# Test the second switch with its own value

A Haxe author can unwrap a result and then switch on a second value:

```haxe
final found = switch lookup(key) { case Ok(value): value; case Err(error): return Err(error); };
final depth = switch wordOf(found) { case "summary": 1; case "body": 2; case _: return Err("unknown depth"); };
```

Haxe stores the value of each switch in a temporary variable, and both get the
name `_g`. After the early return is lowered, the second switch lives inside the
`Ok` branch of the first one:

```elixir
_g = lookup(key)
case _g do
  {:ok, value} ->
    found = value
    _g = word_of(found)
    case _g do ...
```

The pass `TempAliasCleanup` removes `_g = lookup(key)` and writes the call where
`_g` is read. It replaced every `_g` in the case, also the reads of the second
binding. The second switch then tested `lookup(key)`, never matched a word, and
the lookup ran three times.

The pass now replaces the alias only when the rest of the block reads that binding
exactly once, and it writes the value only in that one place.

`runtime.exs` checks the result for each word and that the lookup runs once.

Run the snapshot with `make -C test test-regression__switch_after_early_return_switch`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture covers one alias that is bound again in a case body. It does not
cover other passes that replace temporary variables.
