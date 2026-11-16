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
compiler before the fix printed 34 of the 66 lines wrong. The fixture covers:

- a value `switch` with a plain subject and with a call subject (the compiler
  stores a call subject in a temporary first, which makes the value a block);
- a value `if`, also when its result goes to an existing variable;
- a ternary whose branch is the assignment (`c ? (v = 2) : 0`), and a nested
  ternary whose condition assigns;
- value `if` and `switch` inside an arm of a value `switch`, with two updated
  variables. That arm declares locals, so the compiler runs it as
  `(fn -> ... end).()`; the updates leave that closure the same way;
- a `var` inside a branch that has the name of an outer variable, with no
  write to the outer one. It is a new local, so the outer variable keeps its
  value;
- a branch that throws. It has no value, so it stays as it is; pairing it with
  the updates would not even be valid Elixir (`{raise ..., out}`);
- a function that ends by returning the assigned variable, and one that ends
  by returning only the value. In the second one nothing can read the
  assignment after the `switch`, so the generated `case` keeps its plain form;
- three loops: `for` with an early return (the shape above), `for` without one,
  and `while`.

## Another variable under the same name

`Shadowing.hx` holds the second half of the output. There, one branch assigns
an outer variable, and another branch has a different variable with that name:

```haxe
var value = 100;
var ok = switch r {
  case Ok(value): value > 0;            // `value` is the payload here
  case Error(_): value = value + 1; false;
};
// Haxe: the outer value is still 100 after Ok(3)
```

Every hoisted branch ends with the updated variables. The first version of
this fix let the `Ok` branch return its own `value`, so the outer variable
became 3. The statement form of the same code was already wrong before. Now a
branch whose name belongs to another variable returns the outer value from a
capture:

```elixir
reflaxe_outer_value_1 = value
{ok, value} = case r do
  {:ok, value} -> {value > 0, reflaxe_outer_value_1}
  {:error, _} ->
    value = value + 1
    {false, value}
end
```

For a `var` inside the branch, the capture is made just before that `var`, so
it holds what the branch wrote to the outer variable until then.

A branch-local `var` whose outer variable is read again later usually does
not reach this capture any more: before the builders run, `ShadowedLocals`
gives it a fresh name (`v` -> `v_shadow`), and the branch returns the outer `v`
directly. The capture still covers pattern binders, which keep their names.

The shapes, each in value and in statement position where both exist:

- a pattern binder with the name of the updated variable (`Ok(value)`,
  `Some(out)`), also with a second updated variable;
- a branch-local `var` with that name, also after a write to the outer
  variable in the same branch;
- a write that has no Haxe assignment behind it (`items.push(v)`, the result
  of a loop) in one branch, and a `var` of that name in the other branch. The
  `var` must not hide the write.

- a `var` of that name inside a plain block of the branch: the body of a loop
  over a constant range or array, which the compiler unrolls, and the body of
  a `switch` arm that has a binder. Such a block prints inline, so its `var`
  keeps the name until the branch ends;
- a program variable that already has the name of a capture
  (`reflaxe_outer_value_1`). The compiler picks a name that the function does
  not use.

Of the first 26 of these lines, 13 were wrong on the first version of the fix
(commit 6bbcfc12a); 7 of those were right on the base commit. Of the 10 lines
for the last two shapes, 5 were wrong on the second version (commit
1d9720c8c); 4 of those were right on the base commit.

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
