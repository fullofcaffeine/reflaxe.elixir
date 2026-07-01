defmodule SslSocket do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, SslSocket, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, SslSocket, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def default_verify_cert() do
    __haxe_static_get__(:default_verify_cert, true)
  end
  def default_verify_cert(value) do
    __haxe_static_put__(:default_verify_cert, value)
  end
  def default_ca() do
    __haxe_static_get__(:default_ca, nil)
  end
  def default_ca(value) do
    __haxe_static_put__(:default_ca, value)
  end
  def new() do
    struct = %{:__reflaxe_class__ => SslSocket, :verify_cert => nil, :ca_cert => nil, :hostname => nil, :own_certificate => nil, :own_key => nil, :input => nil, :output => nil, :custom => nil, :socket_ref => nil}
    struct = Map.merge(struct, Map.drop(Socket.new(), [:__struct__, :__reflaxe_class__]))
    struct = %{struct | input: SslSocketInput.new(struct.socket_ref)}
    struct = %{struct | output: SslSocketOutput.new(struct.socket_ref)}
    struct = %{struct | verify_cert: SslSocket.default_verify_cert()}
    struct = %{struct | ca_cert: SslSocket.default_ca()}
    struct
  end
  def connect(struct, host, port) do
    server_name = struct.hostname
    server_name = if (Kernel.is_nil(server_name)) do
      Host.get_host(host)
    else
      server_name
    end
    _ = SslSocketState.connect(struct.socket_ref, host.ip, port, server_name, struct.verify_cert, struct.ca_cert)
  end
  def listen(struct, connections) do
    SslSocketState.listen(struct.socket_ref, connections, struct.verify_cert, struct.ca_cert, struct.own_certificate, struct.own_key)
  end
  def accept(struct) do
    accepted = SslSocketState.accept(struct.socket_ref)
    socket = SslSocket.new()
    _ = SslSocketState.attach(socket.socket_ref, accepted, struct.verify_cert, struct.ca_cert, struct.own_certificate, struct.own_key)
    socket
  end
  def shutdown(struct, read, write) do
    SslSocketState.shutdown(struct.socket_ref, read, write)
  end
  def peer(struct) do
    info = SslSocketState.peer(struct.socket_ref)
    if (SocketState.is_nil_term(info)), do: nil, else: endpoint_to_record(info)
  end
  def host(struct) do
    info = SslSocketState.host(struct.socket_ref)
    if (SocketState.is_nil_term(info)), do: nil, else: endpoint_to_record(info)
  end
  def handshake(struct) do
    SslSocketState.handshake(struct.socket_ref)
  end
  def set_ca(struct, cert) do
    struct = %{struct | ca_cert: cert}
    _ = SslSocketState.set_ca(struct.socket_ref, cert)
  end
  def set_hostname(struct, name) do
    struct = %{struct | hostname: name}
    _ = SslSocketState.set_hostname(struct.socket_ref, name)
  end
  def set_certificate(struct, cert, key) do
    struct = %{struct | own_certificate: cert}
    struct = %{struct | own_key: key}
    _ = SslSocketState.set_certificate(struct.socket_ref, cert, key)
  end
  def add_sni_certificate(_struct, _cb_servername_match, _cert, _key) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Socket.addSNICertificate is not supported on the Elixir target yet; use setCertificate for a single certificate/key pair"}]
  end
  def peer_certificate(struct) do
    Certificate.from_der_chain(SslSocketState.peer_certificate(struct.socket_ref))
  end
  defp endpoint_to_record(info) do
    host_object = Host.new("127.0.0.1")
    host_object = %{host_object | ip: SocketState.endpoint_host(info)}
    %{host: host_object, port: SocketState.endpoint_port(info)}
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
  def bind(struct, host, port) do
    Socket.bind(struct, host, port)
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
