defmodule Ecto.ColumnType do
  def integer() do
    {0}
  end
  def big_integer() do
    {1}
  end
  def float() do
    {2}
  end
  def decimal(arg0, arg1) do
    {3, arg0, arg1}
  end
  def string(arg0) do
    {4, arg0}
  end
  def text() do
    {5}
  end
  def uuid() do
    {6}
  end
  def boolean() do
    {7}
  end
  def date() do
    {8}
  end
  def time() do
    {9}
  end
  def date_time() do
    {10}
  end
  def timestamp() do
    {11}
  end
  def binary() do
    {12}
  end
  def json() do
    {13}
  end
  def json_array() do
    {14}
  end
  def array(arg0) do
    {15, arg0}
  end
  def references(arg0) do
    {16, arg0}
  end
  def enum(arg0) do
    {17, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Integer", "BigInteger", "Float", "Decimal", "String", "Text", "UUID", "Boolean", "Date", "Time", "DateTime", "Timestamp", "Binary", "Json", "JsonArray", "Array", "References", "Enum"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :integer -> 0
        1 -> 1
        :big_integer -> 1
        2 -> 2
        :float -> 2
        3 -> 3
        :decimal -> 3
        4 -> 4
        :string -> 4
        5 -> 5
        :text -> 5
        6 -> 6
        :uuid -> 6
        7 -> 7
        :boolean -> 7
        8 -> 8
        :date -> 8
        9 -> 9
        :time -> 9
        10 -> 10
        :date_time -> 10
        11 -> 11
        :timestamp -> 11
        12 -> 12
        :binary -> 12
        13 -> 13
        :json -> 13
        14 -> 14
        :json_array -> 14
        15 -> 15
        :array -> 15
        16 -> 16
        :references -> 16
        17 -> 17
        :enum -> 17
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.ColumnType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Integer"
        :integer -> "Integer"
        1 -> "BigInteger"
        :big_integer -> "BigInteger"
        2 -> "Float"
        :float -> "Float"
        3 -> "Decimal"
        :decimal -> "Decimal"
        4 -> "String"
        :string -> "String"
        5 -> "Text"
        :text -> "Text"
        6 -> "UUID"
        :uuid -> "UUID"
        7 -> "Boolean"
        :boolean -> "Boolean"
        8 -> "Date"
        :date -> "Date"
        9 -> "Time"
        :time -> "Time"
        10 -> "DateTime"
        :date_time -> "DateTime"
        11 -> "Timestamp"
        :timestamp -> "Timestamp"
        12 -> "Binary"
        :binary -> "Binary"
        13 -> "Json"
        :json -> "Json"
        14 -> "JsonArray"
        :json_array -> "JsonArray"
        15 -> "Array"
        :array -> "Array"
        16 -> "References"
        :references -> "References"
        17 -> "Enum"
        :enum -> "Enum"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.ColumnType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Integer" when values == [] -> List.to_tuple([:integer | values])
      "Integer" -> raise "Enum constructor Integer expects 0 params for Ecto.ColumnType"
      "BigInteger" when values == [] -> List.to_tuple([:big_integer | values])
      "BigInteger" -> raise "Enum constructor BigInteger expects 0 params for Ecto.ColumnType"
      "Float" when values == [] -> List.to_tuple([:float | values])
      "Float" -> raise "Enum constructor Float expects 0 params for Ecto.ColumnType"
      "Decimal" when length(values) == 2 -> List.to_tuple([:decimal | values])
      "Decimal" -> raise "Enum constructor Decimal expects 2 params for Ecto.ColumnType"
      "String" when length(values) == 1 -> List.to_tuple([:string | values])
      "String" -> raise "Enum constructor String expects 1 params for Ecto.ColumnType"
      "Text" when values == [] -> List.to_tuple([:text | values])
      "Text" -> raise "Enum constructor Text expects 0 params for Ecto.ColumnType"
      "UUID" when values == [] -> List.to_tuple([:uuid | values])
      "UUID" -> raise "Enum constructor UUID expects 0 params for Ecto.ColumnType"
      "Boolean" when values == [] -> List.to_tuple([:boolean | values])
      "Boolean" -> raise "Enum constructor Boolean expects 0 params for Ecto.ColumnType"
      "Date" when values == [] -> List.to_tuple([:date | values])
      "Date" -> raise "Enum constructor Date expects 0 params for Ecto.ColumnType"
      "Time" when values == [] -> List.to_tuple([:time | values])
      "Time" -> raise "Enum constructor Time expects 0 params for Ecto.ColumnType"
      "DateTime" when values == [] -> List.to_tuple([:date_time | values])
      "DateTime" -> raise "Enum constructor DateTime expects 0 params for Ecto.ColumnType"
      "Timestamp" when values == [] -> List.to_tuple([:timestamp | values])
      "Timestamp" -> raise "Enum constructor Timestamp expects 0 params for Ecto.ColumnType"
      "Binary" when values == [] -> List.to_tuple([:binary | values])
      "Binary" -> raise "Enum constructor Binary expects 0 params for Ecto.ColumnType"
      "Json" when values == [] -> List.to_tuple([:json | values])
      "Json" -> raise "Enum constructor Json expects 0 params for Ecto.ColumnType"
      "JsonArray" when values == [] -> List.to_tuple([:json_array | values])
      "JsonArray" -> raise "Enum constructor JsonArray expects 0 params for Ecto.ColumnType"
      "Array" when length(values) == 1 -> List.to_tuple([:array | values])
      "Array" -> raise "Enum constructor Array expects 1 params for Ecto.ColumnType"
      "References" when length(values) == 1 -> List.to_tuple([:references | values])
      "References" -> raise "Enum constructor References expects 1 params for Ecto.ColumnType"
      "Enum" when length(values) == 1 -> List.to_tuple([:enum | values])
      "Enum" -> raise "Enum constructor Enum expects 1 params for Ecto.ColumnType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.ColumnType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:integer | values])
      0 -> raise "Enum constructor Integer expects 0 params for Ecto.ColumnType"
      1 when values == [] -> List.to_tuple([:big_integer | values])
      1 -> raise "Enum constructor BigInteger expects 0 params for Ecto.ColumnType"
      2 when values == [] -> List.to_tuple([:float | values])
      2 -> raise "Enum constructor Float expects 0 params for Ecto.ColumnType"
      3 when length(values) == 2 -> List.to_tuple([:decimal | values])
      3 -> raise "Enum constructor Decimal expects 2 params for Ecto.ColumnType"
      4 when length(values) == 1 -> List.to_tuple([:string | values])
      4 -> raise "Enum constructor String expects 1 params for Ecto.ColumnType"
      5 when values == [] -> List.to_tuple([:text | values])
      5 -> raise "Enum constructor Text expects 0 params for Ecto.ColumnType"
      6 when values == [] -> List.to_tuple([:uuid | values])
      6 -> raise "Enum constructor UUID expects 0 params for Ecto.ColumnType"
      7 when values == [] -> List.to_tuple([:boolean | values])
      7 -> raise "Enum constructor Boolean expects 0 params for Ecto.ColumnType"
      8 when values == [] -> List.to_tuple([:date | values])
      8 -> raise "Enum constructor Date expects 0 params for Ecto.ColumnType"
      9 when values == [] -> List.to_tuple([:time | values])
      9 -> raise "Enum constructor Time expects 0 params for Ecto.ColumnType"
      10 when values == [] -> List.to_tuple([:date_time | values])
      10 -> raise "Enum constructor DateTime expects 0 params for Ecto.ColumnType"
      11 when values == [] -> List.to_tuple([:timestamp | values])
      11 -> raise "Enum constructor Timestamp expects 0 params for Ecto.ColumnType"
      12 when values == [] -> List.to_tuple([:binary | values])
      12 -> raise "Enum constructor Binary expects 0 params for Ecto.ColumnType"
      13 when values == [] -> List.to_tuple([:json | values])
      13 -> raise "Enum constructor Json expects 0 params for Ecto.ColumnType"
      14 when values == [] -> List.to_tuple([:json_array | values])
      14 -> raise "Enum constructor JsonArray expects 0 params for Ecto.ColumnType"
      15 when length(values) == 1 -> List.to_tuple([:array | values])
      15 -> raise "Enum constructor Array expects 1 params for Ecto.ColumnType"
      16 when length(values) == 1 -> List.to_tuple([:references | values])
      16 -> raise "Enum constructor References expects 1 params for Ecto.ColumnType"
      17 when length(values) == 1 -> List.to_tuple([:enum | values])
      17 -> raise "Enum constructor Enum expects 1 params for Ecto.ColumnType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.ColumnType"
    end
  end
  def __haxe_enum_all__() do
    [{:integer}, {:big_integer}, {:float}, {:text}, {:uuid}, {:boolean}, {:date}, {:time}, {:date_time}, {:timestamp}, {:binary}, {:json}, {:json_array}]
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
