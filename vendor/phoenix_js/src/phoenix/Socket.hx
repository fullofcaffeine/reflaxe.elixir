package phoenix;

/**
 * phoenix.Socket (JS)
 *
 * WHAT
 * - Typed externs for the Phoenix Channels JS client APIs from the `phoenix` npm package.
 *
 * WHY
 * - Reflaxe.Elixir projects often compile client code via Genes (Haxe→JS).
 * - We want a faithful Phoenix API surface that is usable from Haxe without raw JS.
 *
 * HOW
 * - `@:jsRequire("phoenix", "Socket")` binds to the Phoenix Socket constructor.
 * - `Channel` and `Push` are runtime classes constructed by Phoenix; we expose them via externs so
 *   Haxe code can type them when wrapping the API.
 */
#if js

import js.lib.Object as JsObject;
import js.lib.Function as JsFunction;

@:jsRequire("phoenix", "Socket")
extern class Socket {
  public function new(?endpointUrl: String, ?opts: SocketOptions): Void;
  public function connect(): Void;
  public function disconnect(?code: Int, ?reason: String): Void;
  public function isConnected(): Bool;
  public function channel(topic: String, ?params: ChannelParams): Channel;
  public function remove(channel: Channel): Void;
  public function connectionState(): String;
  public function makeRef(): String;
  public function sendHeartbeat(): Void;
}

typedef SocketParams = {
  @:optional var _csrf_token: String;
}

typedef ChannelParams = {}

typedef SocketOptions = {
  @:optional var transport: JsFunction;
  @:optional var timeout: Int;
  @:optional var heartbeatIntervalMs: Int;
  @:optional var reconnectAfterMs: Int -> Int;
  @:optional var rejoinAfterMs: Int -> Int;
  @:optional var logger: String -> String -> JsObject -> Void;
  @:optional var longpollerTimeout: Int;
  @:optional var params: SocketParams;
  @:optional var binaryType: String;
  @:optional var vsn: String;
}

@:native("Channel")
extern class Channel {
  public function join(?timeout: Int): Push;
  public function leave(?timeout: Int): Push;
  public function push(event: String, payload: JsObject, ?timeout: Int): Push;
  public function on(event: String, callback: JsObject -> Void): Void;
  public function off(event: String, ?callback: JsObject -> Void): Void;
  public function state(): String;
}

@:native("Push")
extern class Push {
  public function receive(status: String, callback: JsObject -> Void): Push;
}
#end
