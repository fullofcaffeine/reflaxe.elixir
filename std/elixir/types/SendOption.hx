package elixir.types;

/**
 * Options for `Process.sendWithOptions` (Elixir `Process.send/3`).
 *
 * WHY: The BEAM accepts only the atoms `:noconnect` and `:nosuspend` here. A
 * plain string list such as `["noconnect"]` compiles but raises
 * `ArgumentError` at run time, so the extern takes this closed atom type.
 *
 * EXAMPLE: `Process.sendWithOptions(pid, msg, [SendOption.NoConnect])`
 * -> `Process.send(pid, msg, [:noconnect])`.
 */
enum abstract SendOption(Atom) to Atom {
	/** Do not auto-connect to a remote node; return `:noconnect` instead. */
	var NoConnect = "noconnect";

	/** Do not suspend the sender on a busy distribution port; return `:nosuspend` instead. */
	var NoSuspend = "nosuspend";
}
