package phoenix;

#if (elixir || reflaxe_runtime)
import elixir.types.Term;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Kernel;

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
		if (Kernel.isNil(params))
			return null;

		var map:Map<Term, Term> = cast params;
		var stringKey:Term = cast key;
		if (ElixirMap.hasKey(map, stringKey))
			return ElixirMap.get(params, stringKey);

		var atomKey = existingAtomOrNull(key);
		return !Kernel.isNil(atomKey) && ElixirMap.hasKey(map, atomKey) ? ElixirMap.get(params, atomKey) : null;
	}

	public static function getNested(params:Term, key:String, nestedKey:String):Null<Term> {
		var nested = get(params, key);
		return !Kernel.isNil(nested) ? get(nested, nestedKey) : null;
	}

	public static function getString(params:Term, key:String):Null<String> {
		return stringFromTerm(get(params, key));
	}

	public static function getStringDefault(params:Term, key:String, defaultValue:String):String {
		return stringFromTermDefault(get(params, key), defaultValue);
	}

	public static function stringFromTerm(value:Null<Term>):Null<String> {
		return !Kernel.isNil(value) ? Kernel.toString(value) : null;
	}

	public static function stringFromTermDefault(value:Null<Term>, defaultValue:String):String {
		var decoded = stringFromTerm(value);
		return decoded != null ? decoded : defaultValue;
	}

	public static function getInt(params:Term, key:String):Null<Int> {
		return intFromTerm(get(params, key));
	}

	public static function getNestedInt(params:Term, key:String, nestedKey:String):Null<Int> {
		return intFromTerm(getNested(params, key, nestedKey));
	}

	public static function getBool(params:Term, key:String):Null<Bool> {
		var value = get(params, key);
		if (Kernel.isNil(value))
			return null;

		if (Kernel.isBoolean(value))
			return cast value;

		if (!Kernel.isBinary(value))
			return null;

		return switch (ElixirString.downcase(ElixirString.trim(cast value))) {
			case "true" | "1" | "yes" | "on": true;
			case "false" | "0" | "no" | "off": false;
			case _: null;
		};
	}

	public static function getIntDefault(params:Term, key:String, defaultValue:Int):Int {
		var value = getInt(params, key);
		return value != null ? value : defaultValue;
	}

	public static function getNestedIntDefault(params:Term, key:String, nestedKey:String, defaultValue:Int):Int {
		var value = getNestedInt(params, key, nestedKey);
		return value != null ? value : defaultValue;
	}

	public static function intFromTerm(value:Null<Term>):Null<Int> {
		if (Kernel.isNil(value))
			return null;

		if (Kernel.isInteger(value))
			return cast value;

		if (Kernel.isFloat(value))
			return Std.int(cast value);

		return Kernel.isBinary(value) ? Std.parseInt(cast value) : null;
	}

	static function existingAtomOrNull(key:String):Null<Term> {
		// Boundary escape hatch: Elixir raises ArgumentError when a trusted atom
		// key is absent; Haxe catch lowering would add HaxeThrow rescue scaffolding.
		return untyped __elixir__("try do\n  String.to_existing_atom({0})\nrescue\n  ArgumentError -> nil\nend", key);
	}
}
#end
