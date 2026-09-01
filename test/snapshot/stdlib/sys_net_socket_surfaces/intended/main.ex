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
  defp receive_udp_datagram(host) do
    receiver = UdpSocket.new()
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :bind, [receiver, host, 0])
    receiver_endpoint = apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :host, [receiver])
    if (Kernel.is_nil(receiver_endpoint) or receiver_endpoint.port <= 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.host should expose the bound receiver port"]
    end
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :set_blocking, [receiver, false])
    try do
      apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :read_from, [receiver, Bytes.alloc(16), 0, 16, Address.new()])
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should block when no datagram is ready"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_tuple(error) and elem(error, 0) in [:overflow, :outside_bounds, :custom, :blocked] ->
            (case error do
              {:blocked} -> nil
              _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should raise Error.Blocked without data"]
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :set_blocking, [receiver, true])
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :set_timeout, [receiver, 0.25])
    sender = UdpSocket.new()
    sender_endpoint = apply(Map.get(sender, :__reflaxe_class__) || Map.get(sender, :__struct__), :host, [sender])
    destination = Address.new()
    Address.set_host(destination, host.ip)
    Address.set_port(destination, receiver_endpoint.port)
    payload = Bytes.of_string("hello!", {:utf8})
    if (apply(Map.get(sender, :__reflaxe_class__) || Map.get(sender, :__struct__), :send_to, [sender, payload, 0, payload.length, destination]) != payload.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.sendTo should send the complete datagram"]
    end
    buffer = Bytes.of_string("________", {:utf8})
    source = Address.new()
    received = apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :read_from, [receiver, buffer, 2, 5, source])
    if (received != 5 or apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :to_string, [buffer]) != "__hello_") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should truncate and mutate only the requested buffer range"]
    end
    if (Address.get_host(source) != host.ip or Address.get_port(source) != sender_endpoint.port) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "UdpSocket.readFrom should report the sender address"]
    end
    apply(Map.get(sender, :__reflaxe_class__) || Map.get(sender, :__struct__), :close, [sender])
    apply(Map.get(receiver, :__reflaxe_class__) || Map.get(receiver, :__struct__), :close, [receiver])
  end
  defp receive_tcp_stream(host) do
    parent = Sys.Thread.Thread.current()
    server = Sys.Thread.Thread.create(fn ->
      listener = Socket.new()
      apply(Map.get(listener, :__reflaxe_class__) || Map.get(listener, :__struct__), :bind, [listener, host, 0])
      apply(Map.get(listener, :__reflaxe_class__) || Map.get(listener, :__struct__), :listen, [listener, 1])
      apply(Map.get(parent, :__reflaxe_class__) || Map.get(parent, :__struct__), :send_message, [parent, apply(Map.get(listener, :__reflaxe_class__) || Map.get(listener, :__struct__), :host, [listener]).port])
      Sys.Thread.Thread.read_message(true)
      peer = apply(Map.get(listener, :__reflaxe_class__) || Map.get(listener, :__struct__), :accept, [listener])
      apply(Map.get(peer, :__reflaxe_class__) || Map.get(peer, :__struct__), :write, [peer, "hello!"])
      apply(Map.get(peer, :__reflaxe_class__) || Map.get(peer, :__struct__), :close, [peer])
      apply(Map.get(listener, :__reflaxe_class__) || Map.get(listener, :__struct__), :close, [listener])
    end)
    port = Sys.Thread.Thread.read_message(true)
    client = Socket.new()
    apply(Map.get(client, :__reflaxe_class__) || Map.get(client, :__struct__), :connect, [client, host, port])
    apply(Map.get(client, :__reflaxe_class__) || Map.get(client, :__struct__), :set_blocking, [client, false])
    try do
      reflaxe_dispatch_receiver = client.input
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :read_bytes, [reflaxe_dispatch_receiver, Bytes.alloc(1), 0, 1])
      raise Reflaxe.Elixir.HaxeThrow, [value: "Socket.input.readBytes should block when no stream data is ready"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_tuple(error) and elem(error, 0) in [:overflow, :outside_bounds, :custom, :blocked] ->
            (case error do
              {:blocked} -> nil
              _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "Socket.input.readBytes should raise Error.Blocked without data"]
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    apply(Map.get(client, :__reflaxe_class__) || Map.get(client, :__struct__), :set_blocking, [client, true])
    apply(Map.get(client, :__reflaxe_class__) || Map.get(client, :__struct__), :set_timeout, [client, 0.25])
    apply(Map.get(server, :__reflaxe_class__) || Map.get(server, :__struct__), :send_message, [server, "send"])
    buffer = Bytes.of_string("________", {:utf8})
    reflaxe_dispatch_receiver = client.input
    received = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :read_bytes, [reflaxe_dispatch_receiver, buffer, 2, 5])
    if (received != 5 or apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :to_string, [buffer]) != "__hello_") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Socket.input.readBytes should mutate only the requested buffer range"]
    end
    apply(Map.get(client, :__reflaxe_class__) || Map.get(client, :__struct__), :close, [client])
  end
  def main() do
    host = Host.new("127.0.0.1")
    tcp = Socket.new()
    configure_tcp(tcp, host)
    apply(Map.get(tcp, :__reflaxe_class__) || Map.get(tcp, :__struct__), :close, [tcp])
    udp = UdpSocket.new()
    configure_udp(udp, host)
    apply(Map.get(udp, :__reflaxe_class__) || Map.get(udp, :__struct__), :close, [udp])
    receive_udp_datagram(host)
    receive_tcp_stream(host)
  end
end
