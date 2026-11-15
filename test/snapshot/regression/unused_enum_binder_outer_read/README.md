# Keep an outer variable visible when a clause does not read its binder

```haxe
enum SRes { SOk(value:String); SErr(e:String); }

public static function outerArgument(r:SRes, value:String):String {
  return switch (r) {
    case SOk(a): "ok " + value;   // `a` is not read
    ...
```

The clause does not read `a`, so the compiler names the payload after the enum
field, `value`. That name hid the function argument:

```elixir
{:s_ok, payload_value} -> "ok #{payload_value}"   # prints the payload
```

`outerArgument(SOk("x"), "P")` returned `"ok x"` instead of `"ok P"`. The
earlier fix in `result_payload_outer_name` covered only the `value` and
`reason` names that the compiler gives `Ok` and `Error` payloads.

The compiler now checks every payload name against the outer variables that
the clause reads. An outer variable is one that the clause reads but does not
declare. On a clash the binder keeps its Haxe name:

```elixir
{:s_ok, _a} -> "ok #{value}"
```

A nested pattern such as `Wrap(SOk(_))` has no Haxe name for the outer
payload. There the compiler adds `payload_` to the field name:

```elixir
{:wrap, payload_value} ->
  value = (case payload_value do ...
```

## An outer variable that an arm assigns

```haxe
var value = "d";
switch (r) {
  case Ok(v): note(v);
  case Error(e): value = "err " + e;
}
return "r=" + value;
```

Elixir does not keep an assignment made inside a `case` arm, so the compiler
makes the `case` return `value` from every arm. The `Ok` arm does not mention
`value` in Haxe, but its Elixir clause reads it. The check above looked only at
the Haxe code of one arm, so the payload still got the name `value`:

```elixir
value = (case r do
  {:ok, value} ->
    v = value
    note(v)
    value          # the payload, not the outer "d"
```

The function returned `"r=o"` instead of `"r=d"`. The compiler now also counts,
for every arm, the outer variables that any arm of the same switch assigns:

```elixir
{:ok, v} ->
  note(v)
  value
```

## An outer variable named `reason` in an `Error` clause

Two late passes assume that `reason` in the body of an `{:error, binder}`
clause means the payload. One adds `reason = binder`, the other renames the
binder to `reason`. With an outer `reason` that is wrong, and the two together
gave code that does not compile:

```elixir
def reason_length(r, reason) do
  (case r do
    {:error, reason} ->
      reason = e          # `e` no longer exists
```

Both passes now leave a function alone when it binds `reason` itself, as an
argument or by an assignment:

```elixir
{:error, e} -> StringTools.haxe_length(reason) * 10 + StringTools.haxe_length(e)
```

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

It covers an argument and a local named like the enum field, a local that is
null (the folded nil test must use the outer value), `Ok` and `Error`
payloads, an inner switch that binds the same name, a nested pattern, and a
constructor with two payloads.
For an assigned outer variable it covers an arm that does not mention the
variable, an assignment under an `if`, and a nested pattern.
For `reason` it covers an outer local that the other arm assigns and an
argument that the `Error` arm reads outside a string.

Not covered:

- A pattern binder that itself has the name of an outer variable, as in
  `var value = "d"; switch (r) { case SOk(value): ...; case SErr(e): value = e; }`.
  A new binder name does not help there (haxe.elixir.codex-d2g).
- `case Both(a, b)` with an unread `a` next to a `case _:` clause does not
  compile to valid Elixir (`_a = _`). That older problem is separate from the
  naming rule here (haxe.elixir.codex-9ue).

Run the snapshot with `make -C test test-regression__unused_enum_binder_outer_read`
and the native check with
`bash scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/unused_enum_binder_outer_read`.
