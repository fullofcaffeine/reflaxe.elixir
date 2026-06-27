package client.hooks;

import phoenix.live_view.HookContext;

class PingHook {
	public static function mounted(hook:HookContext):Void {
		try {
			if (hook.pushEvent != null) {
				hook.pushEvent("ping", {});
			}
		} catch (_:Dynamic) {
			// LiveView hook callbacks can throw host JS values; the ping probe is optional diagnostics.
		}
	}
}
