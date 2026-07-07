defmodule Elixir.Types.InitResult do
  def ok(arg0) do
    {0, arg0}
  end
  def ok_timeout(arg0, arg1) do
    {1, arg0, arg1}
  end
  def ok_hibernate(arg0) do
    {2, arg0}
  end
  def ok_continue(arg0, arg1) do
    {3, arg0, arg1}
  end
  def stop(arg0) do
    {4, arg0}
  end
  def ignore() do
    {5}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "OkTimeout", "OkHibernate", "OkContinue", "Stop", "Ignore"]
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
        :ok_timeout -> 1
        2 -> 2
        :ok_hibernate -> 2
        3 -> 3
        :ok_continue -> 3
        4 -> 4
        :stop -> 4
        5 -> 5
        :ignore -> 5
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.InitResult"
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
        1 -> "OkTimeout"
        :ok_timeout -> "OkTimeout"
        2 -> "OkHibernate"
        :ok_hibernate -> "OkHibernate"
        3 -> "OkContinue"
        :ok_continue -> "OkContinue"
        4 -> "Stop"
        :stop -> "Stop"
        5 -> "Ignore"
        :ignore -> "Ignore"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.InitResult"
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
      "Ok" -> raise "Enum constructor Ok expects 1 params for Elixir.Types.InitResult"
      "OkTimeout" when length(values) == 2 -> List.to_tuple([:ok_timeout | values])
      "OkTimeout" -> raise "Enum constructor OkTimeout expects 2 params for Elixir.Types.InitResult"
      "OkHibernate" when length(values) == 1 -> List.to_tuple([:ok_hibernate | values])
      "OkHibernate" -> raise "Enum constructor OkHibernate expects 1 params for Elixir.Types.InitResult"
      "OkContinue" when length(values) == 2 -> List.to_tuple([:ok_continue | values])
      "OkContinue" -> raise "Enum constructor OkContinue expects 2 params for Elixir.Types.InitResult"
      "Stop" when length(values) == 1 -> List.to_tuple([:stop | values])
      "Stop" -> raise "Enum constructor Stop expects 1 params for Elixir.Types.InitResult"
      "Ignore" when values == [] -> List.to_tuple([:ignore | values])
      "Ignore" -> raise "Enum constructor Ignore expects 0 params for Elixir.Types.InitResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Types.InitResult"
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
      0 -> raise "Enum constructor Ok expects 1 params for Elixir.Types.InitResult"
      1 when length(values) == 2 -> List.to_tuple([:ok_timeout | values])
      1 -> raise "Enum constructor OkTimeout expects 2 params for Elixir.Types.InitResult"
      2 when length(values) == 1 -> List.to_tuple([:ok_hibernate | values])
      2 -> raise "Enum constructor OkHibernate expects 1 params for Elixir.Types.InitResult"
      3 when length(values) == 2 -> List.to_tuple([:ok_continue | values])
      3 -> raise "Enum constructor OkContinue expects 2 params for Elixir.Types.InitResult"
      4 when length(values) == 1 -> List.to_tuple([:stop | values])
      4 -> raise "Enum constructor Stop expects 1 params for Elixir.Types.InitResult"
      5 when values == [] -> List.to_tuple([:ignore | values])
      5 -> raise "Enum constructor Ignore expects 0 params for Elixir.Types.InitResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Types.InitResult"
    end
  end
  def __haxe_enum_all__() do
    [{:ignore}]
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
