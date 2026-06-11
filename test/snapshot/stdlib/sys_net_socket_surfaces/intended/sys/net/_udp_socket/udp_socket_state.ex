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
end
