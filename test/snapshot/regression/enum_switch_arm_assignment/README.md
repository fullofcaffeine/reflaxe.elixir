# Keep an assignment made in the arm of an enum switch

```haxe
var out:String = null;
switch find(k) {
  case Some(v): out = v;
  case None:
}
return out == null ? "null" : out;
```

The pass `CaseSomeBinderNormalize` cleans up `{:some, binder}` clauses. It
dropped a leading `alias = binder` statement as a redundant alias, without
checking the alias name. Here the "alias" is the real assignment to the outer
`out`, so the arm lost its value:

```elixir
out = case g do
  {:some, _v} -> out      # should be v
  {:none} -> out
end
```

`armAssign("x")` returned `"null"`. The pass now drops only an alias whose
name is the binder's own plain name (for example `v = _v`):

```elixir
{:some, v} ->
  out = v
  out
```

`expected.stdout` is the output of this program on the Haxe interpreter. It
covers one assigning arm with an empty arm, and two assigning arms.

Not covered: a switch in value position, as in
`var r = switch find(k) { case Some(v): out = v; 1; case None: 0; }`. The
assignment to `out` is still lost there, through a different mechanism than
the one fixed here. No assignment inside a value-position `switch` or `if`
reaches the code after it yet (haxe.elixir.codex-pap).

Run the snapshot with `make -C test test-regression__enum_switch_arm_assignment`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/enum_switch_arm_assignment`.
