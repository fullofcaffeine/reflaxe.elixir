package haxe;

@:noDoc
typedef TypeResolver = {
	function resolveClass(name:String):Class<Dynamic>;
	function resolveEnum(name:String):Enum<Dynamic>;
}

/**
 * Elixir-target unserializer for the portable subset emitted by `haxe.Serializer`.
 */
class Unserializer {
	public static var DEFAULT_RESOLVER:TypeResolver = null;

	var buffer:String;
	var resolver:TypeResolver;

	public function new(buffer:String) {
		this.buffer = buffer;
		resolver = DEFAULT_RESOLVER;
	}

	public function setResolver(resolver:TypeResolver):Void {
		this.resolver = resolver;
	}

	public function getResolver():TypeResolver {
		return resolver;
	}

	public function unserialize():Dynamic {
		return decode(buffer);
	}

	public static function run(value:String):Dynamic {
		return decode(value);
	}

	static function decode(value:String):Dynamic {
		return untyped __elixir__('
read_digits = fn text, pos ->
  len = byte_size(text)
  {sign, pos} =
    if pos < len and :binary.at(text, pos) == ?- do
      {-1, pos + 1}
    else
      {1, pos}
    end

  start = pos
  pos =
    Stream.iterate(pos, &(&1 + 1))
    |> Enum.reduce_while(pos, fn current, _ ->
      if current < len do
        char = :binary.at(text, current)
        if char >= ?0 and char <= ?9, do: {:cont, current + 1}, else: {:halt, current}
      else
        {:halt, current}
      end
    end)

  digits = binary_part(text, start, pos - start)
  number = if digits == "", do: 0, else: String.to_integer(digits) * sign
  {number, pos}
end

parse = fn parse, text, pos ->
  case :binary.at(text, pos) do
    ?n -> {nil, pos + 1}
    ?t -> {true, pos + 1}
    ?f -> {false, pos + 1}
    ?z -> {0, pos + 1}
    ?i ->
      {number, next_pos} = read_digits.(text, pos + 1)
      {number, next_pos}
    ?d ->
      start = pos + 1
      len = byte_size(text)
      stop =
        Stream.iterate(start, &(&1 + 1))
        |> Enum.reduce_while(start, fn current, _ ->
          if current < len do
            char = :binary.at(text, current)
            if (char >= ?0 and char <= ?9) or char in [?+, ?-, ?., ?e, ?E] do
              {:cont, current + 1}
            else
              {:halt, current}
            end
          else
            {:halt, current}
          end
        end)

      float_text = binary_part(text, start, stop - start)
      {Reflaxe.Elixir.HaxeFloat.parse(float_text), stop}
    ?k -> {Reflaxe.Elixir.HaxeFloat.nan(), pos + 1}
    ?p -> {Reflaxe.Elixir.HaxeFloat.positive_infinity(), pos + 1}
    ?m -> {Reflaxe.Elixir.HaxeFloat.negative_infinity(), pos + 1}
    ?y ->
      {length, after_length} = read_digits.(text, pos + 1)
      if :binary.at(text, after_length) != ?:, do: raise(Reflaxe.Elixir.HaxeThrow, [value: "Invalid string length"])
      start = after_length + 1
      encoded = binary_part(text, start, length)
      {URI.decode_www_form(encoded), start + length}
    ?a ->
      collect = fn collect, collect, acc, current_pos ->
        if :binary.at(text, current_pos) == ?h do
          {Enum.reverse(acc), current_pos + 1}
        else
          {item, next_pos} = parse.(parse, text, current_pos)
          collect.(collect, collect, [item | acc], next_pos)
        end
      end
      collect.(collect, collect, [], pos + 1)
    ?o ->
      collect = fn collect, collect, acc, current_pos ->
        if :binary.at(text, current_pos) == ?g do
          {acc, current_pos + 1}
        else
          {key, after_key} = parse.(parse, text, current_pos)
          {item, after_item} = parse.(parse, text, after_key)
          collect.(collect, collect, Map.put(acc, key, item), after_item)
        end
      end
      collect.(collect, collect, %{}, pos + 1)
    ?x ->
      {exception_value, _} = parse.(parse, text, pos + 1)
      raise Reflaxe.Elixir.HaxeThrow, [value: exception_value]
    other ->
      raise Reflaxe.Elixir.HaxeThrow, [value: "Invalid char " <> <<other>> <> " at position " <> Kernel.to_string(pos)]
  end
end

{result, _} = parse.(parse, {0}, 0)
result
', value);
	}
}
