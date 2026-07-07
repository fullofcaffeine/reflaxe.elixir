defmodule Ecto.OnUpdateAction do
  def restrict() do
    {0}
  end
  def cascade() do
    {1}
  end
  def set_null() do
    {2}
  end
  def no_action() do
    {3}
  end
  def __haxe_enum_constructs__() do
    ["Restrict", "Cascade", "SetNull", "NoAction"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :restrict -> 0
        1 -> 1
        :cascade -> 1
        2 -> 2
        :set_null -> 2
        3 -> 3
        :no_action -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.OnUpdateAction"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Restrict"
        :restrict -> "Restrict"
        1 -> "Cascade"
        :cascade -> "Cascade"
        2 -> "SetNull"
        :set_null -> "SetNull"
        3 -> "NoAction"
        :no_action -> "NoAction"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.OnUpdateAction"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Restrict" when values == [] -> List.to_tuple([:restrict | values])
      "Restrict" -> raise "Enum constructor Restrict expects 0 params for Ecto.OnUpdateAction"
      "Cascade" when values == [] -> List.to_tuple([:cascade | values])
      "Cascade" -> raise "Enum constructor Cascade expects 0 params for Ecto.OnUpdateAction"
      "SetNull" when values == [] -> List.to_tuple([:set_null | values])
      "SetNull" -> raise "Enum constructor SetNull expects 0 params for Ecto.OnUpdateAction"
      "NoAction" when values == [] -> List.to_tuple([:no_action | values])
      "NoAction" -> raise "Enum constructor NoAction expects 0 params for Ecto.OnUpdateAction"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.OnUpdateAction"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:restrict | values])
      0 -> raise "Enum constructor Restrict expects 0 params for Ecto.OnUpdateAction"
      1 when values == [] -> List.to_tuple([:cascade | values])
      1 -> raise "Enum constructor Cascade expects 0 params for Ecto.OnUpdateAction"
      2 when values == [] -> List.to_tuple([:set_null | values])
      2 -> raise "Enum constructor SetNull expects 0 params for Ecto.OnUpdateAction"
      3 when values == [] -> List.to_tuple([:no_action | values])
      3 -> raise "Enum constructor NoAction expects 0 params for Ecto.OnUpdateAction"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.OnUpdateAction"
    end
  end
  def __haxe_enum_all__() do
    [{:restrict}, {:cascade}, {:set_null}, {:no_action}]
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
