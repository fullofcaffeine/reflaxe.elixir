defmodule UdpSocketState do
  def open(socket_ref, port, host_address) do
    (
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                if state.socket != nil do
                  case state.kind do
                    :udp -> :gen_udp.close(state.socket)
                    _ -> :gen_tcp.close(state.socket)
                  end
                end
                opts = [:binary, {:active, false}]
                opts = if is_nil(host_address), do: opts, else: [{:ip, host_address} | opts]
                case :gen_udp.open(port, opts) do
                  {:ok, socket} -> Process.put(key, %{state | socket: socket, kind: :udp})
                  {:error, reason} -> raise "sys.net.UdpSocket.open failed: #{inspect(reason)}"
                end
                :ok
            )
  end
  def set_broadcast(socket_ref, enabled) do
    (
                socket = SocketState.fetch_socket(SocketState.fetch_state(socket_ref))
                :inet.setopts(socket, [{:broadcast, enabled}])
                :ok
            )
  end
  def send_to(socket_ref, data, host_ip, port) do
    (
                socket = SocketState.fetch_socket(SocketState.fetch_state(socket_ref))
                address = Host.to_inet_address(host_ip)
                case :gen_udp.send(socket, address, port, data) do
                  :ok -> :ok
                  {:error, reason} -> raise "sys.net.UdpSocket.sendTo failed: #{inspect(reason)}"
                end
        )
  end
  def receive_from(socket_ref) do
    (
                state = SocketState.fetch_state(socket_ref)
                socket = SocketState.fetch_socket(state)
                case :gen_udp.recv(socket, 0, SocketState.recv_timeout(state)) do
                  {:ok, {address, port, data}} ->
                    {data, SocketState.ipv4_to_int(address), port}
                  {:error, :timeout} -> {:reflaxe_blocked}
                  {:error, reason} -> {:reflaxe_error, reason}
                end
            )
  end
  def received_data(result) do
    elem(result, 0)
  end
  def received_host(result) do
    elem(result, 1)
  end
  def received_port(result) do
    elem(result, 2)
  end
end
