package client.hooks;

import phoenix.live_view.HookContext;

class AutoFocusHook {
  public static function mounted(hook: HookContext): Void {
    // Element.focus() exists on HTMLElement; we keep this as a safe boundary call.
    try {
      untyped hook.el.focus();
    } catch (_: Dynamic) {}
  }
}
