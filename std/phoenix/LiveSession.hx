package phoenix;

#if (elixir || reflaxe_runtime)
import elixir.types.Term;
import plug.Conn;

/**
 * Helpers for Phoenix LiveView session maps.
 *
 * WHAT
 * - Build and read the string-keyed session map passed to LiveView `mount/3`.
 *
 * WHY
 * - Phoenix LiveView receives a router-declared session payload, not the whole
 *   Plug session. Apps often need a small bridge function for
 *   `live_session ..., session: {Module, :function, []}`.
 *
 * HOW
 * - `fromConnKeys` copies selected Plug session keys into a string-keyed map.
 * - `put` and `get` operate on the LiveView session map itself.
 * - All helpers emit normal `Plug.Conn` and `Map` calls.
 */
class LiveSession {
	public static inline function empty():Term {
		return untyped __elixir__('%{}');
	}

	public static inline function put(session:Term, key:String, value:Term):Term {
		return untyped __elixir__('Map.put({0}, {1}, {2})', session, key, value);
	}

	public static inline function get(session:Term, key:String):Term {
		return untyped __elixir__('Map.get({0}, {1})', session, key);
	}

	public static inline function getWithDefault(session:Term, key:String, defaultValue:Term):Term {
		return untyped __elixir__('Map.get({0}, {1}, {2})', session, key, defaultValue);
	}

	/**
	 * Copy selected Plug session values into a LiveView session map.
	 *
	 * Plug accepts atom or binary session keys. This helper uses the binary key
	 * directly and stores the LiveView session entry under the same string key.
	 */
	public static inline function fromConnKeys<TParams>(conn:Conn<TParams>, keys:Array<String>):Term {
		return untyped __elixir__('
          Enum.reduce({1}, %{}, fn key, acc ->
            case Plug.Conn.get_session({0}, key) do
              nil -> acc
              value -> Map.put(acc, key, value)
            end
          end)
        ', conn, keys);
	}
}
#end
