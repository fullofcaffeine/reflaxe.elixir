defmodule Elixir.ReduceWhileResult do
  def cont(arg0) do
    {0, arg0}
  end
  def halt(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Cont", "Halt"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :cont -> 0
        1 -> 1
        :halt -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.ReduceWhileResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Cont"
        :cont -> "Cont"
        1 -> "Halt"
        :halt -> "Halt"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.ReduceWhileResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Cont" when length(values) == 1 -> List.to_tuple([:cont | values])
      "Cont" -> raise "Enum constructor Cont expects 1 params for Elixir.ReduceWhileResult"
      "Halt" when length(values) == 1 -> List.to_tuple([:halt | values])
      "Halt" -> raise "Enum constructor Halt expects 1 params for Elixir.ReduceWhileResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.ReduceWhileResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:cont | values])
      0 -> raise "Enum constructor Cont expects 1 params for Elixir.ReduceWhileResult"
      1 when length(values) == 1 -> List.to_tuple([:halt | values])
      1 -> raise "Enum constructor Halt expects 1 params for Elixir.ReduceWhileResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.ReduceWhileResult"
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
