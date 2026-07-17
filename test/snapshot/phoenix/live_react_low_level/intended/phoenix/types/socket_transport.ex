defmodule Phoenix.Types.SocketTransport do
  def web_socket() do
    {:web_socket}
  end
  def long_poll() do
    {:long_poll}
  end
  def __haxe_enum_constructs__() do
    ["WebSocket", "LongPoll"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :web_socket -> 0
        1 -> 1
        :long_poll -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Types.SocketTransport"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "WebSocket"
        :web_socket -> "WebSocket"
        1 -> "LongPoll"
        :long_poll -> "LongPoll"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Types.SocketTransport"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "WebSocket" when values == [] -> List.to_tuple([:web_socket | values])
      "WebSocket" -> raise "Enum constructor WebSocket expects 0 params for Phoenix.Types.SocketTransport"
      "LongPoll" when values == [] -> List.to_tuple([:long_poll | values])
      "LongPoll" -> raise "Enum constructor LongPoll expects 0 params for Phoenix.Types.SocketTransport"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.Types.SocketTransport"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:web_socket | values])
      0 -> raise "Enum constructor WebSocket expects 0 params for Phoenix.Types.SocketTransport"
      1 when values == [] -> List.to_tuple([:long_poll | values])
      1 -> raise "Enum constructor LongPoll expects 0 params for Phoenix.Types.SocketTransport"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.Types.SocketTransport"
    end
  end
  def __haxe_enum_all__() do
    [{:web_socket}, {:long_poll}]
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
