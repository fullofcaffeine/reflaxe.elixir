# Forget a nil fact when a condition assigns the variable

```haxe
var v:Null<String> = null;
if ((v = m.get(k)) != "zzz") {
  if (v == null) return "nil";
  return v;
}
return "zzz";
```

The pass `SimplifyIsNilFalse` folds `is_nil(x)` when it knows that `x` is nil
or not nil. It handled one statement at a time: it rewrote the whole `if` with
the facts from before the statement, and only then forgot the names that the
statement assigns. The inner test therefore still saw `v = nil`:

```elixir
if ((v = Map.get(m, k)) != "zzz"), do: "nil", else: "zzz"
```

`nilThenAssigned(m, "a")` returned `"nil"` instead of `"apple"`. With
`var v = "set"` the fold went the other way and removed the nil test.

The pass now drops the facts about a name at the moment its walk passes a
match on that name. Elixir evaluates an `if` condition before the branches, so
the branches are rewritten without the stale fact:

```elixir
if ((v = Map.get(m, k)) != "zzz") do
  if (Kernel.is_nil(v)), do: "nil", else: v
else
  "zzz"
end
```

A fact still holds up to the assignment. In `stillFolded` a branch assigns
`mode`, but the test runs first, so the test is folded away as before:

```elixir
mode = "asc"
"#{mode}#{k}"
```

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

It covers a variable that is null and one that is set before the condition, a
test in the same condition, in the else branch, in a value `if` and in an
inner `if`.

Run the snapshot with `make -C test test-regression__condition_assignment_nil_fact`
and the native check with
`bash scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/condition_assignment_nil_fact`.
