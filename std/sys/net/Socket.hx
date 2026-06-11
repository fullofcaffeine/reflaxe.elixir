package sys.net;

import elixir.types.Term;
import haxe.io.Bytes;
import haxe.io.Error;

/**
 * sys.net.Socket (Elixir target)
 *
 * WHAT
 * - TCP socket implementation backed by Erlang `:gen_tcp`.
 *
 * WHY
 * - Haxe sockets are mutable objects: `connect()`, `bind()`, `listen()`, and
 *   `accept()` change the socket behind existing `input`/`output` fields.
 * - Generated Elixir structs are immutable, so storing the raw socket directly
 *   in a field would make those `Void` methods lose state after returning.
 *
 * HOW
 * - Each `Socket` owns an opaque BEAM reference.
 * - Mutable socket state is stored in the current process dictionary under that
 *   reference, while the public Haxe value remains immutable.
 * - `input` and `output` hold the same reference, so reads/writes observe later
 *   `connect()` or `accept()` state.
 */
class Socket {
	public var input(default, null):haxe.io.Input;
	public var output(default, null):haxe.io.Output;
	// Haxe stdlib compatibility: upstream exposes a dynamic custom payload slot.
	public var custom:Dynamic;

	@:noCompletion public var socketRef(default, null):Term;

	public function new():Void {
		socketRef = SocketState.create(untyped __elixir__(':tcp'));
		input = new SocketInput(socketRef);
		output = new SocketOutput(socketRef);
	}

	public function close():Void {
		SocketState.close(socketRef);
		input.close();
		output.close();
	}

	public function read():String {
		return Bytes.ofData(SocketState.recvAll(socketRef)).toString();
	}

	public function write(content:String):Void {
		SocketState.sendBinary(socketRef, Bytes.ofString(content).getData());
	}

	public function connect(host:Host, port:Int):Void {
		SocketState.tcpConnect(socketRef, host.ip, port);
	}

	public function listen(connections:Int):Void {
		SocketState.tcpListen(socketRef, connections);
	}

	public function shutdown(read:Bool, write:Bool):Void {
		SocketState.tcpShutdown(socketRef, read, write);
	}

	public function bind(host:Host, port:Int):Void {
		SocketState.bind(socketRef, host.ip, port);
	}

	public function accept():Socket {
		var accepted = SocketState.tcpAccept(socketRef);
		var socket = new Socket();
		SocketState.attach(socket.socketRef, accepted);
		return socket;
	}

	public function peer():{host:Host, port:Int} {
		var info = SocketState.peer(socketRef);
		if (SocketState.isNilTerm(info))
			return null;
		return endpointToRecord(info);
	}

	public function host():{host:Host, port:Int} {
		var info = SocketState.host(socketRef);
		if (SocketState.isNilTerm(info))
			return null;
		return endpointToRecord(info);
	}

	public function setTimeout(timeout:Float):Void {
		SocketState.setTimeout(socketRef, timeout);
	}

	public function waitForRead():Void {
		var result = SocketState.recvPeek(socketRef);
		if (SocketState.isBlocked(result))
			throw Error.Blocked;
		if (SocketState.isError(result))
			throw Error.Custom(SocketState.errorMessage(result));
	}

	public function setBlocking(b:Bool):Void {
		SocketState.setBlocking(socketRef, b);
	}

	public function setFastSend(b:Bool):Void {
		SocketState.tcpSetFastSend(socketRef, b);
	}

	public static function select(read:Array<Socket>, write:Array<Socket>, others:Array<Socket>,
			?timeout:Float):{read:Array<Socket>, write:Array<Socket>, others:Array<Socket>} {
		return {
			read: selectReady(read, untyped __elixir__(':read'), timeout),
			write: selectReady(write, untyped __elixir__(':write'), timeout),
			others: selectReady(others, untyped __elixir__(':error'), timeout)
		};
	}

	static function selectReady(sockets:Array<Socket>, kind:Term, ?timeout:Float):Array<Socket> {
		if (sockets == null)
			return null;
		return SocketState.selectReady(sockets, kind, timeout);
	}

	static function endpointToRecord(info:Term):{host:Host, port:Int} {
		var hostObject = new Host("127.0.0.1");
		untyped hostObject.ip = SocketState.endpointHost(info);
		return {host: hostObject, port: SocketState.endpointPort(info)};
	}
}

private class SocketInput extends haxe.io.Input {
	final socketRef:Term;

	public function new(socketRef:Term) {
		this.socketRef = socketRef;
	}

	override public function readByte():Int {
		var result = SocketState.recvBinary(socketRef, 1);
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

		throw Error.Custom("sys.net.Socket.input.readBytes is not supported on the Elixir target because haxe.io.Bytes buffers are immutable in generated Elixir; use Socket.read() or Input.readByte() instead");
	}
}

private class SocketOutput extends haxe.io.Output {
	final socketRef:Term;

	public function new(socketRef:Term) {
		this.socketRef = socketRef;
	}

	override public function writeByte(c:Int):Void {
		SocketState.sendBinary(socketRef, untyped __elixir__('<<{0}::8>>', c));
	}

	override public function writeBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length)
			throw Error.OutsideBounds;
		if (len == 0)
			return 0;

		SocketState.sendBinary(socketRef, buf.sub(pos, len).getData());
		return len;
	}
}

class SocketState {
	public static function create(kind:Term):Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_net_socket, ref}, %{
              kind: {0},
              socket: nil,
              bind_host: nil,
              bind_port: nil,
              timeout: :infinity,
              blocking: true,
              fast_send: false
            })
            ref
        )', kind);
	}

	public static function attach(socketRef:Term, socket:Term):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | socket: {1}, kind: :tcp})
            :ok
        )', socketRef, socket);
	}

	public static function bind(socketRef:Term, hostIp:Int, port:Int):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | bind_host: Host.to_inet_address({1}), bind_port: {2}})
            :ok
        )', socketRef, hostIp, port);
	}

	public static function tcpConnect(socketRef:Term, hostIp:Int, port:Int):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            address = Host.to_inet_address({1})
            opts = [:binary, {:active, false}, {:packet, 0}]
	            case :gen_tcp.connect(address, {2}, opts, SocketState.timeout_for_connect(state)) do
	              {:ok, socket} ->
	                :inet.setopts(socket, [{:nodelay, Map.get(state, :fast_send, false)}])
	                Process.put(key, %{state | socket: socket, kind: :tcp})
                :ok
              {:error, reason} ->
                raise "sys.net.Socket.connect failed: #{inspect(reason)}"
            end
        )', socketRef, hostIp, port);
	}

	public static function tcpListen(socketRef:Term, connections:Int):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            address = state.bind_host || {0, 0, 0, 0}
            port = state.bind_port || 0
            opts = [:binary, {:active, false}, {:packet, 0}, {:ip, address}, {:backlog, {1}}, {:reuseaddr, true}]
	            case :gen_tcp.listen(port, opts) do
	              {:ok, socket} ->
	                :inet.setopts(socket, [{:nodelay, Map.get(state, :fast_send, false)}])
	                Process.put(key, %{state | socket: socket, kind: :tcp})
                :ok
              {:error, reason} ->
                raise "sys.net.Socket.listen failed: #{inspect(reason)}"
            end
        )', socketRef, connections);
	}

	public static function tcpAccept(socketRef:Term):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
            case :gen_tcp.accept(SocketState.fetch_socket(state), SocketState.recv_timeout(state)) do
              {:ok, socket} -> socket
              {:error, :timeout} -> {:reflaxe_blocked}
              {:error, reason} -> raise "sys.net.Socket.accept failed: #{inspect(reason)}"
            end
        )', socketRef);
	}

	public static function tcpShutdown(socketRef:Term, read:Bool, write:Bool):Void {
		untyped __elixir__('(
            socket = SocketState.fetch_socket(SocketState.fetch_state({0}))
            how =
              case {{1}, {2}} do
                {true, true} -> :read_write
                {true, false} -> :read
                {false, true} -> :write
                {false, false} -> :read_write
              end
            :gen_tcp.shutdown(socket, how)
            :ok
        )', socketRef, read, write);
	}

	public static function tcpSetFastSend(socketRef:Term, enabled:Bool):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            if state.socket != nil do
              :inet.setopts(state.socket, [{:nodelay, {1}}])
            end
            Process.put(key, %{state | fast_send: {1}})
            :ok
        )', socketRef, enabled);
	}

	public static function close(socketRef:Term):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Process.get(key)
            if is_map(state) and state.socket != nil do
              case state.kind do
                :udp -> :gen_udp.close(state.socket)
                _ -> :gen_tcp.close(state.socket)
              end
            end
            Process.delete(key)
            :ok
        )', socketRef);
	}

	public static function setTimeout(socketRef:Term, timeout:Float):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            timeout_value =
              cond do
                is_nil({1}) -> :infinity
                {1} < 0 -> :infinity
                true -> trunc({1} * 1000)
              end
            Process.put(key, %{state | timeout: timeout_value})
            :ok
        )', socketRef, timeout);
	}

	public static function setBlocking(socketRef:Term, blocking:Bool):Void {
		untyped __elixir__('(
            key = {:reflaxe_sys_net_socket, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | blocking: {1}})
            :ok
        )', socketRef, blocking);
	}

	public static function recvBinary(socketRef:Term, len:Int):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
            case :gen_tcp.recv(SocketState.fetch_socket(state), {1}, SocketState.recv_timeout(state)) do
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
              case :gen_tcp.recv(socket, 0, timeout) do
                {:ok, data} -> read_all.(read_all, [data | acc])
                {:error, :closed} -> :erlang.iolist_to_binary(Enum.reverse(acc))
                {:error, :timeout} -> :erlang.iolist_to_binary(Enum.reverse(acc))
                {:error, reason} -> raise "sys.net.Socket.read failed: #{inspect(reason)}"
              end
            end
            read_all.(read_all, [])
        )', socketRef);
	}

	public static function recvPeek(socketRef:Term):Term {
		return untyped __elixir__('(
            state = SocketState.fetch_state({0})
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
        )', socketRef);
	}

	public static function sendBinary(socketRef:Term, data:Term):Void {
		untyped __elixir__('(
            state = SocketState.fetch_state({0})
            case :gen_tcp.send(SocketState.fetch_socket(state), {1}) do
              :ok -> :ok
              {:error, reason} -> raise "sys.net.Socket.write failed: #{inspect(reason)}"
            end
        )', socketRef, data);
	}

	public static function peer(socketRef:Term):Term {
		return endpoint(socketRef, true);
	}

	public static function host(socketRef:Term):Term {
		var endpointInfo = endpoint(socketRef, false);
		if (!isNilTerm(endpointInfo))
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
            result = if {1}, do: :inet.peername(socket), else: :inet.sockname(socket)
            case result do
              {:ok, {address, port}} -> {SocketState.ipv4_to_int(address), port}
              {:error, _reason} -> nil
            end
        )', socketRef, peerSide);
	}

	public static function endpointHost(info:Term):Int {
		return untyped __elixir__('elem({0}, 0)', info);
	}

	public static function endpointPort(info:Term):Int {
		return untyped __elixir__('elem({0}, 1)', info);
	}

	public static function selectReady(sockets:Array<Socket>, kind:Term, ?timeout:Float):Array<Socket> {
		return untyped __elixir__('(
            timeout_value =
              cond do
                is_nil({2}) -> :infinity
                {2} < 0 -> :infinity
                true -> trunc({2} * 1000)
              end
            sockets = {0}
            kind = {1}
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
	        )', sockets, kind, timeout);
	}

	public static function fetchState(socketRef:Term):Term {
		return untyped __elixir__('(
            case Process.get({:reflaxe_sys_net_socket, {0}}) do
              nil -> raise "sys.net.Socket: socket is closed or was not initialized"
              state -> state
            end
        )', socketRef);
	}

	public static function fetchSocket(state:Term):Term {
		return untyped __elixir__('(
            case Map.fetch!({0}, :socket) do
              nil -> raise "sys.net.Socket: socket is not connected or listening"
              socket -> socket
            end
        )', state);
	}

	public static function recvTimeout(state:Term):Term {
		return untyped __elixir__('(
            if Map.fetch!({0}, :blocking), do: Map.fetch!({0}, :timeout), else: 0
        )', state);
	}

	public static function timeoutForConnect(state:Term):Term {
		return untyped __elixir__('Map.fetch!({0}, :timeout)', state);
	}

	public static function ipv4ToInt(address:Term):Int {
		return untyped __elixir__('(
            {a, b, c, d} = {0}
            Bitwise.bor(Bitwise.bsl(a, 24), Bitwise.bor(Bitwise.bsl(b, 16), Bitwise.bor(Bitwise.bsl(c, 8), d)))
        )', address);
	}

	public static function isNilTerm(value:Term):Bool {
		return untyped __elixir__('is_nil({0})', value);
	}

	public static function isBlocked(value:Term):Bool {
		return untyped __elixir__('{0} == {:reflaxe_blocked}', value);
	}

	public static function isEof(value:Term):Bool {
		return untyped __elixir__('{0} == {:reflaxe_eof}', value);
	}

	public static function isError(value:Term):Bool {
		return untyped __elixir__('match?({:reflaxe_error, _}, {0})', value);
	}

	public static function errorMessage(value:Term):String {
		return untyped __elixir__('(
            case {0} do
              {:reflaxe_error, reason} -> inspect(reason)
              other -> inspect(other)
            end
        )', value);
	}
}
