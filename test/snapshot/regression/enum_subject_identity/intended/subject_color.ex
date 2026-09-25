defmodule SubjectColor do
  def red() do
    {0}
  end
  def blue() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["Red", "Blue"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :red -> 0
        1 -> 1
        :blue -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for SubjectColor"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Red"
        :red -> "Red"
        1 -> "Blue"
        :blue -> "Blue"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for SubjectColor"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Red" when values == [] -> List.to_tuple([:red | values])
      "Red" -> raise "Enum constructor Red expects 0 params for SubjectColor"
      "Blue" when values == [] -> List.to_tuple([:blue | values])
      "Blue" -> raise "Enum constructor Blue expects 0 params for SubjectColor"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for SubjectColor"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:red | values])
      0 -> raise "Enum constructor Red expects 0 params for SubjectColor"
      1 when values == [] -> List.to_tuple([:blue | values])
      1 -> raise "Enum constructor Blue expects 0 params for SubjectColor"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for SubjectColor"
    end
  end
  def __haxe_enum_all__() do
    [{:red}, {:blue}]
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
