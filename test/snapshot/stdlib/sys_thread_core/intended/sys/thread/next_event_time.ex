defmodule Sys.Thread.NextEventTime do
  def now() do
    {0}
  end
  def never() do
    {1}
  end
  def any_time(arg0) do
    {2, arg0}
  end
  def at(arg0) do
    {3, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Now", "Never", "AnyTime", "At"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :now -> 0
        1 -> 1
        :never -> 1
        2 -> 2
        :any_time -> 2
        3 -> 3
        :at -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Sys.Thread.NextEventTime"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Now"
        :now -> "Now"
        1 -> "Never"
        :never -> "Never"
        2 -> "AnyTime"
        :any_time -> "AnyTime"
        3 -> "At"
        :at -> "At"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Sys.Thread.NextEventTime"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Now" when values == [] -> List.to_tuple([:now | values])
      "Now" -> raise "Enum constructor Now expects 0 params for Sys.Thread.NextEventTime"
      "Never" when values == [] -> List.to_tuple([:never | values])
      "Never" -> raise "Enum constructor Never expects 0 params for Sys.Thread.NextEventTime"
      "AnyTime" when length(values) == 1 -> List.to_tuple([:any_time | values])
      "AnyTime" -> raise "Enum constructor AnyTime expects 1 params for Sys.Thread.NextEventTime"
      "At" when length(values) == 1 -> List.to_tuple([:at | values])
      "At" -> raise "Enum constructor At expects 1 params for Sys.Thread.NextEventTime"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Sys.Thread.NextEventTime"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:now | values])
      0 -> raise "Enum constructor Now expects 0 params for Sys.Thread.NextEventTime"
      1 when values == [] -> List.to_tuple([:never | values])
      1 -> raise "Enum constructor Never expects 0 params for Sys.Thread.NextEventTime"
      2 when length(values) == 1 -> List.to_tuple([:any_time | values])
      2 -> raise "Enum constructor AnyTime expects 1 params for Sys.Thread.NextEventTime"
      3 when length(values) == 1 -> List.to_tuple([:at | values])
      3 -> raise "Enum constructor At expects 1 params for Sys.Thread.NextEventTime"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Sys.Thread.NextEventTime"
    end
  end
  def __haxe_enum_all__() do
    [{:now}, {:never}]
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
