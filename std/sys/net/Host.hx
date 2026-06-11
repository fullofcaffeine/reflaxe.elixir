package sys.net;

import elixir.types.Term;

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
 * - Convert back to BEAM tuples when socket code calls `toInetAddress()`.
 */
class Host {
	public var host(get, never):String;
	public var ip(default, null):Int;

	var hostName:String;

	public function new(name:String):Void {
		hostName = name;
		ip = resolve(name);
	}

	function get_host():String {
		return hostName;
	}

	public function toString():String {
		return hostToString(ip);
	}

	public function reverse():String {
		return hostReverse(ip);
	}

	public static function localhost():String {
		return untyped __elixir__('(
            case :inet.gethostname() do
              {:ok, name} -> List.to_string(name)
              _ -> "localhost"
            end
        )');
	}

	static function resolve(name:String):Int {
		return untyped __elixir__('(
            char_name = String.to_charlist({0})
            address =
              case :inet.parse_address(char_name) do
                {:ok, {a, b, c, d}} -> {a, b, c, d}
                {:ok, other} -> raise "sys.net.Host only supports IPv4 addresses on the Elixir target, got: #{inspect(other)}"
                {:error, _} ->
                  case :inet.getaddr(char_name, :inet) do
                    {:ok, {a, b, c, d}} -> {a, b, c, d}
                    {:ok, other} -> raise "sys.net.Host only supports IPv4 addresses on the Elixir target, got: #{inspect(other)}"
                    {:error, reason} -> raise "sys.net.Host: failed to resolve " <> inspect({0}) <> ": " <> inspect(reason)
                  end
              end
            {a, b, c, d} = address
            Bitwise.bor(Bitwise.bsl(a, 24), Bitwise.bor(Bitwise.bsl(b, 16), Bitwise.bor(Bitwise.bsl(c, 8), d)))
        )', name);
	}

	static function hostToString(ip:Int):String {
		return untyped __elixir__('(
            {a, b, c, d} = Host.to_inet_address({0})
            Enum.join([a, b, c, d], ".")
        )', ip);
	}

	static function hostReverse(ip:Int):String {
		return untyped __elixir__('(
            address = Host.to_inet_address({0})
            case :inet.gethostbyaddr(address) do
              {:ok, {:hostent, name, _aliases, _addrtype, _length, _addr_list}} -> List.to_string(name)
              {:error, reason} -> raise "sys.net.Host.reverse failed for #{inspect(address)}: #{inspect(reason)}"
            end
        )', ip);
	}

	public static function toInetAddress(ip:Int):Term {
		return untyped __elixir__('(
            value = {0}
            {
              Bitwise.band(Bitwise.bsr(value, 24), 255),
              Bitwise.band(Bitwise.bsr(value, 16), 255),
              Bitwise.band(Bitwise.bsr(value, 8), 255),
              Bitwise.band(value, 255)
            }
        )', ip);
	}
}
