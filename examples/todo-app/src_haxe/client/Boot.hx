package client;

import client.extern.PhoenixHookContext;
import client.hooks.AutoFocusHook;
import client.hooks.CopyToClipboardHook;
import client.hooks.PingHook;
import client.hooks.ThemeToggleHook;
import client.utils.Theme;
import shared.liveview.HookName;

import haxe.DynamicAccess;

// Phoenix Hook type with only the callbacks we use
typedef PhoenixHook = {
  var mounted: Void->Void;
  @:optional var destroyed: Void->Void;
}

/**
 * Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
 * Avoids raw JS strings; uses typed Haxe that compiles via Genes.
 * Only uses dynamic interop at the Phoenix Hook boundary (`this` context).
 */
class Boot {
  static inline function hookContext(): PhoenixHookContext {
    return cast js.Lib.nativeThis;
  }

  static function buildHooks(): DynamicAccess<PhoenixHook> {
    var hooks: DynamicAccess<PhoenixHook> = {};

    hooks[HookName.AutoFocus] = {
      mounted: function(): Void {
        AutoFocusHook.mounted(hookContext());
      }
    };

    hooks[HookName.Ping] = {
      mounted: function(): Void {
        PingHook.mounted(hookContext());
      }
    };

    hooks[HookName.CopyToClipboard] = {
      mounted: function(): Void {
        CopyToClipboardHook.mounted(hookContext());
      }
    };

    hooks[HookName.ThemeToggle] = {
      mounted: function(): Void {
        ThemeToggleHook.mounted(hookContext());
      },
      destroyed: function(): Void {
        ThemeToggleHook.destroyed(hookContext());
      }
    };

    return hooks;
  }

  public static function main() {
    Theme.applyStoredOrDefault();

    var hooks = buildHooks();

    // Publish hooks for phoenix_app.js to pick up
    js.Syntax.code("window.Hooks = Object.assign(window.Hooks || {}, {0})", hooks);
  }
}
