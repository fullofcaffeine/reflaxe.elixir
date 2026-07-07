defmodule OptionPatterns.NotificationType do
  def email() do
    {0}
  end
  def sms() do
    {1}
  end
  def push() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["Email", "SMS", "Push"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :email -> 0
        1 -> 1
        :sms -> 1
        2 -> 2
        :push -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for OptionPatterns.NotificationType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Email"
        :email -> "Email"
        1 -> "SMS"
        :sms -> "SMS"
        2 -> "Push"
        :push -> "Push"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for OptionPatterns.NotificationType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Email" when values == [] -> List.to_tuple([:email | values])
      "Email" -> raise "Enum constructor Email expects 0 params for OptionPatterns.NotificationType"
      "SMS" when values == [] -> List.to_tuple([:sms | values])
      "SMS" -> raise "Enum constructor SMS expects 0 params for OptionPatterns.NotificationType"
      "Push" when values == [] -> List.to_tuple([:push | values])
      "Push" -> raise "Enum constructor Push expects 0 params for OptionPatterns.NotificationType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for OptionPatterns.NotificationType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:email | values])
      0 -> raise "Enum constructor Email expects 0 params for OptionPatterns.NotificationType"
      1 when values == [] -> List.to_tuple([:sms | values])
      1 -> raise "Enum constructor SMS expects 0 params for OptionPatterns.NotificationType"
      2 when values == [] -> List.to_tuple([:push | values])
      2 -> raise "Enum constructor Push expects 0 params for OptionPatterns.NotificationType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for OptionPatterns.NotificationType"
    end
  end
  def __haxe_enum_all__() do
    [{:email}, {:sms}, {:push}]
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
