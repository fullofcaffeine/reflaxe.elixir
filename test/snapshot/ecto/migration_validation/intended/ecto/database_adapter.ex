defmodule Ecto.DatabaseAdapter do
  def postgres() do
    {0}
  end
  def my_sql() do
    {1}
  end
  def sq_lite3() do
    {2}
  end
  def sql_server() do
    {3}
  end
  def in_memory() do
    {4}
  end
  def __haxe_enum_constructs__() do
    ["Postgres", "MySQL", "SQLite3", "SQLServer", "InMemory"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :postgres -> 0
        1 -> 1
        :my_sql -> 1
        2 -> 2
        :sq_lite3 -> 2
        3 -> 3
        :sql_server -> 3
        4 -> 4
        :in_memory -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.DatabaseAdapter"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Postgres"
        :postgres -> "Postgres"
        1 -> "MySQL"
        :my_sql -> "MySQL"
        2 -> "SQLite3"
        :sq_lite3 -> "SQLite3"
        3 -> "SQLServer"
        :sql_server -> "SQLServer"
        4 -> "InMemory"
        :in_memory -> "InMemory"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.DatabaseAdapter"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Postgres" when values == [] -> List.to_tuple([:postgres | values])
      "Postgres" -> raise "Enum constructor Postgres expects 0 params for Ecto.DatabaseAdapter"
      "MySQL" when values == [] -> List.to_tuple([:my_sql | values])
      "MySQL" -> raise "Enum constructor MySQL expects 0 params for Ecto.DatabaseAdapter"
      "SQLite3" when values == [] -> List.to_tuple([:sq_lite3 | values])
      "SQLite3" -> raise "Enum constructor SQLite3 expects 0 params for Ecto.DatabaseAdapter"
      "SQLServer" when values == [] -> List.to_tuple([:sql_server | values])
      "SQLServer" -> raise "Enum constructor SQLServer expects 0 params for Ecto.DatabaseAdapter"
      "InMemory" when values == [] -> List.to_tuple([:in_memory | values])
      "InMemory" -> raise "Enum constructor InMemory expects 0 params for Ecto.DatabaseAdapter"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.DatabaseAdapter"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:postgres | values])
      0 -> raise "Enum constructor Postgres expects 0 params for Ecto.DatabaseAdapter"
      1 when values == [] -> List.to_tuple([:my_sql | values])
      1 -> raise "Enum constructor MySQL expects 0 params for Ecto.DatabaseAdapter"
      2 when values == [] -> List.to_tuple([:sq_lite3 | values])
      2 -> raise "Enum constructor SQLite3 expects 0 params for Ecto.DatabaseAdapter"
      3 when values == [] -> List.to_tuple([:sql_server | values])
      3 -> raise "Enum constructor SQLServer expects 0 params for Ecto.DatabaseAdapter"
      4 when values == [] -> List.to_tuple([:in_memory | values])
      4 -> raise "Enum constructor InMemory expects 0 params for Ecto.DatabaseAdapter"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.DatabaseAdapter"
    end
  end
  def __haxe_enum_all__() do
    [{:postgres}, {:my_sql}, {:sq_lite3}, {:sql_server}, {:in_memory}]
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
