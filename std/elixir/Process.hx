package elixir;

import elixir.types.Pid;
import elixir.types.Reference;
import elixir.types.ProcessInfo;
import elixir.types.ProcessFlag;
import elixir.types.Priority;
import elixir.types.MessageQueueData;
import elixir.types.Term;
import elixir.types.Atom;
import elixir.types.Tuple2;
import elixir.types.SendOption;
import elixir.types.DemonitorOption;
import elixir.Kernel;

#if (macro || reflaxe_runtime || elixir)
/**
 * Process module extern definitions for Elixir standard library
 * Provides type-safe interfaces for basic OTP process operations
 * 
 * Maps to Elixir's Process module functions with proper type signatures
 */
@:native("Process")
extern class Process {
	// Process identification

	/**
	 * Return the current process.
	 *
	 * WHAT: Exposes Haxe `Process.self()` as Elixir `Kernel.self()`.
	 * WHY: `self/0` is a Kernel function; `Process.self/0` does not exist.
	 * HOW: An inline extern wrapper keeps the Haxe-facing Process namespace while
	 * emitting the real target call with no runtime adapter.
	 * EXAMPLE: `Process.self()` -> `Kernel.self()`.
	 */
	public static inline function self():Pid {
		return cast Kernel.self();
	}

	@:native("Process.whereis")
	public static function whereis(name:Atom):Null<Pid>;

	/**
	 * Parse a local pid from its printed form.
	 *
	 * WHAT: Accepts `"#PID<0.123.0>"` (what `inspect/1` prints) or `"<0.123.0>"`.
	 * WHY: Elixir has no `Process.pid_from_string/1`; the real parser is
	 * `:erlang.list_to_pid/1`, which takes a charlist without the `#PID` prefix.
	 * HOW: Drops an optional `#PID` prefix, converts to a charlist, and calls
	 * `:erlang.list_to_pid/1`. Malformed input raises `ArgumentError` at run time.
	 * EXAMPLE: `Process.pidFromString(Process.self().toString())` returns the same pid.
	 */
	public static inline function pidFromString(string:String):Pid {
		return cast untyped __elixir__(':erlang.list_to_pid(String.to_charlist(String.replace_prefix({0}, "#PID", "")))', string);
	}

	// Process spawning

	/**
	 * Start an unlinked local process.
	 *
	 * WHAT: Exposes Haxe `Process.spawn(fn)` as Elixir `Kernel.spawn(fn)`.
	 * WHY: The one-function form belongs to Kernel; `Process.spawn/1` does not exist.
	 * HOW: The inline wrapper delegates directly and narrows the returned term to `Pid`.
	 * EXAMPLE: `Process.spawn(() -> work())` -> `Kernel.spawn(fn -> work() end)`.
	 */
	public static inline function spawn(func:Void->Void):Pid {
		return cast Kernel.spawn(func);
	}

	/**
	 * Start an unlinked process that runs `apply(module, func, args)`.
	 *
	 * WHY: `Process.spawn/3` does not exist; the three-argument form is `Kernel.spawn/3`.
	 * Module and function names are atoms on the BEAM, so they are typed `Atom`.
	 * EXAMPLE: `Process.spawnModule("timer", "sleep", [200])` -> `spawn(:timer, :sleep, [200])`.
	 * For an Elixir module, pass its full atom name, such as `"Elixir.String"`.
	 */
	@:native("Kernel.spawn")
	public static function spawnModule(module:Atom, func:Atom, args:Array<Term>):Pid;

	/**
	 * Start a process linked to the caller.
	 *
	 * WHY: `spawn_link/1` belongs to Kernel; `Process.spawn_link/1` does not exist.
	 * EXAMPLE: `Process.spawnLink(() -> work())` -> `Kernel.spawn_link(fn -> work() end)`.
	 */
	public static inline function spawnLink(func:Void->Void):Pid {
		return cast Kernel.spawnLink(func);
	}

	/** Linked form of `spawnModule`: maps to `Kernel.spawn_link/3`. */
	@:native("Kernel.spawn_link")
	public static function spawnLinkModule(module:Atom, func:Atom, args:Array<Term>):Pid;

	/**
	 * Start a process and monitor it.
	 *
	 * WHY: `spawn_monitor/1` belongs to Kernel. It returns the native tuple
	 * `{pid, ref}`, so the result is a `Tuple2` (`_0` is the pid, `_1` the monitor
	 * reference), not a record with named fields.
	 * EXAMPLE: `Process.spawnMonitor(() -> work())._0` is the new pid.
	 */
	@:native("Kernel.spawn_monitor")
	public static function spawnMonitor(func:Void->Void):Tuple2<Pid, Reference>;

	/** Monitored form of `spawnModule`: maps to `Kernel.spawn_monitor/3`. */
	@:native("Kernel.spawn_monitor")
	public static function spawnMonitorModule(module:Atom, func:Atom, args:Array<Term>):Tuple2<Pid, Reference>;

	// Process lifecycle
	@:native("Process.exit")
	public static function exit(pid:Pid, reason:Term):Bool;

	/**
	 * Kill a process unconditionally.
	 *
	 * WHY: Elixir has no `Process.kill/2`. Killing is `Process.exit(pid, :kill)`,
	 * the one exit reason that a process trapping exits cannot catch. Any other
	 * reason belongs to `exit(pid, reason)`.
	 * EXAMPLE: `Process.kill(pid)` -> `Process.exit(pid, :kill)`.
	 */
	public static inline function kill(pid:Pid):Bool {
		return exit(pid, cast("kill" : Atom));
	}

	@:native("Process.alive?")
	public static function alive(pid:Pid):Bool;

	// Process linking and monitoring
	@:native("Process.link")
	public static function link(pid:Pid):Bool;

	@:native("Process.unlink")
	public static function unlink(pid:Pid):Bool;

	@:native("Process.monitor")
	public static function monitor(pid:Pid):Reference;

	@:native("Process.demonitor")
	public static function demonitor(ref:Reference):Bool;

	/** `Process.demonitor/2` with `DemonitorOption` atoms such as `Flush`. */
	@:native("Process.demonitor")
	public static function demonitorWithOptions(ref:Reference, options:Array<DemonitorOption>):Bool;

	// Process communication

	/**
	 * Send a message to a pid and return the message.
	 *
	 * WHY: `send/2` belongs to Kernel; Elixir only has `Process.send/3`.
	 * EXAMPLE: `Process.send(pid, "hello")` -> `Kernel.send(pid, "hello")`.
	 */
	public static inline function send(dest:Pid, message:Term):Term {
		return Kernel.send(dest, message);
	}

	/**
	 * Send a message to a locally registered name and return the message.
	 *
	 * WHY: The name must be an atom; a string destination raises `ArgumentError`.
	 * Maps to `Kernel.send/2`. Sending to a name that is not registered raises.
	 */
	public static inline function sendToName(dest:Atom, message:Term):Term {
		return Kernel.send(dest, message);
	}

	/** `Process.send/3` with `SendOption` atoms. Returns `:ok` unless an option prevents sending. */
	@:native("Process.send")
	public static function sendWithOptions(dest:Pid, message:Term, options:Array<SendOption>):Term;

	@:native("Process.send_after")
	public static function sendAfter(dest:Pid, message:Term, time:Int):Reference;

	// Process registration
	@:native("Process.register")
	public static function register(pid:Pid, name:Atom):Bool;

	@:native("Process.unregister")
	public static function unregister(name:Atom):Bool;

	@:native("Process.registered")
	public static function registered():Array<Atom>; // List all registered names

	// Process information
	@:native("Process.info")
	public static function info(pid:Pid):Null<ProcessInfo>; // Process info map

	/**
	 * Read one info item: `Process.info(pid, key)`.
	 *
	 * The key is an atom such as `status`; a string key raises `ArgumentError`.
	 * The native result is the tuple `{key, value}`, or `nil` for a dead process.
	 * EXAMPLE: `Process.infoKey(pid, "status")._1` is the status atom.
	 */
	@:native("Process.info")
	public static function infoKey(pid:Pid, key:Atom):Null<Tuple2<Atom, Term>>;

	/**
	 * Read several info items: `Process.info(pid, keys)`.
	 *
	 * Keys are atoms. The native result is a keyword list of `{key, value}`
	 * tuples, or `nil` for a dead process.
	 */
	@:native("Process.info")
	public static function infoKeys(pid:Pid, keys:Array<Atom>):Null<Array<Tuple2<Atom, Term>>>;

	// Process list operations
	@:native("Process.list")
	public static function list():Array<Pid>; // All process pids

	// Process flags with type-safe abstractions
	@:native("Process.flag")
	public static function flag<T>(flag:ProcessFlag, value:T):T;

	// Process dictionary with generic key/value types

	/** The whole process dictionary: `Process.get/0` returns a list of `{key, value}` tuples, not a map. */
	@:native("Process.get")
	public static function get<K, V>():Array<Tuple2<K, V>>;

	@:native("Process.get")
	public static function getKey<K, V>(key:K):Null<V>;

	@:native("Process.get")
	public static function getWithDefault<K, V>(key:K, defaultValue:V):V;

	@:native("Process.put")
	public static function put<K, V>(key:K, value:V):Null<V>;

	@:native("Process.delete")
	public static function delete<K, V>(key:K):Null<V>;

	@:native("Process.get_keys")
	public static function getKeys<K>():Array<K>;

	@:native("Process.get_keys")
	public static function getKeysForValue<K, V>(value:V):Array<K>;

	// Process sleeping and timing
	@:native("Process.sleep")
	public static function sleep(timeout:Int):Term; // Returns :ok

	// Process hibernation

	/**
	 * Hibernate the caller until a message arrives, then run `apply(module, func, args)`.
	 *
	 * Module and function names are atoms. This call never returns: the call
	 * stack is discarded and the process continues in the given function.
	 */
	@:native("Process.hibernate")
	public static function hibernate(module:Atom, func:Atom, args:Array<Term>):Void;

	// Process cancellation

	/**
	 * Cancel a timer from `sendAfter`. Returns the remaining milliseconds.
	 *
	 * LIMIT: when the timer already fired or does not exist, the native result
	 * is `false`, not `nil`, so a `null` check does not detect that case.
	 */
	@:native("Process.cancel_timer")
	public static function cancelTimer(ref:Reference):Null<Int>;

	/** Read a timer's remaining milliseconds. Same `false` limit as `cancelTimer`. */
	@:native("Process.read_timer")
	public static function readTimer(ref:Reference):Null<Int>;

	// Group leader operations
	@:native("Process.group_leader")
	public static function groupLeader():Pid; // Get group leader pid

	/**
	 * Set the group leader of `pid` to `leader`.
	 *
	 * WHY: Elixir's argument order is `Process.group_leader(pid, leader)`, the
	 * reverse of this Haxe signature, so the wrapper swaps them.
	 */
	public static inline function setGroupLeader(leader:Pid, pid:Pid):Bool {
		return cast untyped __elixir__('Process.group_leader({0}, {1})', pid, leader);
	}
}
#end
