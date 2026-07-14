defmodule Elixir.Types.MonitorInfo do
  def process_monitor(arg0) do
    {0, arg0}
  end
  def port_monitor(arg0) do
    {1, arg0}
  end
  def named_monitor(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["ProcessMonitor", "PortMonitor", "NamedMonitor"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :process_monitor -> 0
        1 -> 1
        :port_monitor -> 1
        2 -> 2
        :named_monitor -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.MonitorInfo"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "ProcessMonitor"
        :process_monitor -> "ProcessMonitor"
        1 -> "PortMonitor"
        :port_monitor -> "PortMonitor"
        2 -> "NamedMonitor"
        :named_monitor -> "NamedMonitor"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.MonitorInfo"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "ProcessMonitor" when length(values) == 1 -> List.to_tuple([:process_monitor | values])
      "ProcessMonitor" -> raise "Enum constructor ProcessMonitor expects 1 params for Elixir.Types.MonitorInfo"
      "PortMonitor" when length(values) == 1 -> List.to_tuple([:port_monitor | values])
      "PortMonitor" -> raise "Enum constructor PortMonitor expects 1 params for Elixir.Types.MonitorInfo"
      "NamedMonitor" when length(values) == 1 -> List.to_tuple([:named_monitor | values])
      "NamedMonitor" -> raise "Enum constructor NamedMonitor expects 1 params for Elixir.Types.MonitorInfo"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Types.MonitorInfo"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:process_monitor | values])
      0 -> raise "Enum constructor ProcessMonitor expects 1 params for Elixir.Types.MonitorInfo"
      1 when length(values) == 1 -> List.to_tuple([:port_monitor | values])
      1 -> raise "Enum constructor PortMonitor expects 1 params for Elixir.Types.MonitorInfo"
      2 when length(values) == 1 -> List.to_tuple([:named_monitor | values])
      2 -> raise "Enum constructor NamedMonitor expects 1 params for Elixir.Types.MonitorInfo"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Types.MonitorInfo"
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
