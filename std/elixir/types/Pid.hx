package elixir.types;

/**
 * Type-safe abstraction for Elixir process identifiers (PIDs)
 * 
 * This abstract type provides compile-time type safety for process IDs
 * while compiling to regular Elixir PIDs at runtime with zero overhead.
 * 
 * Usage:
 * ```haxe
 * var myPid: Pid = Process.self();
 * Process.send(myPid, "Hello");
 * if (Process.alive(myPid)) { ... }
 * ```
 */
abstract Pid(Term) from Term to Term {
	/**
	 * Create a new Pid wrapper
	 * Note: This is typically not called directly - PIDs come from Process functions
	 */
	public inline function new(pid:Term) {
		this = pid;
	}

	/**
	 * Convert a string representation to a Pid
	 * Example: "#PID<0.123.0>" becomes a valid Pid
	 */
	@:from
	public static inline function fromString(str:String):Pid {
		return new Pid(untyped __elixir__(':erlang.list_to_pid(String.to_charlist(String.replace_prefix({0}, "#PID", "")))', str));
	}

	/**
	 * Convert this Pid to its string representation
	 * Returns format like "#PID<0.123.0>"
	 */
	@:to
	public inline function toString():String {
		return untyped __elixir__('inspect({0})', this);
	}

	/**
	 * Check if this PID represents the current process
	 */
	public inline function isSelf():Bool {
		return untyped __elixir__('{0} == self()', this);
	}

	/**
	 * Check if this process is alive
	 */
	public inline function isAlive():Bool {
		return untyped __elixir__('Process.alive?({0})', this);
	}

	/**
	 * Get the node where this process is running
	 */
	public inline function node():String {
		return untyped __elixir__('node({0})', this);
	}
}
