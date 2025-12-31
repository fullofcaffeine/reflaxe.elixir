package client.hooks;

import client.extern.PhoenixHookContext;

class AutoFocusHook {
  public static function mounted(hook: PhoenixHookContext): Void {
    // Element.focus() exists on HTMLElement; we keep this as a safe boundary call.
    try {
      untyped hook.el.focus();
    } catch (_: Dynamic) {}
  }
}

