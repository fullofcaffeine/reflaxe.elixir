package sys.ssl;

import elixir.types.Term;
import haxe.io.Bytes;
import haxe.io.Error;
import sys.net.Host;
import sys.net.Socket.SocketState;

/**
 * sys.ssl.Socket (Elixir target)
 *
 * WHAT
 * - TLS socket implementation backed by Erlang/OTP `:ssl`.
 *
 * WHY
 * - TLS is the natural BEAM mapping for Haxe `sys.ssl.Socket`.
 * - The existing `sys.net.Socket` state model already solves Haxe's mutable
 *   socket API on immutable generated Elixir structs.
 *
 * HOW
 * - Reuses the inherited socket reference/state.
 * - Replaces inherited TCP input/output with SSL-aware streams.
 * - Client connect/listen/accept map to `:ssl.connect`, `:ssl.listen`, and
 *   `:ssl.transport_accept` + `:ssl.handshake`.
 */
@:native("SslSocket")
class Socket extends sys.net.Socket {
	public static var DEFAULT_VERIFY_CERT:Null<Bool> = true;
	public static var DEFAULT_CA:Null<Certificate>;

	public var verifyCert:Null<Bool>;

	var caCert:Null<Certificate>;
	var hostname:Null<String>;
	var ownCertificate:Null<Certificate>;
	var ownKey:Null<Key>;

	public function new():Void {
		super();
		input = new SslSocketInput(socketRef);
		output = new SslSocketOutput(socketRef);
		verifyCert = DEFAULT_VERIFY_CERT;
		caCert = DEFAULT_CA;
	}

	override public function connect(host:Host, port:Int):Void {
		var serverName = hostname;
		if (serverName == null)
			serverName = host.host;
		SslSocketState.connect(socketRef, host.ip, port, serverName, verifyCert, caCert);
	}

	override public function listen(connections:Int):Void {
		SslSocketState.listen(socketRef, connections, verifyCert, caCert, ownCertificate, ownKey);
	}

	override public function accept():Socket {
		var accepted = SslSocketState.accept(socketRef);
		var socket = new Socket();
		SslSocketState.attach(socket.socketRef, accepted, verifyCert, caCert, ownCertificate, ownKey);
		return socket;
	}

	override public function shutdown(read:Bool, write:Bool):Void {
		SslSocketState.shutdown(socketRef, read, write);
	}

	override public function peer():{host:Host, port:Int} {
		var info = SslSocketState.peer(socketRef);
		if (SocketState.isNilTerm(info))
			return null;
		return endpointToRecord(info);
	}

	override public function host():{host:Host, port:Int} {
		var info = SslSocketState.host(socketRef);
		if (SocketState.isNilTerm(info))
			return null;
		return endpointToRecord(info);
	}

	public function handshake():Void {
		SslSocketState.handshake(socketRef);
	}

	public function setCA(cert:Certificate):Void {
		caCert = cert;
		SslSocketState.setCA(socketRef, cert);
	}

	public function setHostname(name:String):Void {
		hostname = name;
		SslSocketState.setHostname(socketRef, name);
	}

	public function setCertificate(cert:Certificate, key:Key):Void {
		ownCertificate = cert;
		ownKey = key;
		SslSocketState.setCertificate(socketRef, cert, key);
	}

	public function addSNICertificate(cbServernameMatch:String->Bool, cert:Certificate, key:Key):Void {
		throw Error.Custom("sys.ssl.Socket.addSNICertificate is not supported on the Elixir target yet; use setCertificate for a single certificate/key pair");
	}

	public function peerCertificate():Certificate {
		return Certificate.fromDerChain(SslSocketState.peerCertificate(socketRef));
	}

	static function endpointToRecord(info:Term):{host:Host, port:Int} {
		var hostObject = new Host("127.0.0.1");
		untyped hostObject.ip = SocketState.endpointHost(info);
		return {host: hostObject, port: SocketState.endpointPort(info)};
	}
}

private class SslSocketInput extends haxe.io.Input {
	final socketRef:Term;

	public function new(socketRef:Term) {
		this.socketRef = socketRef;
	}

	override public function readByte():Int {
		var result = SslSocketState.recvBinary(socketRef, 1);
		if (SocketState.isBlocked(result))
			throw Error.Blocked;
		if (SocketState.isEof(result))
			throw new haxe.io.Eof();
		if (SocketState.isError(result))
			throw Error.Custom(SocketState.errorMessage(result));
		return untyped __elixir__(':binary.at({0}, 0)', result);
	}

	override public function readBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length)
			throw Error.OutsideBounds;
		if (len == 0)
			return 0;

		throw Error.Custom("sys.ssl.Socket.input.readBytes is not supported on the Elixir target because haxe.io.Bytes buffers are immutable in generated Elixir; use Socket.read() or Input.readByte() instead");
	}
}

private class SslSocketOutput extends haxe.io.Output {
	final socketRef:Term;

	public function new(socketRef:Term) {
		this.socketRef = socketRef;
	}

	override public function writeByte(c:Int):Void {
		SslSocketState.sendBinary(socketRef, untyped __elixir__('<<{0}::8>>', c));
	}

	override public function writeBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length)
			throw Error.OutsideBounds;
		if (len == 0)
			return 0;

		SslSocketState.sendBinary(socketRef, buf.sub(pos, len).getData());
		return len;
	}
}

private class SslSocketState {
	public static function attach(socketRef:Term, socket:Term, verifyCert:Bool, caCert:Certificate, ownCertificate:Certificate, ownKey:Key):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, Map.merge(state, %{
              socket: {1},
              kind: :ssl,
              ssl_hostname: nil,
              ssl_verify_cert: {2},
              ssl_ca: SslSocketState.certificate_der_list({3}),
              ssl_cert: SslSocketState.first_certificate_der({4}),
              ssl_key: SslSocketState.ssl_key({5}),
              ssl_handshake_done: true
            }))
            :ok
        )', socketRef, socket, verifyCert, caCert, ownCertificate, ownKey);
	}

	public static function connect(socketRef:Term, hostIp:Int, port:Int, hostname:String, verifyCert:Bool, caCert:Certificate):Void {
		untyped __elixir__('(
            :ssl.start()
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            address = Host.to_inet_address({1})
            opts = SslSocketState.client_options({3}, {4}, {5})
            case :ssl.connect(address, {2}, opts, SocketState.timeout_for_connect(state)) do
              {:ok, socket} ->
                Process.put(key, Map.merge(state, %{
                  socket: socket,
                  kind: :ssl,
                  ssl_hostname: {3},
                  ssl_verify_cert: {4},
                  ssl_ca: SslSocketState.certificate_der_list({5}),
                  ssl_cert: nil,
                  ssl_key: nil,
                  ssl_handshake_done: true
                }))
                :ok
              {:error, reason} ->
                raise "sys.ssl.Socket.connect failed: #{inspect(reason)}"
            end
        )', socketRef, hostIp, port, hostname, verifyCert, caCert);
	}

	public static function listen(socketRef:Term, connections:Int, verifyCert:Bool, caCert:Certificate, ownCertificate:Certificate, ownKey:Key):Void {
		untyped __elixir__('(
            :ssl.start()
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            address = state.bind_host || {0, 0, 0, 0}
            port = state.bind_port || 0
            opts =
              SslSocketState.server_options({2}, {3}, {4}, {5})
              |> Keyword.put(:ip, address)
              |> Keyword.put(:backlog, {1})
              |> Keyword.put(:reuseaddr, true)
            case :ssl.listen(port, opts) do
              {:ok, socket} ->
                Process.put(key, Map.merge(state, %{
                  socket: socket,
                  kind: :ssl,
                  ssl_hostname: nil,
                  ssl_verify_cert: {2},
                  ssl_ca: SslSocketState.certificate_der_list({3}),
                  ssl_cert: SslSocketState.first_certificate_der({4}),
                  ssl_key: SslSocketState.ssl_key({5}),
                  ssl_handshake_done: false
                }))
                :ok
              {:error, reason} ->
                raise "sys.ssl.Socket.listen failed: #{inspect(reason)}"
            end
        )', socketRef, connections, verifyCert, caCert, ownCertificate, ownKey);
	}

	public static function accept(socketRef:Term):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
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
        )', socketRef);
	}

	public static function handshake(socketRef:Term):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = SocketState.fetch_state({0})
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
        )', socketRef);
	}

	public static function shutdown(socketRef:Term, read:Bool, write:Bool):Void {
		untyped __elixir__('(
            socket = SocketState.fetch_socket(SocketState.fetch_state({0}))
            how =
              case {{1}, {2}} do
                {true, true} -> :read_write
                {true, false} -> :read
                {false, true} -> :write
                {false, false} -> :read_write
              end
            :ssl.shutdown(socket, how)
            :ok
        )', socketRef, read, write);
	}

	public static function recvBinary(socketRef:Term, len:Int):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
            case :ssl.recv(SocketState.fetch_socket(state), {1}, SocketState.recv_timeout(state)) do
              {:ok, data} -> data
              {:error, :timeout} -> {:reflaxe_blocked}
              {:error, :closed} -> {:reflaxe_eof}
              {:error, reason} -> {:reflaxe_error, reason}
            end
        )', socketRef, len);
	}

	public static function recvAll(socketRef:Term):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
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
        )', socketRef);
	}

	public static function sendBinary(socketRef:Term, data:Term):Void {
		untyped __elixir__('(
            state = SocketState.fetch_state({0})
            case :ssl.send(SocketState.fetch_socket(state), {1}) do
              :ok -> :ok
              {:error, reason} -> raise "sys.ssl.Socket.write failed: #{inspect(reason)}"
            end
        )', socketRef, data);
	}

	public static function setCA(socketRef:Term, cert:Certificate):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, Map.put(state, :ssl_ca, SslSocketState.certificate_der_list({1})))
            :ok
        )', socketRef, cert);
	}

	public static function setHostname(socketRef:Term, hostname:String):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, Map.put(state, :ssl_hostname, {1}))
            :ok
        )', socketRef, hostname);
	}

	public static function setCertificate(socketRef:Term, cert:Certificate, keyValue:Key):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, Map.merge(state, %{
              ssl_cert: SslSocketState.first_certificate_der({1}),
              ssl_key: SslSocketState.ssl_key({2})
            }))
            :ok
        )', socketRef, cert, keyValue);
	}

	public static function peerCertificate(socketRef:Term):Term {
		return untyped __elixir__('(
            socket = SocketState.fetch_socket(SocketState.fetch_state({0}))
            case :ssl.peercert(socket) do
              {:ok, der} -> der
              {:error, :no_peercert} -> raise "sys.ssl.Socket.peerCertificate failed: peer did not provide a certificate"
              {:error, reason} -> raise "sys.ssl.Socket.peerCertificate failed: #{inspect(reason)}"
            end
        )', socketRef);
	}

	public static function peer(socketRef:Term):Term {
		return endpoint(socketRef, true);
	}

	public static function host(socketRef:Term):Term {
		var endpointInfo = endpoint(socketRef, false);
		if (!SocketState.isNilTerm(endpointInfo))
			return endpointInfo;
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
            if state.bind_host == nil or state.bind_port == nil do
              nil
            else
              {SocketState.ipv4_to_int(state.bind_host), state.bind_port}
            end
        )', socketRef);
	}

	static function endpoint(socketRef:Term, peerSide:Bool):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
            socket = SocketState.fetch_socket(state)
            result = if {1}, do: :ssl.peername(socket), else: :ssl.sockname(socket)
            case result do
              {:ok, {address, port}} -> {SocketState.ipv4_to_int(address), port}
              {:error, _reason} -> nil
            end
        )', socketRef, peerSide);
	}

	public static function clientOptions(hostname:String, verifyCert:Bool, caCert:Certificate):Term {
		return untyped __elixir__('(
            verify_mode = if {1} == false, do: :verify_none, else: :verify_peer
            opts = [:binary, {:active, false}, {:packet, 0}, {:verify, verify_mode}]
            opts =
              if verify_mode == :verify_peer do
                cacerts = SslSocketState.certificate_der_list({2})
                cacerts = if is_nil(cacerts), do: :public_key.cacerts_get(), else: cacerts
                Keyword.put(opts, :cacerts, cacerts)
              else
                opts
              end
            if is_nil({0}) do
              opts
            else
              opts
              |> Keyword.put(:server_name_indication, String.to_charlist({0}))
              |> Keyword.put(:customize_hostname_check, [
                match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
              ])
            end
        )', hostname, verifyCert, caCert);
	}

	public static function serverOptions(verifyCert:Bool, caCert:Certificate, ownCertificate:Certificate, ownKey:Key):Term {
		return untyped __elixir__('(
            verify_mode = if {0} == true, do: :verify_peer, else: :verify_none
            opts = [:binary, {:active, false}, {:packet, 0}, {:verify, verify_mode}]
            opts =
              case SslSocketState.certificate_der_list({1}) do
                nil -> opts
                cacerts -> Keyword.put(opts, :cacerts, cacerts)
              end
            opts =
              case SslSocketState.first_certificate_der({2}) do
                nil -> opts
                cert -> Keyword.put(opts, :cert, cert)
              end
            opts =
              case SslSocketState.ssl_key({3}) do
                nil -> opts
                key -> Keyword.put(opts, :key, key)
              end
            opts
        )', verifyCert, caCert, ownCertificate, ownKey);
	}

	public static function certificateDerList(cert:Certificate):Term {
		if (cert == null)
			return null;
		return cert.toDerList();
	}

	public static function firstCertificateDer(cert:Certificate):Term {
		if (cert == null)
			return null;
		return cert.firstDer();
	}

	public static function sslKey(key:Key):Term {
		if (key == null)
			return null;
		return key.toSslKey();
	}
}
