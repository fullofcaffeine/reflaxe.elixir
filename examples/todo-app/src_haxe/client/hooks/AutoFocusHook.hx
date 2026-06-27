package client.hooks;

import phoenix.live_view.HookContext;

class AutoFocusHook {
	public static function mounted(hook:HookContext):Void {
		try {
			hook.el.focus();
		} catch (_:Dynamic) {}
	}
}
