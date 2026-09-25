defmodule Elixir.Types.TermDecodeError do
  def expected_type(arg0, arg1) do
    {0, arg0, arg1}
  end
  def missing_key(arg0) do
    {1, arg0}
  end
  def expected_ok_error_tuple(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["ExpectedType", "MissingKey", "ExpectedOkErrorTuple"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :expected_type -> 0
        1 -> 1
        :missing_key -> 1
        2 -> 2
        :expected_ok_error_tuple -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.TermDecodeError"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "ExpectedType"
        :expected_type -> "ExpectedType"
        1 -> "MissingKey"
        :missing_key -> "MissingKey"
        2 -> "ExpectedOkErrorTuple"
        :expected_ok_error_tuple -> "ExpectedOkErrorTuple"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.TermDecodeError"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "ExpectedType" when length(values) == 2 -> List.to_tuple([:expected_type | values])
      "ExpectedType" -> raise "Enum constructor ExpectedType expects 2 params for Elixir.Types.TermDecodeError"
      "MissingKey" when length(values) == 1 -> List.to_tuple([:missing_key | values])
      "MissingKey" -> raise "Enum constructor MissingKey expects 1 params for Elixir.Types.TermDecodeError"
      "ExpectedOkErrorTuple" when length(values) == 1 -> List.to_tuple([:expected_ok_error_tuple | values])
      "ExpectedOkErrorTuple" -> raise "Enum constructor ExpectedOkErrorTuple expects 1 params for Elixir.Types.TermDecodeError"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Types.TermDecodeError"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:expected_type | values])
      0 -> raise "Enum constructor ExpectedType expects 2 params for Elixir.Types.TermDecodeError"
      1 when length(values) == 1 -> List.to_tuple([:missing_key | values])
      1 -> raise "Enum constructor MissingKey expects 1 params for Elixir.Types.TermDecodeError"
      2 when length(values) == 1 -> List.to_tuple([:expected_ok_error_tuple | values])
      2 -> raise "Enum constructor ExpectedOkErrorTuple expects 1 params for Elixir.Types.TermDecodeError"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Types.TermDecodeError"
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
