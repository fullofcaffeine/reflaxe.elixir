package client.hooks;

import phoenix.live_view.HookContext;
import phoenix.live_view.HookContextTools;
import shared.liveview.HookEvents;

class PingHook {
	public static function mounted(hook:HookContext):Void {
		try {
			HookContextTools.pushEncoded(hook, HookEvents.encodeClientPush(HookPing));
		} catch (_:Dynamic) {
			// LiveView hook callbacks can throw host JS values; the ping probe is optional diagnostics.
		}
	}
}
