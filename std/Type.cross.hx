/**
 * The possible runtime types of a value.
 */
enum ValueType {
	TNull;
	TInt;
	TFloat;
	TBool;
	TObject;
	TClass(c:Class<Dynamic>);
	TEnum(e:Enum<Dynamic>);
	TUnknown;
}

/**
 * The Type API provides runtime type information and reflection capabilities.
 * This is essential for dynamic programming and enum manipulation in Haxe.
 * 
 * For the Elixir target, these functions use simple placeholders during compilation
 * and are properly implemented in the generated Elixir runtime code.
 */
class Type {
	/** Returns the runtime type of a value. */
	public static function typeof(value: Dynamic): ValueType {
		return untyped __elixir__('
      case {0} do
        nil -> {:TNull}
        val when is_integer(val) -> {:TInt}
        val when is_float(val) -> {:TFloat}
        val when is_boolean(val) -> {:TBool}
        %{__struct__: mod} -> {:TClass, mod}
        val when is_tuple(val) and tuple_size(val) > 0 and is_atom(elem(val, 0)) -> {:TEnum, nil}
        val when is_map(val) -> {:TObject}
        _ -> {:TUnknown}
      end
    ', value);
	}

	/** Returns the index of an enum value. */
	public static function enumIndex(enumValue: Dynamic): Int {
		return untyped __elixir__('
      case {0} do
        tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> :erlang.phash2(elem(tuple, 0))
        atom when is_atom(atom) -> :erlang.phash2(atom)
        _ -> 0
      end
    ', enumValue);
	}

	/** Returns the parameters of an enum value as an array. */
	public static function enumParameters(enumValue: Dynamic): Array<Dynamic> {
		return untyped __elixir__('
      case {0} do
        tuple when is_tuple(tuple) and tuple_size(tuple) > 1 ->
          tuple |> Tuple.to_list() |> Enum.drop(1)
        _ -> []
      end
    ', enumValue);
	}

	/** Returns the constructor name of an enum value. */
	public static function enumConstructor(enumValue: Dynamic): String {
		return untyped __elixir__('
      case {0} do
        tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0) |> Atom.to_string()
        atom when is_atom(atom) -> Atom.to_string(atom)
        _ -> ""
      end
    ', enumValue);
	}

	/** Checks if two enum values are equal. */
	public static function enumEq<T>(a: T, b: T): Bool {
		return a == b;
	}

	/** Gets the class/module of an instance. */
	public static function getClass<T>(object: T): Class<T> {
		return untyped __elixir__('case {0} do %{__struct__: mod} -> mod; _ -> nil end', object);
	}

	/** Gets the superclass of a class (always nil in Elixir). */
	public static function getSuperClass(c: Class<Dynamic>): Class<Dynamic> {
		var _ignore = c;
		return null;
	}

	/** Gets the class name as a string. */
	public static function getClassName(c: Class<Dynamic>): String {
		return untyped __elixir__('case {0} do mod when is_atom(mod) -> mod |> Module.split() |> Enum.join(\".\"); _ -> nil end', c);
	}

	/** Gets the enum name as a string. */
	public static function getEnumName(e: Enum<Dynamic>): String {
		return untyped __elixir__('case {0} do mod when is_atom(mod) -> mod |> Module.split() |> Enum.join(\".\"); _ -> nil end', e);
	}

	/** Checks if an object is of a specific type. */
	public static function isType(value: Dynamic, t: Dynamic): Bool {
		return untyped __elixir__('case {0} do %{__struct__: mod} -> mod == {1}; _ -> false end', value, t);
	}

	/** Creates an instance of a class with given arguments. */
	public static function createInstance<T>(cl: Class<T>, args: Array<Dynamic>): T {
		return untyped __elixir__('apply({0}, :new, {1})', cl, args);
	}

	/** Creates an empty instance of a class without calling the constructor. */
	public static function createEmptyInstance<T>(cl: Class<T>): T {
		return untyped __elixir__('struct({0})', cl);
	}

	/** Creates an enum value by name and parameters. */
	public static function createEnum<T>(_enum: Enum<T>, constructor: String, ?params: Array<Dynamic>): T {
		var _ignoreEnum = _enum; // keep parameter used to avoid warnings when unused
		return untyped __elixir__('
      tag = String.to_atom({0})
      values = case {1} do
        nil -> []
        arr when is_list(arr) -> arr
        other -> List.wrap(other)
      end
      List.to_tuple([tag | values])
    ', constructor, params);
	}

	/** Creates an enum value by index and parameters (unsupported). */
	public static function createEnumIndex<T>(_enum: Enum<T>, index: Int, ?params: Array<Dynamic>): T {
		var _ignoreEnum = _enum;
		var _ignoreI = index;
		var _ignoreP = params;
		throw "Type.createEnumIndex not implemented for Elixir target";
	}

	/** Returns all enum constructors (not available at runtime). */
	public static function getEnumConstructs(_enum: Enum<Dynamic>): Array<String> {
		var _ignoreEnum = _enum;
		return [];
	}

	/** Returns all values of an enum that has no parameters (not available). */
	public static function allEnums<T>(_enum: Enum<T>): Array<T> {
		var _ignoreEnum = _enum;
		return [];
	}
}
