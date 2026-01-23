package phoenix;

/**
 * phoenix.Socket (JS)
 *
 * WHAT
 * - Typed externs for Phoenix Channels client APIs from the `phoenix` npm package.
 *
 * WHY
 * - Reflaxe.Elixir projects often compile client code via Genes (Haxe→JS).
 * - We want a faithful Phoenix API surface that is usable from Haxe without raw JS.
 *
 * HOW
 * - `@:jsRequire("phoenix", "Socket")` binds to the Phoenix Socket constructor.
 * - `Channel` and `Push` are exposed as separate extern modules for easy importing.
 */
#if js
@:jsRequire("phoenix", "Socket")
extern class Socket {
  public function new(?endpointUrl: String, ?opts: SocketOptions): Void;
  public function connect(): Void;
  public function disconnect(?code: Int, ?reason: String): Void;
  public function isConnected(): Bool;
  public function channel(topic: String, ?params: js.lib.Object): Channel;
}

typedef SocketOptions = {
  @:optional var timeout: Int;
  @:optional var heartbeatIntervalMs: Int;
  @:optional var params: js.lib.Object;
}
#end
