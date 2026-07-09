package sys.net;

import elixir.types.Term;
import haxe.io.Bytes;
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
 * - `readFrom()` fails explicitly until generated `haxe.io.Bytes` can preserve
 *   caller-buffer mutations on immutable BEAM terms.
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

		throw Error.Custom("sys.net.UdpSocket.readFrom is not supported on the Elixir target because haxe.io.Bytes buffers are immutable in generated Elixir; use sendTo() for UDP output or a target-specific receive wrapper");
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
}
