# Nested function returns

This fixture checks that a Haxe `return` exits its owning function, including
returns inside conditional branches and loops. A return inside a local function
must stay inside that function.

For example, `nested(10, false, true)` must return `-2`. The previous output
discarded that value and returned the later mutable local, `11`.

```haxe
if (absent) {
    if (denied) return -1;
} else {
    if (denied) return -2;
    current = current + 2;
}
return current;
```

The generated Elixir puts the continuation on paths that did not return:

```elixir
if absent do
  if denied, do: -1, else: current
else
  if denied, do: -2, else: current + 2
end
```

Range and array loops use the existing tagged `Enum.reduce_while` protocol when
a source return can exit the function. This also applies when the loop changes
no outer variable. Normal completion and a function return remain distinct.

The fixture covers both conditional branches, successful continuations, loop
rejections, values assigned by a returning switch, nested loops, and local
functions. `expected.stdout` independently checks which paths execute later
effects. Stock Haxe and the strict native runtime runner must agree.

Run the fixture through `npm run test:runtime-smoke`. It is also part of the
normal snapshot suite. These checks do not establish universal support for
every combination of returns, exceptions, and loop control.

Statement switches also preserve direct and nested function exits before later statements.
The mixed branch fixture returns -1 or -2 without printing; its fallthrough prints once and returns 5.
Transparent blocks must carry that continuation without moving it onto a returning path.
