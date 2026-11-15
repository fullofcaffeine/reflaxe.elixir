defmodule Haxe.Io.Encoding do
  def utf8() do
    {0}
  end
  def utf16_le() do
    {1}
  end
  def utf16_be() do
    {2}
  end
  def utf32_le() do
    {3}
  end
  def utf32_be() do
    {4}
  end
  def raw_native() do
    {5}
  end
  def __haxe_enum_constructs__() do
    ["UTF8", "UTF16LE", "UTF16BE", "UTF32LE", "UTF32BE", "RawNative"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :utf8 -> 0
        1 -> 1
        :utf16_le -> 1
        2 -> 2
        :utf16_be -> 2
        3 -> 3
        :utf32_le -> 3
        4 -> 4
        :utf32_be -> 4
        5 -> 5
        :raw_native -> 5
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Haxe.Io.Encoding"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "UTF8"
        :utf8 -> "UTF8"
        1 -> "UTF16LE"
        :utf16_le -> "UTF16LE"
        2 -> "UTF16BE"
        :utf16_be -> "UTF16BE"
        3 -> "UTF32LE"
        :utf32_le -> "UTF32LE"
        4 -> "UTF32BE"
        :utf32_be -> "UTF32BE"
        5 -> "RawNative"
        :raw_native -> "RawNative"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Haxe.Io.Encoding"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "UTF8" when values == [] -> List.to_tuple([:utf8 | values])
      "UTF8" -> raise "Enum constructor UTF8 expects 0 params for Haxe.Io.Encoding"
      "UTF16LE" when values == [] -> List.to_tuple([:utf16_le | values])
      "UTF16LE" -> raise "Enum constructor UTF16LE expects 0 params for Haxe.Io.Encoding"
      "UTF16BE" when values == [] -> List.to_tuple([:utf16_be | values])
      "UTF16BE" -> raise "Enum constructor UTF16BE expects 0 params for Haxe.Io.Encoding"
      "UTF32LE" when values == [] -> List.to_tuple([:utf32_le | values])
      "UTF32LE" -> raise "Enum constructor UTF32LE expects 0 params for Haxe.Io.Encoding"
      "UTF32BE" when values == [] -> List.to_tuple([:utf32_be | values])
      "UTF32BE" -> raise "Enum constructor UTF32BE expects 0 params for Haxe.Io.Encoding"
      "RawNative" when values == [] -> List.to_tuple([:raw_native | values])
      "RawNative" -> raise "Enum constructor RawNative expects 0 params for Haxe.Io.Encoding"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Haxe.Io.Encoding"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:utf8 | values])
      0 -> raise "Enum constructor UTF8 expects 0 params for Haxe.Io.Encoding"
      1 when values == [] -> List.to_tuple([:utf16_le | values])
      1 -> raise "Enum constructor UTF16LE expects 0 params for Haxe.Io.Encoding"
      2 when values == [] -> List.to_tuple([:utf16_be | values])
      2 -> raise "Enum constructor UTF16BE expects 0 params for Haxe.Io.Encoding"
      3 when values == [] -> List.to_tuple([:utf32_le | values])
      3 -> raise "Enum constructor UTF32LE expects 0 params for Haxe.Io.Encoding"
      4 when values == [] -> List.to_tuple([:utf32_be | values])
      4 -> raise "Enum constructor UTF32BE expects 0 params for Haxe.Io.Encoding"
      5 when values == [] -> List.to_tuple([:raw_native | values])
      5 -> raise "Enum constructor RawNative expects 0 params for Haxe.Io.Encoding"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Haxe.Io.Encoding"
    end
  end
  def __haxe_enum_all__() do
    [{:utf8}, {:utf16_le}, {:utf16_be}, {:utf32_le}, {:utf32_be}, {:raw_native}]
  end
  def __haxe_enum_eq__(left, right) do
    left_name = __haxe_enum_constructor__(left)
    right_name = __haxe_enum_constructor__(right)
    left_params = case left do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    right_params = case right do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    left_name == right_name and left_params == right_params
  end
end
