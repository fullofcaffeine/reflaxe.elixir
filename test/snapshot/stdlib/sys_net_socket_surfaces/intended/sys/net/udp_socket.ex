defmodule UdpSocket do
  def new() do
    struct = %{:__reflaxe_class__ => UdpSocket, :input => nil, :output => nil, :custom => nil, :socket_ref => nil}
    struct = Map.merge(struct, Map.drop(Socket.new(), [:__struct__, :__reflaxe_class__]))
    UdpSocketState.open(struct.socket_ref, 0, nil)
    struct
  end
  def set_broadcast(struct, b) do
    UdpSocketState.set_broadcast(struct.socket_ref, b)
  end
  def bind(struct, host, port) do
    UdpSocketState.open(struct.socket_ref, port, Host.to_inet_address(host.ip))
  end
  def send_to(struct, buf, pos, len, addr) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      UdpSocketState.send_to(struct.socket_ref, (fn ->
        reflaxe_dispatch_receiver = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :sub, [buf, pos, len])
        apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get_data, [reflaxe_dispatch_receiver])
      end).(), Address.get_host(addr), Address.get_port(addr))
      len
    end
  end
  def read_from(_struct, buf, pos, len, _addr) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.net.UdpSocket.readFrom is not supported on the Elixir target because haxe.io.Bytes buffers are immutable in generated Elixir; use sendTo() for UDP output or a target-specific receive wrapper"}]
    end
  end
  def close(struct) do
    Socket.close(struct)
  end
  def read(struct) do
    Socket.read(struct)
  end
  def write(struct, content) do
    Socket.write(struct, content)
  end
  def connect(struct, host, port) do
    Socket.connect(struct, host, port)
  end
  def listen(struct, connections) do
    Socket.listen(struct, connections)
  end
  def shutdown(struct, read, write) do
    Socket.shutdown(struct, read, write)
  end
  def accept(struct) do
    Socket.accept(struct)
  end
  def peer(struct) do
    Socket.peer(struct)
  end
  def host(struct) do
    Socket.host(struct)
  end
  def set_timeout(struct, timeout) do
    Socket.set_timeout(struct, timeout)
  end
  def wait_for_read(struct) do
    Socket.wait_for_read(struct)
  end
  def set_blocking(struct, b) do
    Socket.set_blocking(struct, b)
  end
  def set_fast_send(struct, b) do
    Socket.set_fast_send(struct, b)
  end
end
