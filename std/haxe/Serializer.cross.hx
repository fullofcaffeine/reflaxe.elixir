package haxe;

/**
 * Elixir-target serializer for the Haxe serialization wire format.
 *
 * This override intentionally starts with the portable data subset that maps cleanly to BEAM
 * terms: null, booleans, numbers, strings, arrays/lists, and string-key maps/anonymous objects.
 * Class, enum, object-identity map, reference-cache, custom `hxSerialize`, Date, and Bytes
 * support should be added as explicit follow-up slices with runtime tests.
 */
class Serializer {
	public static var USE_CACHE = false;
	public static var USE_ENUM_INDEX = false;

	public var useCache:Bool;
	public var useEnumIndex:Bool;

	var serializerId:Int;

	public function new() {
		serializerId = untyped __elixir__('System.unique_integer([:positive])');
		untyped __elixir__('Process.put({:haxe_serializer_parts, {0}}, [])', serializerId);
		useCache = USE_CACHE;
		useEnumIndex = USE_ENUM_INDEX;
	}

	public function toString():String {
		return untyped __elixir__('Process.get({:haxe_serializer_parts, {0}}, []) |> Enum.join("")', serializerId);
	}

	public function serialize(value:Dynamic):Void {
		untyped __elixir__('
key = {:haxe_serializer_parts, {0}}
Process.put(key, Process.get(key, []) ++ [encode({1})])
', serializerId, value);
	}

	public function serializeException(value:Dynamic):Void {
		untyped __elixir__('
key = {:haxe_serializer_parts, {0}}
Process.put(key, Process.get(key, []) ++ ["x" <> encode({1})])
', serializerId, value);
	}

	public static function run(value:Dynamic):String {
		return encode(value);
	}

	static function encode(value:Dynamic):String {
		return untyped __elixir__('
encode = fn encode, value ->
  cond do
    value == nil ->
      "n"

    value == true ->
      "t"

    value == false ->
      "f"

    is_integer(value) ->
      if value == 0, do: "z", else: "i" <> Kernel.to_string(value)

    is_float(value) ->
      cond do
        value != value -> "k"
        value == :math.pow(1.0, 309) -> "p"
        value == -:math.pow(1.0, 309) -> "m"
        true -> "d" <> Kernel.to_string(value)
      end

    is_binary(value) ->
      encoded = URI.encode_www_form(value)
      "y" <> Kernel.to_string(byte_size(encoded)) <> ":" <> encoded

    is_list(value) ->
      "a" <> Enum.map_join(value, "", fn item -> encode.(encode, item) end) <> "h"

    is_map(value) ->
      body =
        value
        |> Map.drop([:__reflaxe_class__, :__struct__])
        |> Enum.map_join("", fn {key, item} ->
          key_text =
            case key do
              atom when is_atom(atom) -> Atom.to_string(atom)
              binary when is_binary(binary) -> binary
              other -> Kernel.to_string(other)
            end

          encode.(encode, key_text) <> encode.(encode, item)
        end)

      "o" <> body <> "g"

    true ->
      raise Reflaxe.Elixir.HaxeThrow, [value: "Cannot serialize " <> Kernel.inspect(value)]
  end
end

encode.(encode, {0})
', value);
	}
}
