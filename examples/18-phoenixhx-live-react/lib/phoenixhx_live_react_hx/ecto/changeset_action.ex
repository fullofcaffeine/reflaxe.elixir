defmodule Ecto.ChangesetAction do
  def insert() do
    {0}
  end
  def update() do
    {1}
  end
  def delete() do
    {2}
  end
  def replace() do
    {3}
  end
  def __haxe_enum_constructs__() do
    ["Insert", "Update", "Delete", "Replace"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :insert -> 0
        1 -> 1
        :update -> 1
        2 -> 2
        :delete -> 2
        3 -> 3
        :replace -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.ChangesetAction"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Insert"
        :insert -> "Insert"
        1 -> "Update"
        :update -> "Update"
        2 -> "Delete"
        :delete -> "Delete"
        3 -> "Replace"
        :replace -> "Replace"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.ChangesetAction"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Insert" when values == [] -> List.to_tuple([:insert | values])
      "Insert" -> raise "Enum constructor Insert expects 0 params for Ecto.ChangesetAction"
      "Update" when values == [] -> List.to_tuple([:update | values])
      "Update" -> raise "Enum constructor Update expects 0 params for Ecto.ChangesetAction"
      "Delete" when values == [] -> List.to_tuple([:delete | values])
      "Delete" -> raise "Enum constructor Delete expects 0 params for Ecto.ChangesetAction"
      "Replace" when values == [] -> List.to_tuple([:replace | values])
      "Replace" -> raise "Enum constructor Replace expects 0 params for Ecto.ChangesetAction"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.ChangesetAction"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:insert | values])
      0 -> raise "Enum constructor Insert expects 0 params for Ecto.ChangesetAction"
      1 when values == [] -> List.to_tuple([:update | values])
      1 -> raise "Enum constructor Update expects 0 params for Ecto.ChangesetAction"
      2 when values == [] -> List.to_tuple([:delete | values])
      2 -> raise "Enum constructor Delete expects 0 params for Ecto.ChangesetAction"
      3 when values == [] -> List.to_tuple([:replace | values])
      3 -> raise "Enum constructor Replace expects 0 params for Ecto.ChangesetAction"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.ChangesetAction"
    end
  end
  def __haxe_enum_all__() do
    [{:insert}, {:update}, {:delete}, {:replace}]
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
