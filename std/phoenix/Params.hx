package phoenix;

#if (elixir || reflaxe_runtime)
import elixir.types.Term;

/**
 * Typed readers for Phoenix params maps.
 *
 * WHAT
 * - Reads LiveView event params, route params, and controller params from the
 *   native Phoenix `%{}` shape.
 *
 * WHY
 * - Phoenix params are string-keyed maps at the framework boundary. App code
 *   should decode them once through typed helpers instead of scattering
 *   `Reflect.field` and `cast` across callbacks.
 *
 * HOW
 * - Reads string keys with `Map.get/2`.
 * - Falls back to `String.to_existing_atom/1` for trusted internal/test maps
 *   without creating atoms from request data.
 * - Narrows values with BEAM predicates before returning typed Haxe values.
 */
@:native("PhoenixHx.Params")
class Params {
	public static function get(params:Term, key:String):Null<Term> {
		return untyped __elixir__('
          case {0} do
            nil -> nil
            params ->
              case Map.fetch(params, {1}) do
                {:ok, value} -> value
                :error ->
                  try do
                    Map.get(params, String.to_existing_atom({1}))
                  rescue
                    ArgumentError -> nil
                  end
              end
          end
        ', params, key);
	}

	public static function getNested(params:Term, key:String, nestedKey:String):Null<Term> {
		var nested = get(params, key);
		return nested != null ? get(nested, nestedKey) : null;
	}

	public static function getString(params:Term, key:String):Null<String> {
		return untyped __elixir__('
          case PhoenixHx.Params.get({0}, {1}) do
            nil -> nil
            value -> Kernel.to_string(value)
          end
        ', params, key);
	}

	public static function getStringDefault(params:Term, key:String, defaultValue:String):String {
		var value = getString(params, key);
		return value != null ? value : defaultValue;
	}

	public static function getInt(params:Term, key:String):Null<Int> {
		return intFromTerm(get(params, key));
	}

	public static function getNestedInt(params:Term, key:String, nestedKey:String):Null<Int> {
		return intFromTerm(getNested(params, key, nestedKey));
	}

	public static function getBool(params:Term, key:String):Null<Bool> {
		return untyped __elixir__('
          case PhoenixHx.Params.get({0}, {1}) do
            value when is_boolean(value) -> value
            value when is_binary(value) ->
              case String.downcase(String.trim(value)) do
                "true" -> true
                "1" -> true
                "yes" -> true
                "on" -> true
                "false" -> false
                "0" -> false
                "no" -> false
                "off" -> false
                _ -> nil
              end
            _ -> nil
          end
        ', params, key);
	}

	public static function getIntDefault(params:Term, key:String, defaultValue:Int):Int {
		var value = getInt(params, key);
		return value != null ? value : defaultValue;
	}

	public static function getNestedIntDefault(params:Term, key:String, nestedKey:String, defaultValue:Int):Int {
		var value = getNestedInt(params, key, nestedKey);
		return value != null ? value : defaultValue;
	}

	static function intFromTerm(value:Null<Term>):Null<Int> {
		return untyped __elixir__('
          case {0} do
            nil -> nil
            value when is_integer(value) -> value
            value when is_float(value) -> Kernel.trunc(value)
            value when is_binary(value) ->
              case Integer.parse(value) do
                {num, _} -> num
                :error -> nil
              end
            _ -> nil
          end
        ', value);
	}
}
#end
