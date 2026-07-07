defmodule Ecto.Migration.AlterOperation do
  def add_column(arg0, arg1, arg2) do
    {0, arg0, arg1, arg2}
  end
  def remove_column(arg0) do
    {1, arg0}
  end
  def modify_column(arg0, arg1, arg2) do
    {2, arg0, arg1, arg2}
  end
  def rename_column(arg0, arg1) do
    {3, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["AddColumn", "RemoveColumn", "ModifyColumn", "RenameColumn"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :add_column -> 0
        1 -> 1
        :remove_column -> 1
        2 -> 2
        :modify_column -> 2
        3 -> 3
        :rename_column -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.Migration.AlterOperation"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "AddColumn"
        :add_column -> "AddColumn"
        1 -> "RemoveColumn"
        :remove_column -> "RemoveColumn"
        2 -> "ModifyColumn"
        :modify_column -> "ModifyColumn"
        3 -> "RenameColumn"
        :rename_column -> "RenameColumn"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.Migration.AlterOperation"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "AddColumn" when length(values) == 3 -> List.to_tuple([:add_column | values])
      "AddColumn" -> raise "Enum constructor AddColumn expects 3 params for Ecto.Migration.AlterOperation"
      "RemoveColumn" when length(values) == 1 -> List.to_tuple([:remove_column | values])
      "RemoveColumn" -> raise "Enum constructor RemoveColumn expects 1 params for Ecto.Migration.AlterOperation"
      "ModifyColumn" when length(values) == 3 -> List.to_tuple([:modify_column | values])
      "ModifyColumn" -> raise "Enum constructor ModifyColumn expects 3 params for Ecto.Migration.AlterOperation"
      "RenameColumn" when length(values) == 2 -> List.to_tuple([:rename_column | values])
      "RenameColumn" -> raise "Enum constructor RenameColumn expects 2 params for Ecto.Migration.AlterOperation"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.Migration.AlterOperation"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 3 -> List.to_tuple([:add_column | values])
      0 -> raise "Enum constructor AddColumn expects 3 params for Ecto.Migration.AlterOperation"
      1 when length(values) == 1 -> List.to_tuple([:remove_column | values])
      1 -> raise "Enum constructor RemoveColumn expects 1 params for Ecto.Migration.AlterOperation"
      2 when length(values) == 3 -> List.to_tuple([:modify_column | values])
      2 -> raise "Enum constructor ModifyColumn expects 3 params for Ecto.Migration.AlterOperation"
      3 when length(values) == 2 -> List.to_tuple([:rename_column | values])
      3 -> raise "Enum constructor RenameColumn expects 2 params for Ecto.Migration.AlterOperation"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.Migration.AlterOperation"
    end
  end
  def __haxe_enum_all__() do
    []
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
