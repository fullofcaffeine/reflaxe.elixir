defmodule Phoenix.HandleInfoResult do
  def no_reply(arg0) do
    {:no_reply, arg0}
  end
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["NoReply", "Error"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :no_reply -> 0
        1 -> 1
        :error -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.HandleInfoResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "NoReply"
        :no_reply -> "NoReply"
        1 -> "Error"
        :error -> "Error"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.HandleInfoResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "NoReply" when length(values) == 1 -> List.to_tuple([:no_reply | values])
      "NoReply" -> raise "Enum constructor NoReply expects 1 params for Phoenix.HandleInfoResult"
      "Error" when length(values) == 2 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 2 params for Phoenix.HandleInfoResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.HandleInfoResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:no_reply | values])
      0 -> raise "Enum constructor NoReply expects 1 params for Phoenix.HandleInfoResult"
      1 when length(values) == 2 -> List.to_tuple([:error | values])
      1 -> raise "Enum constructor Error expects 2 params for Phoenix.HandleInfoResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.HandleInfoResult"
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
