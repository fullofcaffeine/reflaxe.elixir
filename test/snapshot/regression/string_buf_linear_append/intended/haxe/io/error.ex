defmodule Haxe.Io.Error do
  def blocked() do
    {0}
  end
  def overflow() do
    {1}
  end
  def outside_bounds() do
    {2}
  end
  def custom(arg0) do
    {3, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Blocked", "Overflow", "OutsideBounds", "Custom"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :blocked -> 0
        1 -> 1
        :overflow -> 1
        2 -> 2
        :outside_bounds -> 2
        3 -> 3
        :custom -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Haxe.Io.Error"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Blocked"
        :blocked -> "Blocked"
        1 -> "Overflow"
        :overflow -> "Overflow"
        2 -> "OutsideBounds"
        :outside_bounds -> "OutsideBounds"
        3 -> "Custom"
        :custom -> "Custom"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Haxe.Io.Error"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Blocked" when values == [] -> List.to_tuple([:blocked | values])
      "Blocked" -> raise "Enum constructor Blocked expects 0 params for Haxe.Io.Error"
      "Overflow" when values == [] -> List.to_tuple([:overflow | values])
      "Overflow" -> raise "Enum constructor Overflow expects 0 params for Haxe.Io.Error"
      "OutsideBounds" when values == [] -> List.to_tuple([:outside_bounds | values])
      "OutsideBounds" -> raise "Enum constructor OutsideBounds expects 0 params for Haxe.Io.Error"
      "Custom" when length(values) == 1 -> List.to_tuple([:custom | values])
      "Custom" -> raise "Enum constructor Custom expects 1 params for Haxe.Io.Error"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Haxe.Io.Error"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:blocked | values])
      0 -> raise "Enum constructor Blocked expects 0 params for Haxe.Io.Error"
      1 when values == [] -> List.to_tuple([:overflow | values])
      1 -> raise "Enum constructor Overflow expects 0 params for Haxe.Io.Error"
      2 when values == [] -> List.to_tuple([:outside_bounds | values])
      2 -> raise "Enum constructor OutsideBounds expects 0 params for Haxe.Io.Error"
      3 when length(values) == 1 -> List.to_tuple([:custom | values])
      3 -> raise "Enum constructor Custom expects 1 params for Haxe.Io.Error"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Haxe.Io.Error"
    end
  end
  def __haxe_enum_all__() do
    [{:blocked}, {:overflow}, {:outside_bounds}]
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
