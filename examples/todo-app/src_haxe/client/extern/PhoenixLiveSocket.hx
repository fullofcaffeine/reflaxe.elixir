package client.extern;

import haxe.DynamicAccess;

/**
 * PhoenixLiveSocket
 *
 * WHAT
 * - Extern for the browser `LiveSocket` constructor exported by the `phoenix_live_view` npm package.
 *
 * WHY
 * - Allows us to bootstrap Phoenix LiveView from typed Haxe (Genes output) while staying faithful to
 *   Phoenix's standard JS integration surface.
 *
 * HOW
 * - Constructed as: `new LiveSocket("/live", Socket, {params: {...}, hooks: ...})`
 * - We model only the options we actually use in the todo-app (params + hooks).
 */
typedef LiveSocketParams = {
  @:optional var _csrf_token: String;
}

typedef LiveSocketOptions = {
  @:optional var params: LiveSocketParams;
  @:optional var hooks: DynamicAccess<PhoenixHook>;
}

@:jsRequire("phoenix_live_view", "LiveSocket")
extern class PhoenixLiveSocket {
  public function new(endpoint: String, socket: Class<PhoenixSocket>, options: LiveSocketOptions): Void;
  public function connect(): Void;
}

