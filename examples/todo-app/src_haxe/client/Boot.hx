package client;

import phoenix.Socket;
import phoenix.live_view.Hook;
import phoenix.live_view.HookContext;
import phoenix.live_view.LiveSocket;
import phoenix.live_view.LiveSocket.LiveSocketParams;
import client.hooks.AutoFocusHook;
import client.hooks.CopyToClipboardHook;
import client.hooks.PingHook;
import client.hooks.ThemeToggleHook;
import client.utils.Theme;
import client.channels.PingChannelClient;
import haxe.DynamicAccess;
import StringTools;

/**
 * Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
 * Avoids raw JS strings; uses typed Haxe that compiles via Genes.
 * Only uses dynamic interop at the Phoenix Hook boundary (`this` context).
 */
class Boot {
	static inline function hookContext():HookContext {
		return cast js.Lib.nativeThis;
	}

	static function readCsrfToken():Null<String> {
		var meta = js.Browser.document.querySelector("meta[name='csrf-token']");
		return meta == null ? null : meta.getAttribute("content");
	}

	static function connectLiveView(hooks:DynamicAccess<Hook>):Void {
		var csrfToken = readCsrfToken();
		var params:LiveSocketParams = {};
		if (csrfToken != null && StringTools.trim(csrfToken) != "") {
			params._csrf_token = csrfToken;
		}

		var liveSocket = new LiveSocket("/live", Socket, {
			params: params,
			hooks: hooks
		});

		liveSocket.connect();
		js.Syntax.code("window.liveSocket = {0}", liveSocket);
	}

	static function buildHooks():DynamicAccess<Hook> {
		return HookRegistry.build({
			AutoFocus: {
				mounted: function():Void {
					AutoFocusHook.mounted(hookContext());
				}
			},
			Ping: {
				mounted: function():Void {
					PingHook.mounted(hookContext());
				}
			},
			CopyToClipboard: {
				mounted: function():Void {
					CopyToClipboardHook.mounted(hookContext());
				}
			},
			ThemeToggle: {
				mounted: function():Void {
					ThemeToggleHook.mounted(hookContext());
				},
				destroyed: function():Void {
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

		// Boot a minimal typed Phoenix Channel client to validate cross-runtime channel APIs.
		// This is independent of LiveView boot ownership (assets/js vs Haxe/Genes).
		PingChannelClient.bootstrap();

		#if todoapp_hx_live_socket_bootstrap
		// Bootstrap Phoenix LiveView from typed Haxe (Genes).
		//
		// Bootstrapping LiveView is a side-effectful “pick one owner” responsibility, so the todo-app
		// supports two mutually-exclusive owners:
		// 1) JS bootstrap (no flag): `assets/js/phoenix_app.js` does the canonical Phoenix bootstrap
		//    (`new LiveSocket(...).connect()`), and this Haxe/Genes bundle only publishes hooks onto
		//    `window.Hooks`.
		// 2) Haxe bootstrap (with `-D todoapp_hx_live_socket_bootstrap`): this bundle also runs the
		//    LiveSocket bootstrap (`connectLiveView(hooks)`), so more of the client boot is typed.
		//
		// This repo defaults to (2) via `build-client.hxml`. Remove the define there if you want to
		// switch back to (1).
		//
		// `assets/js/phoenix_app.js` still keeps a runtime guard to avoid double-connect if both are present.
		connectLiveView(hooks);
		#end
	}
}
