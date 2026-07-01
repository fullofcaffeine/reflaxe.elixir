defmodule Socket do
  def new() do
    struct = %{:__reflaxe_class__ => Socket, :input => nil, :output => nil, :custom => nil, :socket_ref => nil}
    struct = %{struct | socket_ref: SocketState.create(:tcp)}
    struct = %{struct | input: SocketInput.new(struct.socket_ref)}
    struct = %{struct | output: SocketOutput.new(struct.socket_ref)}
    struct
  end
  def close(struct) do
    _ = SocketState.close(struct.socket_ref)
    reflaxe_dispatch_receiver = struct.input
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :close, [reflaxe_dispatch_receiver])
    reflaxe_dispatch_receiver = struct.output
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :close, [reflaxe_dispatch_receiver])
  end
  def read(struct) do
    reflaxe_dispatch_receiver = Bytes.of_data(SocketState.recv_all(struct.socket_ref))
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
  end
  def write(struct, content) do
    SocketState.send_binary(struct.socket_ref, (fn ->
      reflaxe_dispatch_receiver = Bytes.of_string(content, nil)
      _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver])
    end).())
  end
  def connect(struct, host, port) do
    SocketState.tcp_connect(struct.socket_ref, host.ip, port)
  end
  def listen(struct, connections) do
    SocketState.tcp_listen(struct.socket_ref, connections)
  end
  def shutdown(struct, read, write) do
    SocketState.tcp_shutdown(struct.socket_ref, read, write)
  end
  def bind(struct, host, port) do
    SocketState.bind(struct.socket_ref, host.ip, port)
  end
  def accept(struct) do
    accepted = SocketState.tcp_accept(struct.socket_ref)
    socket = Socket.new()
    _ = SocketState.attach(socket.socket_ref, accepted)
    socket
  end
  def peer(struct) do
    info = SocketState.peer(struct.socket_ref)
    if (SocketState.is_nil_term(info)), do: nil, else: endpoint_to_record(info)
  end
  def host(struct) do
    info = SocketState.host(struct.socket_ref)
    if (SocketState.is_nil_term(info)), do: nil, else: endpoint_to_record(info)
  end
  def set_timeout(struct, timeout) do
    SocketState.set_timeout(struct.socket_ref, timeout)
  end
  def wait_for_read(struct) do
    result = SocketState.recv_peek(struct.socket_ref)
    if (SocketState.is_blocked(result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
    end
    if (SocketState.is_error(result)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, SocketState.error_message(result)}]
    end
  end
  def set_blocking(struct, b) do
    SocketState.set_blocking(struct.socket_ref, b)
  end
  def set_fast_send(struct, b) do
    SocketState.tcp_set_fast_send(struct.socket_ref, b)
  end
  def select(read, write, others, timeout) do
    %{read: select_ready(read, :read, timeout), write: select_ready(write, :write, timeout), others: select_ready(others, :error, timeout)}
  end
  defp select_ready(sockets, kind, timeout) do
    if (Kernel.is_nil(sockets)) do
      nil
    else
      SocketState.select_ready(sockets, kind, timeout)
    end
  end
  defp endpoint_to_record(info) do
    host_object = Host.new("127.0.0.1")
    host_object = %{host_object | ip: SocketState.endpoint_host(info)}
    %{host: host_object, port: SocketState.endpoint_port(info)}
  end
end
