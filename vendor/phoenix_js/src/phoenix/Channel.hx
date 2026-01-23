package phoenix;

#if js
/**
 * phoenix.Channel (JS)
 *
 * WHAT
 * - Extern for the Phoenix JS Channel class created by `Socket.channel(...)`.
 *
 * WHY
 * - Exposing this as a top-level module allows `import phoenix.Channel` from
 *   other Haxe modules (Haxe module resolution is file-based).
 *
 * HOW
 * - `@:native("Channel")` binds to the runtime constructor name used by Phoenix.
 */
@:native("Channel")
extern class Channel {
  public function join(?timeout: Int): Push;
  public function leave(?timeout: Int): Push;
  public function push(event: String, payload: js.lib.Object, ?timeout: Int): Push;
  public function on(event: String, callback: js.lib.Object -> Void): Void;
  public function off(event: String, ?callback: js.lib.Object -> Void): Void;
}
#end

