defmodule Main do
  defp configure_tcp(socket, host) do
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_timeout, [socket, 0.01])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_blocking, [socket, false])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_fast_send, [socket, true])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :bind, [socket, host, 0])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :listen, [socket, 1])
    endpoint = apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :host, [socket])
    if (not Kernel.is_nil(endpoint) and endpoint.port < 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Socket.host returned an invalid port"]
    end
  end
  defp configure_udp(socket, host) do
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_timeout, [socket, 0.01])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_broadcast, [socket, false])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :bind, [socket, host, 0])
    destination = Address.new()
    Address.set_host(destination, host.ip)
    Address.set_port(destination, 9)
    bytes = Bytes.of_string("ping", {:utf8})
    sent = apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :send_to, [socket, bytes, 0, bytes.length, destination])
    if (sent != bytes.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.sendTo should report the sent length"]
    end
  end
  defp reject_unsupported_udp_read(host) do
    receiver = UdpSocket.new()
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :bind, [receiver, host, 0])
    try do
      apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :read_from, [receiver, Bytes.alloc(16), 0, 16, Address.new()])
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should fail explicitly on the Elixir target"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_tuple(error) and elem(error, 0) in [:overflow, :outside_bounds, :custom, :blocked] ->
            (case error do
              {:custom, message} ->
                if (Reflaxe.Elixir.HaxeFloat.eq(message, "")) do
                  raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should explain the unsupported API"]
                end
              _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should raise Error.Custom"]
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :close, [receiver])
  end
  def main() do
    host = Host.new("127.0.0.1")
    tcp = Socket.new()
    configure_tcp(tcp, host)
    apply(Map.get(tcp, :__reflaxe_class__) || Map.get(tcp, :__struct__), :close, [tcp])
    udp = UdpSocket.new()
    configure_udp(udp, host)
    apply(Map.get(udp, :__reflaxe_class__) || Map.get(udp, :__struct__), :close, [udp])
    reject_unsupported_udp_read(host)
  end
end
