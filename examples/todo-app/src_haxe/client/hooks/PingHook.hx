package client.hooks;

import phoenix.live_view.HookContext;
import shared.liveview.HookEvents;

class PingHook {
	public static function mounted(hook:HookContext):Void {
		try {
			HookEvents.pushHookPing(hook);
		} catch (_:Dynamic) {
			// LiveView hook callbacks can throw host JS values; the ping probe is optional diagnostics.
		}
	}
}
