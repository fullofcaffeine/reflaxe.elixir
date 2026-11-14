# Report EReg positions in codepoints

Application code combines a regular-expression match with `String` operations:

```haxe
var matcher = ~/b/;
if (matcher.match(text))
	return text.substr(matcher.matchedPos().pos, 2);
```

This works only when `matchedPos()` counts the same unit as `substr`. Every
Haxe `String` position counts codepoints on this target (see
`docs/05-architecture/STRING_INDEX_UNITS.md`), but the `EReg` runtime counted
graphemes. A grapheme is one character as a reader sees it, and `\r\n` is one
grapheme and two codepoints. For `text = "a\r\nbc"` the match reported position
2 where `substr` needed 3, so the code above returned `"\nb"`. The Haxe
interpreter returns `"bc"`.

`matchedPos`, `matchedLeft`, `matchedRight`, `matchSub`, `replace` and `map` now
count codepoints.

`runtime.exs` builds the inputs in Elixir (`\r\n`, a combining accent, a flag
emoji) and compares each result with `interpreter.txt`, the output of the same
program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > interpreter.txt
```

One difference is deliberate. The interpreter reads the `matchSub(text, pos,
len)` range in bytes when the text is not ASCII, which disagrees with its own
`matchedPos`. On this target the range counts codepoints. `interpreter.txt`
therefore holds `matchSub` results for ASCII text only, and `runtime.exs` checks
the non-ASCII ranges against values written by hand.

Run the snapshot with `make -C test test-regression__ereg_codepoint_positions`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/ereg_codepoint_positions`.
