defmodule TodoAppWeb.Live.RowState do
  def open() do
    {0}
  end
  def closed() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["Open", "Closed"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :open -> 0
        1 -> 1
        :closed -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TodoAppWeb.Live.RowState"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Open"
        :open -> "Open"
        1 -> "Closed"
        :closed -> "Closed"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TodoAppWeb.Live.RowState"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Open" when values == [] -> List.to_tuple([:open | values])
      "Open" -> raise "Enum constructor Open expects 0 params for TodoAppWeb.Live.RowState"
      "Closed" when values == [] -> List.to_tuple([:closed | values])
      "Closed" -> raise "Enum constructor Closed expects 0 params for TodoAppWeb.Live.RowState"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for TodoAppWeb.Live.RowState"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:open | values])
      0 -> raise "Enum constructor Open expects 0 params for TodoAppWeb.Live.RowState"
      1 when values == [] -> List.to_tuple([:closed | values])
      1 -> raise "Enum constructor Closed expects 0 params for TodoAppWeb.Live.RowState"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for TodoAppWeb.Live.RowState"
    end
  end
  def __haxe_enum_all__() do
    [{:open}, {:closed}]
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
