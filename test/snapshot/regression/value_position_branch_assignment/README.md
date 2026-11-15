# Keep an assignment made inside a value-position `switch`, `if` or ternary

```haxe
var out = "d";
var r = switch o {
  case Some(v): out = v; 1;
  case None: 0;
};
return out + r;   // Haxe: "x1" for Some("x")
```

Here the `switch` is in value position: its result goes to `r`. One arm also
assigns the outer variable `out`. Both must reach the code after the `switch`.

In Elixir, a binding made inside a `case` or `if` branch ends with the branch.
The pass `ControlFlowStateHoist` already returned such updates from a branch,
but only for a control flow in statement position, where the branch value is
free. For `r = case ... end` it did nothing. A later pass then removed
`out = v` as dead code:

```elixir
r = case o do
  {:some, _v} -> 1      # the assignment to out is gone
  {:none} -> 0
end
```

The function returned `"d1"`. The same happened to the state of a loop. This
function always returned `false`, which would let an allow-check fail open:

```haxe
var seen = false;
for (name in names) {
  final ok = switch name { case "order": seen = true; name.length > 0; case _: true; };
  if (!ok) return false;
}
return seen;
```

Now each branch returns its value together with the updated variables, and the
match binds them all:

```elixir
{r, out} = case o do
  {:some, v} ->
    out = v
    {1, out}
  {:none} -> {0, out}
end
```

`expected.stdout` is the output of this program on the Haxe interpreter. The
compiler before the fix printed 18 of the 30 lines wrong. The fixture covers:

- a value `switch` with a plain subject and with a call subject (the compiler
  stores a call subject in a temporary first, which makes the value a block);
- a value `if`, also when its result goes to an existing variable;
- a ternary whose branch is the assignment (`c ? (v = 2) : 0`), and a nested
  ternary whose condition assigns;
- value `if` and `switch` inside an arm of a value `switch`, with two updated
  variables. That arm declares locals, so the compiler runs it as
  `(fn -> ... end).()`; the updates leave that closure the same way;
- a `var` inside a branch that has the name of an outer variable. It is a new
  local, so the outer variable keeps its value. The statement form
  (`if (c) { var v = ...; r = v + 1; }`) overwrote the outer variable before
  this fix;
- a branch that throws. It has no value, so it stays as it is; pairing it with
  the updates would not even be valid Elixir (`{raise ..., out}`);
- a function that ends by returning the assigned variable, and one that ends
  by returning only the value. In the second one nothing can read the
  assignment after the `switch`, so the generated `case` keeps its plain form;
- three loops: `for` with an early return (the shape above), `for` without one,
  and `while`.

Not covered, and still wrong: a control flow that assigns and is neither a
statement nor the whole right side of a match. Examples are a call argument,
`f(if (c) { v = 2; "a"; } else "b")`, and an operand,
`total + switch o { case Some(x): last = x; 1; case None: 0; }`. Bind the
control flow to a variable first. A `try` in value position is also not
covered: `var r = try { out = 1; f(); } catch (e) { 0; }` still loses `out`.

Run the snapshot with
`make -C test test-regression__value_position_branch_assignment` and the native
check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/value_position_branch_assignment`.
