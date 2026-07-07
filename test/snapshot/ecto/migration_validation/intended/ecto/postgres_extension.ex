defmodule Ecto.PostgresExtension do
  def uuid_ossp() do
    {0}
  end
  def post_gis() do
    {1}
  end
  def h_store() do
    {2}
  end
  def pg_trgm() do
    {3}
  end
  def pg_crypto() do
    {4}
  end
  def jsonb_plv8() do
    {5}
  end
  def __haxe_enum_constructs__() do
    ["UuidOssp", "PostGIS", "HStore", "PgTrgm", "PgCrypto", "JsonbPlv8"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :uuid_ossp -> 0
        1 -> 1
        :post_gis -> 1
        2 -> 2
        :h_store -> 2
        3 -> 3
        :pg_trgm -> 3
        4 -> 4
        :pg_crypto -> 4
        5 -> 5
        :jsonb_plv8 -> 5
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.PostgresExtension"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "UuidOssp"
        :uuid_ossp -> "UuidOssp"
        1 -> "PostGIS"
        :post_gis -> "PostGIS"
        2 -> "HStore"
        :h_store -> "HStore"
        3 -> "PgTrgm"
        :pg_trgm -> "PgTrgm"
        4 -> "PgCrypto"
        :pg_crypto -> "PgCrypto"
        5 -> "JsonbPlv8"
        :jsonb_plv8 -> "JsonbPlv8"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.PostgresExtension"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "UuidOssp" when values == [] -> List.to_tuple([:uuid_ossp | values])
      "UuidOssp" -> raise "Enum constructor UuidOssp expects 0 params for Ecto.PostgresExtension"
      "PostGIS" when values == [] -> List.to_tuple([:post_gis | values])
      "PostGIS" -> raise "Enum constructor PostGIS expects 0 params for Ecto.PostgresExtension"
      "HStore" when values == [] -> List.to_tuple([:h_store | values])
      "HStore" -> raise "Enum constructor HStore expects 0 params for Ecto.PostgresExtension"
      "PgTrgm" when values == [] -> List.to_tuple([:pg_trgm | values])
      "PgTrgm" -> raise "Enum constructor PgTrgm expects 0 params for Ecto.PostgresExtension"
      "PgCrypto" when values == [] -> List.to_tuple([:pg_crypto | values])
      "PgCrypto" -> raise "Enum constructor PgCrypto expects 0 params for Ecto.PostgresExtension"
      "JsonbPlv8" when values == [] -> List.to_tuple([:jsonb_plv8 | values])
      "JsonbPlv8" -> raise "Enum constructor JsonbPlv8 expects 0 params for Ecto.PostgresExtension"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.PostgresExtension"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:uuid_ossp | values])
      0 -> raise "Enum constructor UuidOssp expects 0 params for Ecto.PostgresExtension"
      1 when values == [] -> List.to_tuple([:post_gis | values])
      1 -> raise "Enum constructor PostGIS expects 0 params for Ecto.PostgresExtension"
      2 when values == [] -> List.to_tuple([:h_store | values])
      2 -> raise "Enum constructor HStore expects 0 params for Ecto.PostgresExtension"
      3 when values == [] -> List.to_tuple([:pg_trgm | values])
      3 -> raise "Enum constructor PgTrgm expects 0 params for Ecto.PostgresExtension"
      4 when values == [] -> List.to_tuple([:pg_crypto | values])
      4 -> raise "Enum constructor PgCrypto expects 0 params for Ecto.PostgresExtension"
      5 when values == [] -> List.to_tuple([:jsonb_plv8 | values])
      5 -> raise "Enum constructor JsonbPlv8 expects 0 params for Ecto.PostgresExtension"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.PostgresExtension"
    end
  end
  def __haxe_enum_all__() do
    [{:uuid_ossp}, {:post_gis}, {:h_store}, {:pg_trgm}, {:pg_crypto}, {:jsonb_plv8}]
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
