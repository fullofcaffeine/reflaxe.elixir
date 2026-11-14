# Count every String position in codepoints

Haxe code often reads one string with several operations on one index:

```haxe
while (index < source.length) {
	if (source.charAt(index) == "\"") ...
	if (source.charCodeAt(index) == "[".code) ...
}
```

This only works when all operations count the same unit. The compiler used
Elixir graphemes for `length`, `charAt`, `substr` and `substring`, but
codepoints for `charCodeAt`. A grapheme is one character as a reader sees it,
and it can hold several codepoints: `\r\n` is one grapheme and two codepoints.
After the first such character the two indexes pointed at different places, so
a parser rejected valid text such as `[1,\r\n2]`.

All String operations now count codepoints, as the Haxe interpreter does. See
`docs/05-architecture/STRING_INDEX_UNITS.md`.

`Main.check` is a small JSON checker written like a real parser. `runtime.exs`
builds the inputs in Elixir: `\r\n`, a combining accent, a flag emoji, a
zero-width-joiner emoji and Hangul jamo. It compares each result with
`interpreter.txt`, the output of the same program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > interpreter.txt
```

Run the snapshot with `make -C test test-regression__string_codepoint_units`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/string_codepoint_units`.

Not covered here: `EReg` positions, `haxe.Template`, and text that is not valid
UTF-8.
