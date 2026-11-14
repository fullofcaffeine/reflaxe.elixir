# Keep `array.push` in a loop linear

A Haxe program collects items in a loop:

```haxe
var items = [];
while (index < count) {
	items.push(read(index));
	index++;
}
return items;
```

A Haxe `Array` is a BEAM list on this target, and `items.push(x)` became
`items = items ++ [x]`. `++` copies its whole left list, so each `push` cost
more than the one before: 10,000 items took 0.3 seconds, 40,000 items took
14 seconds.

The compiler now writes what an Elixir developer writes. Inside the loop it
adds each item in front of the list, and it puts the list back in order once,
where the loop ends:

```elixir
acc_items = [acc_i | acc_items]
...
{:halt, {Enum.reverse(acc_items), acc_i}}
```

A `for` loop with one `push` for each value becomes `Enum.map/2`.

The compiler does this only when it can see that the array is new and empty at
the loop, and that the loop body does nothing with the array except `push`. A
`return` or `break` may read the array, because the loop ends there.
`LinearListAppendTransforms` states the exact rule.

## What this fixture checks

`runtime.exs` calls each function of `Main` and compares the result with
`interpreter.txt`, the output of the same program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > interpreter.txt
```

These loops change to the fast form: `collect`, `collectOdd` (`break` and
`continue`), `untilLimit` (`return` inside the loop reads the array),
`squares`, `keepEven`, `split` (two arrays), `aliasAfter`, `doubled`, `none`,
and the row and line arrays of `grid`.

These loops keep the old form, and must give the same results as before:

- `runningTotal` reads `items.length` and `items[i]` while it pushes.
- `extend` starts from an array that already holds items.
- `twoLoops` pushes to one array in a second loop.
- `grid` pushes to an outer array from a nested loop.
- `fill` pushes to an array that the caller passed in.

Two kinds of code look like something else in the generated Elixir, and the
compiler must leave those loops alone too:

- An assignment used as a value: `note(items = items.concat([i]))`
  (`assignValue`, `assignArgumentFor`, `assignArgumentWhile`, `assignOnlyFor`).
  The value of the assignment goes to other code, so it must be the array in
  order.
- A Haxe enum constructor named `Cont`, as in `noteStep(Cont(items))`
  (`contBox`, `contArgument`, `contOnlyFor`). It compiles to the tuple
  `{:cont, items}`, which is also what a generated loop returns to go on. An
  earlier version of this change took it for loop control and passed the
  array in reverse order.

`assignOnlyFor` and `contOnlyFor` print from inside the loop; `runtime.exs`
collects that output and compares it too.

Then seven of the fast loops collect 200,000 items each. All together must take
less than 3 seconds. The budget is wide for slow machines; a normal run takes
about 0.3 seconds.

Run the snapshot with `make -C test test-regression__array_push_linear_loop`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/array_push_linear_loop`.

## Not covered here

A second variable that names the same array before the loop does not see the
pushes on this target; on the Haxe interpreter it does. This change does not
alter that: the loop keeps its old form whenever another statement names the
array between `items = []` and the loop. The managed array work
(`haxe.elixir.codex-0yn.10.3.14.1`) owns that behavior.
