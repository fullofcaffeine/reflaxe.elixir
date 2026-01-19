package client;

import client.extern.PhoenixHookContext;
import client.extern.PhoenixHook;
import client.extern.PhoenixLiveSocket;
import client.extern.PhoenixLiveSocket.LiveSocketParams;
import client.extern.PhoenixSocket;
import client.hooks.AutoFocusHook;
import client.hooks.CopyToClipboardHook;
import client.hooks.PingHook;
import client.hooks.ThemeToggleHook;
import client.utils.Theme;

import haxe.DynamicAccess;

/**
 * Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
 * Avoids raw JS strings; uses typed Haxe that compiles via Genes.
 * Only uses dynamic interop at the Phoenix Hook boundary (`this` context).
 */
class Boot {
  static inline function hookContext(): PhoenixHookContext {
    return cast js.Lib.nativeThis;
  }

  static function readCsrfToken(): Null<String> {
    var meta = js.Browser.document.querySelector("meta[name='csrf-token']");
    return meta == null ? null : meta.getAttribute("content");
  }

  static function connectLiveView(hooks: DynamicAccess<PhoenixHook>): Void {
    var csrfToken = readCsrfToken();
    var params: LiveSocketParams = {};
    if (csrfToken != null && StringTools.trim(csrfToken) != "") {
      params._csrf_token = csrfToken;
    }

    var liveSocket = new PhoenixLiveSocket(
      "/live",
      PhoenixSocket,
      {
        params: params,
        hooks: hooks
      }
    );

    liveSocket.connect();
    js.Syntax.code("window.liveSocket = {0}", liveSocket);
  }

  static function buildHooks(): DynamicAccess<PhoenixHook> {
    return HookRegistry.build({
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
    });
  }

  public static function main() {
    Theme.applyStoredOrDefault();

    var hooks = buildHooks();

    // Publish hooks for phoenix_app.js to pick up
    js.Syntax.code("window.Hooks = Object.assign(window.Hooks || {}, {0})", hooks);

    #if todoapp_hx_live_socket_bootstrap
    // Optional: Do the Phoenix LiveView bootstrap from typed Haxe (Genes).
    //
    // Bootstrapping LiveView is a side-effectful “pick one owner” responsibility, so the todo-app
    // supports two mutually-exclusive owners:
    // 1) Default (no flag): `assets/js/phoenix_app.js` does the canonical Phoenix bootstrap
    //    (`new LiveSocket(...).connect()`), and the Haxe/Genes bundle only publishes hooks onto
    //    `window.Hooks`.
    // 2) Opt-in (with `-D todoapp_hx_live_socket_bootstrap`): this Haxe/Genes bundle also runs the
    //    LiveSocket bootstrap (`connectLiveView(hooks)`), so more of the client boot is typed.
    //
    // The todo-app enables this define by default in `build-client.hxml`. Remove it there if you
    // want to switch back to the JS bootstrap.
    //
    // `assets/js/phoenix_app.js` still keeps a runtime guard to avoid double-connect.
    connectLiveView(hooks);
    #end
  }
}
