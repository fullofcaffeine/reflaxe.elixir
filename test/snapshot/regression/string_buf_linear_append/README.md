# Keep StringBuf appends constant time

A Haxe program builds text with many small appends:

```haxe
var out = new StringBuf();
while (index < source.length) {
	out.addChar(source.charCodeAt(index));
	index++;
}
return out.toString();
```

The `StringBuf` runtime kept its pieces in a list and appended with
`struct.parts ++ [piece]`. `++` copies its whole left list, so each append
cost more than the one before. A buffer of 80 KB took 40 seconds, and one
40 KB JSON string value took 3.9 seconds to read.

The runtime now keeps the pieces as iodata. An append makes the two-element
list `[earlier, piece]`, which points at the earlier pieces and copies nothing.
`toString()` joins all pieces in one pass with `IO.iodata_to_binary/1`.

This fixture also covers two other defects of the same runtime:

- `addSub(s, pos, len)` cut in UTF-16 units over graphemes. It now cuts in
  codepoints, like every other String position on this target. See
  `docs/05-architecture/STRING_INDEX_UNITS.md`.
- `buf.length` called a function that the runtime did not define.

`runtime.exs` does two checks:

1. It calls `Main.subs`, `Main.copy` and `Main.kinds` with `\r\n`, a combining
   accent, a flag emoji and a zero-width-joiner emoji. It compares each result
   with `interpreter.txt`, the output of the same program on the Haxe
   interpreter:

   ```bash
   haxe -cp . -main Main --interp > interpreter.txt
   ```

2. It builds 800 KB with 400,000 `addChar` and 400,000 `add` calls, and copies
   200 KB with one `addSub` for each character. Both together must take less
   than 3 seconds. The budget is wide for slow machines; a normal run takes
   about 0.3 seconds.

Run the snapshot with `make -C test test-regression__string_buf_linear_append`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/string_buf_linear_append`.

Not covered here: `addSub` with a negative or too large `pos` or `len`, which
Haxe leaves unspecified, and a second variable that names the same buffer
(`haxe.elixir.codex-0yn.10.3.14`).
