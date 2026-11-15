# Keep an assignment made under `&&` or `||` in an `if` test

```haxe
var v = 1;
var r = "";
if (k == "x")
  r = "x";
else if (k != "z" && (v = get(m, k)) > 0)
  r = "pos";
else
  r = "other";
return r + v;
```

Haxe runs the assignment when `k != "z"` holds, and the code after the `if`
reads the new `v`. The earlier fix in `else_if_condition_assignment` kept such a
test as an Elixir `if`, because Elixir exports a binding from an `if` test. That
is not true for the right side of `and` and `or`: Elixir runs it in a scope of
its own. The output still lost the assignment:

```elixir
r = if (k != "z" and (v = get(m, k)) > 0), do: "pos", else: "other"
{r, v}        # the old v
```

For a value of -5 Haxe returns `"other-5"` and the generated code returned
`"other1"`. When a branch read `v`, the Elixir build failed instead.

The compiler now splits such a test, so that the assigning part is the whole
test of an `if` of its own:

```elixir
k != "z" ->
  r = if ((v = get(m, k)) > 0), do: "pos", else: "other"
  {r, v}
true ->
  r = "other"
  {r, v}
```

`a && b` becomes `if a, do: (if b, ...), else: ...`, `a || b` becomes
`if a, do: ..., else: (if b, ...)`, and `!a` changes the places of the two
branches. One branch is written twice; at most one copy runs. A test with no
assignment on the right side of `&&` or `||` is not changed.

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

It covers `&&` and `||` in an else-if test, an assignment in the middle of a
chain, a negated test, an `if` without `else`, and branches that read the
assigned value.

Not covered: a value `if`, such as the ternary
`var r = k == "x" ? "x" : ((v = get(m, k)) > 0 ? "pos" : "other")`. No
assignment inside a value-position `if` or `switch` reaches the code after it
yet; that is a separate, larger change (haxe.elixir.codex-pap). Loop tests are
also not covered.

Run the snapshot with `make -C test test-regression__short_circuit_condition_assignment`
and the native check with
`bash scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/short_circuit_condition_assignment`.
