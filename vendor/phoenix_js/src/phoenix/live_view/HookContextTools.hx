package phoenix.live_view;

#if js
import phoenix.channels.EncodedEvent;

/**
 * Typed helpers for Phoenix LiveView hook contexts.
 *
 * Phoenix exposes `pushEvent(name, payload)` as two loose arguments. App code
 * should prefer shared EncodedEvent values produced by a typed protocol module.
 */
class HookContextTools {
  public static inline function pushEncoded(hook: HookContext, event: EncodedEvent): Void {
    if (hook.pushEvent != null) {
      hook.pushEvent(event.event, event.payload);
    }
  }
}
#end
