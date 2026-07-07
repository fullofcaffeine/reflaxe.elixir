defmodule Phoenix.Test.LiveViewState do
  def mounted() do
    {:mounted}
  end
  def disconnected() do
    {:disconnected}
  end
  def error(arg0) do
    {:error, arg0}
  end
  def redirecting(arg0) do
    {:redirecting, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Mounted", "Disconnected", "Error", "Redirecting"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :mounted -> 0
        1 -> 1
        :disconnected -> 1
        2 -> 2
        :error -> 2
        3 -> 3
        :redirecting -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Test.LiveViewState"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Mounted"
        :mounted -> "Mounted"
        1 -> "Disconnected"
        :disconnected -> "Disconnected"
        2 -> "Error"
        :error -> "Error"
        3 -> "Redirecting"
        :redirecting -> "Redirecting"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Test.LiveViewState"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Mounted" when values == [] -> List.to_tuple([:mounted | values])
      "Mounted" -> raise "Enum constructor Mounted expects 0 params for Phoenix.Test.LiveViewState"
      "Disconnected" when values == [] -> List.to_tuple([:disconnected | values])
      "Disconnected" -> raise "Enum constructor Disconnected expects 0 params for Phoenix.Test.LiveViewState"
      "Error" when length(values) == 1 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 1 params for Phoenix.Test.LiveViewState"
      "Redirecting" when length(values) == 1 -> List.to_tuple([:redirecting | values])
      "Redirecting" -> raise "Enum constructor Redirecting expects 1 params for Phoenix.Test.LiveViewState"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.Test.LiveViewState"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:mounted | values])
      0 -> raise "Enum constructor Mounted expects 0 params for Phoenix.Test.LiveViewState"
      1 when values == [] -> List.to_tuple([:disconnected | values])
      1 -> raise "Enum constructor Disconnected expects 0 params for Phoenix.Test.LiveViewState"
      2 when length(values) == 1 -> List.to_tuple([:error | values])
      2 -> raise "Enum constructor Error expects 1 params for Phoenix.Test.LiveViewState"
      3 when length(values) == 1 -> List.to_tuple([:redirecting | values])
      3 -> raise "Enum constructor Redirecting expects 1 params for Phoenix.Test.LiveViewState"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.Test.LiveViewState"
    end
  end
  def __haxe_enum_all__() do
    [{:mounted}, {:disconnected}]
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
