defmodule Sys.Io.FileSeek do
  def seek_begin() do
    {0}
  end
  def seek_cur() do
    {1}
  end
  def seek_end() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["SeekBegin", "SeekCur", "SeekEnd"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :seek_begin -> 0
        1 -> 1
        :seek_cur -> 1
        2 -> 2
        :seek_end -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Sys.Io.FileSeek"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "SeekBegin"
        :seek_begin -> "SeekBegin"
        1 -> "SeekCur"
        :seek_cur -> "SeekCur"
        2 -> "SeekEnd"
        :seek_end -> "SeekEnd"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Sys.Io.FileSeek"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "SeekBegin" when values == [] -> List.to_tuple([:seek_begin | values])
      "SeekBegin" -> raise "Enum constructor SeekBegin expects 0 params for Sys.Io.FileSeek"
      "SeekCur" when values == [] -> List.to_tuple([:seek_cur | values])
      "SeekCur" -> raise "Enum constructor SeekCur expects 0 params for Sys.Io.FileSeek"
      "SeekEnd" when values == [] -> List.to_tuple([:seek_end | values])
      "SeekEnd" -> raise "Enum constructor SeekEnd expects 0 params for Sys.Io.FileSeek"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Sys.Io.FileSeek"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:seek_begin | values])
      0 -> raise "Enum constructor SeekBegin expects 0 params for Sys.Io.FileSeek"
      1 when values == [] -> List.to_tuple([:seek_cur | values])
      1 -> raise "Enum constructor SeekCur expects 0 params for Sys.Io.FileSeek"
      2 when values == [] -> List.to_tuple([:seek_end | values])
      2 -> raise "Enum constructor SeekEnd expects 0 params for Sys.Io.FileSeek"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Sys.Io.FileSeek"
    end
  end
  def __haxe_enum_all__() do
    [{:seek_begin}, {:seek_cur}, {:seek_end}]
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
