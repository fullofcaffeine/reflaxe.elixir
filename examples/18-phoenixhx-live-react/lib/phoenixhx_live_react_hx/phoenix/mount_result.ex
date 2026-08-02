defmodule Phoenix.MountResult do
  def ok(arg0) do
    {:ok, arg0}
  end
  def ok_with_temporary_assigns(arg0, arg1) do
    {:ok_with_temporary_assigns, arg0, arg1}
  end
  def error(arg0) do
    {:error, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "OkWithTemporaryAssigns", "Error"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :ok -> 0
        1 -> 1
        :ok_with_temporary_assigns -> 1
        2 -> 2
        :error -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.MountResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Ok"
        :ok -> "Ok"
        1 -> "OkWithTemporaryAssigns"
        :ok_with_temporary_assigns -> "OkWithTemporaryAssigns"
        2 -> "Error"
        :error -> "Error"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.MountResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Ok" when length(values) == 1 -> List.to_tuple([:ok | values])
      "Ok" -> raise "Enum constructor Ok expects 1 params for Phoenix.MountResult"
      "OkWithTemporaryAssigns" when length(values) == 2 -> List.to_tuple([:ok_with_temporary_assigns | values])
      "OkWithTemporaryAssigns" -> raise "Enum constructor OkWithTemporaryAssigns expects 2 params for Phoenix.MountResult"
      "Error" when length(values) == 1 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 1 params for Phoenix.MountResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.MountResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:ok | values])
      0 -> raise "Enum constructor Ok expects 1 params for Phoenix.MountResult"
      1 when length(values) == 2 -> List.to_tuple([:ok_with_temporary_assigns | values])
      1 -> raise "Enum constructor OkWithTemporaryAssigns expects 2 params for Phoenix.MountResult"
      2 when length(values) == 1 -> List.to_tuple([:error | values])
      2 -> raise "Enum constructor Error expects 1 params for Phoenix.MountResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.MountResult"
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
