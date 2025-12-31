package client;

import client.extern.PhoenixHookContext;
import client.hooks.AutoFocusHook;
import client.hooks.CopyToClipboardHook;
import client.hooks.PingHook;
import client.hooks.ThemeToggleHook;
import client.utils.Theme;

// Phoenix Hook type with only the callbacks we use
typedef PhoenixHook = {
  var mounted: Void->Void;
  @:optional var destroyed: Void->Void;
}

// Typed Hooks registry shape
typedef Hooks = {
  var AutoFocus: PhoenixHook;
  var Ping: PhoenixHook;
  var CopyToClipboard: PhoenixHook;
  var ThemeToggle: PhoenixHook;
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

  public static function main() {
    Theme.applyStoredOrDefault();

    var hooks: Hooks = {
      AutoFocus: {
        mounted: function(): Void {
          AutoFocusHook.mounted(hookContext());
        }
      },
      Ping: {
        mounted: function(): Void {
          PingHook.mounted(hookContext());
        }
      },
      CopyToClipboard: {
        mounted: function(): Void {
          CopyToClipboardHook.mounted(hookContext());
        }
      },
      ThemeToggle: {
        mounted: function(): Void {
          ThemeToggleHook.mounted(hookContext());
        },
        destroyed: function(): Void {
          ThemeToggleHook.destroyed(hookContext());
        }
      }
    };

    // Publish hooks for phoenix_app.js to pick up
    js.Syntax.code("window.Hooks = Object.assign(window.Hooks || {}, {0})", hooks);
  }
}
