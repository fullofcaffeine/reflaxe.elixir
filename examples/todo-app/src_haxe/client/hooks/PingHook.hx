package client.hooks;

import client.extern.PhoenixHookContext;

class PingHook {
  public static function mounted(hook: PhoenixHookContext): Void {
    try {
      if (hook.pushEvent != null) {
        hook.pushEvent("ping", {});
      }
    } catch (_: Dynamic) {}
  }
}

