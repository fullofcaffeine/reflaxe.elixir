# Keep an assignment in an `else if` condition visible to later branches

```haxe
var v:Int = 0;
if (k == "x") v = 100;
else if ((v = m.get(k)) > 0) v = v * 2;
else v = v - 1;
return v;
```

Haxe runs the assignment before it tests the condition, so the `else` branch
and the code after the `if` read the new `v`.

The compiler turned the chain into one `cond`. A variable bound in a `cond`
test is visible only in that clause's body, so the `true` clause read the old
`v`:

```elixir
v = cond do
  k == "x" -> ...
  (v = Map.get(m, k)) > 0 -> ...
  true -> v - 1           # old v (0), not Map.get(m, k)
end
```

For a key whose value is -5, Haxe returns -6 and the old output returned -1.
The cond builder now stops at a test that binds a variable and keeps it as an
`if`. Elixir evaluates an `if` condition before either branch, so the binding
reaches both:

```elixir
true ->
  v = if (v = Map.get(m, k)) > 0, do: v * 2, else: v - 1
```

The unused-variable analysis (`VarUseAnalyzer.freeVarUseCounts`) now also
knows this scope rule, so the dead `v = 0` still becomes `_v = 0` and the
strict build stays free of warnings.

`expected.stdout` is the output of this program on the Haxe interpreter. It
covers a later branch that reads the value and code after the `if` that reads
it.

Not covered here:

- A test that assigns on the right side of `&&` or `||`. The fixture
  `short_circuit_condition_assignment` covers that form.
- A value `if`, such as the ternary
  `var r = k == "x" ? "x" : ((v = m.get(k)) > 0 ? "pos" : "other")`. This fix
  covers `if` statements only. No assignment inside a value-position `if` or
  `switch` reaches the code after it yet (haxe.elixir.codex-pap).

Run the snapshot with `make -C test test-regression__else_if_condition_assignment`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/else_if_condition_assignment`.
