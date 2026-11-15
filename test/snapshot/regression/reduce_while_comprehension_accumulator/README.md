# Keep the result of a comprehension whose outer loop is `Enum.reduce_while`

```haxe
return [for (k in m.keys()) k];
return [for (k in m.keys()) for (x in xs) k + x];
return [for (i in 0...2) for (k in im.keys()) i * 10 + k];
```

Haxe turns a comprehension into one empty array and loops that add to it. A
loop over map keys, over map values, or over an iterator becomes
`Enum.reduce_while` in Elixir. The array travels through the loop as an
accumulator, and the loop result rebinds it as a one-element tuple. The
generated code was:

```elixir
{_g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} -> ... end)
[]
```

The loop was correct, but the function returned `[]`, the empty initial list,
for any input. `haxe --interp` returned `a,b`. The compiler gave no warning.

Two more shapes were wrong in a different way:

- Keys inside keys. The inner loop started from `{[]}` instead of the outer
  loop's state `{acc__g}`, so each outer step dropped the earlier elements.
- A constant range around a map loop. Haxe unrolls `for (i in 0...2)` into two
  copies of the inner loop. The second copy also started from `{[]}`, so it
  dropped the elements of the first copy.

The fixed code returns the loop result and threads one state through every
loop:

```elixir
{g} = Enum.reduce_while(Map.keys(m), {[]}, fn k, {acc__g} ->
  {acc__g} = Enum.reduce_while(Map.keys(im), {acc__g}, fn j, {acc__g} -> ... end)
  ...
end)
g
```

## Cause

Two separate faults.

1. **The returned value.** Before the loop, the function body holds
   `_g = []`, and it ends with `_g`. Two late cleanup passes replace a trailing
   variable with the value of its last simple assignment. Both passes looked
   only for `_g = value` and did not see the tuple match `{_g} = ...` that
   rebinds `_g` after it. That match is also inside a nested statement block
   (`k = Map.keys(m)` and then the loop), which prints as plain statements in
   the same scope. So both passes chose `_g = []` and returned `[]`:

   | Pass | Result |
   | --- | --- |
   | `InlineTrailingReturnVar` | trailing `_g` became `[]` |
   | `TrailingTempReturnSimplify` | the same, after the first pass was fixed |

   Both passes now stop when a later match binds the name with any other
   pattern, also inside a nested statement block
   (`BinderTransforms.statementBindsName`).

2. **The seed of a later or inner loop.** `reduce_while` lowering starts a
   comprehension temp from its tracked initializer (`[]`). That is right only
   while the temp still has that value. Inside the body of a loop that threads
   the temp, and after a loop that rebinds it, the current value is the
   binding. `LoopBuilder.seedThreadedLocalsFromBinding` now points the tracked
   initializer at the binding in both places, by TVar ID. The enclosing loop
   then renames that read to its accumulator (`_g` becomes `acc__g`).

PR #82 (haxe.elixir.codex-uplw) fixed the same nesting when the outer loop is
`Enum.reduce` (an array). This fixture covers the `Enum.reduce_while` outer
loop.

## What the fixture covers

- one loop over map keys, returned directly and stored in a local first;
- map keys outside an array loop, and an array loop outside map keys;
- map keys inside map keys;
- an outer loop over map values;
- an outer loop over an array iterator (`xs.iterator()`);
- a constant range around map keys, which Haxe unrolls;
- an `if` filter on each loop;
- an empty outer map, an empty inner map, and an empty map in the range case.

Results from map loops are sorted, because map order differs between the
interpreter and the BEAM.

`expected.stdout` is the output of this program on the Haxe interpreter. Before
the fix, the module compiled with no warning, and seven of its nine non-empty
lines printed an empty list. Only `keysNamed` and `keysInner` were right.

## Not covered

A user class iterator whose `next()` changes the object, such as a
`Countdown` class with `n--`, does not end on the BEAM. That is a separate
fault in iterator lowering, not in the comprehension result.

Run the snapshot with
`make -C test test-regression__reduce_while_comprehension_accumulator` and the
native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/reduce_while_comprehension_accumulator`.
