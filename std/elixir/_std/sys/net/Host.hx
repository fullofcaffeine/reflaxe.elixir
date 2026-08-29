package sys.net;

import elixir.ErlangInet.ErlangHostEntry;
import elixir.ErlangInet.ErlangIPv4Address;
import elixir.ErlangInet.ErlangInetFamily;
import elixir.types.Atom;

/**
 * sys.net.Host (Elixir target)
 *
 * WHAT
 * - BEAM-backed implementation of Haxe's IPv4 `sys.net.Host` API.
 *
 * WHY
 * - Haxe's `sys.net.*` classes expose host names through `Host.ip` integer
 *   values, while Erlang socket APIs use `{a, b, c, d}` tuples.
 *
 * HOW
 * - Resolve host names with `:inet.getaddr/2`.
 * - Store `ip` as a big-endian IPv4 integer (`a.b.c.d` -> `a<<24 | b<<16 | c<<8 | d`).
 * - Normalize that integer to Haxe's signed 32-bit `Int` range.
 * - Convert back to BEAM tuples when socket code calls `toInetAddress()`.
 */
class Host {
	public var host(default, null):String;
	public var ip(default, null):Int;

	public function new(name:String):Void {
		host = name;
		ip = resolve(name);
	}

	public function toString():String {
		var address = toInetAddress(ip);
		return elixir.ElixirInteger.toString(address._0) + "." + elixir.ElixirInteger.toString(address._1) + "." + elixir.ElixirInteger.toString(address._2)
			+ "." + elixir.ElixirInteger.toString(address._3);
	}

	public function reverse():String {
		var result = elixir.ErlangInet.getHostByAddress(toInetAddress(ip));
		if (result._0 != cast Atom.OK) {
			throw "sys.net.Host.reverse failed for " + toString();
		}

		var entry:ErlangHostEntry = cast result._1;
		return elixir.List.toString(entry._1);
	}

	public static function localhost():String {
		var result = elixir.ErlangInet.getHostname();
		if (result._0 != cast Atom.OK) {
			throw "sys.net.Host.localhost failed";
		}
		return elixir.List.toString(cast result._1);
	}

	static function resolve(name:String):Int {
		var result = elixir.ErlangInet.getAddress(elixir.ElixirString.toCharlist(name), ErlangInetFamily.IPv4);
		if (result._0 != cast Atom.OK) {
			throw "sys.net.Host: failed to resolve " + name;
		}

		var address:ErlangIPv4Address = cast result._1;
		var signedHighByte = address._0 >= 128 ? address._0 - 256 : address._0;
		return (signedHighByte << 24) | (address._1 << 16) | (address._2 << 8) | address._3;
	}

	public static function toInetAddress(ip:Int):ErlangIPv4Address {
		return {
			_0: (ip >> 24) & 255,
			_1: (ip >> 16) & 255,
			_2: (ip >> 8) & 255,
			_3: ip & 255
		};
	}
}
