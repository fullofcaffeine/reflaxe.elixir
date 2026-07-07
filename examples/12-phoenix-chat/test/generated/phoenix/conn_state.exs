defmodule Phoenix.ConnState do
  def unset() do
    {:unset}
  end
  def set() do
    {:set}
  end
  def sent() do
    {:sent}
  end
  def chunked() do
    {:chunked}
  end
  def file_chunked() do
    {:file_chunked}
  end
  def __haxe_enum_constructs__() do
    ["Unset", "Set", "Sent", "Chunked", "FileChunked"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :unset -> 0
        1 -> 1
        :set -> 1
        2 -> 2
        :sent -> 2
        3 -> 3
        :chunked -> 3
        4 -> 4
        :file_chunked -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.ConnState"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Unset"
        :unset -> "Unset"
        1 -> "Set"
        :set -> "Set"
        2 -> "Sent"
        :sent -> "Sent"
        3 -> "Chunked"
        :chunked -> "Chunked"
        4 -> "FileChunked"
        :file_chunked -> "FileChunked"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.ConnState"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Unset" when values == [] -> List.to_tuple([:unset | values])
      "Unset" -> raise "Enum constructor Unset expects 0 params for Phoenix.ConnState"
      "Set" when values == [] -> List.to_tuple([:set | values])
      "Set" -> raise "Enum constructor Set expects 0 params for Phoenix.ConnState"
      "Sent" when values == [] -> List.to_tuple([:sent | values])
      "Sent" -> raise "Enum constructor Sent expects 0 params for Phoenix.ConnState"
      "Chunked" when values == [] -> List.to_tuple([:chunked | values])
      "Chunked" -> raise "Enum constructor Chunked expects 0 params for Phoenix.ConnState"
      "FileChunked" when values == [] -> List.to_tuple([:file_chunked | values])
      "FileChunked" -> raise "Enum constructor FileChunked expects 0 params for Phoenix.ConnState"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.ConnState"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:unset | values])
      0 -> raise "Enum constructor Unset expects 0 params for Phoenix.ConnState"
      1 when values == [] -> List.to_tuple([:set | values])
      1 -> raise "Enum constructor Set expects 0 params for Phoenix.ConnState"
      2 when values == [] -> List.to_tuple([:sent | values])
      2 -> raise "Enum constructor Sent expects 0 params for Phoenix.ConnState"
      3 when values == [] -> List.to_tuple([:chunked | values])
      3 -> raise "Enum constructor Chunked expects 0 params for Phoenix.ConnState"
      4 when values == [] -> List.to_tuple([:file_chunked | values])
      4 -> raise "Enum constructor FileChunked expects 0 params for Phoenix.ConnState"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.ConnState"
    end
  end
  def __haxe_enum_all__() do
    [{:unset}, {:set}, {:sent}, {:chunked}, {:file_chunked}]
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
