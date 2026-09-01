package sys.net;

import elixir.types.Term;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Error;
import sys.net.Socket.SocketState;

/**
 * sys.net.UdpSocket (Elixir target)
 *
 * WHAT
 * - UDP socket implementation backed by Erlang `:gen_udp`.
 *
 * WHY
 * - UDP support is useful for BEAM integration tests and service discovery code,
 *   but it has different semantics than TCP streams.
 *
 * HOW
 * - Reuses `Socket` lifecycle fields for Haxe API compatibility.
 * - Opens a passive binary UDP socket with `:gen_udp.open/2`.
 * - `sendTo()` maps to `:gen_udp.send/4`.
 * - `readFrom()` receives one datagram, copies the requested byte range into
 *   the caller buffer, and updates the caller's source address.
 */
class UdpSocket extends Socket {
	public function new() {
		super();
		UdpSocketState.open(socketRef, 0, null);
	}

	public function setBroadcast(b:Bool):Void {
		UdpSocketState.setBroadcast(socketRef, b);
	}

	override public function bind(host:Host, port:Int):Void {
		UdpSocketState.open(socketRef, port, Host.toInetAddress(host.ip));
	}

	public function sendTo(buf:Bytes, pos:Int, len:Int, addr:Address):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length)
			throw Error.OutsideBounds;
		if (len == 0)
			return 0;

		UdpSocketState.sendTo(socketRef, buf.sub(pos, len).getData(), addr.host, addr.port);
		return len;
	}

	public function readFrom(buf:Bytes, pos:Int, len:Int, addr:Address):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length)
			throw Error.OutsideBounds;
		if (len == 0)
			return 0;

		var result = UdpSocketState.receiveFrom(socketRef);
		if (SocketState.isBlocked(result))
			throw Error.Blocked;
		if (SocketState.isError(result))
			throw Error.Custom(SocketState.errorMessage(result));

		var received = Bytes.ofData(UdpSocketState.receivedData(result));
		var copied = received.length < len ? received.length : len;
		buf.blit(pos, received, 0, copied);
		addr.host = UdpSocketState.receivedHost(result);
		addr.port = UdpSocketState.receivedPort(result);
		return copied;
	}
}

private class UdpSocketState {
	public static function open(socketRef:Term, port:Int, hostAddress:Term):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            if state.socket != nil do
              case state.kind do
                :udp -> :gen_udp.close(state.socket)
                _ -> :gen_tcp.close(state.socket)
              end
            end
            opts = [:binary, {:active, false}]
            opts = if is_nil({2}), do: opts, else: [{:ip, {2}} | opts]
            case :gen_udp.open({1}, opts) do
              {:ok, socket} -> Process.put(key, %{state | socket: socket, kind: :udp})
              {:error, reason} -> raise "sys.net.UdpSocket.open failed: #{inspect(reason)}"
            end
            :ok
        )', socketRef, port, hostAddress);
	}

	public static function setBroadcast(socketRef:Term, enabled:Bool):Void {
		untyped __elixir__('(
            socket = SocketState.fetch_socket(SocketState.fetch_state({0}))
            :inet.setopts(socket, [{:broadcast, {1}}])
            :ok
        )', socketRef, enabled);
	}

	public static function sendTo(socketRef:Term, data:Term, hostIp:Int, port:Int):Void {
		untyped __elixir__('(
            socket = SocketState.fetch_socket(SocketState.fetch_state({0}))
            address = Host.to_inet_address({2})
            case :gen_udp.send(socket, address, {3}, {1}) do
              :ok -> :ok
              {:error, reason} -> raise "sys.net.UdpSocket.sendTo failed: #{inspect(reason)}"
            end
		)', socketRef, data, hostIp, port);
	}

	public static function receiveFrom(socketRef:Term):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
            socket = SocketState.fetch_socket(state)
            case :gen_udp.recv(socket, 0, SocketState.recv_timeout(state)) do
              {:ok, {address, port, data}} ->
                {data, SocketState.ipv4_to_int(address), port}
              {:error, :timeout} -> {:reflaxe_blocked}
              {:error, reason} -> {:reflaxe_error, reason}
            end
        )', socketRef);
	}

	public static function receivedData(result:Term):BytesData {
		return untyped __elixir__('elem({0}, 0)', result);
	}

	public static function receivedHost(result:Term):Int {
		return untyped __elixir__('elem({0}, 1)', result);
	}

	public static function receivedPort(result:Term):Int {
		return untyped __elixir__('elem({0}, 2)', result);
	}
}
