# Keep every element of a comprehension with nested `for` clauses

```haxe
return [for (x in xs) for (y in ys) x + y];
```

Haxe turns this comprehension into one empty array and two nested loops that
add to it. In Elixir, a loop that changes an outer variable becomes
`Enum.reduce`, and the variable travels through the loop as an accumulator. The
generated code was:

```elixir
g = []
Enum.reduce(xs, g, fn x, g_acc ->
  _ = Enum.reduce(ys, g, fn y, g_acc -> Enum.concat(g_acc, [x <> y]) end)
  g_acc
end)
```

The inner loop started again from `g`, the empty list from before the outer
loop, and the outer loop dropped the inner result and returned its own
unchanged `g_acc`. So the function returned `[]` for any input. `haxe --interp`
returned `a1,a2,b1,b2`. The compiler gave no warning. A `switch` in the element,
as in the first report, does not matter; the nesting is enough.

The fixed code threads one accumulator through both loops. The inner callback
parameter has the same name as the outer one and shadows it:

```elixir
g = []
Enum.reduce(xs, g, fn x, g_acc ->
  Enum.reduce(ys, g_acc, fn y, g_acc -> Enum.concat(g_acc, [x <> y]) end)
end)
```

## Cause

While the compiler builds the body of a reducer, it maps the changed variable to
the accumulator name by its Haxe variable ID (`_g` becomes `_g_acc`). The inner
loop also changes `_g`, but it took the declared name `_g` for its initial value
and for the name that its result rebinds. It now asks for the name that holds
the variable at that point (`LoopBuilder.reducerStateNames`), so it starts from
`_g_acc`, rebinds `_g_acc`, and uses `_g_acc` as its own callback parameter.

An inner loop over `m.keys()` uses a different builder,
`buildReduceWhileWithState`. It had the same problem in another form: it seeded
the inner state with the tracked initializer `[]` instead of `_g_acc`. With
that seed fixed, two late passes still renamed the inner loop's accumulator
update to the outer accumulator, because their walk entered the nested
callback:

| Pass | Result |
| --- | --- |
| `ReduceAppendCanonicalize` | inner `acc__g_acc = acc__g_acc ++ [..]` became `g_acc = g_acc ++ [..]` |
| `ReduceAppendCanonicalize` fallback | an outer body that only calls the inner reduce was rebuilt from the inner append, which deleted the inner loop |
| `AccAliasLateRewrite` | inner `acc__g_acc = acc__g_acc ++ [..]` became `g_acc = Enum.concat(g_acc, [..])` |

These passes now stay in the current callback and do not rewrite the body of a
nested anonymous function. Each nested callback is handled with its own
accumulator.

## What the fixture covers

- two `for` clauses, with no `switch`;
- the same nesting as statements that add to an outer array;
- a `switch` whose `Error` arm reads both loop variables, with and without a guard;
- three `for` clauses;
- an `if` filter on each loop;
- an inner loop over an integer range with a variable end;
- an inner loop over the keys of a map (the result is sorted, because map
  order differs between the interpreter and the BEAM);
- a comprehension stored in a local before it is read;
- an empty inner list and an empty outer list.

`expected.stdout` is the output of this program on the Haxe interpreter. The
compiler before the fix printed none of its lines: the generated module did not
compile, because the map variant read an undefined `_g_acc`. Without the map
variant, the module compiled with no warning, and each comprehension printed an
empty list (`named` printed `0`). Only the statement form printed the correct
line before the fix.

## Not covered

A single-level comprehension over map keys that is returned directly,
`return [for (k in m.keys()) k];`, still returns `[]`. That is
haxe.elixir.codex-47i: a different pass (`InlineTrailingReturnVar`) replaces the
returned variable with its empty initializer.

Run the snapshot with
`make -C test test-regression__nested_comprehension_accumulator` and the native
check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/nested_comprehension_accumulator`.
