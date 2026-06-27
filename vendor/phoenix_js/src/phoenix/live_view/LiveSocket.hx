package phoenix.live_view;

import phoenix.Socket;

/**
 * phoenix.live_view.LiveSocket (JS)
 *
 * WHAT
 * - Typed extern for the browser `LiveSocket` constructor exported by the `phoenix_live_view` npm package.
 *
 * WHY
 * - Allows bootstrapping Phoenix LiveView from typed Haxe (Genes output) while staying faithful to
 *   Phoenix's standard JS integration surface.
 *
 * HOW
 * - Constructed as: `new LiveSocket("/live", Socket, {params: {...}, hooks: ...})`
 * - We model only the options we use (params + hooks).
 */
typedef LiveSocketParams = {
  @:optional var _csrf_token: String;
}

typedef LiveSocketOptions = {
  @:optional var params: LiveSocketParams;
  @:optional var hooks: HookMap;
}

#if js
@:jsRequire("phoenix_live_view", "LiveSocket")
extern class LiveSocket {
  public function new(endpoint: String, socket: Class<Socket>, options: LiveSocketOptions): Void;
  public function connect(): Void;
  public function disconnect(): Void;
  public function isConnected(): Bool;
}
#end
