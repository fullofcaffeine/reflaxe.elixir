package sys.net;

import elixir.types.Term;

/**
 * sys.net.Address (Elixir target)
 *
 * WHAT
 * - Haxe-compatible UDP address value object.
 *
 * WHY
 * - Haxe addresses are mutable value objects, while generated Elixir maps do not
 *   mutate in place.
 * - The Elixir target stores IPv4 hosts in the same integer representation as
 *   `Host.ip`.
 *
 * HOW
 * - Each address owns an opaque BEAM reference.
 * - `host` and `port` are properties backed by process-local state so mutations
 *   made by APIs like `UdpSocket.readFrom()` remain visible to the caller.
 * - `getHost()` reconstructs a `Host` from the stored IPv4 integer.
 */
class Address {
	public var host(get, set):Int;
	public var port(get, set):Int;

	final addressRef:Term;

	public function new() {
		addressRef = AddressState.create();
		host = 0;
		port = 0;
	}

	function get_host():Int {
		return AddressState.getHost(addressRef);
	}

	function set_host(value:Int):Int {
		AddressState.setHost(addressRef, value);
		return value;
	}

	function get_port():Int {
		return AddressState.getPort(addressRef);
	}

	function set_port(value:Int):Int {
		AddressState.setPort(addressRef, value);
		return value;
	}

	@:native("to_host")
	public function getHost():Host {
		var hostObject = new Host("127.0.0.1");
		untyped hostObject.ip = host;
		return hostObject;
	}

	public function compare(a:Address):Int {
		var hostDelta = a.host - host;
		if (hostDelta != 0)
			return hostDelta;

		var portDelta = a.port - port;
		if (portDelta != 0)
			return portDelta;

		return 0;
	}

	public function clone():Address {
		var cloned = new Address();
		cloned.host = host;
		cloned.port = port;
		return cloned;
	}
}

private class AddressState {
	public static function create():Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_net_address, ref}, %{host: 0, port: 0})
            ref
        )');
	}

	public static function getHost(addressRef:Term):Int {
		return untyped __elixir__('Map.fetch!(Process.get({:reflaxe_sys_net_address, {0}}), :host)', addressRef);
	}

	public static function setHost(addressRef:Term, host:Int):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_address, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | host: {1}})
            :ok
        )', addressRef, host);
	}

	public static function getPort(addressRef:Term):Int {
		return untyped __elixir__('Map.fetch!(Process.get({:reflaxe_sys_net_address, {0}}), :port)', addressRef);
	}

	public static function setPort(addressRef:Term, port:Int):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_address, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | port: {1}})
            :ok
        )', addressRef, port);
	}
}
