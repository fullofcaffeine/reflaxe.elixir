package sys.thread;

import elixir.types.Term;

/**
 * Thread-local storage mapped to the current BEAM process dictionary.
 */
@:native("Sys.Thread.Tls")
class Tls<T> {
	final ref:Term;

	public var value(get, set):T;

	public function new():Void {
		ref = untyped __elixir__('make_ref()');
	}

	function get_value():T {
		return untyped __elixir__('Process.get({:reflaxe_sys_thread_tls, {0}})', ref);
	}

	function set_value(value:T):T {
		untyped __elixir__('Process.put({:reflaxe_sys_thread_tls, {0}}, {1})', ref, value);
		return value;
	}
}
