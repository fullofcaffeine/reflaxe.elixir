defmodule Phoenix.Types.FlashType do
  def info() do
    {:info}
  end
  def success() do
    {:success}
  end
  def warning() do
    {:warning}
  end
  def error() do
    {:error}
  end
  def __haxe_enum_constructs__() do
    ["Info", "Success", "Warning", "Error"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :info -> 0
        1 -> 1
        :success -> 1
        2 -> 2
        :warning -> 2
        3 -> 3
        :error -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Types.FlashType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Info"
        :info -> "Info"
        1 -> "Success"
        :success -> "Success"
        2 -> "Warning"
        :warning -> "Warning"
        3 -> "Error"
        :error -> "Error"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Types.FlashType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Info" when values == [] -> List.to_tuple([:info | values])
      "Info" -> raise "Enum constructor Info expects 0 params for Phoenix.Types.FlashType"
      "Success" when values == [] -> List.to_tuple([:success | values])
      "Success" -> raise "Enum constructor Success expects 0 params for Phoenix.Types.FlashType"
      "Warning" when values == [] -> List.to_tuple([:warning | values])
      "Warning" -> raise "Enum constructor Warning expects 0 params for Phoenix.Types.FlashType"
      "Error" when values == [] -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 0 params for Phoenix.Types.FlashType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.Types.FlashType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:info | values])
      0 -> raise "Enum constructor Info expects 0 params for Phoenix.Types.FlashType"
      1 when values == [] -> List.to_tuple([:success | values])
      1 -> raise "Enum constructor Success expects 0 params for Phoenix.Types.FlashType"
      2 when values == [] -> List.to_tuple([:warning | values])
      2 -> raise "Enum constructor Warning expects 0 params for Phoenix.Types.FlashType"
      3 when values == [] -> List.to_tuple([:error | values])
      3 -> raise "Enum constructor Error expects 0 params for Phoenix.Types.FlashType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.Types.FlashType"
    end
  end
  def __haxe_enum_all__() do
    [{:info}, {:success}, {:warning}, {:error}]
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
