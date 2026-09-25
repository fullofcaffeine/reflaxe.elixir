defmodule Elixir.Types.TermKind do
  def atom() do
    {0}
  end
  def binary() do
    {1}
  end
  def bitstring() do
    {2}
  end
  def boolean() do
    {3}
  end
  def float() do
    {4}
  end
  def function() do
    {5}
  end
  def integer() do
    {6}
  end
  def list() do
    {7}
  end
  def map() do
    {8}
  end
  def nil_fn() do
    {9}
  end
  def number() do
    {10}
  end
  def pid() do
    {11}
  end
  def port() do
    {12}
  end
  def reference() do
    {13}
  end
  def tuple() do
    {14}
  end
  def unknown() do
    {15}
  end
  def __haxe_enum_constructs__() do
    ["Atom", "Binary", "Bitstring", "Boolean", "Float", "Function", "Integer", "List", "Map", "Nil", "Number", "Pid", "Port", "Reference", "Tuple", "Unknown"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :atom -> 0
        1 -> 1
        :binary -> 1
        2 -> 2
        :bitstring -> 2
        3 -> 3
        :boolean -> 3
        4 -> 4
        :float -> 4
        5 -> 5
        :function -> 5
        6 -> 6
        :integer -> 6
        7 -> 7
        :list -> 7
        8 -> 8
        :map -> 8
        9 -> 9
        :nil -> 9
        10 -> 10
        :number -> 10
        11 -> 11
        :pid -> 11
        12 -> 12
        :port -> 12
        13 -> 13
        :reference -> 13
        14 -> 14
        :tuple -> 14
        15 -> 15
        :unknown -> 15
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.TermKind"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Atom"
        :atom -> "Atom"
        1 -> "Binary"
        :binary -> "Binary"
        2 -> "Bitstring"
        :bitstring -> "Bitstring"
        3 -> "Boolean"
        :boolean -> "Boolean"
        4 -> "Float"
        :float -> "Float"
        5 -> "Function"
        :function -> "Function"
        6 -> "Integer"
        :integer -> "Integer"
        7 -> "List"
        :list -> "List"
        8 -> "Map"
        :map -> "Map"
        9 -> "Nil"
        :nil -> "Nil"
        10 -> "Number"
        :number -> "Number"
        11 -> "Pid"
        :pid -> "Pid"
        12 -> "Port"
        :port -> "Port"
        13 -> "Reference"
        :reference -> "Reference"
        14 -> "Tuple"
        :tuple -> "Tuple"
        15 -> "Unknown"
        :unknown -> "Unknown"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.TermKind"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Atom" when values == [] -> List.to_tuple([:atom | values])
      "Atom" -> raise "Enum constructor Atom expects 0 params for Elixir.Types.TermKind"
      "Binary" when values == [] -> List.to_tuple([:binary | values])
      "Binary" -> raise "Enum constructor Binary expects 0 params for Elixir.Types.TermKind"
      "Bitstring" when values == [] -> List.to_tuple([:bitstring | values])
      "Bitstring" -> raise "Enum constructor Bitstring expects 0 params for Elixir.Types.TermKind"
      "Boolean" when values == [] -> List.to_tuple([:boolean | values])
      "Boolean" -> raise "Enum constructor Boolean expects 0 params for Elixir.Types.TermKind"
      "Float" when values == [] -> List.to_tuple([:float | values])
      "Float" -> raise "Enum constructor Float expects 0 params for Elixir.Types.TermKind"
      "Function" when values == [] -> List.to_tuple([:function | values])
      "Function" -> raise "Enum constructor Function expects 0 params for Elixir.Types.TermKind"
      "Integer" when values == [] -> List.to_tuple([:integer | values])
      "Integer" -> raise "Enum constructor Integer expects 0 params for Elixir.Types.TermKind"
      "List" when values == [] -> List.to_tuple([:list | values])
      "List" -> raise "Enum constructor List expects 0 params for Elixir.Types.TermKind"
      "Map" when values == [] -> List.to_tuple([:map | values])
      "Map" -> raise "Enum constructor Map expects 0 params for Elixir.Types.TermKind"
      "Nil" when values == [] -> List.to_tuple([:nil | values])
      "Nil" -> raise "Enum constructor Nil expects 0 params for Elixir.Types.TermKind"
      "Number" when values == [] -> List.to_tuple([:number | values])
      "Number" -> raise "Enum constructor Number expects 0 params for Elixir.Types.TermKind"
      "Pid" when values == [] -> List.to_tuple([:pid | values])
      "Pid" -> raise "Enum constructor Pid expects 0 params for Elixir.Types.TermKind"
      "Port" when values == [] -> List.to_tuple([:port | values])
      "Port" -> raise "Enum constructor Port expects 0 params for Elixir.Types.TermKind"
      "Reference" when values == [] -> List.to_tuple([:reference | values])
      "Reference" -> raise "Enum constructor Reference expects 0 params for Elixir.Types.TermKind"
      "Tuple" when values == [] -> List.to_tuple([:tuple | values])
      "Tuple" -> raise "Enum constructor Tuple expects 0 params for Elixir.Types.TermKind"
      "Unknown" when values == [] -> List.to_tuple([:unknown | values])
      "Unknown" -> raise "Enum constructor Unknown expects 0 params for Elixir.Types.TermKind"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Types.TermKind"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:atom | values])
      0 -> raise "Enum constructor Atom expects 0 params for Elixir.Types.TermKind"
      1 when values == [] -> List.to_tuple([:binary | values])
      1 -> raise "Enum constructor Binary expects 0 params for Elixir.Types.TermKind"
      2 when values == [] -> List.to_tuple([:bitstring | values])
      2 -> raise "Enum constructor Bitstring expects 0 params for Elixir.Types.TermKind"
      3 when values == [] -> List.to_tuple([:boolean | values])
      3 -> raise "Enum constructor Boolean expects 0 params for Elixir.Types.TermKind"
      4 when values == [] -> List.to_tuple([:float | values])
      4 -> raise "Enum constructor Float expects 0 params for Elixir.Types.TermKind"
      5 when values == [] -> List.to_tuple([:function | values])
      5 -> raise "Enum constructor Function expects 0 params for Elixir.Types.TermKind"
      6 when values == [] -> List.to_tuple([:integer | values])
      6 -> raise "Enum constructor Integer expects 0 params for Elixir.Types.TermKind"
      7 when values == [] -> List.to_tuple([:list | values])
      7 -> raise "Enum constructor List expects 0 params for Elixir.Types.TermKind"
      8 when values == [] -> List.to_tuple([:map | values])
      8 -> raise "Enum constructor Map expects 0 params for Elixir.Types.TermKind"
      9 when values == [] -> List.to_tuple([:nil | values])
      9 -> raise "Enum constructor Nil expects 0 params for Elixir.Types.TermKind"
      10 when values == [] -> List.to_tuple([:number | values])
      10 -> raise "Enum constructor Number expects 0 params for Elixir.Types.TermKind"
      11 when values == [] -> List.to_tuple([:pid | values])
      11 -> raise "Enum constructor Pid expects 0 params for Elixir.Types.TermKind"
      12 when values == [] -> List.to_tuple([:port | values])
      12 -> raise "Enum constructor Port expects 0 params for Elixir.Types.TermKind"
      13 when values == [] -> List.to_tuple([:reference | values])
      13 -> raise "Enum constructor Reference expects 0 params for Elixir.Types.TermKind"
      14 when values == [] -> List.to_tuple([:tuple | values])
      14 -> raise "Enum constructor Tuple expects 0 params for Elixir.Types.TermKind"
      15 when values == [] -> List.to_tuple([:unknown | values])
      15 -> raise "Enum constructor Unknown expects 0 params for Elixir.Types.TermKind"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Types.TermKind"
    end
  end
  def __haxe_enum_all__() do
    [{:atom}, {:binary}, {:bitstring}, {:boolean}, {:float}, {:function}, {:integer}, {:list}, {:map}, {:nil}, {:number}, {:pid}, {:port}, {:reference}, {:tuple}, {:unknown}]
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
