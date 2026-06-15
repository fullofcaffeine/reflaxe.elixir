package haxe.io;

/**
 * StringInput (Elixir target)
 *
 * WHAT
 * - In-memory `haxe.io.Input` backed by a Haxe `String`.
 *
 * WHY
 * - The upstream API is intentionally a thin `BytesInput(Bytes.ofString(s))`
 *   wrapper. Keeping that shape lets the Elixir target reuse the existing
 *   BEAM-safe cursor and binary handling from `BytesInput`.
 *
 * HOW
 * - Convert the source string to target `Bytes` once, then delegate all read
 *   semantics (`readByte`, `readBytes`, `readLine`, `readAll`, position) to
 *   `BytesInput`.
 */
class StringInput extends BytesInput {
	public function new(source:String) {
		super(Bytes.ofString(source));
	}
}
