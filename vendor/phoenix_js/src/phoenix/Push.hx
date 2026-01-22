package phoenix;

#if js
/**
 * phoenix.Push (JS)
 *
 * WHAT
 * - Extern for the Phoenix JS Push returned by `channel.join()` and `channel.push(...)`.
 *
 * WHY
 * - `Push.receive("ok" | "error", ...)` is the core control-flow mechanism for
 *   join/push acknowledgements.
 *
 * HOW
 * - `@:native("Push")` binds to the runtime constructor name used by Phoenix.
 */
@:native("Push")
extern class Push {
  public function receive(status: String, callback: js.lib.Object -> Void): Push;
}
#end

