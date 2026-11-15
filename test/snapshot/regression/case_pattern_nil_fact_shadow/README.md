# Forget outer nil facts for names a case pattern binds

```haxe
var value:Null<String> = null;
switch (r) {
  case SOk(value):
    if (value == null) return "inner nil";
    return value;
  case SErr(e):
    return value == null ? "outer nil" : "outer set";
}
```

The pass `SimplifyIsNilFalse` folds `is_nil(x)` when it knows that `x` is nil
or not nil. It knew that the outer `value` was nil and used that fact inside
`{:s_ok, value} ->`, where `value` is the payload:

```elixir
{:s_ok, _value} -> "inner nil"
```

`clash(SOk("x"))` returned `"inner nil"`. The pass now removes every name that
a clause pattern binds before it rewrites the clause guard and body. It does
the same for `receive` clauses, `with` and `for` patterns, and `rescue` and
`catch` clauses:

```elixir
{:s_ok, value} -> if is_nil(value), do: "inner nil", else: value
```

`expected.stdout` is the output of this program on the Haxe interpreter. It
covers a nil test in the clause body and a Haxe case guard
(`case SOk(value) if (value != null)`), which the compiler places in the
clause body as a `cond`.

Run the snapshot with `make -C test test-regression__case_pattern_nil_fact_shadow`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/case_pattern_nil_fact_shadow`.
