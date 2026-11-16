package elixir.types;

/**
 * Options for `Process.demonitorWithOptions` (Elixir `Process.demonitor/2`).
 *
 * WHY: The BEAM accepts only the atoms `:flush` and `:info` here. A plain
 * string list such as `["flush"]` compiles but raises `ArgumentError` at run
 * time, so the extern takes this closed atom type.
 *
 * EXAMPLE: `Process.demonitorWithOptions(ref, [DemonitorOption.Flush])`
 * -> `Process.demonitor(ref, [:flush])`.
 */
enum abstract DemonitorOption(Atom) to Atom {
	/** Also remove a `:DOWN` message for this monitor from the mailbox. */
	var Flush = "flush";

	/** Return `false` instead of `true` when the monitor was already gone. */
	var Info = "info";
}
