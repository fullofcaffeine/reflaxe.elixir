defmodule SocketState do
  def create(kind) do
    (
            ref = make_ref()
            Process.put({:reflaxe_sys_net_socket, ref}, %{
              kind: kind,
              socket: nil,
              bind_host: nil,
              bind_port: nil,
              timeout: :infinity,
              blocking: true,
              fast_send: false
            })
            ref
        )
  end
  def attach(socket_ref, socket) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | socket: socket, kind: :tcp})
            :ok
        )
  end
  def bind(socket_ref, host_ip, port) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | bind_host: Host.to_inet_address(host_ip), bind_port: port})
            :ok
        )
  end
  def tcp_connect(socket_ref, host_ip, port) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            address = Host.to_inet_address(host_ip)
            opts = [:binary, {:active, false}, {:packet, 0}]
	            case :gen_tcp.connect(address, port, opts, SocketState.timeout_for_connect(state)) do
	              {:ok, socket} ->
	                :inet.setopts(socket, [{:nodelay, Map.get(state, :fast_send, false)}])
	                Process.put(key, %{state | socket: socket, kind: :tcp})
                :ok
              {:error, reason} ->
                raise "sys.net.Socket.connect failed: #{inspect(reason)}"
            end
        )
  end
  def tcp_listen(socket_ref, connections) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            address = state.bind_host || {0, 0, 0, 0}
            port = state.bind_port || 0
            opts = [:binary, {:active, false}, {:packet, 0}, {:ip, address}, {:backlog, connections}, {:reuseaddr, true}]
	            case :gen_tcp.listen(port, opts) do
	              {:ok, socket} ->
	                :inet.setopts(socket, [{:nodelay, Map.get(state, :fast_send, false)}])
	                Process.put(key, %{state | socket: socket, kind: :tcp})
                :ok
              {:error, reason} ->
                raise "sys.net.Socket.listen failed: #{inspect(reason)}"
            end
        )
  end
  def tcp_accept(socket_ref) do
    (
            state = SocketState.fetch_state(socket_ref)
            case :gen_tcp.accept(SocketState.fetch_socket(state), SocketState.recv_timeout(state)) do
              {:ok, socket} -> socket
              {:error, :timeout} -> {:reflaxe_blocked}
              {:error, reason} -> raise "sys.net.Socket.accept failed: #{inspect(reason)}"
            end
        )
  end
  def tcp_shutdown(socket_ref, read, write) do
    (
            socket = SocketState.fetch_socket(SocketState.fetch_state(socket_ref))
            how =
              case {read, write} do
                {true, true} -> :read_write
                {true, false} -> :read
                {false, true} -> :write
                {false, false} -> :read_write
              end
            :gen_tcp.shutdown(socket, how)
            :ok
        )
  end
  def tcp_set_fast_send(socket_ref, enabled) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            if state.socket != nil do
              :inet.setopts(state.socket, [{:nodelay, enabled}])
            end
            Process.put(key, %{state | fast_send: enabled})
            :ok
        )
  end
  def close(socket_ref) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Process.get(key)
            if is_map(state) and state.socket != nil do
              case state.kind do
                :ssl -> :ssl.close(state.socket)
                :udp -> :gen_udp.close(state.socket)
                _ -> :gen_tcp.close(state.socket)
              end
            end
            Process.delete(key)
            :ok
        )
  end
  def set_timeout(socket_ref, timeout) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            timeout_value =
              cond do
                is_nil(timeout) -> :infinity
                timeout < 0 -> :infinity
                true -> trunc(timeout * 1000)
              end
            Process.put(key, %{state | timeout: timeout_value})
            :ok
        )
  end
  def set_blocking(socket_ref, blocking) do
    (
            key = {:reflaxe_sys_net_socket, socket_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | blocking: blocking})
            :ok
        )
  end
  def recv_binary(socket_ref, len) do
    (
            state = SocketState.fetch_state(socket_ref)
            case :gen_tcp.recv(SocketState.fetch_socket(state), len, SocketState.recv_timeout(state)) do
              {:ok, data} -> data
              {:error, :timeout} -> {:reflaxe_blocked}
              {:error, :closed} -> {:reflaxe_eof}
              {:error, reason} -> {:reflaxe_error, reason}
            end
        )
  end
  def recv_all(socket_ref) do
    (
            state = SocketState.fetch_state(socket_ref)
            socket = SocketState.fetch_socket(state)
            timeout = SocketState.recv_timeout(state)
            read_all = fn read_all, acc ->
              case :gen_tcp.recv(socket, 0, timeout) do
                {:ok, data} -> read_all.(read_all, [data | acc])
                {:error, :closed} -> :erlang.iolist_to_binary(Enum.reverse(acc))
                {:error, :timeout} -> :erlang.iolist_to_binary(Enum.reverse(acc))
                {:error, reason} -> raise "sys.net.Socket.read failed: #{inspect(reason)}"
              end
            end
            read_all.(read_all, [])
        )
  end
  def recv_peek(socket_ref) do
    (
            state = SocketState.fetch_state(socket_ref)
            socket = SocketState.fetch_socket(state)
            case :inet.setopts(socket, [{:active, :once}]) do
              :ok ->
                receive do
                  {:tcp, ^socket, data} ->
                    send(self(), {:tcp, socket, data})
                    :ok
                  {:tcp_closed, ^socket} -> {:reflaxe_eof}
                  {:tcp_error, ^socket, reason} -> {:reflaxe_error, reason}
                after SocketState.recv_timeout(state) ->
                  {:reflaxe_blocked}
                end
              {:error, reason} -> {:reflaxe_error, reason}
            end
        )
  end
  def send_binary(socket_ref, data) do
    (
            state = SocketState.fetch_state(socket_ref)
            case :gen_tcp.send(SocketState.fetch_socket(state), data) do
              :ok -> :ok
              {:error, reason} -> raise "sys.net.Socket.write failed: #{inspect(reason)}"
            end
        )
  end
  def peer(socket_ref) do
    endpoint(socket_ref, true)
  end
  def host(socket_ref) do
    endpoint_info = endpoint(socket_ref, false)
    if (not is_nil_term(endpoint_info)) do
      endpoint_info
    else
      (
            state = SocketState.fetch_state(socket_ref)
            if state.bind_host == nil or state.bind_port == nil do
              nil
            else
              {SocketState.ipv4_to_int(state.bind_host), state.bind_port}
            end
        )
    end
  end
  defp endpoint(socket_ref, peer_side) do
    (
            state = SocketState.fetch_state(socket_ref)
            socket = SocketState.fetch_socket(state)
            result = if peer_side, do: :inet.peername(socket), else: :inet.sockname(socket)
            case result do
              {:ok, {address, port}} -> {SocketState.ipv4_to_int(address), port}
              {:error, _reason} -> nil
            end
        )
  end
  def endpoint_host(info) do
    elem(info, 0)
  end
  def endpoint_port(info) do
    elem(info, 1)
  end
  def select_ready(sockets, kind, timeout) do
    (
            timeout_value =
              cond do
                is_nil(timeout) -> :infinity
                timeout < 0 -> :infinity
                true -> trunc(timeout * 1000)
              end
            sockets = sockets
            kind = kind
            if sockets == [] do
              []
            else
              if timeout_value != 0, do: :timer.sleep(timeout_value)
              Enum.filter(sockets, fn socket_struct ->
                state = SocketState.fetch_state(socket_struct.socket_ref)
                socket = state.socket
                cond do
                  socket == nil -> false
                  kind == :write -> true
                  kind == :error -> false
                  true ->
                    case :inet.setopts(socket, [{:active, :once}]) do
                      :ok ->
                        receive do
                          {:tcp, ^socket, data} ->
                            send(self(), {:tcp, socket, data})
                            true
                          {:tcp_closed, ^socket} -> true
                          {:tcp_error, ^socket, _reason} -> true
                        after 0 ->
                          false
                        end
                      _ -> false
                    end
                end
              end)
            end
	        )
  end
  def fetch_state(socket_ref) do
    (
            case Process.get({:reflaxe_sys_net_socket, socket_ref}) do
              nil -> raise "sys.net.Socket: socket is closed or was not initialized"
              state -> state
            end
        )
  end
  def fetch_socket(state) do
    (
            case Map.fetch!(state, :socket) do
              nil -> raise "sys.net.Socket: socket is not connected or listening"
              socket -> socket
            end
        )
  end
  def recv_timeout(state) do
    (
            if Map.fetch!(state, :blocking), do: Map.fetch!(state, :timeout), else: 0
        )
  end
  def timeout_for_connect(state) do
    Map.fetch!(state, :timeout)
  end
  def ipv4_to_int(address) do
    (
            {a, b, c, d} = address
            Bitwise.bor(Bitwise.bsl(a, 24), Bitwise.bor(Bitwise.bsl(b, 16), Bitwise.bor(Bitwise.bsl(c, 8), d)))
        )
  end
  def is_nil_term(value) do
    is_nil(value)
  end
  def is_blocked(value) do
    value == {:reflaxe_blocked}
  end
  def is_eof(value) do
    value == {:reflaxe_eof}
  end
  def is_error(value) do
    match?({:reflaxe_error, _}, value)
  end
  def error_message(value) do
    (
            case value do
              {:reflaxe_error, reason} -> inspect(reason)
              other -> inspect(other)
            end
        )
  end
end
