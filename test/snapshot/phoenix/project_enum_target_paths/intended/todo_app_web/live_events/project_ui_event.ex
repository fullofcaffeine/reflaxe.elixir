defmodule TodoAppWeb.LiveEvents.ProjectUiEvent do
  def select(arg0) do
    {0, arg0}
  end
  def clear() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["Select", "Clear"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :select -> 0
        1 -> 1
        :clear -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TodoAppWeb.LiveEvents.ProjectUiEvent"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Select"
        :select -> "Select"
        1 -> "Clear"
        :clear -> "Clear"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TodoAppWeb.LiveEvents.ProjectUiEvent"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Select" when length(values) == 1 -> List.to_tuple([:select | values])
      "Select" -> raise "Enum constructor Select expects 1 params for TodoAppWeb.LiveEvents.ProjectUiEvent"
      "Clear" when values == [] -> List.to_tuple([:clear | values])
      "Clear" -> raise "Enum constructor Clear expects 0 params for TodoAppWeb.LiveEvents.ProjectUiEvent"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for TodoAppWeb.LiveEvents.ProjectUiEvent"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:select | values])
      0 -> raise "Enum constructor Select expects 1 params for TodoAppWeb.LiveEvents.ProjectUiEvent"
      1 when values == [] -> List.to_tuple([:clear | values])
      1 -> raise "Enum constructor Clear expects 0 params for TodoAppWeb.LiveEvents.ProjectUiEvent"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for TodoAppWeb.LiveEvents.ProjectUiEvent"
    end
  end
  def __haxe_enum_all__() do
    [{:clear}]
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
