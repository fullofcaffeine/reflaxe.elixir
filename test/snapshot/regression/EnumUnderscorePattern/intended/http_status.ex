defmodule HttpStatus do
  def ok() do
    {0}
  end
  def custom(arg0) do
    {1, arg0}
  end
  def error(arg0) do
    {2, arg0}
  end
  def redirect(arg0, arg1) do
    {3, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "Custom", "Error", "Redirect"]
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
        :custom -> 1
        2 -> 2
        :error -> 2
        3 -> 3
        :redirect -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for HttpStatus"
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
        1 -> "Custom"
        :custom -> "Custom"
        2 -> "Error"
        :error -> "Error"
        3 -> "Redirect"
        :redirect -> "Redirect"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for HttpStatus"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Ok" when values == [] -> List.to_tuple([:ok | values])
      "Ok" -> raise "Enum constructor Ok expects 0 params for HttpStatus"
      "Custom" when length(values) == 1 -> List.to_tuple([:custom | values])
      "Custom" -> raise "Enum constructor Custom expects 1 params for HttpStatus"
      "Error" when length(values) == 1 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 1 params for HttpStatus"
      "Redirect" when length(values) == 2 -> List.to_tuple([:redirect | values])
      "Redirect" -> raise "Enum constructor Redirect expects 2 params for HttpStatus"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for HttpStatus"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:ok | values])
      0 -> raise "Enum constructor Ok expects 0 params for HttpStatus"
      1 when length(values) == 1 -> List.to_tuple([:custom | values])
      1 -> raise "Enum constructor Custom expects 1 params for HttpStatus"
      2 when length(values) == 1 -> List.to_tuple([:error | values])
      2 -> raise "Enum constructor Error expects 1 params for HttpStatus"
      3 when length(values) == 2 -> List.to_tuple([:redirect | values])
      3 -> raise "Enum constructor Redirect expects 2 params for HttpStatus"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for HttpStatus"
    end
  end
  def __haxe_enum_all__() do
    [{:ok}]
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
