package sys.io;

/**
 * sys.io.FileSeek (Elixir target)
 *
 * WHAT
 * - Seek origin used by `FileInput.seek` / `FileOutput.seek`.
 *
 * WHY
 * - Matches the Haxe stdlib API so code can remain portable across targets.
 *
 * HOW
 * - Mapped by our BEAM file-handle implementations to Erlang `:file.position/2`
 *   with `{:bof, offset}` / `{:cur, offset}` / `{:eof, offset}`.
 */
enum FileSeek {
	SeekBegin;
	SeekCur;
	SeekEnd;
}
