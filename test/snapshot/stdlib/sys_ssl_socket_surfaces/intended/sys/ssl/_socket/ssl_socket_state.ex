defmodule SslSocketState do
  def attach(socket_ref, socket, verify_cert, ca_cert, own_certificate, own_key) do
    (
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                Process.put(key, Map.merge(state, %{
                  socket: socket,
                  kind: :ssl,
                  ssl_hostname: nil,
                  ssl_verify_cert: verify_cert,
                  ssl_ca: SslSocketState.certificate_der_list(ca_cert),
                  ssl_cert: SslSocketState.first_certificate_der(own_certificate),
                  ssl_key: SslSocketState.ssl_key(own_key),
                  ssl_handshake_done: true
                }))
                :ok
            )
  end
  def connect(socket_ref, host_ip, port, hostname, verify_cert, ca_cert) do
    (
                :ssl.start()
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                address = Host.to_inet_address(host_ip)
                opts = SslSocketState.client_options(hostname, verify_cert, ca_cert)
                case :ssl.connect(address, port, opts, SocketState.timeout_for_connect(state)) do
                  {:ok, socket} ->
                    Process.put(key, Map.merge(state, %{
                      socket: socket,
                      kind: :ssl,
                      ssl_hostname: hostname,
                      ssl_verify_cert: verify_cert,
                      ssl_ca: SslSocketState.certificate_der_list(ca_cert),
                      ssl_cert: nil,
                      ssl_key: nil,
                      ssl_handshake_done: true
                    }))
                    :ok
                  {:error, reason} ->
                    raise "sys.ssl.Socket.connect failed: #{inspect(reason)}"
                end
            )
  end
  def listen(socket_ref, connections, verify_cert, ca_cert, own_certificate, own_key) do
    (
                :ssl.start()
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                address = state.bind_host || {0, 0, 0, 0}
                port = state.bind_port || 0
                opts =
                  SslSocketState.server_options(verify_cert, ca_cert, own_certificate, own_key)
                  |> Keyword.put(:ip, address)
                  |> Keyword.put(:backlog, connections)
                  |> Keyword.put(:reuseaddr, true)
                case :ssl.listen(port, opts) do
                  {:ok, socket} ->
                    Process.put(key, Map.merge(state, %{
                      socket: socket,
                      kind: :ssl,
                      ssl_hostname: nil,
                      ssl_verify_cert: verify_cert,
                      ssl_ca: SslSocketState.certificate_der_list(ca_cert),
                      ssl_cert: SslSocketState.first_certificate_der(own_certificate),
                      ssl_key: SslSocketState.ssl_key(own_key),
                      ssl_handshake_done: false
                    }))
                    :ok
                  {:error, reason} ->
                    raise "sys.ssl.Socket.listen failed: #{inspect(reason)}"
                end
            )
  end
  def accept(socket_ref) do
    (
                state = SocketState.fetch_state(socket_ref)
                timeout = SocketState.recv_timeout(state)
                case :ssl.transport_accept(SocketState.fetch_socket(state), timeout) do
                  {:ok, transport_socket} ->
                    case :ssl.handshake(transport_socket, timeout) do
                      {:ok, ssl_socket} -> ssl_socket
                      {:error, :timeout} -> {:reflaxe_blocked}
                      {:error, reason} -> raise "sys.ssl.Socket.accept handshake failed: #{inspect(reason)}"
                    end
                  {:error, :timeout} -> {:reflaxe_blocked}
                  {:error, reason} -> raise "sys.ssl.Socket.accept failed: #{inspect(reason)}"
                end
            )
  end
  def handshake(socket_ref) do
    (
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = SocketState.fetch_state(socket_ref)
                if Map.get(state, :ssl_handshake_done, false) do
                  :ok
                else
                  case :ssl.handshake(SocketState.fetch_socket(state), SocketState.recv_timeout(state)) do
                    {:ok, socket} ->
                      Process.put(key, Map.merge(state, %{socket: socket, ssl_handshake_done: true}))
                      :ok
                    {:error, :timeout} -> throw({:blocked})
                    {:error, reason} -> raise "sys.ssl.Socket.handshake failed: #{inspect(reason)}"
                  end
                end
            )
  end
  def shutdown(socket_ref, read, write) do
    (
                socket = SocketState.fetch_socket(SocketState.fetch_state(socket_ref))
                how =
                  case {read, write} do
                    {true, true} -> :read_write
                    {true, false} -> :read
                    {false, true} -> :write
                    {false, false} -> :read_write
                  end
                :ssl.shutdown(socket, how)
                :ok
            )
  end
  def recv_binary(socket_ref, len) do
    (
                state = SocketState.fetch_state(socket_ref)
                case :ssl.recv(SocketState.fetch_socket(state), len, SocketState.recv_timeout(state)) do
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
                  case :ssl.recv(socket, 0, timeout) do
                    {:ok, data} -> read_all.(read_all, [data | acc])
                    {:error, :closed} -> :erlang.iolist_to_binary(Enum.reverse(acc))
                    {:error, :timeout} -> :erlang.iolist_to_binary(Enum.reverse(acc))
                    {:error, reason} -> raise "sys.ssl.Socket.read failed: #{inspect(reason)}"
                  end
                end
                read_all.(read_all, [])
            )
  end
  def send_binary(socket_ref, data) do
    (
                state = SocketState.fetch_state(socket_ref)
                case :ssl.send(SocketState.fetch_socket(state), data) do
                  :ok -> :ok
                  {:error, reason} -> raise "sys.ssl.Socket.write failed: #{inspect(reason)}"
                end
            )
  end
  def set_ca(socket_ref, cert) do
    (
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                Process.put(key, Map.put(state, :ssl_ca, SslSocketState.certificate_der_list(cert)))
                :ok
            )
  end
  def set_hostname(socket_ref, hostname) do
    (
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                Process.put(key, Map.put(state, :ssl_hostname, hostname))
                :ok
            )
  end
  def set_certificate(socket_ref, cert, key_value) do
    (
                key = {:reflaxe_sys_net_socket, socket_ref}
                state = Map.fetch!(%{value: Process.get(key)}, :value)
                Process.put(key, Map.merge(state, %{
                  ssl_cert: SslSocketState.first_certificate_der(cert),
                  ssl_key: SslSocketState.ssl_key(key_value)
                }))
                :ok
            )
  end
  def peer_certificate(socket_ref) do
    (
                socket = SocketState.fetch_socket(SocketState.fetch_state(socket_ref))
                case :ssl.peercert(socket) do
                  {:ok, der} -> der
                  {:error, :no_peercert} -> raise "sys.ssl.Socket.peerCertificate failed: peer did not provide a certificate"
                  {:error, reason} -> raise "sys.ssl.Socket.peerCertificate failed: #{inspect(reason)}"
                end
            )
  end
  def peer(socket_ref) do
    endpoint(socket_ref, true)
  end
  def host(socket_ref) do
    endpoint_info = endpoint(socket_ref, false)
    if (not SocketState.is_nil_term(endpoint_info)) do
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
                result = if peer_side, do: :ssl.peername(socket), else: :ssl.sockname(socket)
                case result do
                  {:ok, {address, port}} -> {SocketState.ipv4_to_int(address), port}
                  {:error, _reason} -> nil
                end
            )
  end
  def client_options(hostname, verify_cert, ca_cert) do
    (
                verify_mode = if verify_cert == false, do: :verify_none, else: :verify_peer
                opts = [:binary, {:active, false}, {:packet, 0}, {:verify, verify_mode}]
                opts =
                  if verify_mode == :verify_peer do
                    cacerts = SslSocketState.certificate_der_list(ca_cert)
                    cacerts = if is_nil(cacerts), do: :public_key.cacerts_get(), else: cacerts
                    Keyword.put(opts, :cacerts, cacerts)
                  else
                    opts
                  end
                if is_nil(hostname) do
                  opts
                else
                  opts
                  |> Keyword.put(:server_name_indication, String.to_charlist(hostname))
                  |> Keyword.put(:customize_hostname_check, [
                    match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
                  ])
                end
            )
  end
  def server_options(verify_cert, ca_cert, own_certificate, own_key) do
    (
                verify_mode = if verify_cert == true, do: :verify_peer, else: :verify_none
                opts = [:binary, {:active, false}, {:packet, 0}, {:verify, verify_mode}]
                opts =
                  case SslSocketState.certificate_der_list(ca_cert) do
                    nil -> opts
                    cacerts -> Keyword.put(opts, :cacerts, cacerts)
                  end
                opts =
                  case SslSocketState.first_certificate_der(own_certificate) do
                    nil -> opts
                    cert -> Keyword.put(opts, :cert, cert)
                  end
                opts =
                  case SslSocketState.ssl_key(own_key) do
                    nil -> opts
                    key -> Keyword.put(opts, :key, key)
                  end
                opts
            )
  end
  def certificate_der_list(cert) do
    if (Kernel.is_nil(cert)) do
      nil
    else
      apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :to_der_list, [cert])
    end
  end
  def first_certificate_der(cert) do
    if (Kernel.is_nil(cert)) do
      nil
    else
      apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :first_der, [cert])
    end
  end
  def ssl_key(key) do
    if (Kernel.is_nil(key)) do
      nil
    else
      apply(Map.get(key, :__reflaxe_class__) || Map.get(key, :__struct__), :to_ssl_key, [key])
    end
  end
end
