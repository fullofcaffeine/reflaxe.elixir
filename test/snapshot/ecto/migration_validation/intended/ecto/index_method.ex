defmodule Ecto.IndexMethod do
  def b_tree() do
    {0}
  end
  def hash() do
    {1}
  end
  def gin() do
    {2}
  end
  def gist() do
    {3}
  end
  def brin() do
    {4}
  end
  def __haxe_enum_constructs__() do
    ["BTree", "Hash", "Gin", "Gist", "Brin"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :b_tree -> 0
        1 -> 1
        :hash -> 1
        2 -> 2
        :gin -> 2
        3 -> 3
        :gist -> 3
        4 -> 4
        :brin -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.IndexMethod"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "BTree"
        :b_tree -> "BTree"
        1 -> "Hash"
        :hash -> "Hash"
        2 -> "Gin"
        :gin -> "Gin"
        3 -> "Gist"
        :gist -> "Gist"
        4 -> "Brin"
        :brin -> "Brin"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.IndexMethod"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "BTree" when values == [] -> List.to_tuple([:b_tree | values])
      "BTree" -> raise "Enum constructor BTree expects 0 params for Ecto.IndexMethod"
      "Hash" when values == [] -> List.to_tuple([:hash | values])
      "Hash" -> raise "Enum constructor Hash expects 0 params for Ecto.IndexMethod"
      "Gin" when values == [] -> List.to_tuple([:gin | values])
      "Gin" -> raise "Enum constructor Gin expects 0 params for Ecto.IndexMethod"
      "Gist" when values == [] -> List.to_tuple([:gist | values])
      "Gist" -> raise "Enum constructor Gist expects 0 params for Ecto.IndexMethod"
      "Brin" when values == [] -> List.to_tuple([:brin | values])
      "Brin" -> raise "Enum constructor Brin expects 0 params for Ecto.IndexMethod"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.IndexMethod"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:b_tree | values])
      0 -> raise "Enum constructor BTree expects 0 params for Ecto.IndexMethod"
      1 when values == [] -> List.to_tuple([:hash | values])
      1 -> raise "Enum constructor Hash expects 0 params for Ecto.IndexMethod"
      2 when values == [] -> List.to_tuple([:gin | values])
      2 -> raise "Enum constructor Gin expects 0 params for Ecto.IndexMethod"
      3 when values == [] -> List.to_tuple([:gist | values])
      3 -> raise "Enum constructor Gist expects 0 params for Ecto.IndexMethod"
      4 when values == [] -> List.to_tuple([:brin | values])
      4 -> raise "Enum constructor Brin expects 0 params for Ecto.IndexMethod"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.IndexMethod"
    end
  end
  def __haxe_enum_all__() do
    [{:b_tree}, {:hash}, {:gin}, {:gist}, {:brin}]
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
